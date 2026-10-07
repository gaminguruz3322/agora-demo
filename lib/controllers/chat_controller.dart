import 'package:agora_chat_sdk/agora_chat_sdk.dart';

import 'package:flutter/foundation.dart';



import '../models/chat_message_model.dart';

import '../services/agora_chat_service.dart';



class ChatController extends ChangeNotifier {

  final String userId;



  final String receiverId;



  final String chatToken;



  final AgoraChatService _chatService =

      AgoraChatService();



  final List<ChatMessageModel> _messages = [];



  List<ChatMessageModel> get messages =>

      List.unmodifiable(_messages);



  bool _isLoading = false;



  bool get isLoading => _isLoading;



  bool _isSending = false;



  bool get isSending => _isSending;



  bool _isLoggedIn = false;



  bool get isLoggedIn => _isLoggedIn;



  String? _errorMessage;



  String? get errorMessage => _errorMessage;



  ChatMessageModel? _pendingMessage;

  // Custom edit/delete events received before or during history loading.
  final Set<String> _deletedMessageIds = <String>{};
  final Map<String, String> _editedMessageTexts = <String, String>{};



  ChatController({

    required this.userId,

    required this.receiverId,

    required this.chatToken,

  });



  Future<void> initialize() async {

    try {

      _isLoading = true;

      _errorMessage = null;



      notifyListeners();



      await _chatService.initialize();



      _registerHandlers();



      await _chatService.login(

        userId: userId,

        token: chatToken,

      );



      _isLoggedIn = true;



      await loadHistory();

    } catch (e) {

      _errorMessage = e.toString();



      debugPrint(

        'CHAT INITIALIZATION ERROR: $e',

      );

    } finally {

      _isLoading = false;



      notifyListeners();

    }

  }



  void _registerHandlers() {

    _chatService.addConnectionHandler(

      onConnected: () {

        debugPrint(

          'AGORA CHAT CONNECTED',

        );

      },

      onDisconnected: () {

        debugPrint(

          'AGORA CHAT DISCONNECTED',

        );

      },

    );



    _chatService.addMessageHandler(

      onMessagesReceived:

          _onMessagesReceived,

      onMessagesRecalled:

          _onMessagesRecalled,

      onMessageContentChanged:

          _onMessageContentChanged,

    );



    _chatService.addMessageStatusHandler(

      onSuccess: _onMessageSendSuccess,

      onError: _onMessageSendError,

    );

  }



  void _onMessageRecalled(

    List<ChatMessage> messages,

  ) {

    debugPrint(

      'CHAT MESSAGE RECALLED: '

      'count=${messages.length}',

    );



    for (final ChatMessage message in messages) {

      final String messageId = message.msgId;



      debugPrint(

        'CHAT DELETE CALLBACK: '

        'id=$messageId',

      );



      final ChatMessageModel? existing =

          _findMessage(messageId);



      if (existing != null) {

        existing.isDeleted = true;

        existing.text = 'This message was deleted';

      }

    }



    notifyListeners();

  }



  Future<void> loadHistory() async {

    try {

      final ChatCursorResult<ChatMessage> result =

          await _chatService.fetchHistory(

        conversationId: receiverId,

      );



      _messages.clear();



      for (final ChatMessage message

          in result.data) {

        _addHistoryMessage(message);

      }



      _sortMessages();



      notifyListeners();

    } catch (e) {

      debugPrint(

        'CHAT HISTORY ERROR: $e',

      );

    }

  }



