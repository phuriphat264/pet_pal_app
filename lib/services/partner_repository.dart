// Partner application (shop sign-up) + admin review, backed by the real
// backend. Document uploads go straight from the device to MinIO via a
// presigned URL the backend hands out -- this repository never sends file
// bytes through the FastAPI server itself.
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

Map<String, dynamic> partnerApplicationFromJson(Map<String, dynamic> json) {
  return {
    'id': json['id'],
    'shopName': json['shop_name'] as String? ?? '',
    'serviceType': json['service_type'] as String? ?? '',
    'address': json['address'] as String? ?? '',
    'phone': json['phone'] as String? ?? '',
    'description': json['description'] as String? ?? '',
    'status': json['status'] as String? ?? 'pending',
    'docIdCardUrl': json['doc_id_card_url'] as String?,
    'docBusinessLicenseUrl': json['doc_business_license_url'] as String?,
    'docShopPhotoUrl': json['doc_shop_photo_url'] as String?,
    'rejectionReason': json['rejection_reason'] as String?,
  };
}

class PartnerRepository {
  final ApiClient client;
  final http.Client _uploadClient;
  PartnerRepository(this.client, {http.Client? uploadClient}) : _uploadClient = uploadClient ?? http.Client();

  Future<Map<String, dynamic>?> fetchMyApplication() async {
    try {
      final result = await client.get('/partners/applications/me');
      return partnerApplicationFromJson(result as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitApplication({
    required String shopName,
    required String serviceType,
    required String address,
    required String phone,
    String? description,
  }) async {
    final result = await client.post('/partners/applications', body: {
      'shop_name': shopName,
      'service_type': serviceType,
      'address': address,
      'phone': phone,
      'description': description,
    });
    return partnerApplicationFromJson(result as Map<String, dynamic>);
  }

  Future<String> uploadDocument({required String docType, required XFile file}) async {
    final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';
    final contentType = _guessContentType(filename);
    final result = await client.post('/partners/applications/me/upload-url', body: {
      'doc_type': docType,
      'filename': filename,
      'content_type': contentType,
    }) as Map<String, dynamic>;

    final uploadUrl = result['upload_url'] as String;
    final publicUrl = result['public_url'] as String;
    final bytes = await file.readAsBytes();

    final response = await _uploadClient.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'อัปโหลดไฟล์ไม่สำเร็จ');
    }
    return publicUrl;
  }

  String _guessContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  // --- Admin ---

  Future<List<Map<String, dynamic>>> fetchApplications({String? status}) async {
    final result = await client.get(
      '/admin/partner-applications',
      query: status == null ? null : {'status': status},
    );
    return (result as List).map((a) => partnerApplicationFromJson(a as Map<String, dynamic>)).toList();
  }

  Future<void> approveApplication(String id) async {
    await client.post('/admin/partner-applications/$id/approve');
  }

  Future<void> rejectApplication(String id, String reason) async {
    await client.post('/admin/partner-applications/$id/reject', body: {'reason': reason});
  }
}
