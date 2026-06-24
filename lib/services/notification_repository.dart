import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'realtime_service.dart';

Map<String, dynamic> notificationFromJson(Map<String, dynamic> json) => {
      'id': json['id'] as String,
      'type': json['type'] as String,
      'title': json['title'] as String,
      'body': json['body'] as String?,
      'data': json['data'] as Map<String, dynamic>?,
      'read': json['read'] as bool,
      'createdAt': json['created_at'] as String,
    };

class NotificationRepository extends ChangeNotifier {
  final ApiClient client;
  final RealtimeService realtime;
  StreamSubscription? _sub;

  List<Map<String, dynamic>> notifications = [];

  NotificationRepository({required this.client, required this.realtime}) {
    _sub = realtime.events.listen(_onEvent);
  }

  int get unreadCount => notifications.where((n) => n['read'] == false).length;

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] != 'notification') return;
    final notification = notificationFromJson(event['notification'] as Map<String, dynamic>);
    notifications = [notification, ...notifications];
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final result = await client.get('/notifications');
    notifications = (result as List).map((n) => notificationFromJson(n as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await client.post('/notifications/$id/read');
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index] = {...notifications[index], 'read': true};
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await client.post('/notifications/read-all');
    notifications = notifications.map((n) => {...n, 'read': true}).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
