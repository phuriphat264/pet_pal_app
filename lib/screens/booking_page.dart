import 'package:flutter/material.dart';
import '../data/hotel_data.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? hotel;
  final String roomType;
  final int nights;
  final int total;
  final String? matchingPrompt;

  const BookingPage({
    super.key,
    this.hotel,
    this.roomType = 'Standard',
    this.nights = 3,
    this.total = 1350,
    this.matchingPrompt,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  String _paymentMethod = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    // กำหนดข้อมูล Hotel Mockup สำหรับกรณีไม่ได้ส่งมา
    final hotel = widget.hotel ?? {
      'name': 'โรงพยาบาลสัตว์แผ่นดินทอง',
      'location': 'จันทบุรี',
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFF7CB9A8),
      'rating': 4.8,
      'reviews': 120,
      'images': ['assets/images/hotel1_1.jpg'],
    };

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFE8D8C8), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left_rounded, color: _brown, size: 22),
          ),
        ),
        title: const Text('ยืนยันการจอง',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepper(),
            const SizedBox(height: 24),
            _buildHotelCard(hotel),
            const SizedBox(height: 20),
            _buildBookingDetails(),
            const SizedBox(height: 20),
            _buildPaymentMethods(),
            const SizedBox(height: 20),
            _buildReceipt(),
            const SizedBox(height: 40), // Spacer for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepCircle('1', isActive: true, isDone: true),
        Expanded(child: Container(height: 2, color: _brown)),
        _stepCircle('2', isActive: true, isDone: false),
        Expanded(child: Container(height: 2, color: _mutedBrown.withValues(alpha:0.3))),
        _stepCircle('3', isActive: false, isDone: false),
      ],
    );
  }

  Widget _stepCircle(String text, {required bool isActive, required bool isDone}) {
    Color bg = isActive ? _brown : _mutedBrown.withValues(alpha:0.2);
    Color fg = isActive ? Colors.white : _mutedBrown;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : Text(text, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: (hotel['color'] as Color).withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Builder(
              builder: (context) {
                final List<String> images = (hotel['images'] as List?)?.cast<String>() ?? 
                    (hotel['image'] != null ? [hotel['image'] as String] : []);
                final String? coverImage = images.isNotEmpty ? images.first : null;
                
                if (coverImage != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      coverImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(hotel['icon'] as IconData, size: 40, color: _brown),
                      ),
                    ),
                  );
                }
                return Center(child: Icon(hotel['icon'] as IconData?, size: 40, color: _brown));
              }
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: _mutedBrown),
                    const SizedBox(width: 4),
                    Text(hotel['location'],
                        style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 4),
                    Text('${hotel['rating']} (${hotel['reviews']} รีวิว)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkBrown)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9C5B2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รายละเอียดการจอง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 16),
          _detailRow(Icons.calendar_month_rounded, 'เช็คอิน - เช็คเอาท์', '12 ส.ค. - 15 ส.ค.'),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.nightlight_round, 'ระยะเวลา', '${widget.nights} คืน'),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.meeting_room_rounded, 'ประเภทห้อง', widget.roomType),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.pets_rounded, 'สัตว์เลี้ยง', 'มะม่วง (สุนัข)'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _brown),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 15, color: _mutedBrown)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown)),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ช่องทางการชำระเงิน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
        const SizedBox(height: 12),
        _paymentTile('Credit Card', Icons.credit_card_rounded),
        const SizedBox(height: 8),
        _paymentTile('PromptPay', Icons.qr_code_2_rounded),
      ],
    );
  }

  Widget _paymentTile(String method, IconData icon) {
    bool selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _brown.withValues(alpha:0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _brown : const Color(0xFFD9C5B2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _brown : _mutedBrown, size: 24),
            const SizedBox(width: 12),
            Text(method,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: selected ? _brown : _darkBrown)),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle_rounded, color: _brown, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildReceipt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ยอดชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ราคาห้องพัก (${widget.nights} คืน)', style: const TextStyle(fontSize: 15, color: _mutedBrown)),
              Text('฿${widget.total}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ภาษีและค่าธรรมเนียม', style: TextStyle(fontSize: 15, color: _mutedBrown)),
              Text('฿0', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFD9C5B2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รวมทั้งสิ้น', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brown)),
              Text('฿${widget.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _brown)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ElevatedButton(
        onPressed: _onPay,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brown,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('ชำระเงิน ฿${widget.total}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _onPay() {
    // Add to global active bookings
    if (widget.hotel != null) {
      addBooking(widget.hotel!, matchingPrompt: widget.matchingPrompt);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 48),
            ),
            const SizedBox(height: 24),
            const Text('ชำระเงินสำเร็จ!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
            const SizedBox(height: 8),
            const Text('รายการจองของคุณได้รับการยืนยันแล้ว\nสามารถดูรายละเอียดได้ที่หน้าการจองของฉัน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: _mutedBrown, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to Detail
                  Navigator.pop(context); // Go back to List
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('กลับสู่หน้าหลัก',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}