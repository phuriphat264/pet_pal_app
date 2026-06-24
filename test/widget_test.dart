// Basic smoke test for the PetPal app shell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_pal_app/main.dart';
import 'package:pet_pal_app/services/auth_service.dart';

void main() {
  testWidgets('App launches and shows bottom navigation', (WidgetTester tester) async {
    final authService = AuthService()
      ..debugSetSession(const AuthUser(id: 'test-user', email: 'test@example.com', name: 'Test User', role: 'customer'));
    await tester.pumpWidget(PetPalApp(authService: authService));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('หน้าหลัก'), findsOneWidget);
    expect(find.text('โปรไฟล์'), findsOneWidget);
  });
}
