// Pet care tip articles shown on the home page. Static editorial content
// (not user data), so it lives as a plain Dart list rather than a backend
// model -- there's no CRUD need for this.
import '../widgets/care_tip_illustration.dart';

class CareTipSection {
  final String heading;
  final String body;
  const CareTipSection({required this.heading, required this.body});
}

class CareTip {
  final CareTipIllustrationType illustration;
  final String title;
  final String summary;
  final List<CareTipSection> sections;
  const CareTip({
    required this.illustration,
    required this.title,
    required this.summary,
    required this.sections,
  });
}

final List<CareTip> careTips = [
  CareTip(
    illustration: CareTipIllustrationType.food,
    title: 'อาหารที่ดีสำหรับหมา',
    summary: 'อาหารสูตร adult ช่วยบำรุงกระดูกและขนให้แข็งแรง',
    sections: [
      CareTipSection(
        heading: 'ทำไมเรื่องอาหารถึงสำคัญ',
        body:
            'อาหารคือพื้นฐานของสุขภาพน้องหมาทั้งหมด ทั้งกระดูก กล้ามเนื้อ ขน และระบบภูมิคุ้มกัน '
            'การเลือกอาหารให้เหมาะกับช่วงอายุ (ลูกสุนัข / โตเต็มวัย / สูงวัย) และขนาดตัวจึงสำคัญมาก '
            'อาหารสูตร adult ที่มีโปรตีนคุณภาพดีและแคลเซียม-ฟอสฟอรัสในสัดส่วนที่เหมาะสม จะช่วยบำรุงกระดูกและข้อให้แข็งแรง',
      ),
      CareTipSection(
        heading: 'วิธีปฏิบัติ',
        body:
            '• แบ่งให้อาหาร 2 มื้อต่อวันสำหรับสุนัขโตเต็มวัย\n'
            '• เลือกปริมาณตามน้ำหนักตัวที่ระบุบนถุงอาหาร ไม่ใช่ตามความอยากของน้อง\n'
            '• เปลี่ยนอาหารสูตรใหม่ควรค่อยๆ ผสมกับสูตรเดิมใน 5-7 วัน เพื่อไม่ให้ระบบย่อยปรับตัวไม่ทัน',
      ),
      CareTipSection(
        heading: 'ข้อควรระวัง',
        body:
            'หลีกเลี่ยงอาหารคน เช่น ช็อกโกแลต หัวหอม กระเทียม และลูกเกรป เพราะเป็นพิษต่อสุนัข '
            'หากน้องมีอาการแพ้อาหาร (เกาบ่อย ผิวแดง ท้องเสียเรื้อรัง) ควรปรึกษาสัตวแพทย์เพื่อเปลี่ยนสูตรอาหาร',
      ),
    ],
  ),
  CareTip(
    illustration: CareTipIllustrationType.water,
    title: 'น้ำสะอาดสำคัญมาก',
    summary: 'น้องหมาควรดื่มน้ำอย่างน้อย 50 มล. ต่อน้ำหนัก 1 กก. ต่อวัน',
    sections: [
      CareTipSection(
        heading: 'ปริมาณน้ำที่เหมาะสม',
        body:
            'โดยเฉลี่ยน้องหมาควรได้รับน้ำสะอาดอย่างน้อย 50 มิลลิลิตรต่อน้ำหนักตัว 1 กิโลกรัมต่อวัน '
            'เช่น น้องหนัก 10 กก. ควรดื่มน้ำประมาณ 500 มล. ต่อวัน และอาจต้องการมากขึ้นในวันที่ร้อนจัดหรือออกกำลังกายหนัก',
      ),
      CareTipSection(
        heading: 'วิธีปฏิบัติ',
        body:
            '• เปลี่ยนน้ำในชามทุกวัน อย่างน้อยวันละ 1-2 ครั้ง\n'
            '• วางชามน้ำไว้หลายจุดถ้าบ้านมีหลายชั้นหรือพื้นที่กว้าง\n'
            '• ทำความสะอาดชามน้ำสัปดาห์ละ 2-3 ครั้งเพื่อลดการสะสมของแบคทีเรีย',
      ),
      CareTipSection(
        heading: 'สัญญาณที่ต้องระวัง',
        body:
            'หากน้องดื่มน้ำน้อยลงผิดปกติ ปัสสาวะสีเข้ม หรือผิวหนังเมื่อจับยกขึ้นแล้วคืนรูปช้า '
            'อาจเป็นสัญญาณของภาวะขาดน้ำ ควรพาไปพบสัตวแพทย์โดยเร็ว',
      ),
    ],
  ),
  CareTip(
    illustration: CareTipIllustrationType.exercise,
    title: 'ออกกำลังกายทุกวัน',
    summary: 'หมาขนาดกลางควรเดินอย่างน้อย 30 นาทีต่อวันเพื่อสุขภาพที่ดี',
    sections: [
      CareTipSection(
        heading: 'ทำไมต้องออกกำลังกาย',
        body:
            'การออกกำลังกายช่วยควบคุมน้ำหนัก เสริมสร้างกล้ามเนื้อและข้อต่อ และลดความเครียด/พฤติกรรมทำลายของในบ้าน '
            'สุนัขขนาดกลางถึงใหญ่ส่วนมากต้องการการเดิน/วิ่งเล่นอย่างน้อย 30-60 นาทีต่อวัน แบ่งเป็น 1-2 รอบ',
      ),
      CareTipSection(
        heading: 'วิธีปฏิบัติ',
        body:
            '• เดินตอนเช้าหรือเย็นที่อากาศไม่ร้อนจัด เพื่อป้องกันฮีทสโตรก\n'
            '• สลับกิจกรรม เช่น เดิน วิ่งเล่นในสนาม หรือเล่นเกมคาบของ เพื่อไม่ให้น้องเบื่อ\n'
            '• สังเกตระดับพลังของน้อง สายพันธุ์ที่พลังเยอะอาจต้องการเวลามากกว่านี้',
      ),
      CareTipSection(
        heading: 'ข้อควรระวัง',
        body:
            'หลีกเลี่ยงการออกกำลังกายหนักในช่วงแดดจัด หรือทันทีหลังกินอาหารมื้อใหญ่ '
            'สำหรับลูกสุนัขหรือสุนัขสูงวัย ควรปรับความหนักและระยะเวลาให้เหมาะกับร่างกาย',
      ),
    ],
  ),
];
