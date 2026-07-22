# สเปกสำหรับพัฒนาฟีเจอร์ "ดูกล้องห้องพักสัตว์เลี้ยงแบบเรียลไทม์"

> เอกสารนี้ใช้เป็น prompt/บรีฟสำหรับส่งให้ Claude Code เริ่มพัฒนาโมดูลกล้อง
> ของแอปนายหน้าโรงแรมสัตว์เลี้ยง สามารถ copy ทั้งไฟล์นี้ส่งไปได้เลย
> หรือตัดเป็นช่วงๆ ตาม phase ที่จะให้ Claude Code ทำทีละส่วน

---

## 1. บริบทของระบบ (Context)

กำลังพัฒนาแอปนายหน้า (marketplace) ที่จับคู่เจ้าของสัตว์เลี้ยงกับโรงแรมสัตว์เลี้ยง
โดยมี LLM ใช้ทำ matching และมีระบบแชท/คอลระหว่างลูกค้ากับโรงแรมอยู่แล้ว

ฟีเจอร์ใหม่ที่ต้องการ: ให้ลูกค้าที่ **จองห้องอยู่จริงเท่านั้น** สามารถเปิดดูกล้องในห้องที่จอง
แบบเรียลไทม์ผ่านแอป โดยต้องประหยัด bandwidth และไม่เปิดช่องโหว่ด้านความปลอดภัย

### Hardware ที่ใช้อยู่ตอนนี้
- กล้อง: TP-Link Tapo C210 (รองรับ RTSP port 554 และ ONVIF Profile S port 2020)
- ข้อจำกัดสำคัญ: กล้องรองรับ **main stream สูงสุด 2 สาย + sub stream สูงสุด 2 สาย พร้อมกัน** (รวมสูงสุด 4 การเชื่อมต่อ RTSP/ONVIF)
  (แชร์โควตานี้ระหว่าง SD card / Tapo Cloud / third-party RTSP-ONVIF client — ถ้าใช้ครบพร้อมกันจะเชื่อมต่อสายใหม่ไม่ได้)
- ต้องสร้าง "camera account" แยกในแอป Tapo ก่อนถึงจะเปิด RTSP ใช้งานได้ (คนละ credential กับ TP-Link ID)

### รูปแบบการใช้งานจริง
- 1 ห้อง = 1 กล้อง = 1 โรงแรมอาจมีหลายห้อง/หลายกล้อง
- มีหลายโรงแรม (multi-site) กระจายกันคนละที่ คนละเน็ต
- **ผู้ชมกล้องต่อครั้ง = ลูกค้าที่จองห้องนั้นเท่านั้น 1 คน** (ไม่ fan-out ให้คนอื่นดู)
- สิทธิ์การดูกล้องเปิดเฉพาะช่วงเวลาที่มีการจองอยู่จริง และถูก revoke ทันทีเมื่อ checkout/หมดเวลาจอง
- ไม่มีการบันทึกวิดีโอเก็บไว้ (ดูสดอย่างเดียว)
- แชท/ประวัติการสนทนายังคงเก็บไว้ตามปกติ (ไม่เกี่ยวกับ policy การลบสิทธิ์ดูกล้อง)

---

## 2. สถาปัตยกรรมที่ต้องการ (Target Architecture)

```
[กล้อง C210 ในห้อง]
      │ RTSP (LAN ภายในโรงแรม)
      ▼
[Edge server ต่อโรงแรม 1 ตัว] ──(รัน MediaMTX)──> แปลง RTSP → WebRTC/HLS
      │ เชื่อมต่อออกผ่าน Tailscale/mesh VPN (outbound only, ไม่ port-forward)
      ▼
[Backend กลาง] ── ตรวจสิทธิ์การจอง (booking service) ── อนุญาต/ปฏิเสธ การขอดูกล้อง
      │
      ▼
[แอปมือถือของลูกค้าที่จองห้องนั้น] ── เห็นสตรีมเมื่อกดเข้าเมนู "ดูกล้อง" ระหว่างช่วงที่จองอยู่เท่านั้น
```

