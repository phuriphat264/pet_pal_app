# PetPal — Pre-Production Checklist (Flow + Security Audit)

สถานะ ณ 2026-07-29 — ตรวจทั้งระบบ (backend `backend/app/` + Flutter `lib/`) ด้วย agent คู่ขนาน 6 ตัว
ครอบคลุม: ทุก user flow ทำงานจริงไหม, authorization/IDOR, injection, secrets/rate-limit, infra hardening

Legend: `[x]` = ตรวจแล้วโอเค/ทำงานสมบูรณ์ · `[/]` = ทำงานได้บางส่วน/มีจุดที่ต้องแก้ · `[ ]` = ยังไม่ทำ/มีช่องโหว่จริง ต้องแก้ก่อนโปรดักชัน

---

## 🔴 Must-fix ก่อนขึ้นโปรดักชัน (เรียงตาม impact)

- [ ] **กล้อง: ช่องโหว่ authorization จริง** — `backend/app/api/cameras.py:149-179` เช็คแค่ระดับโรงแรม ไม่เช็คห้อง/วันที่/สถานะจ่ายเงิน ลูกค้าที่มี booking ที่โรงแรมนั้น (แม้ยังไม่จ่าย, จองห้องอื่น, หรือ checkout ไปแล้ว) ดูกล้องห้องไหนก็ได้ในโรงแรมนั้น — ยืนยันตรงกันจาก 2 agent อิสระ
- [ ] **Refresh token ไม่เคย revoke ได้** — ไม่มี endpoint logout, ไม่มี token blacklist/rotation ถ้า refresh token หลุด ใช้ replay ได้นาน 14 วันเต็ม โดยเจ้าของ account เปลี่ยนรหัสผ่านก็หยุดไม่ได้ (Redis มีอยู่แล้วในสแตก เพิ่ม jti denylist ไม่ยาก)
- [ ] **Rate limiter อ่าน IP ผิดหลัง nginx ใน prod** — uvicorn ไม่ได้ตั้ง `--proxy-headers`/`--forwarded-allow-ips` ทำให้ limiter ระดับ backend เห็น IP ของ nginx (ทุกคนแชร์ bucket เดียวกัน 10 req/60s) ผู้ใช้จริงอาจโดนล็อกกันเองตอนโหลดสูง ส่วน nginx-level limiter (30/min+burst) ยังทำงานถูกอยู่ แต่ backend-level ใช้งานไม่ได้ตามที่ตั้งใจ
- [ ] **Default admin password ไม่มี guard** — `seed.py` สร้าง `admin@petpal.app` ด้วย `SEED_ADMIN_PASSWORD` ถ้าลืมตั้งใน prod จะได้ `ChangeMe123!` ที่รู้กันทั่วไป ควรมี startup assertion ปฏิเสธการบูตถ้ายังเป็นค่า default เวลาไม่ใช่ debug mode
- [ ] **Partner document upload ไม่เช็ค content-type** — `backend/app/schemas/partner.py:41`, `backend/app/api/partners.py:88` ผู้ใช้ขอ presigned URL พร้อมระบุ `content_type` เป็นอะไรก็ได้ (เช่น `text/html`) อัปโหลดไฟล์ HTML/JS แล้วให้แอดมินเปิดดูตอน review เอกสาร = stored XSS ผ่านไฟล์ที่ serve กลับมา
- [ ] **ไม่มี server-side upload size limit** — จุดเดียวกับข้างบน (`storage_service.py`) ไม่ได้ตั้ง Content-Length policy บน presigned PUT
- [ ] **ไม่มี 3D-Secure สำหรับบัตรที่ต้องใช้** — ค้นทั้ง repo ไม่เจอ `authorize_uri`/`3ds`/webview ใดๆ บัตรที่ต้อง 3DS จะ fail ทันทีฝั่ง client (`booking_page.dart:535-539`) โดยไม่มี redirect — เสียรายได้จริงถ้าเปิดใช้บัตรไทยที่บังคับ 3DS
- [ ] **Session ไม่ refresh ตอนเปิดแอปใหม่** — `main.dart` เรียก `GET /users/me` ตรงๆ ตอน cold start ถ้า access token หมดอายุ (30 นาที) จะ force logout ทั้งที่ refresh token ยังใช้ได้อีก 14 วัน — bug ทำให้ผู้ใช้ต้อง login ใหม่บ่อยเกินจำเป็น
- [ ] **ไม่มี DB backup strategy เลย** — ค้นทั้ง repo ไม่เจอ script/cron/เอกสารสำรองข้อมูล Postgres โปรดักชันจริงต้องมีก่อนเปิดใช้งาน
- [ ] **Android release build เซ็นด้วย debug key + ไม่มี code shrinking** — `android/app/build.gradle.kts:35-41` มี TODO ค้างอยู่แล้วว่าต้องตั้ง signing config จริงก่อนปล่อย ไม่มี `isMinifyEnabled`/`proguardFiles` ทำให้ decompile code ได้ง่าย

