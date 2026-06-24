"""Idempotent seed script: creates the initial admin/technician accounts and
migrates the hotels that used to be hard-coded in lib/data/hotel_data.dart
into the database, so the app isn't empty on first run. Safe to run on every
container start -- skips anything that already exists.
"""

import asyncio
import sys

if sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.hotel import Hotel, HotelRoom
from app.models.user import User, UserRole
from app.services.embedding_service import embed_hotel_text

settings = get_settings()

SEED_HOTELS = [
    {
        "name": "โรงพยาบาลสัตว์แผ่นดินทอง",
        "location": "จันทบุรี",
        "distance_text": "1.2 กม.",
        "rating": 4.8,
        "reviews_count": 120,
        "base_price": 320,
        "icon_name": "local_hospital_rounded",
        "color_hex": "#7CB9A8",
        "tags": ["หมอตรวจก่อนเข้าพัก", "มีแอร์", "รับฝากรายชั่วโมง"],
        "ai_tags": ["care", "calm", "private"],
        "pet_types": ["🐶", "🐱"],
        "description": (
            "นับเวลาฝาก 24 ช.ม. จากเวลา Check-in เท่ากับ 1 วัน หากเกินเวลาคิดค่าใช้จ่ายเพิ่มเติม"
            "ชั่วโมงละ 50 บาท (เกิน 6 ช.ม. คิดเป็น 1 วัน) สามารถมาฝากและรับกลับภายในเวลาทำการ "
            "08.30-20.30 น. เท่านั้น\nแนะนำให้มาฝากเวลา 10.30-20.00 น. เพื่อให้คุณหมอตรวจสุขภาพ"
            "ก่อนเข้าพักค่ะ\n\n-ฝากไม่เต็มวัน ไม่เกิน 6 ชม. คิดครึ่งราคา หากเกิน 6 ชม. คิดราคาเต็มค่ะ"
        ),
        "rooms": [
            {"room_type": "Dog < 5 กก.", "price_surcharge": 0, "description": "เริ่มต้นที่ 320 บาท/คืน"},
            {"room_type": "Dog 5.1-10 กก.", "price_surcharge": 60, "description": "380 บาท/คืน"},
            {"room_type": "Dog 10.1-15 กก.", "price_surcharge": 110, "description": "430 บาท/คืน"},
            {"room_type": "Dog 15.1-20 กก.", "price_surcharge": 140, "description": "460 บาท/คืน"},
            {"room_type": "Dog 20.1-25 กก.", "price_surcharge": 160, "description": "480 บาท/คืน"},
            {"room_type": "Dog 25.1-30 กก.", "price_surcharge": 180, "description": "500 บาท/คืน"},
            {"room_type": "Dog 30.1-35 กก.", "price_surcharge": 220, "description": "540 บาท/คืน"},
            {"room_type": "Dog 35.1-40 กก.", "price_surcharge": 250, "description": "570 บาท/คืน"},
            {"room_type": "Dog > 40 กก.", "price_surcharge": 270, "description": "590 บาท/คืน"},
            {"room_type": "Cat ห้อง VIP", "price_surcharge": 80, "description": "400 บาท อยู่ได้สูงสุด 2 ตัว (ตัวที่ 2 +50)"},
            {"room_type": "Cat ห้อง VVIP", "price_surcharge": 380, "description": "700 บาท อยู่ได้สูงสุด 5 ตัว (ราคาเหมา)"},
        ],
        "images": [f"assets/images/hotel1_{i}.jpg" for i in range(1, 13)],
    },
    {
        "name": "Sky Cat Hotel",
        "location": "ตัวเมืองจันทบุรี",
        "distance_text": "2.5 กม.",
        "rating": 4.9,
        "reviews_count": 85,
        "base_price": 300,
        "icon_name": "pets_rounded",
        "color_hex": "#D4956A",
        "tags": ["แอร์ 24 ชม.", "กล้องวงจรปิด", "PlayZone"],
        "ai_tags": ["calm", "care", "playful", "social", "private"],
        "pet_types": ["🐱"],
        "description": (
            "โรงแรมแมวเมืองจันทบุรี Sky Cat hotel\nพร้อมสิ่งอำนวยความสะดวกน้องแมวดังนี้\n"
            "- ฟรี! กล้องวงจรปิดส่วนตัวทุกห้อง\n- ฟรี! น้ำดื่มสะอาดเกรดเดียวกับคนดื่ม\n"
            "- เปิดแอร์ 24 ชม. และเครื่องฟอกอากาศ ลดสารก่อภูมิแพ้ ห้องสะอาด ทำความสะอาดฆ่าเชื้อทุกวัน\n"
            "- พาน้องออกมาเล่นพื้นที่ส่วนกลาง PlayZone\n- อัปเดตรูปภาพและวิดีโอทุกวัน\n"
            "- ปลอดภัยไร้กังวล เจ้าของดูเองทุกขั้นตอน"
        ),
        "rooms": [
            {"room_type": "ห้องไซส์ M", "price_surcharge": 0, "description": "300 บาท/คืน สำหรับ 1 ตัว"},
            {"room_type": "ห้องคู่มีช่องแมวลอด", "price_surcharge": 200, "description": "500 บาท/คืน"},
        ],
        "images": [f"assets/images/hotel2_{i}.jpg" for i in range(1, 4)],
    },
    {
        "name": "PigPao Pet Shop",
        "location": "จันทบุรี",
        "distance_text": "3.1 กม.",
        "rating": 4.7,
        "reviews_count": 210,
        "base_price": 350,
        "icon_name": "store_rounded",
        "color_hex": "#9B7EC8",
        "tags": ["ไม่ขังกรง", "สนามหญ้า", "บริการรถรับส่ง"],
        "ai_tags": ["active", "nature", "social", "friendly", "playful"],
        "pet_types": ["🐶"],
        "description": (
            "สถานที่บริการรับฝากเลี้ยงน้องหมาจังหวัดจันทบุรี แบบไม่ขังกรง ที่นอนนุ่มสบาย "
            "นอนห้องแอร์ มีกล้องวงจรปิดดู 24 ชม. มีบริการพาเดินเล่นรอบสวน มีบริการรถรับส่ง "
            "เปิดรับฝากตลอด 24 ชม."
        ),
        "rooms": [
            {"room_type": "น้องหมาเล็ก", "price_surcharge": 0, "description": "350/คืน (ไม่รวมอาหาร)"},
            {"room_type": "น้องหมาใหญ่", "price_surcharge": 100, "description": "450/คืน (ไม่รวมอาหาร)"},
        ],
        "images": [f"assets/images/hotel3_{i}.jpg" for i in range(1, 8)],
    },
    {
        "name": "Dapperdou",
        "location": "จันทบุรี",
        "distance_text": "1.8 กม.",
        "rating": 4.9,
        "reviews_count": 150,
        "base_price": 450,
        "icon_name": "coffee_rounded",
        "color_hex": "#6A9E7E",
        "tags": ["คาเฟ่โดนัท", "ระบบกรอง Ro", "ทรายพรีเมี่ยม"],
        "ai_tags": ["calm", "care", "lazy", "friendly", "private"],
        "pet_types": ["🐱"],
        "description": (
            "คาเฟ่โดนัท & โรงแรมแมวพรีเมียมและกรูมมิ่งแมวจันทบุรี\nเปิดแอร์ 24 ชั่วโมง "
            "กล้องวงจรปิดเข้าดูเด็กๆได้ตลอดเวลา น้ำดื่มผ่านระบบกรอง Ro รวมทรายแมวพรีเมี่ยม "
            "อัพเดทเป็นภาพและวิดิโอ\nรับฝากรายชั่วโมง (ลูกค้าเตรียมอาหารน้องมาอย่างเดียวค่ะ)\n\n"
            "หมายเหตุ: จองก่อน ได้เลือกห้องก่อนค่ะ"
        ),
        "rooms": [
            {"room_type": "Single Room", "price_surcharge": 0, "description": "450 บาท/วัน (แมว 1-2 ตัว)"},
            {"room_type": "Family Room", "price_surcharge": 200, "description": "650 บาท/วัน (แมว 2-3 ตัว)"},
        ],
        "images": [f"assets/images/hotel4_{i}.jpg" for i in range(1, 14)],
    },
]


