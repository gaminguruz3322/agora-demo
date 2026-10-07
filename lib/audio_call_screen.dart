import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================
// AGORA CONFIG
// ============================================================

const String appId = 'e51be8b788e24b5cac316466a9737269';

const String token = '007eJxTYPDW+bdkPUNguHN/uonimY2G/X1GEpv/HHcUN2Nw4T3uXq3AkGpqmJRqkWRuYZFqZJJkmpyYbGxoZmJmlmhpbmxuZGZ5UG9fVkMgI8NLT31GRgYIBPG5GBJLUzLz45MTc3IYGAAsUx7c';

const String channelName = 'audio_call';


// ============================================================
// AUDIO CALL SCREEN
// ============================================================

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  // ==========================================================
  // AGORA ENGINE
  // ==========================================================

  RtcEngine? _engine;

  // ==========================================================
  // CALL STATE
  // ==========================================================

  bool _isJoined = false;
  bool _isMuted = false;

  // false = normal phone earpiece
  // true = loudspeaker
  bool _isSpeakerOn = false;

  int? _remoteUid;

  String _callStatus = 'Connecting...';

  // ==========================================================
  // CALL TIMER
  // ==========================================================

  Timer? _callTimer;

  Duration _callDuration = Duration.zero;

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initializeAgora();
  }

  // ==========================================================
  // INITIALIZE AGORA
  // ==========================================================

  Future<void> _initializeAgora() async {
    try {
      // ------------------------------------------------------
      // MICROPHONE PERMISSION
      // ------------------------------------------------------

      final microphonePermission =
          await Permission.microphone.request();

      debugPrint(
        'Microphone permission: $microphonePermission',
      );

      if (!microphonePermission.isGranted) {
        if (!mounted) return;

        setState(() {
          _callStatus = 'Microphone permission denied';
        });

        return;
      }

      // ------------------------------------------------------
      // CREATE ENGINE
      // ------------------------------------------------------

      debugPrint(
        'Creating Agora audio engine...',
      );

      final engine = createAgoraRtcEngine();

      _engine = engine;

      // ------------------------------------------------------
      // INITIALIZE ENGINE
      // ------------------------------------------------------

      await engine.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile:
              ChannelProfileType.channelProfileCommunication,
        ),
      );

      debugPrint(
        'Agora audio engine initialized',
      );

      // ------------------------------------------------------
      // EVENT HANDLERS
      // ------------------------------------------------------

      engine.registerEventHandler(
        RtcEngineEventHandler(

          // ==================================================
          // LOCAL USER JOINED
          // ==================================================

          onJoinChannelSuccess:
              (RtcConnection connection, int elapsed) {
            debugPrint(
              'JOIN SUCCESS: ${connection.channelId}',
            );

            if (!mounted) return;

            setState(() {
              _isJoined = true;
              _callStatus = 'Waiting for interviewer...';
            });
          },

          // ==================================================
          // REMOTE USER JOINED
          // ==================================================

          onUserJoined:
              (RtcConnection connection,
                  int remoteUid,
                  int elapsed) {
            debugPrint(
              'REMOTE USER JOINED: $remoteUid',
            );

            if (!mounted) return;

            setState(() {
              _remoteUid = remoteUid;
              _callStatus = 'Connected';
            });

            // Start the real conversation timer
            // when the second participant joins.
            _startCallTimer();
          },

          // ==================================================
          // REMOTE USER LEFT
          // ==================================================

          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            debugPrint(
              'REMOTE USER LEFT: $remoteUid',
            );

            _stopCallTimer();

            if (!mounted) return;

            setState(() {
              _remoteUid = null;
              _callStatus = 'Call ended';
            });
          },

          // ==================================================
          // ERROR
          // ==================================================

          onError: (
            ErrorCodeType errorCode,
            String message,
          ) {
            debugPrint(
              'Agora ERROR: $errorCode - $message',
            );
          },

          // ==================================================
          // CONNECTION STATE
          // ==================================================

          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            debugPrint(
              'Connection state: $state',
            );

            debugPrint(
              'Connection reason: $reason',
            );
          },
        ),
      );

      // ------------------------------------------------------
      // ENABLE AUDIO
      // ------------------------------------------------------

      await engine.enableAudio();

      debugPrint(
        'Audio enabled',
      );

      // ------------------------------------------------------
      // JOIN CHANNEL
      // ------------------------------------------------------

      const ChannelMediaOptions options =
          ChannelMediaOptions(
        channelProfile:
            ChannelProfileType.channelProfileCommunication,

        clientRoleType:
            ClientRoleType.clientRoleBroadcaster,

        publishMicrophoneTrack: true,

        publishCameraTrack: false,

        autoSubscribeAudio: true,

        autoSubscribeVideo: false,
      );

      debugPrint(
        'Joining audio channel: $channelName',
      );

      await engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: options,
      );

      debugPrint(
        'joinChannel called successfully',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Agora audio initialization error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _callStatus = 'Call initialization failed';
      });
    }
  }

  // ==========================================================
  // START TIMER
  // ==========================================================

  void _startCallTimer() {
    _callTimer?.cancel();

    _callDuration = Duration.zero;

    _callTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        setState(() {
          _callDuration += const Duration(seconds: 1);
        });
      },
    );

    debugPrint(
      'Call timer started',
    );
  }

  // ==========================================================
  // STOP TIMER
  // ==========================================================

  void _stopCallTimer() {
    _callTimer?.cancel();

    _callTimer = null;

    debugPrint(
      'Call timer stopped',
    );
  }

  // ==========================================================
  // FORMAT TIMER
  // ==========================================================

  String _formatCallDuration() {
    final int hours = _callDuration.inHours;

    final int minutes =
        _callDuration.inMinutes.remainder(60);

    final int seconds =
        _callDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // SPEAKER / EARPIECE
  // ==========================================================

  Future<void> _toggleSpeaker() async {
    final engine = _engine;

    if (engine == null || !_isJoined) {
      return;
    }

    try {
      final bool newSpeakerState =
          !_isSpeakerOn;

      await engine.setEnableSpeakerphone(
        newSpeakerState,
      );

      if (!mounted) return;

      setState(() {
        _isSpeakerOn = newSpeakerState;
      });

      debugPrint(
        newSpeakerState
            ? 'Speakerphone ON'
            : 'Speakerphone OFF - Phone earpiece',
      );
    } catch (e) {
      debugPrint(
        'Speaker toggle error: $e',
      );
    }
  }

  // ==========================================================
  // MUTE / UNMUTE
  // ==========================================================

  Future<void> _toggleMute() async {
    final engine = _engine;

    if (engine == null || !_isJoined) {
      return;
    }

    try {
      final bool newMuteState =
          !_isMuted;

      await engine.muteLocalAudioStream(
        newMuteState,
      );

      if (!mounted) return;

      setState(() {
        _isMuted = newMuteState;
      });

      debugPrint(
        newMuteState
            ? 'Microphone MUTED'
            : 'Microphone UNMUTED',
      );
    } catch (e) {
      debugPrint(
        'Mute error: $e',
      );
    }
  }

  // ==========================================================
  // END CALL
  // ==========================================================

  Future<void> _leaveCall() async {
    _stopCallTimer();

    final engine = _engine;

    _engine = null;

    if (engine != null) {
      try {
        await engine.leaveChannel();

        debugPrint(
          'Left audio channel',
        );
      } catch (e) {
        debugPrint(
          'Leave channel error: $e',
        );
      }

      try {
        await engine.release();

        debugPrint(
          'Agora engine released',
        );
      } catch (e) {
        debugPrint(
          'Agora release error: $e',
        );
      }
    }

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _stopCallTimer();

    final engine = _engine;

    _engine = null;

    if (engine != null) {
      engine.leaveChannel();
      engine.release();
    }

    super.dispose();
  }

  // ==========================================================
  // CONTROL BUTTON
  // ==========================================================

  Widget _callButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    bool active = false,
    bool danger = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 200,
            ),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: danger
                  ? Colors.red
                  : active
                      ? Colors.white
                      : Colors.white.withOpacity(0.10),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: danger
                  ? Colors.white
                  : active
                      ? Colors.black
                      : Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // STATUS INDICATOR
  // ==========================================================

  Widget _connectionStatus() {
    final bool connected =
        _remoteUid != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
            ),

            const SizedBox(width: 8),

            Text(
              _callStatus,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),

        // ====================================================
        // REAL CALL TIMER
        // ====================================================

        if (connected) ...[
          const SizedBox(height: 10),

          Text(
            _formatCallDuration(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF101114),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // TOP BAR
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _leaveCall,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        'Audio Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 42,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CALLER AREA
            // ==================================================

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // AVATAR
                  // ------------------------------------------------

                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    width: 125,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        0.08,
                      ),
                      border: Border.all(
                        color: _remoteUid != null
                            ? Colors.greenAccent
                            : Colors.white.withOpacity(
                                0.12,
                              ),
                        width: 2,
                      ),
                      boxShadow: _remoteUid != null
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent
                                    .withOpacity(0.20),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 65,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  const Text(
                    'Interview Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // STATUS + TIMER
                  // ------------------------------------------------

                  _connectionStatus(),

                  // ------------------------------------------------
                  // REMOTE CONNECTION
                  // ------------------------------------------------

                  if (_remoteUid != null) ...[
                    const SizedBox(height: 8),

                    const Text(
                      'Both participants are connected',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ==================================================
            // CONTROLS
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                10,
                24,
                35,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      // ==========================================
                      // SPEAKER
                      // ==========================================

                      _callButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.phone_in_talk_rounded,

                        label: _isSpeakerOn
                            ? 'Speaker'
                            : 'Earpiece',

                        active: _isSpeakerOn,

                        onTap: _toggleSpeaker,
                      ),

                      // ==========================================
                      // MUTE
                      // ==========================================

                      _callButton(
                        icon: _isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,

                        label: _isMuted
                            ? 'Unmute'
                            : 'Mute',

                        active: _isMuted,

                        onTap: _toggleMute,
                      ),

                      // ==========================================
                      // END CALL
                      // ==========================================

                      _callButton(
                        icon:
                            Icons.call_end_rounded,

                        label: 'End Call',

                        danger: true,

                        onTap: _leaveCall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // AUDIO ROUTE
                  // ------------------------------------------------

                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: Text(
                      _isSpeakerOn
                          ? '🔊  Speakerphone'
                          : '📞  Phone earpiece',
                      key: ValueKey(
                        _isSpeakerOn,
                      ),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
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
}