---

## Customer-Facing Flows

- [ ] Facebook Sign-In — backend ทำเสร็จสมบูรณ์ (`backend/app/api/auth.py:99-107`, `oauth_service.py`) แต่ฝั่ง Flutter **ไม่มีเลย** — ไม่มี `flutter_facebook_auth` ใน pubspec, ไม่มีปุ่มในหน้า login, `strings.xml` ยังเป็น placeholder `YOUR_FACEBOOK_APP_ID` — ต้องทำต่อให้จบหรือถอด UI ที่ค้างไว้ออก
- [/] Register → Login → session persist — ใช้งานได้ปกติ แต่มี bug refresh-on-restart (ดูรายการ must-fix ด้านบน)
- [x] Google Sign-In — ทำงานสมบูรณ์ end-to-end (แก้ iOS config ในเซสชันนี้แล้วด้วย)
- [/] Forgot/Reset password — flow ถูกต้องหมด (token 256-bit, hash, single-use, ไม่มี user-enumeration) แต่ dev `.env` ไม่ตั้ง SMTP เลยแค่ log token ออก console เฉยๆ — **ต้องยืนยันด้วยตัวเองว่า `.env.production` (มี SMTP จริง) ถูก deploy จริง ไม่ใช่แค่มีไฟล์อยู่เฉยๆ**
- [/] Browse hotels / AI Smart Match → หน้ารายละเอียดโรงแรม — เจอ bug จริง: `HotelListItem` (ที่ใช้ในหน้า list/match) ไม่มี field `rooms` และหน้า detail ไม่ re-fetch `GET /hotels/{id}` ทำให้ตัวเลือกห้องว่างเปล่า จองห้องเจาะจงไม่ได้จากทางนี้ (ต้อง fetch hotel detail ใหม่เมื่อเปิดหน้า) — นอกจากนี้ client poll timeout (20s) สั้นกว่า backend Gemini budget (40s) ทำให้ AI match มัก fallback ไปผลแบบ local โดยไม่จำเป็น
- [x] สร้าง/แก้ไขโปรไฟล์สัตว์เลี้ยง — ทำงานสมบูรณ์ (ไม่มีฟีเจอร์อัปโหลดรูปสัตว์เลี้ยง แต่เป็นฟีเจอร์ที่ไม่มีอยู่ ไม่ใช่ของที่พังคาไว้)
- [x] จองห้องพักโรงแรม — ทำงานสมบูรณ์ ราคาคำนวณฝั่ง server เสมอ
- [/] จ่ายเงิน (Omise) — tokenization ถูกต้อง (server ไม่เห็นเลขบัตรจริง), PromptPay + webhook verify กับ Omise API จริงก่อนอัปเดตสถานะ (ปลอดภัย) แต่ขาด 3D-Secure (ดู must-fix ด้านบน)
- [x] แชท + โทรเสียง/วิดีโอ (LiveKit) — real-time ผ่าน WebSocket ที่ auth จริง, LiveKit token ออกจาก backend จริง
- [/] ดูกล้องสด — โค้ด flow ถูกต้อง (booking-gated check มีจริง, ต่อ RTSP จริงผ่าน media_kit) แต่ **ยังไม่มีกล้องลงทะเบียนจริงเลยสักตัว** ผู้ใช้ปัจจุบันเห็นแต่วิดีโอ DEMO ที่ label ไว้ชัดเจน — ต้องยืนยันว่าข้อความการตลาดไม่ได้สัญญาว่ามีกล้องสดจริงถ้ายังไม่พร้อม (ดูช่องโหว่ authorization ในหมวด security ด้านล่างด้วย)
- [x] สมัครเป็น partner (ร้าน/โรงแรม) — อัปโหลดเอกสารแบบ presigned URL จริง, ติดตามสถานะจริง
- [/] ศูนย์แจ้งเตือนในแอป — ใช้งานได้ แต่ปัจจุบันมีแค่ "ข้อความแชทใหม่" เท่านั้นที่สร้าง notification จริง — booking ยืนยันแล้ว/partner ได้รับอนุมัติ ไม่เคยส่ง notification ทั้งที่ schema/UI รองรับ
- [ ] Push notification ของ OS (FCM/APNs) — **ยังไม่ได้ทำเลย** ไม่มี `firebase_messaging` หรือแพ็กเกจ push ใดๆ ทั้งฝั่ง client และ backend — แจ้งเตือนได้เฉพาะตอนแอปเปิด WebSocket ค้างอยู่เท่านั้น ต้องตัดสินใจว่าจำเป็นสำหรับรอบเปิดตัวนี้ไหม

