import 'package:flutter/material.dart';
import 'package:video_interview_project/audio_call_screen.dart';
import 'video_screen.dart';
import 'screens/chat_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ============================================================
  // TEST USER CONFIGURATION
  // ============================================================
  //
  // PIXEL 9:
  //   true  = User 1
  //
  // 2201117SI:
  //   false = User 2
  //
  // Change ONLY this value for each device.
  // ============================================================

  static const bool isUser1 = true;

  // ============================================================SS
  // USER 1 DATAS
  // ============================================================

  static const String user1Id = 'user1';

  static const String user1ChatToken =
      '007eJxTYGC5y1U8KbmrWy/jyv4HCaLs8+RTH0ocsdStKZPgf6x7KlKBwcTS0swkxTzZxCDZwiTNxCDRxMQgzdjMwDzZPNXUyMSoymJfVkMgI0PA1CAWRgZWBkYgBPFVGCxTDSwMklMNdJNSzNN0DQ3TDHUTDZKMdU3ME80NDA2MUo0sUwA+6yQI';

  // ============================================================
  // USER 2 DATA
  // ============================================================1

  static const String user2Id = 'user2';

  static const String user2ChatToken =
      '007eJxTYJiVJaPH+luWtfhP/WO7iXuTnsjLGZaGcrTvUI8Wc19R6KHAYGJpaWaSYp5sYpBsYZJmYpBoYmKQZmxmYJ5snmpqZGJkZLEvqyGQkWHGbWEGRgZWIGZkAPFVGBJNjNJMU40MdJNSzNN0DQ3TDHWTElPMdU1Mk8zSUi3TjJJSjQD8iCQu';

  // ============================================================
  // VIDEO CALL
  // ============================================================

  void _openVideoCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VideoScreen(),
      ),
    );
  }

  // ============================================================
  // AUDIO CALL
  // ============================================================

  void _openAudioCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AudioCallScreen(),
      ),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

 void _openChat(BuildContext context) {
  final String currentUserId;
  final String currentUserToken;
  final String receiverId;

  if (isUser1) {
    currentUserId = user1Id;
    currentUserToken = user1ChatToken;
    receiverId = user2Id;
  } else {
    currentUserId = user2Id;
    currentUserToken = user2ChatToken;
    receiverId = user1Id;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        userId: currentUserId,
        chatToken: currentUserToken,
        receiverId: receiverId,
      ),
    ),
  );
}

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _callButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3867FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String currentUser =
        isUser1 ? user1Id : user2Id;

    final String receiver =
        isUser1 ? user2Id : user1Id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        title: const Text(
          'OneGlobe',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ==================================================
            // CURRENT USER INFO
            // ==================================================

            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8EEFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF3867FF),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logged in as',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          currentUser,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Chat with $receiver',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F8EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUser1
                          ? 'USER 1'
                          : 'USER 2',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // VIDEO CALL
            // ==================================================

            _callButton(
              title: 'Video Call',
              icon: Icons.videocam_rounded,
              onTap: () {
                _openVideoCall(context);
              },
            ),

            // ==================================================
            // AUDIO CALL
            // ==================================================

            _callButton(
              title: 'Audio Call',
              icon: Icons.call_rounded,
              onTap: () {
                _openAudioCall(context);
              },
            ),

            // ==================================================
            // CHAT
            // ==================================================

            _callButton(
              title: 'Chat',
              icon: Icons.chat_rounded,
              onTap: () {
                _openChat(context);
              },
            ),

            const Spacer(),

            // ==================================================
            // TEST INFORMATION
            // ==================================================

            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isUser1
                    ? 'Testing as User 1 → User 2'
                    : 'Testing as User 2 → User 1',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}