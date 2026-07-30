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
  bool _hasAnimations = false;

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
          if (_hasAnimations)
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
      body: ThreeDViewer(
        controller: _controller,
        assetPath: widget.modelPath,
        backgroundColor: Colors.white,
        initialZoom: widget.initialZoom,
        autoPlay: widget.autoPlay,
        onAnimationsLoaded: (hasAnimations) {
          setState(() {
            _hasAnimations = hasAnimations;
          });
        },
      ),
    );
  }
}
