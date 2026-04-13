import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/live_demo/client/live_demo_client.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class LiveDemoVideoOverlay extends StatefulWidget {
  final LiveDemoClient client;
  final Duration syncInterval;
  final double seekThresholdMs;
  final double playbackRateThresholdMs;
  final double minPlaybackRate;
  final double maxPlaybackRate;
  final bool showingOverlay;

  const LiveDemoVideoOverlay({
    super.key,
    required this.client,
    this.syncInterval = const Duration(seconds: 2),
    this.seekThresholdMs = 500,
    this.playbackRateThresholdMs = 80,
    this.minPlaybackRate = 0.85,
    this.maxPlaybackRate = 1.15,
    required this.showingOverlay
  });

  @override
  State<LiveDemoVideoOverlay> createState() => _LiveDemoVideoOverlayState();
}

class _LiveDemoVideoOverlayState extends State<LiveDemoVideoOverlay> {
  VideoPlayerController? _controller;
  Timer? _syncTimer;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await widget.client.ensureVideoInitialized();

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/video.mp4");

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);

      _controller = controller;

      final initialSync = await widget.client.getSync();
      await _applySync(initialSync, hardSeek: true);
      await _controller!.play();

      _syncTimer = Timer.periodic(widget.syncInterval, (_) async {
        await _tickSync();
      });

      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _tickSync() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final sync = await widget.client.getSync();
      await _applySync(sync);
    } catch (_) {}
  }

  Future<void> _applySync(SyncData sync, {bool hardSeek = false}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final durationMs = controller.value.duration.inMilliseconds;
    if (durationMs <= 0) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final timeSinceReceive = nowMs - sync.clientReceiveTimeMs;
    final estimatedTargetMs = sync.positionMs + sync.latency + timeSinceReceive;

    var targetMs = estimatedTargetMs % durationMs;
    if (targetMs < 0) targetMs += durationMs;

    final localMs = controller.value.position.inMilliseconds;
    var driftMs = targetMs - localMs;
    final halfDuration = durationMs / 2.0;

    if (driftMs > halfDuration) {
      driftMs -= durationMs;
    } else if (driftMs < -halfDuration) {
      driftMs += durationMs;
    }

    final absDrift = driftMs.abs().toDouble();

    if (hardSeek || (absDrift >= widget.seekThresholdMs && !widget.showingOverlay)) {
      printV("absdrift is $absDrift, hard-seeking");

      var predictedTargetMs = (targetMs) % durationMs;

      await controller.seekTo(Duration(milliseconds: predictedTargetMs.toInt()));
      await controller.setPlaybackSpeed(1.0);
      if (!controller.value.isPlaying) {
        await controller.play();
      }
      return;
    }

    if (absDrift >= 150) {
      final intervalMs = widget.syncInterval.inMilliseconds;
      final requiredRate = (intervalMs + driftMs) / intervalMs;

      final clampedRate = requiredRate.clamp(widget.minPlaybackRate, widget.maxPlaybackRate);

      printV("absdrift is $absDrift, adjusting rate to $clampedRate");
      await controller.setPlaybackSpeed(clampedRate);
    } else {
      await controller.setPlaybackSpeed(1.0);
    }

    if (!controller.value.isPlaying) {
      await controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(child: Text(_error!),);
    }

    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return SizedBox.expand();
    }

    return AnimatedOpacity(
      duration: Duration(milliseconds: 200),
      opacity: widget.showingOverlay ? 1 : 0,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}