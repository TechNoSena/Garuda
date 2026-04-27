import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isMe, required this.timestamp});
}

class ChatScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  final String driverName; // Can be generic or specific

  const ChatScreen({
    super.key,
    required this.shipmentId,
    this.driverName = "Delivery Partner",
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _maskedPhone;
  String? _sessionId;
  
  // To auto scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChatBridge();
  }

  Future<void> _initChatBridge() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    try {
      final res = await ApiService().createChatBridge(
        shipmentId: widget.shipmentId,
        requesterId: user.uid,
        requesterRole: user.role.value,
        message: "Hello! Tracking shipment ${widget.shipmentId}.",
      );
      
      setState(() {
        _maskedPhone = res['masked_phone'];
        _sessionId = res['session_id'];
        _messages.add(ChatMessage(
          text: "Hello! Tracking shipment ${widget.shipmentId}.",
          isMe: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      // Simulate auto-reply based on role
      _simulateReply("Hi! I'm your ${user.role.value == 'CONSUMER' ? 'Delivery Partner' : 'Customer'}. How can I help you?");
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _simulateReply(String text) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;
    final text = _messageCtrl.text.trim();
    _messageCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true, timestamp: DateTime.now()));
    });
    _scrollToBottom();

    // AI Simulated Reply for POC
    String reply = "I am on my way.";
    if (text.toLowerCase().contains("where")) {
      reply = "I'm currently about 10 minutes away from your location.";
    } else if (text.toLowerCase().contains("delay")) {
      reply = "There's a bit of traffic, but I'm moving.";
    } else if (text.toLowerCase().contains("call")) {
      reply = "Sure, you can reach me at the masked number above.";
    }

    _simulateReply(reply);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GarudaAppBar(title: 'Secure Chat', showBack: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: GarudaColors.cardHover,
                    border: Border(bottom: BorderSide(color: GarudaColors.glassBorderStrong)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: GarudaColors.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: GarudaColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.driverName, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: GarudaColors.textPrimary)),
                            if (_maskedPhone != null)
                              Row(
                                children: [
                                  const Icon(Icons.lock, size: 12, color: GarudaColors.success),
                                  const SizedBox(width: 4),
                                  Text("Masked Phone: $_maskedPhone", style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.success)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: GarudaColors.primaryLight),
                        onPressed: () {
                          // Would launch phone dialer in production
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling masked number...')));
                        },
                      )
                    ],
                  ),
                ),
                // Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
                    },
                  ),
                ),
                // Input Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GarudaColors.card,
                    border: Border(top: BorderSide(color: GarudaColors.glassBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted),
                            filled: true,
                            fillColor: GarudaColors.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: GarudaGradients.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: GarudaColors.background, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isMe ? GarudaColors.primary.withValues(alpha: 0.2) : GarudaColors.surfaceLight,
          border: Border.all(color: msg.isMe ? GarudaColors.primary : GarudaColors.glassBorderStrong),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: msg.isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: GoogleFonts.inter(color: GarudaColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