หลักการสำคัญที่ต้องยึดตลอดการพัฒนา:
1. **ห้ามให้แอปฝั่งลูกค้ารู้จักหรือเชื่อมต่อ IP ของกล้องโดยตรงเด็ดขาด** ต้องผ่าน backend + edge server เสมอ
2. **RTSP credential ของกล้องต้องไม่หลุดไปถึง client ฝั่งลูกค้า** เก็บไว้ที่ edge server เท่านั้น
3. Edge server เป็นฝ่าย "โทรออก" หา backend เอง (ผ่าน Tailscale) ไม่ต้องเปิด port ที่ router โรงแรม แก้ปัญหา CGNAT/dynamic IP
4. Stream เปิดเฉพาะตอนมีคนกดดูจริง (on-demand) ไม่ stream ทิ้งไว้ตลอดเวลาเพื่อประหยัด bandwidth
5. ใช้ sub-stream (ความละเอียดต่ำ) เป็นค่าเริ่มต้น ให้ user เลือกขยายเป็น main stream ได้ภายหลัง

---

## 3. ขอบเขตงานแบ่งเป็น Phase (แนะนำให้ Claude Code ทำทีละ Phase)

### Phase 1 — Edge Server (รันที่โรงแรม)
- เขียน service (Node.js/Python ก็ได้) ที่ทำหน้าที่:
  - ดึง RTSP จากกล้อง C210 แต่ละตัวในโรงแรม (ต่อ 1 connection ต่อกล้อง เพื่อไม่ชนโควตา main+sub stream)
  - รัน/config MediaMTX ให้แปลง RTSP เป็น WebRTC (real-time) และสำรอง HLS (fallback)
  - เปิด/ปิดการ pull stream จากกล้องตาม "คำสั่งเปิดดู" ที่ backend ส่งมา ไม่ pull ทิ้งไว้ตลอดเวลา
  - มี watchdog: auto-restart ตัวเองถ้า process ค้าง หรือขาดการเชื่อมต่อกับ backend เกิน X นาที
  - ส่ง heartbeat/health status (camera online/offline, edge server online/offline) ไปที่ backend ทุก N วินาที

### Phase 2 — Network/Access Layer
- ติดตั้ง config ให้ edge server เชื่อมต่อผ่าน Tailscale (หรือ ZeroTier) เข้าเครือข่ายกลาง
- ทำ static IP reservation guide สำหรับกล้องแต่ละตัวที่ router โรงแรม (เอกสารประกอบการติดตั้ง ไม่ใช่โค้ด)
- Backend ต้องแมปได้ว่า "โรงแรม X → edge server ตัวไหน → กล้องห้องไหน" ผ่าน Tailscale hostname/IP ภายใน tailnet ไม่ใช่ public IP

### Phase 3 — Backend: Booking-Gated Access Control
- API endpoint สำหรับตรวจสิทธิ์: รับ (user_id, booking_id, room_id) แล้วเช็คว่า
  - booking นี้เป็นของ user คนนี้จริงไหม
  - อยู่ในช่วงเวลาที่ "active" (checked-in แล้ว ยังไม่ checkout) หรือไม่
  - ถ้าผ่าน → ออก short-lived access token (อายุสั้น เช่น 5-10 นาที ต่ออายุได้ถ้ายัง active) ให้ client ใช้เชื่อมต่อ stream ผ่าน backend
- Event-driven revoke: ผูก revoke สิทธิ์เข้ากับ event "checkout confirmed" ไม่ใช่แค่ตั้งเวลาล่วงหน้า
- เก็บ metadata log (ใครดู เมื่อไหร่ นานแค่ไหน) แบบ anonymized/short-retention (เช่น 7-14 วัน) ไว้เผื่อกรณีมีข้อพิพาท — **ห้ามเก็บตัววิดีโอ**
- ลบ/revoke สิทธิ์การเข้าถึง (ไม่ใช่ลบวิดีโอ เพราะไม่มีการบันทึกอยู่แล้ว) ทันทีที่ booking จบ

### Phase 4 — แอปฝั่งลูกค้า (Client)
- เมนู "ดูกล้อง" แยกออกจากหน้า matching/search ปกติ
- แสดงเมนูนี้เฉพาะตอนที่มี active booking เท่านั้น (เช็คจาก backend ทุกครั้งที่เปิดหน้า ไม่ cache สิทธิ์ไว้ฝั่ง client)
- เชื่อมต่อ stream ผ่าน WebRTC (fallback เป็น HLS ถ้า WebRTC ต่อไม่ติด) โดยใช้ access token จาก Phase 3
- Loading/error state ที่ชัดเจนเวลากล้อง offline หรือ edge server ที่โรงแรมหลุด (ต้อง handle gracefully ไม่ crash)

