import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import '../services/crypto_service.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _targetUsernameController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  late SignalingService _signaling;
  late WebRTCService _webrtc;
  final _crypto = CryptoService();

  String _username = '';
  String? _peer;
  bool _isInitiator = false;
  bool _wsConnected = false;
  bool _p2pConnected = false;
  final List<ChatMessage> _messages = [];
  final List<StreamSubscription> _subs = [];

  // Server URL — IMPORTANT: 
  // - Use 'ws://10.189.40.195:8080' for Physical Devices & Emulators
  // - Use 'ws://localhost:8080' for Linux Desktop
  static const _serverUrl = 'ws://10.189.40.195:8080'; 

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'anon';

    _signaling = SignalingService();
    _webrtc = WebRTCService(_signaling);

    _subs.add(_signaling.onConnectionChange.listen((connected) {
      setState(() => _wsConnected = connected);
    }));

    _subs.add(_signaling.onSessionJoined.listen((payload) {
      final peer = payload['peer'] as String;
      final key = payload['key'] as String;
      
      setState(() {
        _peer = peer;
      });
      _crypto.setKey(key);
      
      // The initiator (A) starts the WebRTC call to B
      if (_isInitiator) {
        _webrtc.startCall(peer);
      }
      _showSnackbar('Connected to $peer — establishing encrypted channel...');
    }));

    _subs.add(_signaling.onError.listen((err) {
      _showSnackbar('Error: ${err['message']}', isError: true);
      setState(() => _isInitiator = false);
    }));

    _subs.add(_webrtc.onDataChannelState.listen((connected) {
      setState(() => _p2pConnected = connected);
      if (connected) {
        _showSnackbar('🔒 E2E Encryption Active');
      }
    }));

    _subs.add(_webrtc.onMessage.listen((data) {
      _handleIncomingMessage(data);
    }));

    _signaling.connect(_serverUrl, _username);
  }

  void _handleIncomingMessage(String data) {
    try {
      String content = _crypto.hasKey ? _crypto.decryptMessage(data) : data;

      final msg = ChatMessage(
        id: _uuid.v4(),
        content: content,
        sender: _peer ?? 'peer',
        isMine: false,
        timestamp: DateTime.now(),
      );

      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showSnackbar('Failed to decrypt message', isError: true);
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_p2pConnected) return;

    String payload = _crypto.hasKey ? _crypto.encryptMessage(text) : text;
    _webrtc.sendMessage(payload);

    final msg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      sender: _username,
      isMine: true,
      timestamp: DateTime.now(),
    );

    setState(() => _messages.add(msg));
    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackbar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? const Color(0xFFE57373) : const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _webrtc.dispose();
    _signaling.dispose();
    _msgController.dispose();
    _targetUsernameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_p2pConnected) _buildConnectionPanel(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => MessageBubble(message: _messages[i]),
                  ),
          ),
          if (_p2pConnected) _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _peer ?? 'lowkey',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          ConnectionIndicator(connected: _p2pConnected),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '@$_username',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect to Peer',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetUsernameController,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Enter friend's username",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFBDBDBD),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_wsConnected && !_isInitiator)
                      ? () {
                          final target = _targetUsernameController.text.trim();
                          if (target.isNotEmpty) {
                            setState(() => _isInitiator = true);
                            _signaling.connectToUser(target);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isInitiator
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Connect',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (!_wsConnected) ...[
            const SizedBox(height: 12),
            Text(
              'Waiting for server connection...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFE57373),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _p2pConnected ? Icons.lock_rounded : Icons.chat_bubble_outline_rounded,
            size: 48,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 12),
          Text(
            _p2pConnected
                ? 'Connection secured\nStart chatting!'
                : 'Create or join a session\nto start chatting',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFBDBDBD),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFFBDBDBD),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(21),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
