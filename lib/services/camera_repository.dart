// Camera registration/management for technicians. No real camera hardware
// exists yet -- "test connection" is a real TCP-reachability probe done by
// the backend, not a video stream; this repository only manages the
// registration records (IP, port, protocol, credentials) for cameras that
// will eventually be wired in.
import 'api_client.dart';

Map<String, dynamic> cameraFromJson(Map<String, dynamic> json) {
  return {
    'id': json['id'],
    'hotelId': json['hotel_id'],
    'roomId': json['room_id'],
    'name': json['name'] as String,
    'ipAddress': json['ip_address'] as String,
    'port': json['port'] as int,
    'protocol': json['protocol'] as String,
    'streamPath': json['stream_path'] as String?,
    'username': json['username'] as String?,
    'status': json['status'] as String,
    'lastCheckedAt': json['last_checked_at'] as String?,
    'lastError': json['last_error'] as String?,
    'notes': json['notes'] as String?,
  };
}

class CameraRepository {
  final ApiClient client;
  CameraRepository(this.client);

  Future<List<Map<String, dynamic>>> fetchCameras({String? hotelId}) async {
    final result = await client.get('/cameras', query: hotelId == null ? null : {'hotel_id': hotelId});
    return (result as List).map((c) => cameraFromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createCamera({
    required String hotelId,
    String? roomId,
    required String name,
    required String ipAddress,
    required int port,
    required String protocol,
    String? streamPath,
    String? username,
    String? password,
    String? notes,
  }) async {
    final result = await client.post('/cameras', body: {
      'hotel_id': hotelId,
      'room_id': roomId,
      'name': name,
      'ip_address': ipAddress,
      'port': port,
      'protocol': protocol,
      'stream_path': streamPath,
      'username': username,
      'password': password,
      'notes': notes,
    });
    return cameraFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateCamera(String id, Map<String, dynamic> updates) async {
    final result = await client.patch('/cameras/$id', body: updates);
    return cameraFromJson(result as Map<String, dynamic>);
  }

  Future<void> deleteCamera(String id) async {
    await client.delete('/cameras/$id');
  }

  Future<Map<String, dynamic>> testConnection(String id) async {
    final result = await client.post('/cameras/$id/test-connection') as Map<String, dynamic>;
    return {
      'success': result['success'] as bool,
      'message': result['message'] as String?,
      'camera': cameraFromJson(result['camera'] as Map<String, dynamic>),
    };
  }

  // Customer-facing: only returns cameras for hotels the caller has actually
  // booked (or all, for technician/admin) -- enforced server-side.
  Future<List<Map<String, dynamic>>> fetchCamerasForHotel(String hotelId) async {
    final result = await client.get('/cameras/by-hotel/$hotelId');
    return (result as List).map((c) => cameraFromJson(c as Map<String, dynamic>)).toList();
  }

  Future<String> fetchStreamUrl(String cameraId) async {
    final result = await client.get('/cameras/$cameraId/stream') as Map<String, dynamic>;
    return result['stream_url'] as String;
  }
}
