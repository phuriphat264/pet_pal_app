// Fetches hotels from the backend and reshapes the JSON into the same
// Map<String, dynamic> shape the screens already expect (the shape that
// used to come from lib/data/hotel_data.dart), so the widget trees in
// hotel_list_page.dart / hotel_detail_page.dart / main.dart stay unchanged.
import '../utils/ui_mapping.dart';
import 'api_client.dart';

Map<String, dynamic> hotelFromJson(Map<String, dynamic> json) {
  return {
    'id': json['id'],
    'name': json['name'] as String,
    'location': json['location'] as String? ?? '',
    'distance': json['distance_text'] as String? ?? '',
    'rating': (json['rating'] as num?)?.toDouble() ?? 0.0,
    'reviews': json['reviews_count'] as int? ?? 0,
    'price': json['base_price'] as int? ?? 0,
    'icon': iconFromName(json['icon_name'] as String?),
    'color': colorFromHex(json['color_hex'] as String?),
    'tags': List<String>.from(json['tags'] as List? ?? const []),
    'aiTags': List<String>.from(json['ai_tags'] as List? ?? const []),
    'available': json['available'] as bool? ?? true,
    'description': json['description'] as String? ?? '',
    'rooms': (json['rooms'] as List? ?? const [])
        .map((r) => {
              'id': r['id'],
              'type': r['room_type'] as String,
              'price': r['price_surcharge'] as int? ?? 0,
              'desc': r['description'] as String? ?? '',
              'available': r['available'] as bool? ?? true,
            })
        .toList(),
    'images': (json['images'] as List? ?? const []).map((i) => i['url'] as String).toList(),
    'petTypes': List<String>.from(json['pet_types'] as List? ?? const []),
  };
}

class HotelRepository {
  final ApiClient client;
  HotelRepository(this.client);

  Future<List<Map<String, dynamic>>> fetchHotels({bool availableOnly = true}) async {
    final result = await client.get('/hotels', query: {'available_only': availableOnly}, auth: false);
    return (result as List).map((h) => hotelFromJson(h as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchHotel(String id) async {
    final result = await client.get('/hotels/$id', auth: false);
    return hotelFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchMyHotel() async {
    final result = await client.get('/hotels/mine');
    return hotelFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createHotel(Map<String, dynamic> payload) async {
    final result = await client.post('/hotels', body: payload);
    return hotelFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateHotel(String id, Map<String, dynamic> payload) async {
    final result = await client.patch('/hotels/$id', body: payload);
    return hotelFromJson(result as Map<String, dynamic>);
  }

  Future<void> setRoomAvailability(String hotelId, String roomId, bool available) async {
    await client.patch('/hotels/$hotelId/rooms/$roomId', body: {'available': available});
  }
}
