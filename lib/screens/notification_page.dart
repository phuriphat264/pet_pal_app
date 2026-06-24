// lib/screens/notification_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_repository.dart';

const Map<String, String> _typeIcons = {
  'booking': '🏡',
  'match': '❤️',
  'chat': '💬',
  'system': '🔔',
};

const Map<String, Color> _typeColors = {
  'booking': Color(0xFF7CB9A8),
  'match': Color(0xFFE8936A),
  'chat': Color(0xFF1E88E5),
  'system': Color(0xFF9B7EC8),
};

String _timeAgo(String isoTimestamp) {
  final time = DateTime.tryParse(isoTimestamp);
  if (time == null) return '';
  final diff = DateTime.now().toUtc().difference(time.toUtc());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
  if (diff.inDays == 1) return 'เมื่อวาน';
  return '${diff.inDays} วันที่แล้ว';
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  bool _loading = true;
  String _filter = 'ทั้งหมด';
  final _filters = ['ทั้งหมด', 'ยังไม่อ่าน', 'แชท', 'จอง'];

  @override
  void initState() {
    super.initState();
    context.read<NotificationRepository>().loadNotifications().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> notifications) {
    if (_filter == 'ยังไม่อ่าน') return notifications.where((n) => n['read'] == false).toList();
    if (_filter == 'แชท') return notifications.where((n) => n['type'] == 'chat').toList();
    if (_filter == 'จอง') return notifications.where((n) => n['type'] == 'booking').toList();
    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NotificationRepository>();
    final unread = repo.unreadCount;

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _brown))
            : Column(
                children: [
                  _buildHeader(unread, repo),
                  _buildFilters(),
                  Expanded(child: _buildList(_filtered(repo.notifications))),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(int unread, NotificationRepository repo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('การแจ้งเตือน',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
              if (unread > 0)
                Text('ยังไม่อ่าน $unread รายการ',
                    style: const TextStyle(fontSize: 14, color: _mutedBrown)),
            ],
          ),
          const Spacer(),
          if (unread > 0)
            GestureDetector(
              onTap: () => repo.markAllRead(),
              child: const Text('อ่านทั้งหมด',
                  style: TextStyle(fontSize: 14, color: _brown, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _filters[i] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _brown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _brown : const Color(0xFFD9C5B2), width: 0.5),
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _mutedBrown,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🔔', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('ไม่มีการแจ้งเตือน', style: TextStyle(fontSize: 18, color: _mutedBrown)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildNotifCard(items[i]),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> n) {
    final unread = n['read'] == false;
    final color = _typeColors[n['type']] ?? _typeColors['system']!;
    final icon = _typeIcons[n['type']] ?? _typeIcons['system']!;
    return GestureDetector(
      onTap: () => context.read<NotificationRepository>().markRead(n['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? Colors.white : _bgCard.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? color.withValues(alpha:0.4) : const Color(0xFFD9C5B2),
            width: unread ? 1 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n['title'] as String,
                            style: TextStyle(
                              fontSize: 15, fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                              color: _darkBrown,
                            )),
                      ),
                      if (unread)
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if ((n['body'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(n['body'] as String,
                        style: const TextStyle(fontSize: 14, color: _mutedBrown, height: 1.4)),
                  ],
                  const SizedBox(height: 6),
                  Text(_timeAgo(n['createdAt'] as String),
                      style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
