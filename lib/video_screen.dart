

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const String appId = '9463df2775da4a01bb00889e549dd001';

const String token = '007eJxTYPjRM1Prz7ezxyffkJ3YY6KvVyq6Mlbmaf7N+u59i+RtQ5MUGCxNzIxT0ozMzU1TEk0SDQyTkgwMLCwsU01NLFNSDAwMnfX3ZTUEMjIY9huyMjJAIIjPz1CWmZKaH5+ZV5JaVJaZWs7AAADzLyOR';

const String channelName = 'video_interview';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with WidgetsBindingObserver {
  late RtcEngine _engine;

  int? _remoteUid;

  bool _localUserJoined = false;
  bool _muted = false;
  bool _cameraOff = false;

  bool _engineInitialized = false;
  bool _cameraStarted = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle: $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    }

    if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initialize() async {
    try {
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraPermission = permissions[Permission.camera];
      final microphonePermission = permissions[Permission.microphone];

      debugPrint(
        'Camera permission: $cameraPermission',
      );

      debugPrint(
        'Microphone permission: $microphonePermission',
      );

      if (cameraPermission != PermissionStatus.granted) {
        debugPrint('Camera permission not granted');
        return;
      }

      if (microphonePermission != PermissionStatus.granted) {
        debugPrint('Microphone permission not granted');
        return;
      }

      await _initializeAgora();
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // AGORA INITIALIZATION
  // ============================================================

  Future<void> _initializeAgora() async {
    if (_engineInitialized) {
      return;
    }

    try {
      debugPrint('Creating Agora engine...');

      _engine = createAgoraRtcEngine();

      await _engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile:
              ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engineInitialized = true;

      debugPrint('Agora engine initialized');

      // ----------------------------------------------------------
      // EVENT HANDLERS
      // ----------------------------------------------------------

      _registerEventHandlers();

      // ----------------------------------------------------------
      // ENABLE VIDEO
      // ----------------------------------------------------------

      await _engine.enableVideo();

      debugPrint('Agora video enabled');

      // ----------------------------------------------------------
      // FRONT CAMERA
      // ----------------------------------------------------------

      await _engine.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraFront,
        ),
      );

      debugPrint('Front camera selected');

      // ----------------------------------------------------------
      // ENABLE LOCAL VIDEO
      // ----------------------------------------------------------

      await _engine.enableLocalVideo(true);

      debugPrint('Local video enabled');

      // ----------------------------------------------------------
      // START CAMERA PREVIEW
      // ----------------------------------------------------------

      await _engine.startPreview();

      _cameraStarted = true;

      debugPrint('Camera preview started');

      // ----------------------------------------------------------
      // JOIN CHANNEL
      // ----------------------------------------------------------

      await _joinChannel();

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('Agora initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  void _registerEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        // --------------------------------------------------------
        // LOCAL USER JOINED
        // --------------------------------------------------------

        onJoinChannelSuccess: (
          RtcConnection connection,
          int elapsed,
        ) {
          debugPrint(
            'JOIN SUCCESS: ${connection.channelId}',
          );

          if (!mounted) return;

          setState(() {
            _localUserJoined = true;
          });
        },

        // --------------------------------------------------------
        // REMOTE USER JOINED
        // --------------------------------------------------------

        onUserJoined: (
          RtcConnection connection,
          int remoteUid,
          int elapsed,
        ) {
          debugPrint(
            'REMOTE USER JOINED: $remoteUid',
          );

          if (!mounted) return;

          setState(() {
            _remoteUid = remoteUid;
          });
        },

        // --------------------------------------------------------
        // REMOTE USER LEFT
        // --------------------------------------------------------

        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          debugPrint(
            'REMOTE USER LEFT: $remoteUid',
          );

          if (!mounted) return;

          setState(() {
            _remoteUid = null;
          });
        },

        // --------------------------------------------------------
        // LEAVE CHANNEL
        // --------------------------------------------------------

        onLeaveChannel: (
          RtcConnection connection,
          RtcStats stats,
        ) {
          debugPrint('LEFT CHANNEL');

          if (!mounted) return;

          setState(() {
            _localUserJoined = false;
            _remoteUid = null;
          });
        },

        // --------------------------------------------------------
        // AGORA ERROR
        // --------------------------------------------------------

        onError: (
          ErrorCodeType err,
          String msg,
        ) {
          debugPrint(
            'AGORA ERROR: $err',
          );

          debugPrint(
            'AGORA MESSAGE: $msg',
          );
        },

        // --------------------------------------------------------
        // REMOTE VIDEO STATE
        // --------------------------------------------------------

        onRemoteVideoStateChanged: (
          RtcConnection connection,
          int remoteUid,
          RemoteVideoState state,
          RemoteVideoStateReason reason,
          int elapsed,
        ) {
          debugPrint(
            'REMOTE VIDEO: '
            'uid=$remoteUid '
            'state=$state '
            'reason=$reason',
          );
        },

        // --------------------------------------------------------
        // LOCAL VIDEO STATE
        // --------------------------------------------------------

        onLocalVideoStateChanged: (
          VideoSourceType source,
          LocalVideoStreamState state,
          LocalVideoStreamReason reason,
        ) {
          debugPrint(
            'LOCAL VIDEO: '
            'state=$state '
            'reason=$reason',
          );
        },
      ),
    );
  }

  // ============================================================
  // JOIN CHANNEL
  // ============================================================

  Future<void> _joinChannel() async {
    if (!_engineInitialized) {
      return;
    }

    if (appId == 'YOUR_AGORA_APP_ID') {
      debugPrint(
        'ERROR: Replace YOUR_AGORA_APP_ID',
      );
      return;
    }

    if (token == 'YOUR_TEMPORARY_TOKEN') {
      debugPrint(
        'ERROR: Replace YOUR_TEMPORARY_TOKEN',
      );
      return;
    }

    try {
      debugPrint(
        'Joining channel: $channelName',
      );

      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType:
              ClientRoleType.clientRoleBroadcaster,

          channelProfile:
              ChannelProfileType.channelProfileCommunication,

          publishCameraTrack: true,
          publishMicrophoneTrack: true,

          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('JOIN CHANNEL ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // START CAMERA
  // ============================================================

  Future<void> _startCamera() async {
    if (!_engineInitialized) {
      return;
    }

    if (_cameraOff) {
      return;
    }

    if (_cameraStarted) {
      return;
    }

    if (_isLeaving) {
      return;
    }

    try {
      debugPrint('Starting camera...');

      await _engine.enableVideo();

      await _engine.enableLocalVideo(true);

      await _engine.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraFront,
        ),
      );

      await _engine.startPreview();

      _cameraStarted = true;

      debugPrint('Camera started');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'START CAMERA ERROR: $e',
      );
    }
  }

  // ============================================================
  // STOP CAMERA
  // ============================================================

  Future<void> _stopCamera() async {
    if (!_engineInitialized) {
      return;
    }

    if (!_cameraStarted) {
      return;
    }

    try {
      debugPrint('Stopping camera...');

      await _engine.stopPreview();

      await _engine.enableLocalVideo(false);

      _cameraStarted = false;

      debugPrint('Camera stopped');
    } catch (e) {
      debugPrint(
        'STOP CAMERA ERROR: $e',
      );
    }
  }

  // ============================================================
  // LOCAL VIDEO
  // ============================================================

  Widget _localVideo() {
    if (!_localUserJoined || _cameraOff) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 50,
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(
          uid: 0,

          renderMode:
              RenderModeType.renderModeFit,

          mirrorMode:
              VideoMirrorModeType
                  .videoMirrorModeEnabled,
        ),
      ),
    );
  }

  // ============================================================
  // REMOTE VIDEO
  // ============================================================

  Widget _remoteVideo() {
    if (_remoteUid == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 70,
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for interviewer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(
          uid: _remoteUid,
          renderMode:
              RenderModeType.renderModeFit,
        ),
        connection: RtcConnection(
          channelId: channelName,
        ),
      ),
    );
  }

  // ============================================================
  // MUTE
  // ============================================================

  Future<void> _toggleMute() async {
    if (!_engineInitialized) {
      return;
    }

    final bool newMuted = !_muted;

    try {
      await _engine.muteLocalAudioStream(
        newMuted,
      );

      if (!mounted) return;

      setState(() {
        _muted = newMuted;
      });
    } catch (e) {
      debugPrint(
        'Mute error: $e',
      );
    }
  }

  // ============================================================
  // CAMERA ON / OFF
  // ============================================================

  Future<void> _toggleCamera() async {
    if (!_engineInitialized) {
      return;
    }

    final bool newCameraOff = !_cameraOff;

    try {
      if (newCameraOff) {
        await _engine.stopPreview();

        await _engine.enableLocalVideo(
          false,
        );

        _cameraStarted = false;

        debugPrint('Camera OFF');
      } else {
        await _engine.enableVideo();

        await _engine.enableLocalVideo(
          true,
        );

        await _engine.setCameraCapturerConfiguration(
          const CameraCapturerConfiguration(
            cameraDirection:
                CameraDirection.cameraFront,
          ),
        );

        await _engine.startPreview();

        _cameraStarted = true;

        debugPrint('Camera ON');
      }

      if (!mounted) return;

      setState(() {
        _cameraOff = newCameraOff;
      });
    } catch (e) {
      debugPrint(
        'Camera toggle error: $e',
      );
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> _switchCamera() async {
    if (!_engineInitialized) {
      return;
    }

    if (_cameraOff) {
      return;
    }

    try {
      await _engine.switchCamera();

      debugPrint(
        'Camera switched',
      );
    } catch (e) {
      debugPrint(
        'Switch camera error: $e',
      );
    }
  }

  // ============================================================
  // LEAVE CHANNEL
  // ============================================================

  Future<void> _leaveChannel() async {
    if (_isLeaving) {
      return;
    }

    _isLeaving = true;

    try {
      if (_engineInitialized) {
        await _engine.stopPreview();

        await _engine.leaveChannel();
      }
    } catch (e) {
      debugPrint(
        'Leave error: $e',
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isLeaving = true;

    WidgetsBinding.instance.removeObserver(
      this,
    );

    if (_engineInitialized) {
      _engine.stopPreview();
      _engine.leaveChannel();
      _engine.release();
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ----------------------------------------------------
            // REMOTE VIDEO
            // ----------------------------------------------------

            Positioned.fill(
              child: _remoteVideo(),
            ),

            // ----------------------------------------------------
            // TOP BAR
            // ----------------------------------------------------

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.55),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 10,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'LIVE INTERVIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.55),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Text(
                      channelName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // LOCAL VIDEO
            // ----------------------------------------------------

            Positioned(
              top: 70,
              right: 16,
              child: Container(
                width: 120,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.5),
                    width: 1,
                  ),
                ),
                clipBehavior:
                    Clip.antiAlias,
                child: _localVideo(),
              ),
            ),

            // ----------------------------------------------------
            // CONNECTION STATUS
            // ----------------------------------------------------

            if (!_localUserJoined)
              Positioned(
                top: 70,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.black
                        .withOpacity(0.55),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ----------------------------------------------------
            // BOTTOM CONTROLS
            // ----------------------------------------------------

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  _controlButton(
                    icon: _muted
                        ? Icons.mic_off
                        : Icons.mic,
                    label: _muted
                        ? 'Unmute'
                        : 'Mute',
                    onTap: _toggleMute,
                  ),

                  const SizedBox(width: 18),

                  _controlButton(
                    icon: _cameraOff
                        ? Icons.videocam_off
                        : Icons.videocam,
                    label: _cameraOff
                        ? 'Camera On'
                        : 'Camera',
                    onTap: _toggleCamera,
                  ),

                  const SizedBox(width: 18),

                  _controlButton(
                    icon: Icons.cameraswitch,
                    label: 'Flip',
                    onTap: _switchCamera,
                  ),

                  const SizedBox(width: 18),

                  _controlButton(
                    icon: Icons.call_end,
                    label: 'Leave',
                    backgroundColor: Colors.red,
                    onTap: _leaveChannel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTROL BUTTON
  // ============================================================

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color backgroundColor =
        const Color(0xCC222222),
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder:
                const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}