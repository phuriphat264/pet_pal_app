// End-to-end widget test for the "Pet Hotel Partner" application flow,
// backed by the real repository/screen code with the network and
// image_picker platform channel faked out. Real backend-driven approval
// is an admin action (not something a customer-facing widget test can
// exercise), so the "approved -> dashboard" path is tested by seeding the
// fake backend with an already-approved application rather than simulating
// approval client-side.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:pet_pal_app/main.dart';
import 'package:pet_pal_app/services/auth_service.dart';

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]), name: 'doc.jpg', mimeType: 'image/jpeg');
  }
}

/// Minimal fake of the FastAPI backend: enough routes for whatever screens
/// happen to be mounted (the bottom-nav IndexedStack keeps every tab alive),
/// plus the partner application endpoints under test.
class _FakeBackend {
  String applicationStatus = 'none'; // 'none' | 'pending' | 'approved'
  Map<String, dynamic>? application;

  http.Client get client => MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final method = request.method;

    if (path == '/hotels' && method == 'GET') return _json([]);
    if (path == '/pets' && method == 'GET') return _json([]);

    if (path == '/partners/applications/me' && method == 'GET') {
      if (application == null) return http.Response('{"detail":"not found"}', 404);
      return _json(application!);
    }

    if (path == '/partners/applications' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      application = {
        'id': 'app-1',
        'user_id': 'user-1',
        'shop_name': body['shop_name'],
        'service_type': body['service_type'],
        'address': body['address'],
        'phone': body['phone'],
        'description': body['description'],
        'status': 'pending',
        'doc_id_card_url': null,
        'doc_business_license_url': null,
        'doc_shop_photo_url': null,
        'reviewed_at': null,
        'rejection_reason': null,
      };
      applicationStatus = 'pending';
      return _json(application!, status: 201);
    }

    if (path == '/partners/applications/me/upload-url' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final docType = body['doc_type'];
      return _json({
        'upload_url': 'http://minio.test/petpal/$docType/fake-signed-url',
        'public_url': 'http://minio.test/petpal/$docType/fake.jpg',
      });
    }

    if (request.url.host == 'minio.test' && method == 'PUT') {
      return http.Response('', 200);
    }

    if (path == '/hotels/mine' && method == 'GET') {
      return _json({
        'id': 'hotel-1',
        'name': application?['shop_name'] ?? 'ร้านของฉัน',
        'location': application?['address'],
        'distance_text': null,
        'rating': 4.8,
        'reviews_count': 12,
        'base_price': 350,
        'icon_name': null,
        'color_hex': null,
        'description': application?['description'],
        'service_type': application?['service_type'],
        'available': true,
        'tags': [],
        'ai_tags': [],
        'pet_types': [],
        'images': [],
        'rooms': [
          {'id': 'room-1', 'room_type': 'ห้องมาตรฐาน', 'price_surcharge': 0, 'description': '', 'available': true},
        ],
      });
    }

    if (path == '/bookings/hotel/hotel-1' && method == 'GET') return _json([]);
    if (path == '/chat/threads' && method == 'GET') return _json([]);
    if (path.startsWith('/hotels/') && path.endsWith('/rooms/room-1') && method == 'PATCH') {
      return _json({
        'id': 'room-1',
        'hotel_id': 'hotel-1',
        'room_type': 'ห้องมาตรฐาน',
        'price_surcharge': 0,
        'description': '',
        'available': jsonDecode(request.body)['available'],
      });
    }

    return http.Response('{"detail":"not mocked: $method $path"}', 404);
  }

  http.Response _json(Object body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

void main() {
  setUpAll(() {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
  });

  Future<_FakeBackend> goToProfile(WidgetTester tester, {String seedStatus = 'none'}) async {
    final backend = _FakeBackend();
    if (seedStatus == 'approved') {
      backend.application = {
        'id': 'app-1',
        'user_id': 'user-1',
        'shop_name': 'Test Pet Hotel',
        'service_type': 'โรงแรม',
        'address': '123 Test Address',
        'phone': '0812345678',
        'description': '',
        'status': 'approved',
        'doc_id_card_url': null,
        'doc_business_license_url': null,
        'doc_shop_photo_url': null,
        'reviewed_at': null,
        'rejection_reason': null,
      };
    }

    final authService = AuthService()
      ..debugSetSession(const AuthUser(id: 'test-user', email: 'test@example.com', name: 'Test User', role: 'customer'));
    await tester.pumpWidget(PetPalApp(authService: authService, httpClient: backend.client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('โปรไฟล์'));
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('shows entry point and validates required fields before submitting', (WidgetTester tester) async {
    await goToProfile(tester);

    expect(find.text('สมัครเปิดร้านกับ PetPal'), findsOneWidget);
    await tester.tap(find.text('สมัครเปิดร้านกับ PetPal'));
    await tester.pumpAndSettle();

    final submitButton = find.text('ส่งคำขอเปิดร้าน');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('กรุณากรอกข้อมูลร้านให้ครบถ้วน'), findsOneWidget);
    expect(find.text('สถานะการสมัครเปิดร้าน'), findsNothing);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test Pet Hotel');
    await tester.enterText(fields.at(1), '123 Test Address');
    await tester.enterText(fields.at(2), '0812345678');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('กรุณาแนบเอกสารยืนยันตัวตนให้ครบทั้ง 3 รายการ'), findsOneWidget);
    expect(find.text('สถานะการสมัครเปิดร้าน'), findsNothing);
  });

  testWidgets('submitting with documents uploads and shows pending status', (WidgetTester tester) async {
    final backend = await goToProfile(tester);

    await tester.tap(find.text('สมัครเปิดร้านกับ PetPal'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test Pet Hotel');
    await tester.enterText(fields.at(1), '123 Test Address');
    await tester.enterText(fields.at(2), '0812345678');

    for (var i = 0; i < 3; i++) {
      final docTile = find.text('แนบไฟล์').first;
      await tester.ensureVisible(docTile);
      await tester.pumpAndSettle();
      await tester.tap(docTile);
      await tester.pumpAndSettle();
    }
    expect(find.text('แนบแล้ว'), findsNWidgets(3));

    final submitButton = find.text('ส่งคำขอเปิดร้าน');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('สถานะการสมัครเปิดร้าน'), findsOneWidget);
    expect(find.text('อยู่ระหว่างตรวจสอบเอกสาร'), findsOneWidget);
    expect(backend.application?['status'], 'pending');
    expect(backend.application?['shop_name'], 'Test Pet Hotel');
  });

  testWidgets('already-approved application opens the real shop dashboard', (WidgetTester tester) async {
    await goToProfile(tester, seedStatus: 'approved');

    expect(find.text('จัดการร้านของฉัน'), findsOneWidget);
    await tester.tap(find.text('จัดการร้านของฉัน'));
    await tester.pumpAndSettle();

    expect(find.text('📊 ภาพรวม'), findsOneWidget);
    expect(find.text('🛏️ จัดการห้อง/บริการ'), findsOneWidget);
    expect(find.text('📅 การจองลูกค้า'), findsOneWidget);
    expect(find.text('ห้องมาตรฐาน'), findsOneWidget);

    final switchFinder = find.byType(Switch).first;
    final before = tester.widget<Switch>(switchFinder).value;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    final after = tester.widget<Switch>(switchFinder).value;
    expect(after, !before);
  });
}
