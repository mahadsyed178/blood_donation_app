import 'enums.dart';
import 'json_helpers.dart';

/// `chat.dtos.ChatThreadSummaryOut`. Every other chat call keys off
/// [matchId], not [id].
class ChatThreadSummary {
  final String id;
  final String matchId;
  final String bloodRequestId;
  final String? counterpartyName;
  final SenderType? counterpartyRole;
  final BloodType bloodTypeNeeded;
  final UrgencyLevel urgencyLevel;
  final String? hospitalName;
  final String? areaLabel;
  final MatchStatus matchStatus;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  const ChatThreadSummary({
    required this.id,
    required this.matchId,
    required this.bloodRequestId,
    this.counterpartyName,
    this.counterpartyRole,
    required this.bloodTypeNeeded,
    required this.urgencyLevel,
    this.hospitalName,
    this.areaLabel,
    required this.matchStatus,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  factory ChatThreadSummary.fromJson(Map<String, dynamic> json) =>
      ChatThreadSummary(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        bloodRequestId: json['blood_request_id'] as String,
        counterpartyName: json['counterparty_name'] as String?,
        counterpartyRole: json['counterparty_role'] == null
            ? null
            : SenderType.parse(json['counterparty_role'] as String),
        bloodTypeNeeded: BloodType.parse(json['blood_type_needed'] as String),
        urgencyLevel: UrgencyLevel.parse(json['urgency_level'] as String),
        hospitalName: json['hospital_name'] as String?,
        areaLabel: json['area_label'] as String?,
        matchStatus: MatchStatus.parse(json['match_status'] as String),
        createdAt: parseDateTime(json['created_at']),
        lastMessageAt: parseDateTimeOrNull(json['last_message_at']),
        lastMessagePreview: json['last_message_preview'] as String?,
      );
}

/// `chat.dtos.ChatMessageOut`
class ChatMessage {
  final String id;
  final String chatThreadId;
  final SenderType senderType;
  final String senderId;
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.chatThreadId,
    required this.senderType,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        chatThreadId: json['chat_thread_id'] as String,
        senderType: SenderType.parse(json['sender_type'] as String),
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        sentAt: parseDateTime(json['sent_at']),
      );
}
