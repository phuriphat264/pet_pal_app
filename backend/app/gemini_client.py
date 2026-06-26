# Calls Gemini (gemini-2.5-flash-lite) to write a nicer natural-language
# summary/reasons for hotel candidates that the local pgvector embedding
# search has *already selected* -- Gemini enriches wording, it doesn't
# pick the hotels, so a bad or hallucinated response can't surface a
# result outside what the real semantic search found.
import json
import re

import google.generativeai as genai

MODEL_NAME = "gemini-1.5-flash"
REQUEST_TIMEOUT_SECONDS = 30


def _build_hotel_context(hotels: list[dict]) -> str:
    blocks = []
    for i, h in enumerate(hotels, start=1):
        tags = ", ".join(h.get("tags", []))
        ai_tags = ", ".join(h.get("ai_tags", []))
        desc = (h.get("description") or "")[:150]
        location = h.get("location") or "ไม่ทราบสถานที่"
        has_private = "private" in h.get("ai_tags", [])
        private_note = "มีห้องส่วนตัว" if has_private else "ไม่ใช่ห้องส่วนตัว"
        blocks.append(
            f'โรงแรม {i}: "{h["name"]}"\n'
            f"  สถานที่: {location}\n"
            f"  จุดเด่น: {tags}\n"
            f"  ลักษณะที่พักเหมาะกับสัตว์เลี้ยงแบบ: {ai_tags}\n"
            f"  ห้องพัก: {private_note}\n"
            f"  รายละเอียด: {desc}"
        )
    return "\n\n".join(blocks)


def build_prompt(text: str, hotels: list[dict]) -> str:
    hotel_context = _build_hotel_context(hotels)
    return f'''คุณคือ AI ผู้เชี่ยวชาญด้านพฤติกรรมสัตว์เลี้ยง ระบบค้นหาเชิงความหมาย (semantic vector search) ได้คัดเลือกที่พักที่ใกล้เคียงกับสิ่งที่เจ้าของเล่ามาไว้แล้ว หน้าที่ของคุณคือเขียนคำอธิบายให้เป็นธรรมชาติและเข้าใจง่ายขึ้น ไม่ใช่เลือกที่พักใหม่

--- ที่พักที่ระบบคัดเลือกมาแล้ว (ใช้รายการนี้เท่านั้น ห้ามเพิ่ม/เปลี่ยนชื่อ) ---
{hotel_context}

--- สิ่งที่เจ้าของเล่ามาเกี่ยวกับสัตว์เลี้ยง ---
"{text}"

--- วิธีคิด ---
1. ตีความนิสัย/อารมณ์/ความต้องการของสัตว์เลี้ยงจากบริบท แม้เจ้าของไม่ได้พูดคำตรงๆ
   - ถ้าน้องเป็นอินโทรเวิร์ท ขี้อาย หรือเครียดง่าย และที่พักนั้น "มีห้องส่วนตัว" ให้ระบุในเหตุผลว่าเจ้าของไม่จำเป็นต้องขอให้พนักงานอัปเดตรูป/วิดีโอบ่อยๆ เพราะการถูกรบกวนซ้ำๆ อาจทำให้น้องเครียดได้มากขึ้น
2. ใช้ที่พักทุกรายการที่ให้มาด้านบน เขียนเหตุผลเชื่อมโยงนิสัยของน้องกับจุดเด่นของที่พักนั้นโดยตรง เป็นภาษาไทยสั้นๆ เข้าใจง่าย
3. ชื่อโรงแรมใน "hotelName" ต้องตรงกับชื่อที่ให้มาทุกตัวอักษร

ตอบเป็น JSON เท่านั้น ห้ามมีข้อความอื่นนอกเหนือจาก JSON:
{{
  "summary": "สรุปนิสัย/ความต้องการของสัตว์เลี้ยงใน 1 ประโยค",
  "matches": [
    {{ "hotelName": "ชื่อโรงแรม", "reason": "เหตุผลว่าทำไมเหมาะกับนิสัยของน้อง" }}
  ]
}}
'''


def parse_response(raw_text: str) -> dict | None:
    """Extracts {summary, matches} from the LLM's raw text response.
    Returns None if the response doesn't contain a usable JSON object.
    """
    cleaned = re.sub(r"```json\s*", "", raw_text)
    cleaned = re.sub(r"```\s*", "", cleaned).strip()

    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end == -1:
        return None

    try:
        data = json.loads(cleaned[start:end + 1])
    except json.JSONDecodeError:
        return None

    summary = data.get("summary")
    matches = data.get("matches")
    if not isinstance(summary, str) or not isinstance(matches, list):
        return None

    cleaned_matches = []
    for m in matches:
        if isinstance(m, dict) and "hotelName" in m:
            cleaned_matches.append({
                "hotelName": str(m["hotelName"]),
                "reason": str(m.get("reason", "")),
            })

    return {"summary": summary, "matches": cleaned_matches}


def call_gemini_enrich(text: str, hotels: list[dict], api_key: str) -> dict | None:
    """Calls Gemini with the semantic-matching prompt and returns the parsed
    {summary, matches} dict, or None if the call fails or the response is
    empty/unparseable. Raises on unexpected SDK errors so the caller's
    try/except can apply the local fallback uniformly.
    """
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(MODEL_NAME)
    prompt = build_prompt(text, hotels)

    response = model.generate_content(
        prompt,
        request_options={"timeout": REQUEST_TIMEOUT_SECONDS},
    )

    raw_text = (response.text or "").strip()
    if not raw_text:
        return None

    return parse_response(raw_text)
