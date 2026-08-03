import 'package:flutter/material.dart';
import 'three_d_viewer.dart';

class ThreeDViewerPage extends StatefulWidget {
  final String modelPath;
  final double initialZoom;
  final bool autoPlay;
  final List<double>? initialCameraPosition;
  final List<double>? initialTargetPosition;

  const ThreeDViewerPage({
    super.key,
    required this.modelPath,
    this.initialZoom = 1.0,
    this.autoPlay = true,
    this.initialCameraPosition,
    this.initialTargetPosition,
  });

  @override
  State<ThreeDViewerPage> createState() => _ThreeDViewerPageState();
}

class _ThreeDViewerPageState extends State<ThreeDViewerPage> {
  final ThreeDViewerController _controller = ThreeDViewerController();
  late bool _isPlaying;
  List<ThreeDAnimation> _animations = [];
  Map<String, double> _animationProgress = {};

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
              Expanded(
                child: ThreeDViewer(
                  // rotationLimits: ThreeDRotationLimits(
                  //   minVerticalAngle: 80,
                  //   maxVerticalAngle: 120,
                  //   minHorizontalAngle: -30,
                  //   maxHorizontalAngle: 30
                  //
                  // ),
                  showDebugHelpers: true,
                  enablePan: false,
                  autoCenter: true,
                  initialTargetPosition: widget.initialTargetPosition,
                  initialCameraPosition: widget.initialCameraPosition,
                  zoomConfig: ThreeDZoomConfig(
                    initialZoom: widget.initialZoom,
                    enableZoom: true
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
                    maxHeight: constraints.maxHeight * 0.45, // Dynamic height capped at 45%
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
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
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                        activeTrackColor: Colors.blue,
                                        inactiveTrackColor: Colors.blue.withOpacity(0.1),
                                        thumbColor: Colors.blue,
                                      ),
                                      child: Slider(
                                        value: _animationProgress[anim.name] ?? 0.0,
                                        onChanged: (value) {
                                          setState(() {
                                            _animationProgress[anim.name] = value;
                                            _isPlaying = false;
                                          });
                                          _controller.setAnimationProgress(anim.name, value);
                                        },
                                      ),
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
