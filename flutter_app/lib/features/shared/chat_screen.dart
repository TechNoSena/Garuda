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
  final String driverName;

  const ChatScreen({super.key, required this.shipmentId, this.driverName = "Delivery Partner"});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _maskedPhone;
  String? _sessionId;
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
        _messages.add(ChatMessage(text: "Hello! Tracking shipment ${widget.shipmentId}.", isMe: true, timestamp: DateTime.now()));
        _isLoading = false;
      });
      
      _simulateReply("Hi! I'm your ${user.role.value == 'CONSUMER' ? 'Delivery Partner' : 'Customer'}. How can I help you?");
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _simulateReply(String text) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: text, isMe: false, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;
    final text = _messageCtrl.text.trim();
    _messageCtrl.clear();
    setState(() => _messages.add(ChatMessage(text: text, isMe: true, timestamp: DateTime.now())));
    _scrollToBottom();

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
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final cardColor = isDark ? GarudaDarkColors.card : GarudaColors.card;
    final surfaceColor = isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surfaceLight;
    final borderColor = isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder;

    return Scaffold(
      appBar: const GarudaAppBar(title: 'Secure Chat', showBack: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? GarudaDarkColors.card : GarudaColors.cardHover,
                    border: Border(bottom: BorderSide(color: GarudaColors.primaryDark, width: 2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: GarudaColors.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: GarudaColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.driverName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
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
                        icon: const Icon(Icons.phone, color: GarudaColors.primary),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling masked number...'))),
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
                      return _buildMessageBubble(msg, isDark, textColor).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
                    },
                  ),
                ),
                // Input Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(top: BorderSide(color: borderColor, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.inter(color: GarudaColors.textMuted),
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: GarudaColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: GarudaColors.primaryDark, width: 2),
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark, Color textColor) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isMe ? GarudaColors.primary.withValues(alpha: 0.15) : (isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surfaceLight),
          border: Border.all(color: msg.isMe ? GarudaColors.primary : (isDark ? GarudaDarkColors.glassBorderStrong : GarudaColors.glassBorderStrong), width: 2),
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
            Text(msg.text, style: GoogleFonts.inter(color: textColor, fontSize: 14)),
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