## Partner / Admin / Technician Flows

- [x] Admin อนุมัติ/ปฏิเสธใบสมัคร partner — gate ด้วย `require_admin` ถูกต้อง
- [x] Partner shop dashboard (ห้อง/availability/booking/แชท) — ทุกจุดเช็ค ownership ฝั่ง server จริง ไม่ใช่แค่ซ่อน UI
- [x] Admin สร้างบัญชีช่าง + ช่างล็อกอิน — role gate ถูกต้อง, technician endpoint โดน 403 ถ้าไม่ใช่ role ที่ถูกต้อง
- [x] ช่างจัดการกล้อง + ขอบเขตต่อช่างคนเดียว — server เช็คจริงว่ากล้องนี้ assign ให้ช่างคนนี้หรือยังไม่ assign เท่านั้น เดา UUID กล้องช่างคนอื่นได้ 403 จริง
- [x] Admin คืนเงิน — เรียก Omise refund API จริงก่อน แล้วค่อย commit DB (ไม่ใช่แค่ flip flag) ถ้า Omise fail จะไม่ commit สถานะเพี้ยน
- [ ] **การเข้าถึงสตรีมกล้อง** — VULNERABLE ตามที่ระบุใน must-fix ด้านบน (hotel-level เท่านั้น ไม่เช็คห้อง/วันที่/การจ่ายเงิน)
- [x] Admin เห็นข้อมูลทั้งระบบ (users/cameras/payments) — gate ด้วย `require_admin`/`require_technician` ถูกต้องทุก endpoint

## Security — Authorization & IDOR

- [x] Role-based access control หลัก (`require_admin`, `require_technician`) — ครอบคลุมถูกต้องทุก route ที่ควรมี
- [x] ไม่มีทางยกระดับสิทธิ์ตัวเองเป็น admin ได้ — ตรวจแล้วไม่มีช่องทาง
- [x] Booking/Pet/Payment/Partner/Hotel/Notification — ownership check ครบทุก endpoint หลัก (customer เห็นแค่ของตัวเอง)
- [ ] **Booking สร้างได้โดยใส่ `pet_id` ของคนอื่นได้** — `backend/app/api/bookings.py:44` ไม่เช็ค `Pet.owner_id == user.id` ก่อนรับ severity ต่ำ (ไม่ได้ขโมยข้อมูล แต่ทำให้ booking แสดงชื่อสัตว์เลี้ยงคนอื่นผิด) — เพิ่ม check แบบเดียวกับ `pets.py`
- [ ] **กล้องสตรีม — ดูรายละเอียดในหมวด must-fix ด้านบน**
- [x] Chat WebSocket auth — ใช้ JWT เดียวกับ REST, ทุกข้อความยัง authorize ผ่าน `_authorize_thread`
- [/] Chat WebSocket ส่ง token ผ่าน query string — ไม่ใช่ bypass แต่เสี่ยงหลุดใน access log/proxy log เพราะแอปนี้เป็น Flutter client ที่ตั้ง custom header ได้ ควรย้ายไปใช้ header-based handshake แทน
- [x] Omise webhook ไม่มี auth แต่ปลอดภัย — re-verify กับ Omise API เสมอ ไม่เชื่อ body ที่ส่งมา

