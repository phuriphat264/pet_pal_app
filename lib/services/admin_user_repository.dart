// Admin-only user management: creating technician accounts directly (for
// hiring external contractors who repair/install cameras) and promoting or
// demoting between customer/technician. Promoting to admin is intentionally
// not exposed here -- the backend rejects it as a privilege-escalation risk.
import 'api_client.dart';

Map<String, dynamic> userFromJson(Map<String, dynamic> json) => {
      'id': json['id'] as String,
      'email': json['email'] as String,
      'name': json['name'] as String,
      'phone': json['phone'] as String?,
      'role': json['role'] as String,
    };

class AdminUserRepository {
  final ApiClient client;
  AdminUserRepository(this.client);

  Future<List<Map<String, dynamic>>> fetchUsersByRole(String role) async {
    final result = await client.get('/users', query: {'role': role});
    return (result as List).map((u) => userFromJson(u as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createTechnician({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final result = await client.post('/admin/technicians', body: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
    });
    return userFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    final result = await client.patch('/admin/users/$userId/role', body: {'role': role});
    return userFromJson(result as Map<String, dynamic>);
  }
}
