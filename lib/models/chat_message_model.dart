class ChatMessageModel {
  String? messageId;

  final String senderId;
  final String receiverId;

  String text;

  final bool isMine;

  DateTime timestamp;

  bool isEdited;
  bool isDeleted;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.isMine,
    required this.timestamp,
    this.isEdited = false,
    this.isDeleted = false,
  });
}