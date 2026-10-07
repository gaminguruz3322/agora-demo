import 'package:flutter/material.dart';



import '../controllers/chat_controller.dart';

import '../helpers/chat_helper.dart';

import '../models/chat_message_model.dart';



class ChatScreen extends StatefulWidget {

  final String userId;



  final String chatToken;



  final String receiverId;



  const ChatScreen({

    super.key,

    required this.userId,

    required this.chatToken,

    required this.receiverId,

  });



  @override

  State<ChatScreen> createState() =>

      _ChatScreenState();

}



class _ChatScreenState

    extends State<ChatScreen> {

  late final ChatController

      _controller;



  final TextEditingController

      _textController =

      TextEditingController();



  final ScrollController

      _scrollController =

      ScrollController();



  ChatMessageModel? _editingMessage;



  @override

  void initState() {

    super.initState();



    _controller = ChatController(

      userId: widget.userId,

      receiverId: widget.receiverId,

      chatToken: widget.chatToken,

    );



    _controller.addListener(

      _onControllerChanged,

    );



    _controller.initialize();

  }



  void _onControllerChanged() {

    if (!mounted) {

      return;

    }



    setState(() {});



    WidgetsBinding.instance

        .addPostFrameCallback(

      (_) => _scrollToBottom(),

    );

  }



  String _receiverStatusText() {
    if (!_controller.isLoggedIn) {
      return 'Connecting...';
    }

    return 'Connected';
  }

  void _scrollToBottom() {

    if (!_scrollController

        .hasClients) {

      return;

    }



    _scrollController.animateTo(

      _scrollController

          .position

          .maxScrollExtent,

      duration:

          const Duration(

        milliseconds: 250,

      ),

      curve: Curves.easeOut,

    );

  }



  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor:

          const Color(0xFF090B10),

      appBar: AppBar(

        backgroundColor:

            const Color(0xFF10131A),

        foregroundColor:

            Colors.white,

        elevation: 0,

        title: Row(

          children: [

            Container(

              width: 42,

              height: 42,

              decoration:

                  BoxDecoration(

                shape: BoxShape.circle,

                color: Colors.blue

                    .withValues(

                  alpha: 0.15,

                ),

              ),

              child: const Icon(

                Icons.person,

                color: Colors.blue,

              ),

            ),

            const SizedBox(

              width: 12,

            ),

            Column(

              crossAxisAlignment:

                  CrossAxisAlignment.start,

              children: [

                Text(

                  widget.receiverId,

                  style:

                      const TextStyle(

                    color: Colors.white,

                    fontSize: 16,

                    fontWeight:

                        FontWeight.w600,

                  ),

                ),

                        Text(
                  _receiverStatusText(),
                  style: TextStyle(
                    color: _controller.isLoggedIn
                        ? Colors.green
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),

              ],

            ),

          ],

        ),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_chat') {
                _showClearChatConfirmation();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                      ),
                      SizedBox(width: 10),
                      Text('Clear Chat'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],

      ),

      body: Column(

        children: [

          Expanded(

            child: _buildMessageArea(),

          ),

          _buildInputArea(),

        ],

      ),

    );

  }



  Widget _buildMessageArea() {

    if (_controller.isLoading &&

        _controller.messages.isEmpty) {

      return const Center(

        child: CircularProgressIndicator(),

      );

    }



    if (_controller.messages.isEmpty) {

      return const Center(

        child: Text(

          'No messages yet',

          style: TextStyle(

            color: Colors.white54,

            fontSize: 15,

          ),

        ),

      );

    }



    return ListView.builder(

      controller: _scrollController,

      padding: const EdgeInsets.fromLTRB(

        16,

        20,

        16,

        20,

      ),

      itemCount:

          _controller.messages.length,

      itemBuilder:

          (context, index) {

        final ChatMessageModel

            message =

            _controller.messages[

                index];



        return _buildMessageBubble(

          message,

        );

      },

    );

  }



  Widget _buildMessageBubble(

    ChatMessageModel message,

  ) {

    final bool isMine =

        message.isMine;



    return Align(

      alignment: isMine

          ? Alignment.centerRight

          : Alignment.centerLeft,

      child: GestureDetector(

        onLongPress: isMine

            ? () =>

                _showMessageMenu(

                  message,

                )

            : null,

        child: Container(

          constraints:

              BoxConstraints(

            maxWidth:

                MediaQuery.of(context)

                        .size

                        .width *

                    0.78,

          ),

          margin:

              const EdgeInsets.only(

            bottom: 10,

          ),

          padding:

              const EdgeInsets.symmetric(

            horizontal: 14,

            vertical: 10,

          ),

          decoration:

              BoxDecoration(

            color: isMine

                ? const Color(

                    0xFF2563EB,

                  )

                : const Color(

                    0xFF1B2029,

                  ),

            borderRadius:

                BorderRadius.only(

              topLeft:

                  const Radius.circular(

                16,

              ),

              topRight:

                  const Radius.circular(

                16,

              ),

              bottomLeft:

                  Radius.circular(

                isMine ? 16 : 4,

              ),

              bottomRight:

                  Radius.circular(

                isMine ? 4 : 16,

              ),

            ),

          ),

          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment.end,

            children: [

              Align(

                alignment:

                    Alignment.centerLeft,

                child: Text(

                  message.text,

                  style:

                      const TextStyle(

                    color: Colors.white,

                    fontSize: 15,

                    height: 1.35,

                  ),

                ),

              ),

              const SizedBox(

                height: 5,

              ),

              Row(

                mainAxisSize:

                    MainAxisSize.min,

                children: [

                  if (message.isEdited)

                    const Padding(

                      padding:

                          EdgeInsets.only(

                        right: 5,

                      ),

                      child: Text(

                        'edited',

                        style:

                            TextStyle(

                          color:

                              Colors.white60,

                          fontSize: 10,

                        ),

                      ),

                    ),

                  Text(

                    ChatHelper.formatTime(

                      message.timestamp,

                    ),

                    style:

                        const TextStyle(

                      color:

                          Colors.white60,

                      fontSize: 10,

                    ),

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildInputArea() {

    final bool editing =

        _editingMessage != null;



    return SafeArea(

      top: false,

      child: Container(

        padding:

            const EdgeInsets.fromLTRB(

          12,

          10,

          12,

          12,

        ),

        decoration:

            const BoxDecoration(

          color: Color(0xFF10131A),

          border: Border(

            top: BorderSide(

              color: Color(0xFF20252E),

            ),

          ),

        ),

        child: Column(

          mainAxisSize:

              MainAxisSize.min,

          children: [

            if (editing)

              Container(

                width: double.infinity,

                margin:

                    const EdgeInsets.only(

                  bottom: 8,

                ),

                padding:

                    const EdgeInsets.symmetric(

                  horizontal: 12,

                  vertical: 8,

                ),

                decoration:

                    BoxDecoration(

                  color: const Color(

                    0xFF1B2029,

                  ),

                  borderRadius:

                      BorderRadius.circular(

                    10,

                  ),

                ),

                child: Row(

                  children: [

                    const Icon(

                      Icons.edit,

                      size: 17,

                      color: Colors.blue,

                    ),

                    const SizedBox(

                      width: 8,

                    ),

                    const Expanded(

                      child: Text(

                        'Editing message',

                        style:

                            TextStyle(

                          color:

                              Colors.white70,

                          fontSize: 13,

                        ),

                      ),

                    ),

                    GestureDetector(

                      onTap:

                          _cancelEditing,

                      child:

                          const Icon(

                        Icons.close,

                        size: 18,

                        color:

                            Colors.white54,

                      ),

                    ),

                  ],

                ),

              ),

            Row(

              crossAxisAlignment:

                  CrossAxisAlignment.end,

              children: [

                Expanded(

                  child: Container(

                    decoration:

                        BoxDecoration(

                      color:

                          const Color(

                        0xFF1B2029,

                      ),

                      borderRadius:

                          BorderRadius.circular(

                        24,

                      ),

                    ),

                    child: TextField(

                      controller:

                          _textController,

                      minLines: 1,

                      maxLines: 5,

                      style:

                          const TextStyle(

                        color:

                            Colors.white,

                        fontSize: 15,

                      ),

                      decoration:

                          const InputDecoration(

                        hintText:

                            'Type a message...',

                        hintStyle:

                            TextStyle(

                          color:

                              Colors.white38,

                        ),

                        border:

                            InputBorder.none,

                        contentPadding:

                            EdgeInsets.symmetric(

                          horizontal: 18,

                          vertical: 12,

                        ),

                      ),

                    ),

                  ),

                ),

                const SizedBox(

                  width: 8,

                ),

                GestureDetector(

                  onTap:

                      _sendOrEditMessage,

                  child: Container(

                    width: 48,

                    height: 48,

                    decoration:

                        const BoxDecoration(

                      shape:

                          BoxShape.circle,

                      color:

                          Color(0xFF2563EB),

                    ),

                    child: Icon(

                      editing

                          ? Icons.check

                          : Icons.send,

                      color:

                          Colors.white,

                      size: 20,

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }



  Future<void>

      _sendOrEditMessage() async {

    final String text =

        _textController.text.trim();



    if (text.isEmpty) {

      return;

    }



    if (_editingMessage != null) {

      final ChatMessageModel

          message =

          _editingMessage!;



      final String? messageId =

          message.messageId;



      if (messageId == null ||

          messageId.isEmpty) {

        return;

      }



      await _controller.editMessage(

        messageId: messageId,

        newText: text,

      );



      _cancelEditing();



      return;

    }



    _textController.clear();



    await _controller.sendMessage(

      text,

    );

  }



  void _showMessageMenu(

    ChatMessageModel message,

  ) {

    if (!message.isMine || message.isDeleted) {

      return;

    }



    if (message.messageId ==

            null ||

        message.messageId!.isEmpty) {

      return;

    }



    showModalBottomSheet(

      context: context,

      backgroundColor:

          const Color(0xFF151922),

      shape:

          const RoundedRectangleBorder(

        borderRadius:

            BorderRadius.vertical(

          top: Radius.circular(20),

        ),

      ),

      builder: (context) {

        return SafeArea(

          child: Padding(

            padding:

                const EdgeInsets.symmetric(

              vertical: 12,

            ),

            child: Column(

              mainAxisSize:

                  MainAxisSize.min,

              children: [

                ListTile(

                  leading:

                      const Icon(

                    Icons.edit,

                    color: Colors.white,

                  ),

                  title:

                      const Text(

                    'Edit message',

                    style:

                        TextStyle(

                      color:

                          Colors.white,

                    ),

                  ),

                  onTap: () {

                    Navigator.pop(

                      context,

                    );



                    _startEditing(

                      message,

                    );

                  },

                ),

                ListTile(

                  leading:

                      const Icon(

                    Icons.delete_outline,

                    color: Colors.redAccent,

                  ),

                  title:

                      const Text(

                    'Delete message',

                    style:

                        TextStyle(

                      color:

                          Colors.white,

                    ),

                  ),

                  onTap: () {

                    Navigator.pop(

                      context,

                    );



                    _confirmDelete(

                      message,

                    );

                  },

                ),

              ],

            ),

          ),

        );

      },

    );

  }



  void _startEditing(

    ChatMessageModel message,

  ) {
    if (message.isDeleted) {
      return;
    }

    setState(() {

      _editingMessage =

          message;



      _textController.text =

          message.text;



      _textController.selection =

          TextSelection.collapsed(

        offset:

            _textController.text.length,

      );

    });

  }



  void _cancelEditing() {

    setState(() {

      _editingMessage = null;



      _textController.clear();

    });

  }



  Future<void> _confirmDelete(

    ChatMessageModel message,

  ) async {

    final bool? confirmed =

        await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor:

              const Color(0xFF151922),

          title: const Text(

            'Delete message?',

            style: TextStyle(

              color: Colors.white,

            ),

          ),

          content:

              const Text(

            'This message will be recalled for both users.',

            style: TextStyle(

              color: Colors.white70,

            ),

          ),

          actions: [

            TextButton(

              onPressed: () =>

                  Navigator.pop(

                context,

                false,

              ),

              child: const Text(

                'Cancel',

              ),

            ),

            TextButton(

              onPressed: () =>

                  Navigator.pop(

                context,

                true,

              ),

              child: const Text(

                'Delete',

                style:

                    TextStyle(

                  color:

                      Colors.redAccent,

                ),

              ),

            ),

          ],

        );

      },

    );



    if (confirmed != true) {

      return;

    }



    final String? messageId =

        message.messageId;



    if (messageId == null ||

        messageId.isEmpty) {

      return;

    }



    await _controller.deleteMessage(

      messageId,

    );

  }



  Future<void> _showClearChatConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151922),
          title: const Text(
            'Clear Chat?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: const Text(
            'This will clear this chat from your side only. '
            'The other user will not be affected.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Clear Chat',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _controller.clearChat();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat cleared from your side',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override

  void dispose() {

    _controller.removeListener(

      _onControllerChanged,

    );



    _controller.disposeChat();



    _textController.dispose();



    _scrollController.dispose();



    super.dispose();

  }

}