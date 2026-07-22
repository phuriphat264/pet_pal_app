import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/booking_repository.dart';
import '../services/payment_repository.dart';
import '../services/pet_repository.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? hotel;
  final String? roomId;
  final String roomType;
  final int nights;
  final int total;
  final String? matchingPrompt;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const BookingPage({
    super.key,
    this.hotel,
    this.roomId,
    this.roomType = 'Standard',
    this.nights = 3,
    this.total = 1350,
    this.matchingPrompt,
    this.checkIn,
    this.checkOut,
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
  bool _sharePrompt = true;
  bool _submitting = false;
  Map<String, dynamic>? _firstPet;

  late final DateTime _checkIn = widget.checkIn ?? DateTime.now();
  late final DateTime _checkOut = widget.checkOut ?? DateTime.now().add(Duration(days: widget.nights));

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    try {
      final pets = await context.read<PetRepository>().fetchPets();
      if (!mounted) return;
      if (pets.isNotEmpty) setState(() => _firstPet = pets.first);
    } catch (_) {
      // No pet on file yet -- booking still proceeds without one.
    }
  }

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
            if (widget.matchingPrompt != null && widget.matchingPrompt!.isNotEmpty)
              _buildSharePromptCard(),
            if (widget.matchingPrompt != null && widget.matchingPrompt!.isNotEmpty)
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
          _detailRow(Icons.calendar_month_rounded, 'เช็คอิน - เช็คเอาท์',
              '${_checkIn.day}/${_checkIn.month} - ${_checkOut.day}/${_checkOut.month}'),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.nightlight_round, 'ระยะเวลา', '${widget.nights} คืน'),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.meeting_room_rounded, 'ประเภทห้อง', widget.roomType),
          const Divider(height: 24, color: Color(0xFFE8D8C8)),
          _detailRow(Icons.pets_rounded, 'สัตว์เลี้ยง', _firstPet != null ? '${_firstPet!['name']} (${_firstPet!['breed']})' : 'ยังไม่มีข้อมูลสัตว์เลี้ยง'),
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

  Widget _buildSharePromptCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: _brown),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลจาก AI Smart Match',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown),
                    ),
                    Text(
                      'ส่งให้โรงแรมเพื่อดูแลน้องได้ตรงใจขึ้น',
                      style: TextStyle(fontSize: 12, color: _mutedBrown),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _sharePrompt,
                onChanged: (val) => setState(() => _sharePrompt = val),
                activeThumbColor: _brown,
                activeTrackColor: _brown.withValues(alpha: 0.4),
              ),
            ],
          ),
          if (_sharePrompt) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9C5B2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: _mutedBrown),
                      SizedBox(width: 4),
                      Text(
                        'ที่คุณบอกเราไว้',
                        style: TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.matchingPrompt!,
                    style: const TextStyle(fontSize: 14, color: _darkBrown, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: _mutedBrown),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'โรงแรมจะเห็นข้อความนี้เพื่อเตรียมการดูแลน้องให้เหมาะสม',
                    style: TextStyle(fontSize: 12, color: _mutedBrown, height: 1.4),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: _mutedBrown),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'โรงแรมจะไม่ได้รับข้อมูลนี้ คุณสามารถแจ้งรายละเอียดเองตอนเช็กอิน',
                    style: TextStyle(fontSize: 12, color: _mutedBrown, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
        onPressed: _submitting ? null : _onPay,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brown,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('ชำระเงิน ฿${widget.total}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _onPay() async {
    final hotelId = widget.hotel?['id'] as String?;
    if (hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลโรงแรม ลองใหม่อีกครั้ง'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _submitting = true);
    Map<String, dynamic> booking;
    try {
      booking = await context.read<BookingRepository>().createBooking(
            hotelId: hotelId,
            roomId: widget.roomId,
            petId: _firstPet?['id'] as String?,
            checkIn: _checkIn,
            checkOut: _checkOut,
            paymentMethod: _paymentMethod,
            matchingPrompt: _sharePrompt ? widget.matchingPrompt : null,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('จองไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    final bookingId = booking['id'] as String;
    if (_paymentMethod == 'Credit Card') {
      await _payWithCard(bookingId);
    } else {
      await _payWithPromptPay(bookingId);
    }
  }

  Future<void> _payWithCard(String bookingId) async {
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CardPaymentSheet(),
    );
    if (token == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final payment = await context
          .read<PaymentRepository>()
          .createPayment(bookingId: bookingId, method: 'card', cardToken: token);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (payment['status'] == 'successful') {
        _showSuccessDialog();
      } else {
        _showFailureDialog(payment['failure_message'] as String? ?? 'การชำระเงินไม่สำเร็จ ลองใหม่อีกครั้ง');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailureDialog('$e');
    }
  }

  Future<void> _payWithPromptPay(String bookingId) async {
    setState(() => _submitting = true);
    Map<String, dynamic> payment;
    try {
      payment = await context.read<PaymentRepository>().createPayment(bookingId: bookingId, method: 'promptpay');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailureDialog('$e');
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    final qrUrl = payment['qr_image_url'] as String?;
    if (qrUrl == null) {
      _showFailureDialog('ไม่พบ QR code สำหรับชำระเงิน ลองใหม่อีกครั้ง');
      return;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PromptPayQrDialog(qrUrl: qrUrl, bookingId: bookingId),
    );
    if (success == true) {
      _showSuccessDialog();
    } else if (success == false) {
      _showFailureDialog('การชำระเงินไม่สำเร็จหรือหมดเวลา ลองใหม่อีกครั้ง');
    }
  }

  void _showSuccessDialog() {
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

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFFDECEA), shape: BoxShape.circle),
              child: const Icon(Icons.error_rounded, color: Color(0xFFC0392B), size: 48),
            ),
            const SizedBox(height: 24),
            const Text('ชำระเงินไม่สำเร็จ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: _mutedBrown)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('ปิด', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPaymentSheet extends StatefulWidget {
  const _CardPaymentSheet();

  @override
  State<_CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<_CardPaymentSheet> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);

  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final expParts = _expCtrl.text.split('/');
    final month = expParts.length == 2 ? int.tryParse(expParts[0].trim()) : null;
    final yearPart = expParts.length == 2 ? int.tryParse(expParts[1].trim()) : null;
    if (month == null || yearPart == null) {
      setState(() => _error = 'กรอกวันหมดอายุให้ถูกต้อง (MM/YY)');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = await context.read<PaymentRepository>().createCardToken(
            cardNumber: _numberCtrl.text,
            name: _nameCtrl.text,
            expMonth: month,
            expYear: yearPart < 100 ? 2000 + yearPart : yearPart,
            securityCode: _cvvCtrl.text,
          );
      if (!mounted) return;
      Navigator.pop(context, token);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'ข้อมูลบัตรไม่ถูกต้อง: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ชำระด้วยบัตรเครดิต/เดบิต',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 16),
          TextField(
            controller: _numberCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'หมายเลขบัตร'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อบนบัตร')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expCtrl,
                  decoration: const InputDecoration(labelText: 'MM/YY'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'CVV'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ยืนยันชำระเงิน',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptPayQrDialog extends StatefulWidget {
  final String qrUrl;
  final String bookingId;
  const _PromptPayQrDialog({required this.qrUrl, required this.bookingId});

  @override
  State<_PromptPayQrDialog> createState() => _PromptPayQrDialogState();
}

class _PromptPayQrDialogState extends State<_PromptPayQrDialog> {
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  static const int _timeoutSeconds = 300;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    _elapsedSeconds += 3;
    if (_elapsedSeconds >= _timeoutSeconds) {
      _pollTimer?.cancel();
      if (mounted) Navigator.pop(context, false);
      return;
    }
    try {
      final payment = await context.read<PaymentRepository>().fetchLatestPayment(widget.bookingId);
      final status = payment['status'] as String?;
      if (status == 'successful') {
        _pollTimer?.cancel();
        if (mounted) Navigator.pop(context, true);
      } else if (status == 'failed' || status == 'expired') {
        _pollTimer?.cancel();
        if (mounted) Navigator.pop(context, false);
      }
    } catch (_) {
      // Transient network hiccup while polling -- keep trying until timeout.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('สแกน QR เพื่อชำระผ่าน PromptPay',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 16),
          Image.network(widget.qrUrl, width: 220, height: 220),
          const SizedBox(height: 16),
          const Text('รอการชำระเงิน...', style: TextStyle(fontSize: 13, color: _mutedBrown)),
          const SizedBox(height: 4),
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.pop(context, null);
            },
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}