### Phase 5 — Admin Dashboard
- แสดงสถานะกล้อง/edge server ของทุกโรงแรมแบบ real-time (online/offline, last heartbeat)
- แจ้งเตือน (เช่น ผ่าน LINE Notify/webhook) เมื่อกล้อง/edge server offline เกิน threshold ที่กำหนด
- แสดง log การเข้าถึงกล้อง (metadata เท่านั้น) สำหรับ support/ตรวจสอบข้อพิพาท
- Role-based access: staff/technician เห็นได้เฉพาะโรงแรมที่ตัวเองดูแล

### Phase 6 — Feature: การมองเห็นในหน้า matching (แยกจากเมนูกล้อง)
- Badge "มีกล้องดูสด" ติดที่การ์ดโรงแรมในผลการค้นหา (ให้ filter ได้)
- ปัจจัย "มีกล้อง" เป็นน้ำหนักบวกเล็กน้อยใน scoring ของ LLM matching (ไม่ใช่ hard filter ที่บังคับ)
- **ข้อควรระวัง**: กล้องจะยังไม่แสดงผลจริงจนกว่าจะมีการจอง (ตามที่ระบุใน Phase 4) — ส่วนนี้แค่บอกว่าโรงแรม "มีกล้องติดตั้ง" ไม่ใช่เปิดให้ดูก่อนจอง

---

## 4. Non-functional Requirements ที่ต้องย้ำกับ Claude Code

- **Security**: ไม่ expose RTSP credential/IP กล้องไปยัง client ฝั่งไหนเลย, ไม่ port-forward กล้องออก public internet, ใช้ short-lived token สำหรับสิทธิ์การดู
- **Bandwidth**: stream แบบ on-demand เท่านั้น, default เป็น sub-stream คุณภาพต่ำ, ใช้ H.265 ถ้ากล้อง/media server รองรับ
- **Resilience**: edge server ต้องมี auto-recovery/watchdog, ระบบต้อง handle กรณีเน็ตโรงแรมหลุดโดยไม่ crash แอปฝั่งลูกค้า
- **Privacy**: revoke สิทธิ์ทันทีเมื่อ booking จบ, ไม่เก็บวิดีโอ, เก็บ log แค่ metadata และมี retention สั้น
- **Scalability**: ออกแบบให้รองรับหลายสิบ-หลายร้อยโรงแรมได้ในอนาคต (multi-tenant ตั้งแต่ต้น ไม่ hardcode ผูกกับโรงแรมเดียว)

---

## 5. Tech Stack ที่แนะนำเป็นจุดเริ่มต้น (ปรับได้ตาม stack เดิมของโปรเจกต์)

- Edge server: Node.js หรือ Python + MediaMTX (RTSP → WebRTC/HLS gateway, โอเพนซอร์ส)
- Mesh VPN: Tailscale (มี API สำหรับจัดการ device แบบ automate ได้)
- Backend: ตาม stack เดิมของระบบ matching/booking ที่มีอยู่แล้ว — เพิ่ม service ใหม่สำหรับ "camera access control"
- Client: WebRTC client library (เช่น mediasoup-client หรือใช้ browser native WebRTC API ถ้าเป็น web/hybrid app)

---

## วิธีใช้เอกสารนี้กับ Claude Code

แนะนำให้เริ่มจาก Phase 1 ก่อน โดยส่งข้อความประมาณนี้:

> "นี่คือสเปกของฟีเจอร์กล้องที่จะพัฒนา [แปะเอกสารนี้] ช่วยเริ่มทำ Phase 1 (Edge Server) ให้ก่อน
> โดยใช้ [ระบุภาษา/framework ที่ต้องการ] ระบบปัจจุบันของผมใช้ [ระบุ stack เดิม] อยู่"

แล้วค่อยทำทีละ Phase ต่อไปเรื่อยๆ ไม่ต้องยัดทุก Phase ในครั้งเดียว เพื่อให้ Claude Code
โฟกัสและตรวจสอบความถูกต้องของแต่ละส่วนได้ง่ายกว่า
