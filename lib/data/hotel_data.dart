import 'package:flutter/material.dart';

final List<Map<String, dynamic>> allHotels = [
  {
    'name': 'โรงพยาบาลสัตว์แผ่นดินทอง',
    'location': 'จันทบุรี',
    'distance': '1.2 กม.',
    'rating': 4.8,
    'reviews': 120,
    'price': 320,
    'icon': Icons.local_hospital_rounded,
    'color': const Color(0xFF7CB9A8),
    'tags': ['หมอตรวจก่อนเข้าพัก', 'มีแอร์', 'รับฝากรายชั่วโมง'],
    'available': true,
    'description': 'นับเวลาฝาก 24 ช.ม. จากเวลา Check-in เท่ากับ 1 วัน หากเกินเวลาคิดค่าใช้จ่ายเพิ่มเติมชั่วโมงละ 50 บาท (เกิน 6 ช.ม. คิดเป็น 1 วัน) สามารถมาฝากและรับกลับภายในเวลาทำการ 08.30-20.30 น. เท่านั้น\n**แนะนำให้มาฝากเวลา 10.30-20.00 น. เพื่อให้คุณหมอตรวจสุขภาพก่อนเข้าพักค่ะ**\n\n-ฝากไม่เต็มวัน ไม่เกิน 6 ชม. คิดครึ่งราคา หากเกิน 6 ชม. คิดราคาเต็มค่ะ',
    'rooms': [
      {'type': 'Dog < 5 กก.', 'price': 0, 'desc': 'เริ่มต้นที่ 320 บาท/คืน'},
      {'type': 'Dog 5.1-10 กก.', 'price': 60, 'desc': '380 บาท/คืน'},
      {'type': 'Dog 10.1-15 กก.', 'price': 110, 'desc': '430 บาท/คืน'},
      {'type': 'Dog 15.1-20 กก.', 'price': 140, 'desc': '460 บาท/คืน'},
      {'type': 'Dog 20.1-25 กก.', 'price': 160, 'desc': '480 บาท/คืน'},
      {'type': 'Dog 25.1-30 กก.', 'price': 180, 'desc': '500 บาท/คืน'},
      {'type': 'Dog 30.1-35 กก.', 'price': 220, 'desc': '540 บาท/คืน'},
      {'type': 'Dog 35.1-40 กก.', 'price': 250, 'desc': '570 บาท/คืน'},
      {'type': 'Dog > 40 กก.', 'price': 270, 'desc': '590 บาท/คืน'},
      {'type': 'Cat ห้อง VIP', 'price': 80, 'desc': '400 บาท อยู่ได้สูงสุด 2 ตัว (ตัวที่ 2 +50)'},
      {'type': 'Cat ห้อง VVIP', 'price': 380, 'desc': '700 บาท อยู่ได้สูงสุด 5 ตัว (ราคาเหมา)'},
    ],
    'images': List.generate(12, (i) => 'assets/images/hotel1_${i + 1}.jpg'),
    'petTypes': ['🐶', '🐱'],
  },
  {
    'name': 'Sky Cat Hotel',
    'location': 'ตัวเมืองจันทบุรี',
    'distance': '2.5 กม.',
    'rating': 4.9,
    'reviews': 85,
    'price': 300,
    'icon': Icons.pets_rounded,
    'color': const Color(0xFFD4956A),
    'tags': ['แอร์ 24 ชม.', 'กล้องวงจรปิด', 'PlayZone'],
    'available': true,
    'description': 'โรงแรมแมวเมืองจันทบุรี Sky Cat hotel\nพร้อมสิ่งอำนวยความสะดวกน้องแมวดังนี้\n- ฟรี! กล้องวงจรปิดส่วนตัวทุกห้อง\n- ฟรี! น้ำดื่มสะอาดเกรดเดียวกับคนดื่ม\n- เปิดแอร์ 24 ชม. และเครื่องฟอกอากาศ ลดสารก่อภูมิแพ้ ห้องสะอาด ทำความสะอาดฆ่าเชื้อทุกวัน\n- พาน้องออกมาเล่นพื้นที่ส่วนกลาง PlayZone\n- อัปเดตรูปภาพและวิดีโอทุกวัน\n- ปลอดภัยไร้กังวล เจ้าของดูเองทุกขั้นตอน',
    'rooms': [
      {'type': 'ห้องไซส์ M', 'price': 0, 'desc': '300 บาท/คืน สำหรับ 1 ตัว'},
      {'type': 'ห้องคู่มีช่องแมวลอด', 'price': 200, 'desc': '500 บาท/คืน'},
    ],
    'images': List.generate(3, (i) => 'assets/images/hotel2_${i + 1}.jpg'),
    'petTypes': ['🐱'],
  },
  {
    'name': 'PigPao Pet Shop',
    'location': 'จันทบุรี',
    'distance': '3.1 กม.',
    'rating': 4.7,
    'reviews': 210,
    'price': 350,
    'icon': Icons.store_rounded,
    'color': const Color(0xFF9B7EC8),
    'tags': ['ไม่ขังกรง', 'สนามหญ้า', 'บริการรถรับส่ง'],
    'available': true,
    'description': 'สถานที่บริการรับฝากเลี้ยงน้องหมาจังหวัดจันทบุรี แบบไม่ขังกรง ที่นอนนุ่มสบาย นอนห้องแอร์ มีกล้องวงจรปิดดู 24 ชม. มีบริการพาเดินเล่นรอบสวน มีบริการรถรับส่ง เปิดรับฝากตลอด 24 ชม.',
    'rooms': [
      {'type': 'น้องหมาเล็ก', 'price': 0, 'desc': '350/คืน (ไม่รวมอาหาร)'},
      {'type': 'น้องหมาใหญ่', 'price': 100, 'desc': '450/คืน (ไม่รวมอาหาร)'},
    ],
    'images': List.generate(7, (i) => 'assets/images/hotel3_${i + 1}.jpg'),
    'petTypes': ['🐶'],
  },
  {
    'name': 'Dapperdou',
    'location': 'จันทบุรี',
    'distance': '1.8 กม.',
    'rating': 4.9,
    'reviews': 150,
    'price': 450,
    'icon': Icons.coffee_rounded,
    'color': const Color(0xFF6A9E7E),
    'tags': ['คาเฟ่โดนัท', 'ระบบกรอง Ro', 'ทรายพรีเมี่ยม'],
    'available': true,
    'description': 'คาเฟ่โดนัท & โรงแรมแมวพรีเมียมและกรูมมิ่งแมวจันทบุรี\nเปิดแอร์ 24 ชั่วโมง กล้องวงจรปิดเข้าดูเด็กๆได้ตลอดเวลา น้ำดื่มผ่านระบบกรอง Ro รวมทรายแมวพรีเมี่ยม อัพเดทเป็นภาพและวิดิโอ\nรับฝากรายชั่วโมง (ลูกค้าเตรียมอาหารน้องมาอย่างเดียวค่ะ)\n\nหมายเหตุ: จองก่อน ได้เลือกห้องก่อนค่ะ',
    'rooms': [
      {'type': 'Single Room', 'price': 0, 'desc': '450 บาท/วัน (แมว 1-2 ตัว)'},
      {'type': 'Family Room', 'price': 200, 'desc': '650 บาท/วัน (แมว 2-3 ตัว)'},
    ],
    'images': List.generate(13, (i) => 'assets/images/hotel4_${i + 1}.jpg'),
    'petTypes': ['🐱'],
  },
];

final List<Map<String, dynamic>> activeBookings = [];

void addBooking(Map<String, dynamic> hotel, {String? matchingPrompt}) {
  activeBookings.add({
    'hotel': hotel,
    'prompt': matchingPrompt,
    'bookingDate': DateTime.now(),
  });
}
