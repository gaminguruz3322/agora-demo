import 'package:agora_chat_sdk/agora_chat_sdk.dart';

import 'package:flutter/foundation.dart';



class AgoraChatService {

  static const String appKey =

      '61200076456#200107303';



  final ChatClient client = ChatClient.getInstance;



  static const String connectionHandlerId =

      'oneglobe_connection_handler';



  static const String messageHandlerId =

      'oneglobe_message_handler';



  static const String messageEventHandlerId =

      'oneglobe_message_event_handler';



  static const String presenceHandlerId =

      'oneglobe_presence_handler';



  static bool _initialized = false;

  static bool _callbacksStarted = false;



  // ============================================================

  // INITIALIZE

  // ============================================================



  Future<void> initialize() async {

    if (!_initialized) {

      final ChatOptions options =

          ChatOptions.withAppKey(

        appKey,

        autoLogin: false,

      );



      await client.init(options);



      _initialized = true;



      debugPrint(

        'AGORA CHAT: INITIALIZED',

      );

    }



    if (!_callbacksStarted) {

      await client.startCallback();



      _callbacksStarted = true;



      debugPrint(

        'AGORA CHAT: CALLBACK STARTED',

      );

    }

  }



  // ============================================================

  // LOGIN

  // ============================================================



  Future<void> login({

    required String userId,

    required String token,

  }) async {

    await initialize();



    try {

      if (client.currentUserId != null &&

          client.currentUserId!.isNotEmpty) {

        if (client.currentUserId == userId) {

          debugPrint(

            'AGORA CHAT: ALREADY LOGGED IN AS $userId',

          );



          return;

        }



        await client.logout(true);

      }

    } catch (e) {

      debugPrint(

        'AGORA PREVIOUS LOGOUT WARNING: $e',

      );

    }



    await client.loginWithToken(

      userId,

      token,

    );



    debugPrint(

      'AGORA CHAT LOGIN SUCCESS: $userId',

    );

  }



  // ============================================================

  // LOGOUT

  // ============================================================



  Future<void> logout() async {

    try {

      await client.logout(true);



      debugPrint(

        'AGORA CHAT LOGOUT SUCCESS',

      );

    } catch (e) {

      debugPrint(

        'AGORA CHAT LOGOUT ERROR: $e',

      );

    }

  }



  // ============================================================

  // HISTORY

  // ============================================================



  Future<ChatCursorResult<ChatMessage>> fetchHistory({

    required String conversationId,

  }) async {

    final FetchMessageOptions options =

        FetchMessageOptions(

      direction: ChatSearchDirection.Up,

      needSave: true,

    );



    return await client.chatManager

        .fetchHistoryMessagesByOption(

      conversationId,

      ChatConversationType.Chat,

      options: options,

      pageSize: 50,

    );

  }



  // ============================================================

  // SEND

  // ============================================================



  Future<ChatMessage> sendMessage({

    required String receiverId,

    required String text,

  }) async {

    final ChatMessage message =

        ChatMessage.createTxtSendMessage(

      targetId: receiverId,

      content: text,

    );



    return await client.chatManager.sendMessage(

      message,

    );

  }



  // ============================================================
  // EDIT
  // ============================================================

  Future<ChatMessage> sendEditEvent({
    required String receiverId,
    required String messageId,
    required String text,
  }) async {
    final String editEvent =
        '__ONEGLOBE_EDIT__:$messageId:$text';

    final ChatMessage message =
        ChatMessage.createTxtSendMessage(
      targetId: receiverId,
      content: editEvent,
    );

    return await client.chatManager.sendMessage(
      message,
    );
  }

  // ============================================================
  // DELETE EVENT
  // ============================================================

  Future<ChatMessage> sendDeleteEvent({
    required String receiverId,
    required String messageId,
  }) async {
    final String deleteEvent =
        '__ONEGLOBE_DELETE__:$messageId';

    final ChatMessage message =
        ChatMessage.createTxtSendMessage(
      targetId: receiverId,
      content: deleteEvent,
    );

    return await client.chatManager.sendMessage(
      message,
    );
  }

  Future<ChatMessage> deleteMessage({
    required String messageId,
    required String receiverId,
  }) async {
    return await sendDeleteEvent(
      receiverId: receiverId,
      messageId: messageId,
    );
  }

// ============================================================
// CLEAR CHAT - CURRENT USER SIDE ONLY
// ============================================================

