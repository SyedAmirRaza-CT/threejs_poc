import 'package:flutter/material.dart';
import 'three_d_viewer.dart';

class ThreeDViewerPage extends StatefulWidget {
  final String modelPath;
  final double initialZoom;
  final bool autoPlay;

  const ThreeDViewerPage({
    super.key,
    required this.modelPath,
    this.initialZoom = 1.0,
    this.autoPlay = true,
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
      body: Column(
        children: [
          Expanded(
            child: ThreeDViewer(
              controller: _controller,
              assetPath: widget.modelPath,
              backgroundColor: Colors.white,
              initialZoom: widget.initialZoom,
              autoPlay: widget.autoPlay,
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
            Container(
              height: 200, // Fixed height for the control area
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Animations Control",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _animations.length,
                      itemBuilder: (context, index) {
                        final anim = _animations[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(anim.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Slider(
                              value: _animationProgress[anim.name] ?? 0.0,
                              onChanged: (value) {
                                setState(() {
                                  _animationProgress[anim.name] = value;
                                  _isPlaying = false;
                                });
                                _controller.setAnimationProgress(anim.name, value);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