## Security — Injection & Input Validation

- [x] SQL Injection — ไม่มี raw SQL ที่ interpolate user input เลยทั้ง backend ใช้ SQLAlchemy ORM parameterized query ทุกจุด
- [x] Path traversal ในไฟล์อัปโหลด — ปลอดภัย (object key generate จาก UUID + owner_id ฝั่ง server ไม่ใช้ filename ผู้ใช้)
- [ ] **Content-type ไฟล์อัปโหลดไม่ validate** — ดู must-fix ด้านบน (stored XSS risk)
- [ ] **ไม่มี server-side file size limit** — ดู must-fix ด้านบน
- [/] LLM prompt injection (AI hotel matching) — ผลลัพธ์จาก Gemini ถูก filter ด้วย allow-list ชื่อโรงแรมจริงเสมอ (ป้องกันไม่ให้ inject โรงแรมปลอมได้) แต่ข้อความ summary/reason ยังโดน manipulate เนื้อหาได้ — เพิ่ม `max_length` ให้ `MatchRequest.text` (ตอนนี้ไม่จำกัดความยาว เสี่ยง cost/DoS เบาๆ)
- [x] Mass assignment — ทุก update endpoint ใช้ schema แบบ allow-list ชัดเจน ไม่มีทางแก้ field ที่ไม่ควรแก้ได้ (role, id, has_password ฯลฯ)
- [x] Email XSS — ไม่มีความเสี่ยง อีเมลส่งเป็น plain text ล้วน ไม่มี HTML template
- [/] CORS — `allow_origins=["*"]` กว้างเกินไปสำหรับ prod แต่ `allow_credentials` ไม่ได้เปิด (default False) และ auth ใช้ Bearer token ไม่ใช่ cookie เลยไม่ใช่ช่องโหว่ credential-leak แบบคลาสสิก — แนะนำ scope origin ให้แคบลงก่อนขึ้น prod เป็น defense-in-depth

## Security — Secrets, Auth Tokens & Rate Limiting

- [x] ไม่มี secret จริงถูก commit ในโค้ด — ตรวจ `.env`/`.env.production`/source ทั้งหมดแล้ว ไม่พบ secret จริงหลุดมา (`.env.production` ที่ commit ไว้เป็น placeholder ล้วน)
- [/] Default fallback values ใน config อ่อนเกินไป (`dev-secret-change-me`, `petpal12345` ฯลฯ) — ถ้า `.env` หายไปตอน deploy จะบูตด้วยค่า dev เงียบๆ แนะนำเพิ่ม startup assertion ปฏิเสธค่า default เวลาไม่ใช่ debug mode
- [x] JWT algorithm/expiry — HS256 fixed-algorithm (ป้องกัน alg-confusion attack), access token 30 นาที, refresh 14 วัน — โครงสร้างถูกต้อง
- [ ] **Refresh token ไม่ rotate/revoke ได้ ไม่มี logout endpoint** — ดู must-fix ด้านบน
- [x] Rate limit ครอบคลุมทุก endpoint สำคัญใน `/auth` (login, register, forgot-password, reset-password, set-password, refresh)
- [ ] **Rate limiter อ่าน IP ผิดหลัง nginx** — ดู must-fix ด้านบน
- [x] รหัสผ่าน — hash ด้วย bcrypt, บังคับ min_length=8 ฝั่ง server จริง (ไม่ใช่แค่ UI) — แนะนำพิจารณาเพิ่มเป็น 10-12 ตัวอักษรก่อน prod ตามมาตรฐานปัจจุบัน
- [x] Password reset token — entropy 256-bit, เก็บแค่ hash, single-use, ไม่เคยส่งกลับใน API response
- [/] Reset token log เป็น plain text ถ้าไม่ตั้งค่า SMTP — ปกติสำหรับ dev แต่เสี่ยงถ้า prod ลืมตั้ง SMTP (ควร fail-hard แทน fallback เงียบๆ)
- [x] Transport security ฝั่ง Flutter — ไม่มีการปิด TLS validation, ไม่มี hardcoded http:// ไปยัง production host
- [x] Omise payment webhook — ปลอดภัย (verify กับ Omise API เสมอ ไม่เชื่อ payload ที่ส่งมา)
- [ ] **Default admin password ไม่มี startup guard** — ดู must-fix ด้านบน

