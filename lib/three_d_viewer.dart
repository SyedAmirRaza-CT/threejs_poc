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
  final double minZoom;
  final double maxZoom;
  final bool enableZoom;
  final bool enableRotate;
  final bool enablePan;
  final bool enableBoundaries;
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
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
    this.enableZoom = true,
    this.enableRotate = true,
    this.enablePan = true,
    this.enableBoundaries = true,
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

    // Pass whether we should show the native (JS-based) loader or use Flutter's
    bool showNativeLoader = widget.customLoader == null;

    String cameraPosStr = "null";
    if (widget.initialCameraPosition != null && widget.initialCameraPosition!.length >= 3) {
      cameraPosStr = widget.initialCameraPosition!.join(',');
    }

    String targetPosStr = "null";
    if (widget.initialTargetPosition != null && widget.initialTargetPosition!.length >= 3) {
      targetPosStr = widget.initialTargetPosition!.join(',');
    }

    // Passing config via Hash Fragment (13 parameters)
    final String config = [
      path,
      hexColor,
      widget.initialZoom.toString(),
      widget.autoPlay.toString(),
      widget.minZoom.toString(),
      widget.maxZoom.toString(),
      widget.enableBoundaries.toString(),
      widget.enableZoom.toString(),
      widget.enableRotate.toString(),
      widget.enablePan.toString(),
      showNativeLoader.toString(),
      cameraPosStr,
      targetPosStr,
    ].join('|');

    final String initialUrl = "http://127.0.0.1:8080/assets/web_viewer/index.html#${Uri.encodeComponent(config)}";

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(initialUrl),
          ),
          initialSettings: InAppWebViewSettings(
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            javaScriptEnabled: true,
            transparentBackground: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            supportZoom: false,
            cacheEnabled: true, // Enable cache for faster startup
            disableContextMenu: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
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
              callback: (args) async {
                debugPrint("3D Viewer: Load Complete");
                // Wait for a small delay to ensure the browser has actually rendered the first frame
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) {
                  setState(() => isLoadingModel = false);
                }
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadError',
              callback: (args) {
                debugPrint("3D Viewer Error: ${args[0]}");
                if (mounted) {
                  setState(() => isLoadingModel = false);
                }
                // You could show a snackbar or error widget here
              },
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
        ),
        if (widget.customLoader != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !isLoadingModel,
              child: AnimatedOpacity(
                opacity: isLoadingModel ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: widget.customLoader!,
              ),
            ),
          ),
      ],
    );
  }

  void _sendModelData() {
    if (webViewController == null) return;

    String path = widget.assetPath;
    final bool isRemote = path.startsWith('http://') || path.startsWith('https://');
    
    if (!isRemote) {
      // Local assets are served from http://127.0.0.1:8080/
      // Since index.html is at /assets/web_viewer/index.html,
      // a model at /assets/animation/girl.glb is at "../../animation/girl.glb" relative to index.html
      if (!path.startsWith('/')) {
        path = "/$path";
      }
      // Use absolute path for the localhost server to avoid confusion
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
      source: "if(window.loadModelWithConfig) window.loadModelWithConfig('$path', '$hexColor', ${widget.initialZoom}, ${widget.enableZoom}, ${widget.autoPlay}, $cameraPosJs, $targetPosJs, ${widget.enableRotate}, ${widget.enablePan}, $showNativeLoader, ${widget.minZoom}, ${widget.maxZoom}, ${widget.enableBoundaries});",
    );
  }
}
