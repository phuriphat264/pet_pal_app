import 'api_client.dart';

const Map<String, String> bookingStatusLabelTh = {
  'pending': 'รอยืนยัน',
  'confirmed': 'ยืนยันแล้ว',
  'completed': 'เสร็จสิ้น',
  'cancelled': 'ยกเลิก',
};

Map<String, dynamic> hotelBookingFromJson(Map<String, dynamic> json) {
  return {
    'id': json['id'],
    'customerName': json['customer_name'] as String? ?? 'ลูกค้า',
    'petName': json['pet_name'] as String? ?? '-',
    'date': '${json['check_in']} ถึง ${json['check_out']}',
    'status': json['status'] as String,
    'statusLabel': bookingStatusLabelTh[json['status']] ?? json['status'] as String,
  };
}

class BookingRepository {
  final ApiClient client;
  BookingRepository(this.client);

  Future<Map<String, dynamic>> createBooking({
    required String hotelId,
    String? roomId,
    String? petId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? paymentMethod,
    String? matchingPrompt,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final result = await client.post('/bookings', body: {
      'hotel_id': hotelId,
      'room_id': roomId,
      'pet_id': petId,
      'check_in': fmt(checkIn),
      'check_out': fmt(checkOut),
      'payment_method': paymentMethod,
      'matching_prompt': matchingPrompt,
    });
    return result as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    final result = await client.get('/bookings/me');
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchHotelBookings(String hotelId) async {
    final result = await client.get('/bookings/hotel/$hotelId');
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await client.patch('/bookings/$bookingId/status', body: {'status': status});
  }
}
