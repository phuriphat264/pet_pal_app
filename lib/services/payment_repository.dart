// Card tokenization talks directly to Omise's vault (vault.omise.co) using
// the publishable key -- raw card details never touch our backend, same
// approach Omise's own SDKs use. Everything else (creating the charge,
// polling status) goes through our backend via the shared ApiClient.
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

const Map<String, String> paymentStatusLabelTh = {
  'pending': 'รอดำเนินการ',
  'successful': 'ชำระเงินสำเร็จ',
  'failed': 'ชำระเงินไม่สำเร็จ',
  'expired': 'หมดเวลาชำระเงิน',
  'refunded': 'คืนเงินแล้ว',
};

class PaymentRepository {
  final ApiClient client;
  PaymentRepository(this.client);

  Future<String> createCardToken({
    required String cardNumber,
    required String name,
    required int expMonth,
    required int expYear,
    required String securityCode,
  }) async {
    final publicKey = dotenv.isInitialized ? dotenv.env['OMISE_PUBLIC_KEY'] : null;
    if (publicKey == null || publicKey.isEmpty) {
      throw Exception('ไม่พบ OMISE_PUBLIC_KEY ในไฟล์ .env');
    }

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$publicKey:'))}';
    final response = await http.post(
      Uri.parse('https://vault.omise.co/tokens'),
      headers: {'Authorization': basicAuth},
      body: {
        'card[number]': cardNumber.replaceAll(' ', ''),
        'card[name]': name,
        'card[expiration_month]': expMonth.toString(),
        'card[expiration_year]': expYear.toString(),
        'card[security_code]': securityCode,
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded['id'] as String;
    }
    throw Exception((decoded['message'] as String?) ?? 'ไม่สามารถบันทึกข้อมูลบัตรได้');
  }

  Future<Map<String, dynamic>> createPayment({
    required String bookingId,
    required String method,
    String? cardToken,
  }) async {
    final result = await client.post('/bookings/$bookingId/payments', body: {
      'method': method,
      if (cardToken != null) 'card_token': cardToken,
    });
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchLatestPayment(String bookingId) async {
    final result = await client.get('/bookings/$bookingId/payments/latest');
    return result as Map<String, dynamic>;
  }
}