  void _addHistoryMessage(
    ChatMessage message,
  ) {
    if (message.body.type != MessageType.TXT) {
      return;
    }

    final ChatTextMessageBody body =
        message.body as ChatTextMessageBody;

    final String senderId =
        message.from ?? '';

    if (senderId != userId &&
        senderId != receiverId) {
      return;
    }

    final String content = body.content;

    // Never display internal delete/edit events as chat messages.
    if (content.startsWith('__ONEGLOBE_DELETE__:')) {
      final String deletedMessageId =
          content.substring('__ONEGLOBE_DELETE__:'.length);

      _deletedMessageIds.add(deletedMessageId);
      return;
    }

    if (content.startsWith('__ONEGLOBE_EDIT__:')) {
      final String payload =
          content.substring('__ONEGLOBE_EDIT__:'.length);

      final int separatorIndex = payload.indexOf(':');

      if (separatorIndex > 0) {
        final String editedMessageId =
            payload.substring(0, separatorIndex);
        final String editedText =
            payload.substring(separatorIndex + 1);

        _editedMessageTexts[editedMessageId] = editedText;
      }

      return;
    }

    final String messageId = message.msgId;

    final DateTime timestamp =
        DateTime.fromMillisecondsSinceEpoch(
      message.serverTime > 0
          ? message.serverTime
          : DateTime.now().millisecondsSinceEpoch,
    );

    final bool isMine = senderId == userId;

    final bool isDeleted =
        _deletedMessageIds.contains(messageId);

    final String displayText =
        isDeleted
            ? 'This message was deleted'
            : (_editedMessageTexts[messageId] ?? content);

    final ChatMessageModel model =
        ChatMessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: isMine ? receiverId : userId,
      text: displayText,
      isMine: isMine,
      timestamp: timestamp,
      isEdited:
          !isDeleted &&
          (_editedMessageTexts.containsKey(messageId) ||
              (body.modifyCount ?? 0) > 0),
      isDeleted: isDeleted,
    );

