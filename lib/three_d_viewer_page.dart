import 'package:flutter/material.dart';
import 'three_d_viewer.dart';

class ThreeDViewerPage extends StatefulWidget {
  final String modelPath;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool autoPlay;
  final List<double>? initialCameraPosition;
  final List<double>? initialTargetPosition;
  final List<ThreeDHotspot>? hotspots;
  final ThreeDDebugConfig debugConfig;

  const ThreeDViewerPage({
    super.key,
    required this.modelPath,
    this.initialZoom = 1.0,
    this.minZoom = 0.2,
    this.maxZoom = 10.0,
    this.autoPlay = true,
    this.initialCameraPosition,
    this.initialTargetPosition,
    this.hotspots,
    this.debugConfig = const ThreeDDebugConfig(),
  });

  @override
  State<ThreeDViewerPage> createState() => _ThreeDViewerPageState();
}

class _ThreeDViewerPageState extends State<ThreeDViewerPage> {
  final ThreeDViewerController _controller = ThreeDViewerController();
  late bool _isPlaying;
  bool _isAutoRotating = false;
  bool _isClockwise = true;
  List<ThreeDAnimation> _animations = [];
  final Map<String, double> _animationProgress = {};

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modelPath.split('/').last),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar),
            tooltip: 'Launch AR',
            onPressed: () => _controller.launchAR(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset View',
            onPressed: () => _controller.reset(),
          ),
          IconButton(
            icon: Icon(_isAutoRotating ? Icons.sync : Icons.sync_disabled),
            tooltip: 'Auto Rotate',
            onPressed: () {
              setState(() {
                _isAutoRotating = !_isAutoRotating;
              });
              _controller.setAutoRotate(
                _isAutoRotating,
                speed: 2.0,
                clockwise: _isClockwise,
              );
            },
          ),
          if (_animations.isNotEmpty)
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
                _controller.toggleAnimation(_isPlaying);
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Test Controls for new features
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text("Cinematic View"),
                      onPressed: () =>
                          _controller.goToView(45, 45, 5, durationMillis: 2000),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text("Tint Red"),
                      onPressed: () => _controller.setMaterialColor(
                        "all",
                        Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text("Reset Color"),
                      onPressed: () =>
                          _controller.setMaterialColor("all", Colors.white),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Icon(
                        _isClockwise ? Icons.rotate_right : Icons.rotate_left,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _isClockwise = !_isClockwise);
                        if (_isAutoRotating) {
                          _controller.setAutoRotate(
                            true,
                            clockwise: _isClockwise,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ThreeDViewer(
                  autoCenter: true,
                  // debugConfig: ThreeDDebugConfig(
                  //   showInteractiveParts: true
                  // ),
                  overlays: [
                    ThreeDOverlay(
                      id: 'blinking_dot',
                      position: [0,0, -0.1], // Center-top of model
                      child: _BlinkingDot(),
                    ),
                  ],
                  initialTargetPosition: widget.initialTargetPosition,
                  initialCameraPosition: widget.initialCameraPosition,
                  hotspots: widget.hotspots,
                  onHotspotTapped: (id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hotspot Tapped: $id"),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onObjectDoubleTapped: (name) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Part Selected"),
                        content: Text("You double-tapped on: $name"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _controller.reset(); // Reset when closed
                            },
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  enableDoubleTapZoom: true,
                  enablePan: false,
                  zoomConfig: ThreeDZoomConfig(
                    initialZoom: widget.initialZoom,
                    minZoom: widget.minZoom,
                    maxZoom: widget.maxZoom,
                    enableZoom: true,
                  ),
                  controller: _controller,
                  assetPath: widget.modelPath,
                  backgroundColor: Colors.transparent,
                  autoPlay: widget.autoPlay,
                  customLoader: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onAnimationsLoaded: (animations) {
                    setState(() {
                      _animations = animations;
                      for (var anim in animations) {
                        _animationProgress[anim.name] = 0.0;
                      }
                    });
                  },
                ),
              ),
              if (_animations.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        constraints.maxHeight *
                        0.45, // Dynamic height capped at 45%
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle visual
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Animation Layers",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${_animations.length}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            shrinkWrap: true,
                            itemCount: _animations.length,
                            itemBuilder: (context, index) {
                              final anim = _animations[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anim.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SliderTheme(
                                            data:
                                                SliderTheme.of(context).copyWith(
                                                  trackHeight: 4,
                                                  thumbShape:
                                                      const RoundSliderThumbShape(
                                                        enabledThumbRadius: 8,
                                                      ),
                                                  overlayShape:
                                                      const RoundSliderOverlayShape(
                                                        overlayRadius: 16,
                                                      ),
                                                  activeTrackColor: Colors.blue,
                                                  inactiveTrackColor: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  thumbColor: Colors.blue,
                                                ),
                                            child: Slider(
                                              value:
                                                  _animationProgress[
                                                    anim.name
                                                  ] ??
                                                  0.0,
                                              onChanged: (value) {
                                                setState(() {
                                                  _animationProgress[
                                                    anim.name
                                                  ] = value;
                                                  _isPlaying = false;
                                                });
                                                _controller
                                                    .setAnimationProgress(
                                                      anim.name,
                                                      value,
                                                    );
                                              },
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.play_circle_outline,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _controller.playAnimation(
                                                anim.name,
                                              ),
                                          tooltip: "Play Once",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
