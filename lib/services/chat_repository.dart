// Customer<->partner chat: REST for history, the shared RealtimeService
// socket for live delivery while a thread/list screen is open.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'realtime_service.dart';

Map<String, dynamic> chatThreadFromJson(Map<String, dynamic> json) => {
      'id': json['id'] as String,
      'customerId': json['customer_id'] as String,
      'hotelId': json['hotel_id'] as String,
      'hotelName': json['hotel_name'] as String,
      'customerName': json['customer_name'] as String,
      'lastMessage': json['last_message'] as String?,
      'lastMessageAt': json['last_message_at'] as String?,
      'unreadCount': json['unread_count'] as int,
      'createdAt': json['created_at'] as String,
    };

Map<String, dynamic> chatMessageFromJson(Map<String, dynamic> json) => {
      'id': json['id'] as String,
      'threadId': json['thread_id'] as String,
      'senderId': json['sender_id'] as String,
      'body': json['body'] as String,
      'readAt': json['read_at'] as String?,
      'createdAt': json['created_at'] as String,
    };

class ChatRepository extends ChangeNotifier {
  final ApiClient client;
  final RealtimeService realtime;
  StreamSubscription? _sub;

  List<Map<String, dynamic>> threads = [];

  ChatRepository({required this.client, required this.realtime}) {
    _sub = realtime.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] != 'chat_message') return;
    final message = chatMessageFromJson(event['message'] as Map<String, dynamic>);
    final threadId = event['thread_id'] as String;
    final index = threads.indexWhere((t) => t['id'] == threadId);
    if (index != -1) {
      threads[index] = {
        ...threads[index],
        'lastMessage': message['body'],
        'lastMessageAt': message['createdAt'],
        'unreadCount': (threads[index]['unreadCount'] as int) + 1,
      };
      notifyListeners();
    }
  }

  Future<void> loadThreads() async {
    final result = await client.get('/chat/threads');
    threads = (result as List).map((t) => chatThreadFromJson(t as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<Map<String, dynamic>> createOrGetThread(String hotelId) async {
    final result = await client.post('/chat/threads', body: {'hotel_id': hotelId});
    return chatThreadFromJson(result as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String threadId) async {
    final result = await client.get('/chat/threads/$threadId/messages');
    return (result as List).map((m) => chatMessageFromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> sendMessage(String threadId, String body) async {
    final result = await client.post('/chat/threads/$threadId/messages', body: {'body': body});
    return chatMessageFromJson(result as Map<String, dynamic>);
  }

  Future<void> markThreadRead(String threadId) async {
    await client.post('/chat/threads/$threadId/read');
    final index = threads.indexWhere((t) => t['id'] == threadId);
    if (index != -1) {
      threads[index] = {...threads[index], 'unreadCount': 0};
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
