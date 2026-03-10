import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

/// Manages WebRTC peer connection and DataChannel for P2P chat.
class WebRTCService {
  final SignalingService _signaling;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  String? _remotePeer;
  bool _connected = false;

  final _onMessage = StreamController<String>.broadcast();
  final _onDataChannelState = StreamController<bool>.broadcast();

  Stream<String> get onMessage => _onMessage.stream;
  Stream<bool> get onDataChannelState => _onDataChannelState.stream;
  bool get isConnected => _connected;

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  WebRTCService(this._signaling) {
    _signaling.onSignal.listen(_handleSignal);
  }

  /// Initialize as the caller (creates offer).
  Future<void> startCall(String remotePeer) async {
    _remotePeer = remotePeer;
    await _createPeerConnection();

    // Create DataChannel before offer
    final dcConfig = RTCDataChannelInit()..ordered = true;
    _dataChannel = await _peerConnection!.createDataChannel('chat', dcConfig);
    _setupDataChannel(_dataChannel!);

    // Create and send offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _signaling.sendOffer(remotePeer, offer.toMap());
  }

  /// Handle incoming signal messages.
  Future<void> _handleSignal(Map<String, dynamic> msg) async {
    final type = msg['type'] as String;
    final sender = msg['sender'] as String?;

    switch (type) {
      case 'signal:offer':
        _remotePeer = sender;
        await _createPeerConnection();
        final payload = msg['payload'] as Map<String, dynamic>;
        final sdp = RTCSessionDescription(payload['sdp'], payload['type']);
        await _peerConnection!.setRemoteDescription(sdp);
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _signaling.sendAnswer(sender!, answer.toMap());
        break;

      case 'signal:answer':
        final payload = msg['payload'] as Map<String, dynamic>;
        final sdp = RTCSessionDescription(payload['sdp'], payload['type']);
        await _peerConnection!.setRemoteDescription(sdp);
        break;

      case 'signal:ice':
        final payload = msg['payload'] as Map<String, dynamic>;
        final candidate = RTCIceCandidate(
          payload['candidate'],
          payload['sdpMid'],
          payload['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        break;
    }
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_config);

    // ICE candidate handler
    _peerConnection!.onIceCandidate = (candidate) {
      if (_remotePeer != null) {
        _signaling.sendIceCandidate(_remotePeer!, candidate.toMap());
      }
    };

    // Handle incoming DataChannel (for the answerer)
    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannel(channel);
    };

    _peerConnection!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _connected = true;
        _onDataChannelState.add(true);
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
                 state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _connected = false;
        _onDataChannelState.add(false);
      }
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    channel.onDataChannelState = (state) {
      final open = state == RTCDataChannelState.RTCDataChannelOpen;
      _connected = open;
      _onDataChannelState.add(open);
    };

    channel.onMessage = (message) {
      _onMessage.add(message.text);
    };
  }

  /// Send a text message over the DataChannel.
  void sendMessage(String text) {
    if (_dataChannel != null && _connected) {
      _dataChannel!.send(RTCDataChannelMessage(text));
    }
  }

  /// Close the peer connection.
  Future<void> close() async {
    _dataChannel?.close();
    await _peerConnection?.close();
    _peerConnection = null;
    _dataChannel = null;
    _connected = false;
    _onDataChannelState.add(false);
  }

  void dispose() {
    close();
    _onMessage.close();
    _onDataChannelState.close();
  }
}
