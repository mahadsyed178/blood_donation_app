import 'package:flutter/material.dart';

class CoordinationChatScreen extends StatefulWidget {
  const CoordinationChatScreen({super.key});

  @override
  State<CoordinationChatScreen> createState() =>
      _CoordinationChatScreenState();
}

class _CoordinationChatScreenState extends State<CoordinationChatScreen> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color bgGrey = Color(0xFFF8FAFC);

  // Placeholder data — wire to ChatRepository.getConversations() later
  final List<_ChatSummary> _chats = [
    _ChatSummary(
      name: 'Usman Ghani',
      role: 'Donor',
      bloodGroup: 'O+',
      lastMessage: 'I am on my way to the blood bank now. ETA 15 mins.',
      time: '11:42 AM',
      unreadCount: 2,
      messages: [
        _ChatMessage(
          text: 'Hi, I saw your request for O+ blood. I can donate.',
          isMe: false,
          time: '11:20 AM',
        ),
        _ChatMessage(
          text: 'Thank you so much! Which hospital are you near?',
          isMe: true,
          time: '11:22 AM',
        ),
        _ChatMessage(
          text: 'I am near Civil Hospital. Can head there in 20 mins.',
          isMe: false,
          time: '11:25 AM',
        ),
        _ChatMessage(
          text: 'Perfect, that works. I will let the ward know.',
          isMe: true,
          time: '11:26 AM',
        ),
        _ChatMessage(
          text: 'I am on my way to the blood bank now. ETA 15 mins.',
          isMe: false,
          time: '11:42 AM',
        ),
      ],
    ),
    _ChatSummary(
      name: 'Alkhidmat Foundation Staff',
      role: 'Partner Institution',
      bloodGroup: 'B-',
      lastMessage: 'Stock unit reserved under Voucher #882.',
      time: 'Yesterday',
      unreadCount: 0,
      messages: [
        _ChatMessage(
          text: 'We have B- stock available for your request.',
          isMe: false,
          time: 'Yesterday, 4:10 PM',
        ),
        _ChatMessage(
          text: 'That would be great, how do we proceed?',
          isMe: true,
          time: 'Yesterday, 4:15 PM',
        ),
        _ChatMessage(
          text: 'Stock unit reserved under Voucher #882.',
          isMe: false,
          time: 'Yesterday, 4:18 PM',
        ),
      ],
    ),
  ];

  void _markAsRead(_ChatSummary chat) {
    setState(() => chat.unreadCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Info banner ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: primaryRed, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat unlocks only after donor willingness (FR-21). Coordination here is non-binding.',
                    style: TextStyle(fontSize: 12, color: textDark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_chats.isEmpty)
            _buildEmptyState()
          else
            ..._chats.map((chat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChatTile(context, chat),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 44, color: textGrey.withOpacity(0.4)),
          const SizedBox(height: 10),
          const Text(
            'No conversations yet',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chats unlock once a donor accepts a request',
            style: TextStyle(color: textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, _ChatSummary chat) {
    final bool hasUnread = chat.unreadCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasUnread ? primaryRed.withOpacity(0.25) : borderGrey,
        ),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFFF5F5),
              child: Text(
                chat.bloodGroup,
                style: const TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: primaryRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 14.5,
                  color: textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chat.role,
              style: const TextStyle(
                fontSize: 10.5,
                color: primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: hasUnread ? textDark : textGrey,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat.time,
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? primaryRed : textGrey,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          _markAsRead(chat);
          _openChatDetailSheet(context, chat);
        },
      ),
    );
  }

  void _openChatDetailSheet(BuildContext context, _ChatSummary chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatDetailSheet(chat: chat),
    );
  }
}

// --- Chat detail bottom sheet: real message thread + working send ---
class _ChatDetailSheet extends StatefulWidget {
  const _ChatDetailSheet({required this.chat});

  final _ChatSummary chat;

  @override
  State<_ChatDetailSheet> createState() => _ChatDetailSheetState();
}

class _ChatDetailSheetState extends State<_ChatDetailSheet> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color bgGrey = Color(0xFFF8FAFC);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.chat.messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true, time: 'Now'));
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // TODO: wire to ChatRepository.sendMessage() usecase
  }

  void _flagConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: primaryRed),
            SizedBox(width: 8),
            Text('Report this conversation?'),
          ],
        ),
        content: const Text(
          'This will send the conversation to an admin for manual review (FR-22). The other person will not be notified.',
          style: TextStyle(fontSize: 13, color: textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: textGrey),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation flagged for admin review.'),
                  backgroundColor: primaryRed,
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // --- Drag handle ---
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFF5F5),
                    child: Text(
                      widget.chat.bloodGroup,
                      style: const TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.chat.role,
                          style: const TextStyle(
                            fontSize: 11,
                            color: primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined,
                        color: primaryRed, size: 20),
                    tooltip: 'Report / Flag conversation (FR-22)',
                    onPressed: _flagConversation,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: borderGrey),

            // --- Non-binding disclaimer ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: bgGrey,
              child: const Text(
                '🔒 Coordination messages · non-binding · does not confirm donation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: textGrey),
              ),
            ),

            // --- Message thread ---
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                child: Text(
                  'Start the conversation',
                  style: TextStyle(color: textGrey, fontSize: 13),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildMessageBubble(_messages[index]),
              ),
            ),

            // --- Input row ---
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: borderGrey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a coordination message...',
                        hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0), fontSize: 13),
                        filled: true,
                        fillColor: bgGrey,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: borderGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: borderGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                          const BorderSide(color: primaryRed, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: const BoxDecoration(
                        color: primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment:
      message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? primaryRed : bgGrey,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : textDark,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: message.isMe
                    ? Colors.white.withOpacity(0.75)
                    : textGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Data models ---
class _ChatSummary {
  final String name;
  final String role;
  final String bloodGroup;
  String lastMessage;
  final String time;
  int unreadCount;
  final List<_ChatMessage> messages;

  _ChatSummary({
    required this.name,
    required this.role,
    required this.bloodGroup,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.messages,
  });
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}