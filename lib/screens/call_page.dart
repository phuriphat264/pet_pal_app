// lib/screens/call_page.dart
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:provider/provider.dart';

import '../services/call_service.dart';

String _initial(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBrown,
      body: Consumer<CallService>(
        builder: (context, call, _) {
          if (call.state == CallState.idle) {
            // Signaling already tore the call down (declined/ended) --
            // pop back to wherever the call was started from.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
          }
          return SafeArea(
            child: Stack(
              children: [
                _buildVideoArea(call),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: _buildStatusHeader(call),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: _buildControls(context, call),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoArea(CallService call) {
    final remote = call.remoteVideoTrack;
    if (call.callType == CallType.video && remote != null) {
      return Positioned.fill(child: lk.VideoTrackRenderer(remote));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: _brown,
            child: Text(
              _initial(call.peerName),
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(call.peerName ?? 'ผู้ใช้', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(CallService call) {
    final label = switch (call.state) {
      CallState.ringingOutgoing => 'กำลังโทร...',
      CallState.connecting => 'กำลังเชื่อมต่อ...',
      CallState.active => call.callType == CallType.video ? 'วิดีโอคอล' : 'สายเสียง',
      _ => '',
    };
    return Center(
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLocalPreview(CallService call) {
    final local = call.localVideoTrack;
    if (call.callType != CallType.video || local == null) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          height: 140,
          child: lk.VideoTrackRenderer(local, mirrorMode: lk.VideoViewMirrorMode.mirror),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, CallService call) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (call.callType == CallType.video)
              Padding(
                padding: const EdgeInsets.only(bottom: 160),
                child: Align(alignment: Alignment.topRight, child: _buildLocalPreview(call)),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlButton(
              icon: call.isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              onTap: call.toggleMute,
            ),
            const SizedBox(width: 20),
            _controlButton(
              icon: Icons.call_end_rounded,
              background: Colors.redAccent,
              onTap: call.endCall,
            ),
            if (call.callType == CallType.video) ...[
              const SizedBox(width: 20),
              _controlButton(
                icon: call.isCameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                onTap: call.toggleCamera,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _controlButton({required IconData icon, required VoidCallback onTap, Color? background}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: background ?? Colors.white24, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class IncomingCallPage extends StatelessWidget {
  const IncomingCallPage({super.key});

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBrown,
      body: Consumer<CallService>(
        builder: (context, call, _) {
          final invite = call.incomingCall;
          if (invite == null || call.state != CallState.ringingIncoming) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 56,
                  backgroundColor: _brown,
                  child: Text(
                    _initial(invite.callerName),
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),
                Text(invite.callerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  invite.callType == CallType.video ? 'วิดีโอคอลสาย...' : 'โทรสาย...',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionButton(
                        icon: Icons.call_end_rounded,
                        color: Colors.redAccent,
                        label: 'ปฏิเสธ',
                        onTap: () {
                          call.declineIncoming();
                          Navigator.of(context).pop();
                        },
                      ),
                      _actionButton(
                        icon: Icons.call_rounded,
                        color: Colors.green,
                        label: 'รับสาย',
                        onTap: () async {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallPage()));
                          await call.acceptIncoming();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