## Security — Infra & Deployment Hardening

- [x] Postgres/MinIO/Redis ports ไม่เปิดสู่สาธารณะใน `docker-compose.prod.yml`
- [/] LiveKit UDP/TCP port เปิดสู่สาธารณะโดยตั้งใจ (จำเป็นสำหรับ WebRTC) — ต้อง**ยืนยันด้วยตัวเองว่า `LIVEKIT_API_SECRET` จริงใน prod ไม่ใช่ค่า dev default**
- [ ] **`/docs` และ `/openapi.json` เปิดสาธารณะใน prod ผ่าน nginx** — ควรปิดหรือใส่ auth ก่อนเปิดใช้งานจริง
- [ ] **nginx ไม่มี security headers** — ขาด `Strict-Transport-Security`, `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, และ `server_tokens off`
- [x] nginx TLS config — บังคับ HTTPS redirect, จำกัด TLS 1.2/1.3, cipher list ดี
- [x] Dependency versions — ตรวจแล้วไม่พบ CVE ที่ยืนยันได้ในเวอร์ชันที่ pin ไว้ (FastAPI, python-jose, cryptography, bcrypt ฯลฯ)
- [x] ไม่มี stack trace/debug info หลุดไปหา client — ไม่ได้เปิด debug mode, exception handler ทุกจุด return ข้อความทั่วไป
- [ ] **ไม่มี DB backup strategy** — ดู must-fix ด้านบน
- [ ] **ไม่มี monitoring/error tracking (Sentry ฯลฯ)** — มีแค่ `/health` ที่ return `{"status":"ok"}` เฉยๆ ไม่ได้เช็คว่า DB/Redis/MinIO ยังต่อได้จริงไหม
- [x] Secret ไม่ถูก bake เข้า Docker image — `.env` ถูก exclude ผ่าน `.dockerignore`, inject ตอน runtime เท่านั้น
- [ ] **Android release build ไม่มี code shrinking/obfuscation + เซ็นด้วย debug key** — ดู must-fix ด้านบน
- [x] Gemini API key อยู่ฝั่ง server เท่านั้น — ตรวจแล้วไม่มีใน client code/asset ใดๆ
- [/] `.env` ของแอป Flutter ถูก bundle เป็น asset ตรงๆ (unzip APK อ่านได้เลย) — ปัจจุบันมีแค่ค่า public-safe (API_BASE_URL, Google client id, Omise publishable key) ไม่มีปัญหาตอนนี้ แต่เป็นแพทเทิร์นที่เปราะบาง ถ้ามีคนเผลอใส่ secret จริงเข้าไปทีหลังจะหลุดทันที — แนะนำมี lint/CI guard กันเรื่องนี้

---

*สร้างโดย Claude Code จากการตรวจโค้ดจริง (ไม่ได้เดา) — อ้างอิง file:line ที่ยืนยันได้ทุกจุด รันโดย 6 agent คู่ขนานตรวจแยกกันคนละมุม (authorization, injection, secrets, customer flow, partner/admin flow, infra)*
