import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ThreeDAnimation {
  final String name;
  final double duration;

  ThreeDAnimation({required this.name, required this.duration});

  factory ThreeDAnimation.fromMap(Map map) {
    return ThreeDAnimation(
      name: map['name'] as String,
      duration: (map['duration'] as num).toDouble(),
    );
  }
}

class ThreeDViewerController {
  _ThreeDViewerState? _state;

  void toggleAnimation(bool play) {
    _state?._toggleAnimation(play);
  }

  void setAnimationProgress(String name, double progress) {
    _state?._setAnimationProgress(name, progress);
  }

  void setAnimationTime(String name, double time) {
    _state?._setAnimationTime(name, time);
  }
}

class ThreeDViewer extends StatefulWidget {
  final String assetPath;
  final Color backgroundColor;
  final double initialZoom;
  final bool enableZoom;
  final bool enableRotate;
  final bool enablePan;
  final List<double>? initialCameraPosition;
  final List<double>? initialTargetPosition;
  final bool autoPlay;
  final ThreeDViewerController? controller;
  final Function(List<ThreeDAnimation> animations)? onAnimationsLoaded;
  final Widget? customLoader;

  const ThreeDViewer({
    super.key,
    required this.assetPath,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.initialZoom = 1.0,
    this.enableZoom = true,
    this.enableRotate = true,
    this.enablePan = true,
    this.initialCameraPosition,
    this.initialTargetPosition,
    this.autoPlay = true,
    this.controller,
    this.onAnimationsLoaded,
    this.customLoader,
  });

  @override
  State<ThreeDViewer> createState() => _ThreeDViewerState();
}

class _ThreeDViewerState extends State<ThreeDViewer> {
  InAppWebViewController? webViewController;
  static InAppLocalhostServer? _localhostServer;
  bool isServerRunning = false;
  bool isLoadingModel = true;
  double loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _startServer();
  }

  Future<void> _startServer() async {
    if (_localhostServer == null) {
      _localhostServer = InAppLocalhostServer(port: 8080);
      await _localhostServer!.start();
    }
    if (mounted) {
      setState(() {
        isServerRunning = true;
      });
    }
  }

  void _toggleAnimation(bool play) {
    webViewController?.evaluateJavascript(
      source: "window.toggleAnimation($play);",
    );
  }

  void _setAnimationProgress(String name, double progress) {
    webViewController?.evaluateJavascript(
      source: "window.setAnimationProgress('$name', $progress);",
    );
  }

  void _setAnimationTime(String name, double time) {
    webViewController?.evaluateJavascript(
      source: "window.setAnimationTime('$name', $time);",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isServerRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("http://127.0.0.1:8080/assets/index.html"),
          ),
          initialSettings: InAppWebViewSettings(
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            javaScriptEnabled: true,
            transparentBackground: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            supportZoom: false,
            cacheEnabled: false,
            disableContextMenu: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
            controller.addJavaScriptHandler(
              handlerName: 'onViewerReady',
              callback: (args) => _sendModelData(),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadStart',
              callback: (args) => setState(() => isLoadingModel = true),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadProgress',
              callback: (args) => setState(() => loadingProgress = args[0] / 100.0),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadComplete',
              callback: (args) => setState(() => isLoadingModel = false),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onAnimationsLoaded',
              callback: (args) {
                final List<dynamic> anims = args[0] as List<dynamic>;
                final List<ThreeDAnimation> animations = anims
                    .map((e) => ThreeDAnimation.fromMap(e as Map<dynamic, dynamic>))
                    .toList();
                widget.onAnimationsLoaded?.call(animations);
              },
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("3D JS: ${consoleMessage.message}");
          },
          onLoadStop: (controller, url) {
            _sendModelData();
          },
        ),
        if (isLoadingModel && widget.customLoader != null)
          Positioned.fill(child: widget.customLoader!),
      ],
    );
  }

  void _sendModelData() {
    if (webViewController == null) return;

    String path = widget.assetPath;
    final bool isRemote = path.startsWith('http://') || path.startsWith('https://');
    
    if (!isRemote) {
      if (!path.startsWith('/')) {
        path = "/$path";
      }
      path = "http://127.0.0.1:8080$path";
    }

    String hexColor;
    if (widget.backgroundColor == Colors.transparent) {
      hexColor = 'transparent';
    } else {
      hexColor = '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    }
    
    String cameraPosJs = "null";
    if (widget.initialCameraPosition != null && widget.initialCameraPosition!.length >= 3) {
      cameraPosJs = "{x: ${widget.initialCameraPosition![0]}, y: ${widget.initialCameraPosition![1]}, z: ${widget.initialCameraPosition![2]}}";
    }

    String targetPosJs = "null";
    if (widget.initialTargetPosition != null && widget.initialTargetPosition!.length >= 3) {
      targetPosJs = "{x: ${widget.initialTargetPosition![0]}, y: ${widget.initialTargetPosition![1]}, z: ${widget.initialTargetPosition![2]}}";
    }

    // Pass whether we should show the native (JS-based) loader or use Flutter's
    bool showNativeLoader = widget.customLoader == null;

    webViewController?.evaluateJavascript(
      source: "if(window.loadModelWithConfig) window.loadModelWithConfig('$path', '$hexColor', ${widget.initialZoom}, ${widget.enableZoom}, ${widget.autoPlay}, $cameraPosJs, $targetPosJs, ${widget.enableRotate}, ${widget.enablePan}, $showNativeLoader);",
    );
  }
}