    _upsertMessage(model);
  }

  void _onMessagesReceived(
    List<ChatMessage> messages,
  ) {
    bool changed = false;

    for (final ChatMessage message in messages) {
      if (message.body.type != MessageType.TXT) {
        continue;
      }

      final String senderId = message.from ?? '';

      if (senderId != receiverId && senderId != userId) {
        continue;
      }

      final ChatTextMessageBody body =
          message.body as ChatTextMessageBody;

      final String content = body.content;

      // Internal delete event. Never show it in chat UI.
      if (content.startsWith('__ONEGLOBE_DELETE__:')) {
        final String deletedMessageId =
            content.substring('__ONEGLOBE_DELETE__:'.length);

        _deletedMessageIds.add(deletedMessageId);

        final ChatMessageModel? existing =
            _findMessage(deletedMessageId);

        if (existing != null) {
          existing.text = 'This message was deleted';
          existing.isDeleted = true;
          existing.isEdited = false;
          changed = true;
        }

        continue;
      }

      // Internal edit event. Never show it in chat UI.
      if (content.startsWith('__ONEGLOBE_EDIT__:')) {
        final String payload =
            content.substring('__ONEGLOBE_EDIT__:'.length);

        final int separatorIndex = payload.indexOf(':');

        if (separatorIndex <= 0) {
          continue;
        }

        final String editedMessageId =
            payload.substring(0, separatorIndex);
        final String editedText =
            payload.substring(separatorIndex + 1);

        _editedMessageTexts[editedMessageId] = editedText;

        final ChatMessageModel? existing =
            _findMessage(editedMessageId);

        if (existing != null && !existing.isDeleted) {
          existing.text = editedText;
          existing.isEdited = true;
          changed = true;
        }

        continue;
      }

      // Ignore our own outgoing message here.
      if (senderId == userId) {
        continue;
      }

      final String messageId = message.msgId;
      final bool isDeleted =
          _deletedMessageIds.contains(messageId);

      final String displayText =
          isDeleted
              ? 'This message was deleted'
              : (_editedMessageTexts[messageId] ?? content);

      final ChatMessageModel model =
          ChatMessageModel(
        messageId: messageId,
        senderId: senderId,
        receiverId: userId,
        text: displayText,
        isMine: false,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(
          message.serverTime > 0
              ? message.serverTime
              : DateTime.now().millisecondsSinceEpoch,
        ),
        isEdited:
            !isDeleted &&
            (_editedMessageTexts.containsKey(messageId) ||
                (body.modifyCount ?? 0) > 0),
        isDeleted: isDeleted,
      );

      _upsertMessage(model);
      changed = true;
    }

    if (changed) {
      _sortMessages();
      notifyListeners();
    }
  }

  void _onMessageSendSuccess(

    String msgId,

    ChatMessage message,

  ) {
    // Internal edit/delete events must never become visible chat messages.
    if (message.body.type == MessageType.TXT) {
      final ChatTextMessageBody body =
          message.body as ChatTextMessageBody;

      if (body.content.startsWith('__ONEGLOBE_EDIT__:') ||
          body.content.startsWith('__ONEGLOBE_DELETE__:')) {
        debugPrint(
          'CHAT INTERNAL EVENT SENT: ignored in UI',
        );
        return;
      }
    }


    debugPrint(

      'CHAT SEND SUCCESS: '

      'msgId=$msgId',

    );



    /*

    * Agora gives us the final server-generated

    * message ID here.

    */

    if (_pendingMessage != null) {

      _pendingMessage!.messageId =

          msgId;



      debugPrint(

        'CHAT MESSAGE ID ASSIGNED: '

        '$msgId',

      );



      _pendingMessage = null;



      notifyListeners();



      return;

    }



    /*

    * Fallback if there is no pending message.

    */

    if (message.body.type ==

        MessageType.TXT) {

      final ChatTextMessageBody body =

          message.body

              as ChatTextMessageBody;



      final ChatMessageModel model =

          ChatMessageModel(

        messageId: msgId,

        senderId: userId,

        receiverId: receiverId,

        text: body.content,

        isMine: true,

        timestamp: DateTime.now(),

        isEdited: false,

        isDeleted: false,

      );



      _upsertMessage(model);



      _sortMessages();



      notifyListeners();

    }

  }

  void _onMessageSendError(

    String msgId,

    ChatMessage message,

    ChatError error,

  ) {

    debugPrint(

      'CHAT SEND ERROR: '

      '${error.code} '

      '${error.description}',

    );



    if (_pendingMessage != null) {

      _messages.remove(

        _pendingMessage,

      );

    }



    _pendingMessage = null;



    _isSending = false;



    _errorMessage =

        error.description;



    notifyListeners();

  }



  Future<void> sendMessage(

    String text,

  ) async {

    final String cleanText =

        text.trim();



    if (cleanText.isEmpty) {

      return;

    }



    if (!_isLoggedIn) {

      _errorMessage =

          'Chat is not connected';



      notifyListeners();



      return;

    }



    if (_isSending) {

      debugPrint(

        'CHAT SEND BLOCKED: already sending',

      );



      return;

    }



    try {

      _isSending = true;



      _errorMessage = null;



      notifyListeners();



      final ChatMessageModel localMessage =

          ChatMessageModel(

        messageId: null,

        senderId: userId,

        receiverId: receiverId,

        text: cleanText,

        isMine: true,

        timestamp: DateTime.now(),

        isEdited: false,

        isDeleted: false,

      );



      _messages.add(

        localMessage,

      );



      /*

      * Keep this reference so ChatMessageEvent

      * can assign the final Agora server message ID.

      */

      _pendingMessage =

          localMessage;



      _sortMessages();



      notifyListeners();



      debugPrint(

        'CHAT SEND START: '

        '$userId -> $receiverId '

        'text="$cleanText"',

      );



      /*

      * IMPORTANT:

      *

      * sendMessage() itself is awaited here.

      * We no longer depend on onSuccess to reset

      * _isSending.

      */

      await _chatService.sendMessage(

        receiverId: receiverId,

        text: cleanText,

      );



      debugPrint(

        'CHAT SEND REQUEST COMPLETED',

      );



      /*

      * The message request has completed.

      *

      * ChatMessageEvent.onSuccess will still assign

      * the final server-generated message ID.

      */

      _isSending = false;



      /*

      * Do not clear _pendingMessage here.

      *

      * onSuccess may still need it to attach msgId.

      */



      notifyListeners();

    } on ChatError catch (e) {

      debugPrint(

        'CHAT SEND ERROR: '

        'code=${e.code}, '

        'description=${e.description}',

      );



      if (_pendingMessage != null) {

        _messages.remove(

          _pendingMessage,

        );

      }



      _pendingMessage = null;



      _isSending = false;



      _errorMessage =

          '${e.code}: ${e.description}';



      notifyListeners();

    } catch (e) {

      debugPrint(

        'CHAT SEND EXCEPTION: $e',

      );



      if (_pendingMessage != null) {

        _messages.remove(

          _pendingMessage,

        );

      }



      _pendingMessage = null;



      _isSending = false;



      _errorMessage =

          e.toString();



      notifyListeners();

    }

  }

  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    final String cleanText = newText.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final ChatMessageModel? message =
        _findMessage(messageId);

    if (message == null) {
      debugPrint(
        'CHAT EDIT ERROR: message not found: $messageId',
      );
      return;
    }

    // A deleted message can never be edited.
    if (message.isDeleted) {
      debugPrint(
        'CHAT EDIT BLOCKED: message already deleted',
      );
      return;
    }

    if (!message.isMine) {
      debugPrint(
        'CHAT EDIT BLOCKED: not your message',
      );
      return;
    }

    try {
      debugPrint(
        'CHAT EDIT START: id=$messageId text="$cleanText"',
      );

      await _chatService.sendEditEvent(
        receiverId: receiverId,
        messageId: messageId,
        text: cleanText,
      );

      message.text = cleanText;
      message.isEdited = true;

      _editedMessageTexts[messageId] = cleanText;

      debugPrint(
        'CHAT EDIT SUCCESS: id=$messageId text="${message.text}"',
      );

      notifyListeners();
    } on ChatError catch (e) {
      debugPrint(
        'CHAT EDIT ERROR: code=${e.code}, description=${e.description}',
      );

      _errorMessage = '${e.code}: ${e.description}';
      notifyListeners();
    } catch (e) {
      debugPrint('CHAT EDIT EXCEPTION: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(
    String messageId,
  ) async {
    final ChatMessageModel? message =
        _findMessage(messageId);

    if (message == null) {
      debugPrint(
        'CHAT DELETE ERROR: message not found: $messageId',
      );
      return;
    }

    // A deleted message can never be deleted again.
    if (message.isDeleted) {
      debugPrint(
        'CHAT DELETE BLOCKED: message already deleted',
      );
      return;
    }

    if (!message.isMine) {
      debugPrint(
        'CHAT DELETE BLOCKED: not your message',
      );
      return;
    }

    try {
      debugPrint(
        'CHAT DELETE START: id=$messageId',
      );

      await _chatService.deleteMessage(
        receiverId: receiverId,
        messageId: messageId,
      );

      _deletedMessageIds.add(messageId);
      _editedMessageTexts.remove(messageId);

      message.isDeleted = true;
      message.isEdited = false;
      message.text = 'This message was deleted';

      debugPrint(
        'CHAT DELETE SUCCESS: id=$messageId',
      );

      notifyListeners();
    } on ChatError catch (e) {
      debugPrint(
        'CHAT DELETE ERROR: code=${e.code}, description=${e.description}',
      );

      _errorMessage = '${e.code}: ${e.description}';
      notifyListeners();
    } catch (e) {
      debugPrint('CHAT DELETE EXCEPTION: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR CHAT
  // CURRENT USER SIDE ONLY
  // ============================================================

  Future<void> clearChat() async {
    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'CHAT CLEAR START',
      );

      debugPrint(
        'CURRENT USER: $userId',
      );

      debugPrint(
        'CONVERSATION: $receiverId',
      );

      debugPrint(
        '========================================',
      );

      await _chatService.clearChat(
        conversationId: receiverId,
      );

      // Clear only this controller's current UI messages.
      _messages.clear();

      // Clear local edit/delete tracking for this conversation.
      _deletedMessageIds.clear();
      _editedMessageTexts.clear();

      // Clear pending message reference if any.
      _pendingMessage = null;

      debugPrint(
        'CHAT CLEAR SUCCESS: only current user side cleared',
      );

      notifyListeners();
    } on ChatError catch (e) {
      debugPrint(
        'CHAT CLEAR ERROR: '
        'code=${e.code}, '
        'description=${e.description}',
      );

      _errorMessage =
          '${e.code}: ${e.description}';

      notifyListeners();
    } catch (e) {
      debugPrint(
        'CHAT CLEAR EXCEPTION: $e',
      );

      _errorMessage = e.toString();

      notifyListeners();
    }
  }

  void _onMessageContentChanged(

  ChatMessage message,

  String operatorId,

  int operationTime,

) {

  debugPrint(

    'CHAT MESSAGE MODIFIED: '

    'msgId=${message.msgId}, '

    'operator=$operatorId',

  );



  if (message.body.type != MessageType.TXT) {

    return;

  }



  final ChatTextMessageBody body =

      message.body as ChatTextMessageBody;



  final String messageId = message.msgId;



  final ChatMessageModel? existing =

      _findMessage(messageId);



  if (existing != null) {

    existing.text = body.content;

    existing.isEdited = true;



    debugPrint(

      'CHAT UI EDIT UPDATED: '

      'id=$messageId '

      'text="${body.content}"',

    );



    notifyListeners();

    return;

  }



  final String senderId =

      message.from ?? '';



  if (senderId != userId &&

      senderId != receiverId) {

    return;

  }



  final ChatMessageModel newMessage =

      ChatMessageModel(

    messageId: messageId,

    senderId: senderId,

    receiverId:

        senderId == userId

            ? receiverId

            : userId,

    text: body.content,

    isMine: senderId == userId,

    timestamp:

        DateTime.fromMillisecondsSinceEpoch(

      message.serverTime > 0

          ? message.serverTime

          : operationTime,

    ),

    isEdited: true,

    isDeleted: false,

  );



  _upsertMessage(newMessage);



  _sortMessages();



  notifyListeners();

}

  void _onMessagesRecalled(

    List<ChatMessage> messages,

  ) {

    bool changed = false;



    for (final ChatMessage message

        in messages) {

      final String messageId =

          message.msgId;



      final int before =

          _messages.length;



      _messages.removeWhere(

        (item) =>

            item.messageId ==

            messageId,

      );



      if (_messages.length != before) {

        changed = true;

      }

    }



    if (changed) {

      notifyListeners();

    }

  }



  ChatMessageModel? _findMessage(

    String messageId,

  ) {

    for (final ChatMessageModel message

        in _messages) {

      if (message.messageId ==

          messageId) {

        return message;

      }

    }



    return null;

  }



  void _upsertMessage(

    ChatMessageModel model,

  ) {

    if (model.messageId == null ||

        model.messageId!.isEmpty) {

      _messages.add(model);



      return;

    }



    final int existingIndex =

        _messages.indexWhere(

      (item) =>

          item.messageId ==

          model.messageId,

    );



    if (existingIndex == -1) {

      _messages.add(model);

    } else {

      _messages[existingIndex] =

          model;

    }

  }



  void _sortMessages() {

    _messages.sort(

      (a, b) => a.timestamp.compareTo(

        b.timestamp,

      ),

    );

  }



  Future<void> refreshHistory() async {

    await loadHistory();

  }



  Future<void> disposeChat() async {

    try {

      _chatService.removeHandlers();



      if (_isLoggedIn) {

        await _chatService.logout();

      }

    } catch (e) {

      debugPrint(

        'CHAT DISPOSE ERROR: $e',

      );

    }



    _isLoggedIn = false;

  }



  @override

  void dispose() {

    _chatService.removeHandlers();



    super.dispose();

  }

}