  Future<void> clearChat({
    required String conversationId,
  }) async {
    try {
      await client.chatManager.deleteRemoteConversation(
        conversationId,
        conversationType: ChatConversationType.Chat,
        isDeleteMessage: true,
      );

      debugPrint(
        'CHAT CLEAR SUCCESS: conversation=$conversationId',
      );
    } catch (e) {
      debugPrint(
        'CHAT CLEAR ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // CONNECTION HANDLER

  // ============================================================



  void addConnectionHandler({

    required void Function() onConnected,

    required void Function() onDisconnected,

  }) {

    client.addConnectionEventHandler(

      connectionHandlerId,

      ConnectionEventHandler(

        onConnected: onConnected,

        onDisconnected: onDisconnected,

      ),

    );

  }



  // ============================================================

  // MESSAGE HANDLER

  // ============================================================



  void addMessageHandler({

    required void Function(

      List<ChatMessage>,

    ) onMessagesReceived,

    required void Function(

      List<ChatMessage>,

    ) onMessagesRecalled,

    required void Function(

      ChatMessage,

      String,

      int,

    ) onMessageContentChanged,

  }) {

    client.chatManager.addEventHandler(

      messageHandlerId,

      ChatEventHandler(

        onMessagesReceived:

            onMessagesReceived,

        onMessagesRecalled:

            onMessagesRecalled,

        onMessageContentChanged:

            onMessageContentChanged,

      ),

    );

  }



  // ============================================================

  // MESSAGE STATUS

  // ============================================================



  void addMessageStatusHandler({

    required void Function(

      String msgId,

      ChatMessage message,

    ) onSuccess,

    required void Function(

      String msgId,

      ChatMessage message,

      ChatError error,

    ) onError,

  }) {

    client.chatManager.addMessageEvent(

      messageEventHandlerId,

      ChatMessageEvent(

        onSuccess: onSuccess,

        onError: onError,

      ),

    );

  }



  // ============================================================

  // PRESENCE HANDLER

  // ============================================================



  void addPresenceHandler({

    required void Function(

      List<ChatPresence> presences,

    ) onPresenceChanged,

  }) {

    try {

      client.presenceManager.addEventHandler(

        presenceHandlerId,

        ChatPresenceEventHandler(

          onPresenceStatusChanged:

              onPresenceChanged,

        ),

      );



      debugPrint(

        'AGORA PRESENCE HANDLER REGISTERED',

      );

    } catch (e) {

      debugPrint(

        'AGORA PRESENCE HANDLER ERROR: $e',

      );

    }

  }



  // ============================================================

  // SUBSCRIBE PRESENCE

  // ============================================================



  Future<List<ChatPresence>> subscribeToPresence({

    required String userId,

  }) async {

    try {

      debugPrint(

        'PRESENCE SUBSCRIBE START: $userId',

      );



      final List<ChatPresence> result =

          await client.presenceManager.subscribe(

        members: [userId],

        expiry: 86400,

      );



      debugPrint(

        'PRESENCE SUBSCRIBE RESULT: '

        '${result.length}',

      );



      for (final ChatPresence presence

          in result) {

        debugPrint(

          'PRESENCE SUBSCRIBE DATA: '

          'publisher=${presence.publisher}, '

          'status=${presence.statusDetails}, '

          'lastTime=${presence.lastTime}',

        );

      }



      return result;

    } on ChatError catch (e) {

      debugPrint(

        'PRESENCE SUBSCRIBE ERROR: '

        '${e.code} ${e.description}',

      );



      return [];

    } catch (e) {

      debugPrint(

        'PRESENCE SUBSCRIBE ERROR: $e',

      );



      return [];

    }

  }



  // ============================================================

  // FETCH PRESENCE

  // ============================================================



  Future<List<ChatPresence>> fetchPresence({

    required String userId,

  }) async {

    try {

      debugPrint(

        'PRESENCE FETCH START: $userId',

      );



      final List<ChatPresence> result =

          await client.presenceManager

              .fetchPresenceStatus(

        members: [userId],

      );



      debugPrint(

        'PRESENCE FETCH RESULT: '

        '${result.length}',

      );



      for (final ChatPresence presence

          in result) {

        debugPrint(

          'PRESENCE FETCH DATA: '

          'publisher=${presence.publisher}, '

          'status=${presence.statusDetails}, '

          'lastTime=${presence.lastTime}',

        );

      }



      return result;

    } on ChatError catch (e) {

      debugPrint(

        'PRESENCE FETCH ERROR: '

        '${e.code} ${e.description}',

      );



      return [];

    } catch (e) {

      debugPrint(

        'PRESENCE FETCH ERROR: $e',

      );



      return [];

    }

  }



  // ============================================================

  // REMOVE PRESENCE HANDLER

  // ============================================================



  void removePresenceHandler() {

    try {

      client.presenceManager.removeEventHandler(

        presenceHandlerId,

      );

    } catch (e) {

      debugPrint(

        'PRESENCE REMOVE ERROR: $e',

      );

    }

  }



  // ============================================================

  // REMOVE ALL HANDLERS

  // ============================================================



  void removeHandlers() {

    try {

      client.removeConnectionEventHandler(

        connectionHandlerId,

      );

    } catch (_) {}



    try {

      client.chatManager.removeEventHandler(

        messageHandlerId,

      );

    } catch (_) {}



    try {

      client.chatManager.removeMessageEvent(

        messageEventHandlerId,

      );

    } catch (_) {}



    try {

      client.presenceManager.removeEventHandler(

        presenceHandlerId,

      );

    } catch (_) {}

  }

}