async def seed_users(session) -> None:
    for email, password, role in [
        (settings.seed_admin_email, settings.seed_admin_password, UserRole.admin),
        (settings.seed_technician_email, settings.seed_technician_password, UserRole.technician),
    ]:
        existing = await session.scalar(select(User).where(User.email == email))
        if existing is not None:
            continue
        user = User(
            email=email,
            password_hash=hash_password(password),
            name="PetPal Admin" if role == UserRole.admin else "PetPal Technician",
            role=role,
        )
        session.add(user)
        print(f"seeded {role.value} account: {email}")
    await session.commit()


async def seed_hotels(session) -> None:
    for entry in SEED_HOTELS:
        existing = await session.scalar(select(Hotel).where(Hotel.name == entry["name"]))
        if existing is not None:
            continue

        hotel = Hotel(
            name=entry["name"],
            location=entry["location"],
            distance_text=entry["distance_text"],
            rating=entry["rating"],
            reviews_count=entry["reviews_count"],
            base_price=entry["base_price"],
            icon_name=entry["icon_name"],
            color_hex=entry["color_hex"],
            description=entry["description"],
            service_type="โรงแรม",
            available=True,
            tags=entry["tags"],
            ai_tags=entry["ai_tags"],
            pet_types=entry["pet_types"],
        )
        hotel.embedding = embed_hotel_text(
            name=hotel.name, description=hotel.description, tags=hotel.tags, ai_tags=hotel.ai_tags
        )
        session.add(hotel)
        await session.flush()

        for room in entry["rooms"]:
            session.add(HotelRoom(hotel_id=hotel.id, **room))

        from app.models.hotel import HotelImage

        for i, url in enumerate(entry["images"]):
            session.add(HotelImage(hotel_id=hotel.id, url=url, sort_order=i))

        print(f"seeded hotel: {hotel.name}")
    await session.commit()


async def main() -> None:
    async with AsyncSessionLocal() as session:
        await seed_users(session)
        await seed_hotels(session)


if __name__ == "__main__":
    asyncio.run(main())
