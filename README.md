# 🐾 PetPal Camera (pet_pal_app)

> **กล้องวงจรปิดสัตว์เลี้ยงอัจฉริยะแบบ Real-Time RTSP Video Streaming** 📹🐶🐱

PetPal Camera เป็นแอปพลิเคชันมือถือที่พัฒนาด้วย **Flutter** สำหรับการเฝ้าดูและติดตามสัตว์เลี้ยงแสนรักของคุณผ่านกล้อง IP Camera รุ่น **Tapo C210** ด้วยระบบสตรีมมิ่งวิดีโอ RTSP ประสิทธิภาพสูงผ่านไลบรารี `media_kit`

---

## 🌟 คุณสมบัติเด่น (Features)

* 🎥 **Real-Time Pet Monitoring**: ดูภาพวิดีโอสดจากกล้อง IP Camera (Tapo C210) ได้ทุกที่ทุกเวลาแบบ Real-time
* ⚡ **High-Performance RTSP Streaming**: ลื่นไหล ไม่มีสะดุด ด้วยเอนจินวิดีโอระดับฮาร์ดแวร์จาก `media_kit`
* 📱 **Cross-Platform Support**: รองรับการใช้งานหลากหลายแพลตฟอร์มทั้ง **iOS**, **Android** และ **Desktop**
* 🎮 **Easy Camera Control & View**: หน้าจออินเทอร์เฟซใช้งานง่าย ออกแบบมาสำหรับทาสหมา/ทาสแมวโดยเฉพาะ

---

## 🛠️ เทคโนโลยีที่ใช้ (Tech Stack)

* **Framework**: [Flutter](https://flutter.dev/) (Dart)
* **Video Engine**: [`media_kit`](https://pub.dev/packages/media_kit) + `media_kit_video` (Libmpv-backed RTSP Playback)
* **Protocol**: RTSP (Real-Time Streaming Protocol)
* **Target Hardware**: TP-Link Tapo C210 IP Camera

---

## 🚀 การติดตั้งและเปิดใช้งาน (Getting Started)

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 ขึ้นไป)
* Dart SDK
* กล้อง Tapo C210 ที่เชื่อมต่อ Wi-Fi เครือข่ายเดียวกัน และเปิดใช้งาน **Camera Account** (สำหรับ RTSP URL)

### 2. RTSP URL Format
รูปแบบ URL สำหรับดึง Stream จากกล้อง Tapo C210:
```text
rtsp://<username>:<password>@<camera_ip>:554/stream1   (High Quality - 1080p / 3MP)
rtsp://<username>:<password>@<camera_ip>:554/stream2   (Low Quality - 360p)
```

### 3. Installation & Run
```bash
git clone https://github.com/phuriphat264/pet_pal_app.git
cd petpal_c210

flutter pub get
flutter run
```

---

## 📱 การสนับสนุนแพลตฟอร์ม (Platform Support)

| Platform | Support Status | Note |
| :--- | :---: | :--- |
| **iOS** | ✅ | ต้องตั้งค่า FFmpeg/media_kit native dependencies |
| **Android** | ✅ | รองรับ Hardware Acceleration |
| **macOS / Windows** | ✅ | สำหรับ Desktop monitoring |

---

## 📄 License

Project นี้จัดทำขึ้นเพื่อการศึกษาและการใช้งานส่วนบุคคล ❤️
