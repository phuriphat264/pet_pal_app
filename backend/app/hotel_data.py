# Python mirror of the matching-relevant fields from lib/data/hotel_data.dart.
# Only the attributes needed for semantic matching (name, location, distance,
# rating, tags, aiTags, description) are kept here -- UI-only fields (colors,
# icons, asset paths, room pricing) live exclusively in the Flutter app.

HOTELS: list[dict] = [
    {
        "name": "โรงพยาบาลสัตว์แผ่นดินทอง",
        "location": "จันทบุรี",
        "distance": 1.2,
        "rating": 4.8,
        "tags": ["หมอตรวจก่อนเข้าพัก", "มีแอร์", "รับฝากรายชั่วโมง"],
        "aiTags": ["care", "calm", "private"],
        "description": (
            "นับเวลาฝาก 24 ช.ม. จากเวลา Check-in เท่ากับ 1 วัน หากเกินเวลาคิดค่าใช้จ่ายเพิ่มเติม"
            "ชั่วโมงละ 50 บาท สามารถมาฝากและรับกลับภายในเวลาทำการ 08.30-20.30 น. เท่านั้น "
            "แนะนำให้มาฝากเวลา 10.30-20.00 น. เพื่อให้คุณหมอตรวจสุขภาพก่อนเข้าพักค่ะ"
        ),
    },
    {
        "name": "Sky Cat Hotel",
        "location": "ตัวเมืองจันทบุรี",
        "distance": 2.5,
        "rating": 4.9,
        "tags": ["แอร์ 24 ชม.", "กล้องวงจรปิด", "PlayZone"],
        "aiTags": ["calm", "care", "playful", "social", "private"],
        "description": (
            "โรงแรมแมวเมืองจันทบุรี Sky Cat hotel พร้อมสิ่งอำนวยความสะดวกน้องแมว: "
            "กล้องวงจรปิดส่วนตัวทุกห้อง เปิดแอร์ 24 ชม. และเครื่องฟอกอากาศลดสารก่อภูมิแพ้ "
            "ห้องสะอาด ทำความสะอาดฆ่าเชื้อทุกวัน พาน้องออกมาเล่นพื้นที่ส่วนกลาง PlayZone "
            "อัปเดตรูปภาพและวิดีโอทุกวัน"
        ),
    },
    {
        "name": "PigPao Pet Shop",
        "location": "จันทบุรี",
        "distance": 3.1,
        "rating": 4.7,
        "tags": ["ไม่ขังกรง", "สนามหญ้า", "บริการรถรับส่ง"],
        "aiTags": ["active", "nature", "social", "friendly", "playful"],
        "description": (
            "สถานที่บริการรับฝากเลี้ยงน้องหมาจังหวัดจันทบุรี แบบไม่ขังกรง ที่นอนนุ่มสบาย "
            "นอนห้องแอร์ มีกล้องวงจรปิดดู 24 ชม. มีบริการพาเดินเล่นรอบสวน มีบริการรถรับส่ง "
            "เปิดรับฝากตลอด 24 ชม."
        ),
    },
    {
        "name": "Dapperdou",
        "location": "จันทบุรี",
        "distance": 1.8,
        "rating": 4.9,
        "tags": ["คาเฟ่โดนัท", "ระบบกรอง Ro", "ทรายพรีเมี่ยม"],
        "aiTags": ["calm", "care", "lazy", "friendly", "private"],
        "description": (
            "คาเฟ่โดนัท & โรงแรมแมวพรีเมียมและกรูมมิ่งแมวจันทบุรี เปิดแอร์ 24 ชั่วโมง "
            "กล้องวงจรปิดเข้าดูเด็กๆได้ตลอดเวลา น้ำดื่มผ่านระบบกรอง Ro รวมทรายแมวพรีเมี่ยม "
            "อัพเดทเป็นภาพและวิดิโอ รับฝากรายชั่วโมง"
        ),
    },
]
