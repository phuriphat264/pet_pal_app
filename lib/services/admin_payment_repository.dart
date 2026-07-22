import 'api_client.dart';

const Map<String, String> adminPaymentStatusLabelTh = {
  'pending': 'รอดำเนินการ',
  'successful': 'สำเร็จ',
  'failed': 'ไม่สำเร็จ',
  'expired': 'หมดเวลา',
  'refunded': 'คืนเงินแล้ว',
};

Map<String, dynamic> _paymentFromJson(Map<String, dynamic> json) {
  return {
    'id': json['id'],
    'bookingId': json['booking_id'],
    'amountThb': (json['amount'] as num) / 100,
    'currency': json['currency'] as String,
    'method': json['method'] as String,
    'status': json['status'] as String,
    'failureMessage': json['failure_message'] as String?,
    'createdAt': json['created_at'] as String,
    'customerName': json['customer_name'] as String?,
    'hotelName': json['hotel_name'] as String?,
  };
}

class AdminPaymentRepository {
  final ApiClient client;
  AdminPaymentRepository(this.client);

  Future<List<Map<String, dynamic>>> fetchPayments({String? status}) async {
    final result = await client.get('/admin/payments', query: status == null ? null : {'status': status});
    return (result as List).map((p) => _paymentFromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> refundPayment(String paymentId) async {
    await client.post('/admin/payments/$paymentId/refund');
  }

  Future<Map<String, dynamic>> fetchFinanceReport({int days = 30}) async {
    final result = await client.get('/admin/reports/finance', query: {'days': days}) as Map<String, dynamic>;
    return {
      'periodDays': result['period_days'],
      'totalRevenueThb': (result['total_revenue_thb'] as num).toDouble(),
      'successfulCount': result['successful_count'],
      'pendingCount': result['pending_count'],
      'failedCount': result['failed_count'],
      'refundedCount': result['refunded_count'],
      'daily': (result['daily'] as List)
          .map((d) => {
                'day': d['day'],
                'revenueThb': (d['revenue_thb'] as num).toDouble(),
                'successfulCount': d['successful_count'],
              })
          .toList(),
    };
  }
}
