// Voice/video calls in chat, backed by a self-hosted LiveKit room per
// thread. Signaling (invite/decline/end) rides the same chat WebSocket as
// messages; LiveKit itself only ever sees a room name + per-user token, so
// this service never needs to know about WebRTC/SDP/ICE directly.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'api_client.dart';
import 'realtime_service.dart';

enum CallType { audio, video }

enum CallState { idle, ringingOutgoing, ringingIncoming, connecting, active }

class IncomingCallInfo {
  final String threadId;
  final String room;
  final CallType callType;
  final String callerName;

  const IncomingCallInfo({
    required this.threadId,
    required this.room,
    required this.callType,
    required this.callerName,
  });
}

class CallService extends ChangeNotifier {
  final ApiClient client;
  final RealtimeService realtime;
  StreamSubscription? _sub;
  lk.EventsListener<lk.RoomEvent>? _roomListener;

  CallService({required this.client, required this.realtime}) {
    _sub = realtime.events.listen(_onEvent);
  }

  CallState state = CallState.idle;
  CallType callType = CallType.video;
  String? threadId;
  String? peerName;
  IncomingCallInfo? incomingCall;
  String? error;

  lk.Room? room;
  lk.VideoTrack? localVideoTrack;
  lk.VideoTrack? remoteVideoTrack;

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] != 'call_signal') return;
    switch (event['signal'] as String?) {
      case 'invite':
        if (state != CallState.idle) {
          realtime.send({'type': 'call_signal', 'signal': 'decline', 'thread_id': event['thread_id']});
          return;
        }
        incomingCall = IncomingCallInfo(
          threadId: event['thread_id'] as String,
          room: event['room'] as String,
          callType: event['call_type'] == 'audio' ? CallType.audio : CallType.video,
          callerName: event['caller_name'] as String? ?? 'ผู้ใช้',
        );
        state = CallState.ringingIncoming;
        notifyListeners();
        break;
      case 'decline':
        if (state == CallState.ringingOutgoing || state == CallState.connecting) {
          error = 'อีกฝ่ายปฏิเสธการโทร';
          _teardown();
        }
        break;
      case 'end':
        _teardown();
        break;
    }
  }

  Future<void> startCall(String threadId, CallType type) async {
    this.threadId = threadId;
    callType = type;
    error = null;
    state = CallState.ringingOutgoing;
    notifyListeners();
    try {
      final result = await client.post(
        '/chat/threads/$threadId/call-token',
        body: {'call_type': type == CallType.audio ? 'audio' : 'video', 'is_accept': false},
      );
      await _joinRoom(result as Map<String, dynamic>);
    } catch (e) {
      error = 'เริ่มการโทรไม่สำเร็จ: $e';
      _teardown();
      rethrow;
    }
  }

  Future<void> acceptIncoming() async {
    final invite = incomingCall;
    if (invite == null) return;
    threadId = invite.threadId;
    callType = invite.callType;
    peerName = invite.callerName;
    error = null;
    state = CallState.connecting;
    incomingCall = null;
    notifyListeners();
    try {
      final result = await client.post(
        '/chat/threads/${invite.threadId}/call-token',
        body: {'call_type': invite.callType == CallType.audio ? 'audio' : 'video', 'is_accept': true},
      );
      await _joinRoom(result as Map<String, dynamic>);
    } catch (e) {
      error = 'รับสายไม่สำเร็จ: $e';
      _teardown();
      rethrow;
    }
  }

  void declineIncoming() {
    final invite = incomingCall;
    if (invite == null) return;
    realtime.send({'type': 'call_signal', 'signal': 'decline', 'thread_id': invite.threadId});
    _teardown();
  }

  Future<void> endCall() async {
    if (threadId != null) {
      realtime.send({'type': 'call_signal', 'signal': 'end', 'thread_id': threadId});
    }
    await _teardown();
  }

  Future<void> _joinRoom(Map<String, dynamic> tokenResponse) async {
    final newRoom = lk.Room(roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true));
    room = newRoom;

    _roomListener = newRoom.createListener()
      ..on<lk.RoomDisconnectedEvent>((_) => _teardown())
      ..on<lk.TrackSubscribedEvent>((e) {
        if (e.track is lk.VideoTrack) {
          remoteVideoTrack = e.track as lk.VideoTrack;
          notifyListeners();
        }
      })
      ..on<lk.TrackUnsubscribedEvent>((e) {
        if (identical(e.track, remoteVideoTrack)) {
          remoteVideoTrack = null;
          notifyListeners();
        }
      })
      ..on<lk.ParticipantConnectedEvent>((_) {
        state = CallState.active;
        notifyListeners();
      });

    await newRoom.connect(
      tokenResponse['livekit_url'] as String,
      tokenResponse['token'] as String,
    );

    await newRoom.localParticipant?.setMicrophoneEnabled(true);
    if (callType == CallType.video) {
      await newRoom.localParticipant?.setCameraEnabled(true);
      localVideoTrack = newRoom.localParticipant?.videoTrackPublications
          .map((p) => p.track)
          .whereType<lk.VideoTrack>()
          .firstOrNull;
    }
    if (state != CallState.active) state = CallState.connecting;
    notifyListeners();
  }

  bool get isMicEnabled => room?.localParticipant?.isMicrophoneEnabled() ?? false;
  bool get isCameraEnabled => room?.localParticipant?.isCameraEnabled() ?? false;

  Future<void> toggleMute() async {
    await room?.localParticipant?.setMicrophoneEnabled(!isMicEnabled);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    await room?.localParticipant?.setCameraEnabled(!isCameraEnabled);
    notifyListeners();
  }

  Future<void> _teardown() async {
    await _roomListener?.dispose();
    _roomListener = null;
    await room?.disconnect();
    await room?.dispose();
    room = null;
    state = CallState.idle;
    threadId = null;
    peerName = null;
    incomingCall = null;
    localVideoTrack = null;
    remoteVideoTrack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _teardown();
    super.dispose();
  }
}
