import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/repositories/chat_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../state/chat_providers.dart';

/// One conversation: REST history (`GET /chat/{match_id}/messages`) plus the
/// live socket (`/chat/ws/{match_id}`). Sending goes over the socket when
/// it's up and falls back to `POST /chat/{match_id}/messages` otherwise.
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String matchId;
  final ChatThreadSummary? summary;
  const ChatThreadScreen({super.key, required this.matchId, this.summary});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _live = [];
  final Set<String> _seenIds = {};

  ChatSocket? _socket;
  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<String>? _errSub;
  StreamSubscription<bool>? _connSub;
  bool _connected = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _openSocket();
  }

  Future<void> _openSocket() async {
    try {
      final socket = await ref.read(chatRepositoryProvider).connect(widget.matchId);
      if (!mounted) {
        await socket.dispose();
        return;
      }
      _socket = socket;
      _msgSub = socket.messages.listen(_onLiveMessage);
      _errSub = socket.errors.listen((e) {
        if (mounted) showSnack(context, e, isError: true);
      });
      _connSub = socket.connectionState.listen((c) {
        if (mounted) setState(() => _connected = c);
      });
    } catch (e) {
      debugPrint('[chat] socket open failed: $e');
    }
  }

  void _onLiveMessage(ChatMessage m) {
    if (_seenIds.contains(m.id)) return;
    setState(() {
      _seenIds.add(m.id);
      _live.add(m);
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _errSub?.cancel();
    _connSub?.cancel();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    _messageController.clear();

    // Socket first — the broadcast echoes our own message back with its id.
    if (_socket?.send(text) ?? false) return;

    setState(() => _sending = true);
    try {
      final m = await ref.read(chatRepositoryProvider).sendMessage(widget.matchId, text);
      _onLiveMessage(m);
    } catch (e) {
      if (mounted) {
        _messageController.text = text;
        showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatMessagesProvider(widget.matchId));
    final me = ref.watch(currentUserProvider);
    final summary = widget.summary ??
        (ref.watch(chatThreadsProvider).value ?? const [])
            .where((t) => t.matchId == widget.matchId)
            .firstOrNull;

    // Keep the list fresh in the background so the threads tab's preview
    // updates when we come back.
    ref.listen(chatMessagesProvider(widget.matchId), (_, next) {
      if (next.hasValue) {
        for (final m in next.value!) {
          _seenIds.add(m.id);
        }
        _scrollToBottom();
      }
    });

    final closed = summary != null && summary.matchStatus != MatchStatus.accepted;

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.lightPink,
              child: Text(
                summary?.bloodTypeNeeded.label ?? '?',
                style: const TextStyle(
                    color: AppColors.primaryRed, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary?.counterpartyName ?? 'Coordination chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _connected ? AppColors.successGreen : AppColors.hintGrey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          [
                            _connected ? 'Live' : 'Reconnecting…',
                            if (summary != null) summary.counterpartyRole?.label ?? '',
                            summary?.hospitalName ?? '',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (closed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.borderGrey,
              child: Text(
                'This commitment is ${summary.matchStatus.label.toLowerCase()}. The conversation is read-only.',
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ),
          Expanded(
            child: AsyncView<List<ChatMessage>>(
              value: history,
              onRetry: () async => ref.invalidate(chatMessagesProvider(widget.matchId)),
              builder: (loaded) {
                final all = [...loaded, ..._live.where((m) => !loaded.any((l) => l.id == m.id))]
                  ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Start the conversation',
                    subtitle: 'Agree on a time and place. Keep coordination inside the app.',
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final m = all[i];
                    final isMe = me != null && m.senderId == me.id;
                    return _Bubble(message: m, isMe: isMe);
                  },
                );
              },
            ),
          ),
          if (!closed) _composer(),
        ],
      ),
    );
  }

  Widget _composer() => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: appInputDecoration(hint: 'Type a message…').copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _send,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) => Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryRed : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: isMe ? null : Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textDark,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatTime(message.sentAt),
                style: TextStyle(
                  color: isMe ? Colors.white.withValues(alpha: 0.75) : AppColors.textGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
}
