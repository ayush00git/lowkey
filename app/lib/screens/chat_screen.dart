import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _sessionIdController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  late SignalingService _signaling;
  late WebRTCService _webrtc;
  final _crypto = CryptoService();

  String _username = '';
  String? _peer;
  String? _sessionId;
  bool _wsConnected = false;
  bool _p2pConnected = false;
  final List<ChatMessage> _messages = [];
  final List<StreamSubscription> _subs = [];

  // Server URL — change this for production
  static const _serverUrl = 'ws://10.0.2.2:8080'; // Android emulator → host

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

    // Listen to signaling events
    _subs.add(_signaling.onConnectionChange.listen((connected) {
      setState(() => _wsConnected = connected);
    }));

    _subs.add(_signaling.onSessionCreated.listen((payload) {
      setState(() {
        _sessionId = payload['sessionId'] as String;
        _crypto.setKey(payload['key'] as String);
      });
      _showSnackbar('Session created — share the ID with your peer');
    }));

    _subs.add(_signaling.onSessionJoined.listen((payload) {
      final peer = payload['peer'] as String;
      final key = payload['key'] as String;
      setState(() {
        _peer = peer;
        _sessionId = payload['sessionId'] as String;
      });
      _crypto.setKey(key);
      // Initiator starts the WebRTC call
      if (_isCreator()) {
        _webrtc.startCall(peer);
      }
      _showSnackbar('$peer joined — establishing P2P connection...');
    }));

    _subs.add(_signaling.onError.listen((err) {
      _showSnackbar('Error: ${err['message']}', isError: true);
    }));

    // Listen to WebRTC events
    _subs.add(_webrtc.onDataChannelState.listen((connected) {
      setState(() => _p2pConnected = connected);
      if (connected) {
        _showSnackbar('🔒 P2P connected — messages are end-to-end encrypted');
      }
    }));

    _subs.add(_webrtc.onMessage.listen((data) {
      _handleIncomingMessage(data);
    }));

    // Connect to signaling server
    _signaling.connect(_serverUrl, _username);
  }

  bool _isCreator() {
    // The session creator is the one who created it (onSessionCreated was fired)
    return _peer != null;
  }

  void _handleIncomingMessage(String data) {
    try {
      String content;
      if (_crypto.hasKey) {
        content = _crypto.decryptMessage(data);
      } else {
        content = data;
      }

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

    // Encrypt and send
    String payload;
    if (_crypto.hasKey) {
      payload = _crypto.encryptMessage(text);
    } else {
      payload = text;
    }
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
    _sessionIdController.dispose();
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
          // Session panel (before P2P is connected)
          if (!_p2pConnected) _buildSessionPanel(),

          // Messages
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

          // Input bar
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
            _peer != null ? _peer! : 'lowkey',
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

  Widget _buildSessionPanel() {
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
        children: [
          if (_sessionId != null) ...[
            // Show session ID with copy button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sessionId!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _sessionId!));
                      _showSnackbar('Session ID copied');
                    },
                    child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _peer == null
                  ? 'Waiting for peer to join...'
                  : 'Connecting to $_peer...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ] else ...[
            // Create or join session
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _wsConnected
                          ? () => _signaling.createSession()
                          : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'New Session',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _sessionIdController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste session ID',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFBDBDBD),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _wsConnected
                        ? () {
                            final id = _sessionIdController.text.trim();
                            if (id.isNotEmpty) {
                              _signaling.joinSession(id);
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
                    child: Text(
                      'Join',
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
                'Connecting to server...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFE57373),
                ),
              ),
            ],
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
