// lib/screens/hotel_partner_application_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/partner_data.dart';
import '../services/api_client.dart';
import '../services/partner_repository.dart';
import 'partner_status_page.dart';

class HotelPartnerApplicationPage extends StatefulWidget {
  const HotelPartnerApplicationPage({super.key});

  @override
  State<HotelPartnerApplicationPage> createState() => _HotelPartnerApplicationPageState();
}

class _HotelPartnerApplicationPageState extends State<HotelPartnerApplicationPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _borderColor = Color(0xFFD9C5B2);

  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _serviceType = partnerServiceTypes.first;
  XFile? _docIdCard;
  XFile? _docBusinessLicense;
  XFile? _docShopPhoto;
  bool _submitting = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickDoc(void Function(XFile) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _submit() async {
    if (_shopNameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      _showError('กรุณากรอกข้อมูลร้านให้ครบถ้วน');
      return;
    }
    if (_docIdCard == null || _docBusinessLicense == null || _docShopPhoto == null) {
      _showError('กรุณาแนบเอกสารยืนยันตัวตนให้ครบทั้ง 3 รายการ');
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<PartnerRepository>();
      await repo.submitApplication(
        shopName: _shopNameCtrl.text.trim(),
        serviceType: _serviceType,
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      await repo.uploadDocument(docType: 'id_card', file: _docIdCard!);
      await repo.uploadDocument(docType: 'business_license', file: _docBusinessLicense!);
      await repo.uploadDocument(docType: 'shop_photo', file: _docShopPhoto!);

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerStatusPage()));
    } on ApiException catch (e) {
      _showError(e.statusCode == 409
          ? 'คุณมีคำขอเปิดร้านที่กำลังดำเนินการอยู่แล้ว'
          : 'ส่งคำขอไม่สำเร็จ: ${e.message}');
    } catch (e) {
      _showError('ส่งคำขอไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        foregroundColor: _darkBrown,
        title: const Text('สมัครเปิดร้านกับ PetPal',
            style: TextStyle(fontWeight: FontWeight.w700, color: _darkBrown)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _brown,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ขยายธุรกิจของคุณกับ PetPal',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('กรอกข้อมูลร้านและยืนยันตัวตนเพื่อเริ่มรับลูกค้า',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('🏠 ข้อมูลร้าน'),
            const SizedBox(height: 12),
            _inputField('ชื่อร้าน / โรงแรม', ctrl: _shopNameCtrl, hint: 'เช่น Sky Cat Hotel'),
            const SizedBox(height: 12),

            const Text('ประเภทบริการ', style: TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: partnerServiceTypes.map((t) {
                final selected = t == _serviceType;
                return GestureDetector(
                  onTap: () => setState(() => _serviceType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? _brown : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _brown : _borderColor),
                    ),
                    child: Text(t,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _mutedBrown,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            _inputField('ที่อยู่ร้าน', ctrl: _addressCtrl, hint: 'เช่น 123 ถ.ท่าหลวง ต.ตลาด อ.เมือง จันทบุรี'),
            const SizedBox(height: 12),
            _inputField('เบอร์โทรติดต่อ', ctrl: _phoneCtrl, hint: 'เช่น 081-234-5678', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _inputField('รายละเอียดร้าน', ctrl: _descCtrl, hint: 'จุดเด่นของร้าน บริการที่มี ฯลฯ', maxLines: 3),

            const SizedBox(height: 28),

            _sectionTitle('🪪 เอกสารยืนยันตัวตน'),
            const SizedBox(height: 4),
            const Text('แนบเอกสารเพื่อให้ทีมงานตรวจสอบและยืนยันความน่าเชื่อถือของร้าน',
                style: TextStyle(fontSize: 12, color: _mutedBrown)),
            const SizedBox(height: 12),
            _docTile(
              icon: Icons.badge_outlined,
              title: 'บัตรประชาชน / บัตรประจำตัวผู้ประกอบการ',
              file: _docIdCard,
              onTap: () => _pickDoc((f) => _docIdCard = f),
            ),
            const SizedBox(height: 10),
            _docTile(
              icon: Icons.description_outlined,
              title: 'ทะเบียนพาณิชย์ / หนังสือรับรองร้าน',
              file: _docBusinessLicense,
              onTap: () => _pickDoc((f) => _docBusinessLicense = f),
            ),
            const SizedBox(height: 10),
            _docTile(
              icon: Icons.storefront_outlined,
              title: 'รูปถ่ายหน้าร้าน / สถานที่จริง',
              file: _docShopPhoto,
              onTap: () => _pickDoc((f) => _docShopPhoto = f),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('ส่งคำขอเปิดร้าน',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkBrown));
  }

  Widget _inputField(String label, {required TextEditingController ctrl, String? hint, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: _darkBrown),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _mutedBrown, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _docTile({required IconData icon, required String title, required XFile? file, required VoidCallback onTap}) {
    final attached = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: attached ? _brown.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: attached ? _brown : _borderColor, width: attached ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: _brown, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _darkBrown)),
            ),
            const SizedBox(width: 8),
            attached
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('แนบแล้ว', style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _bgCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: const Text('แนบไฟล์', style: TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w600)),
                  ),
          ],
        ),
      ),
    );
  }
}
