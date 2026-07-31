import 'dart:math' as math;
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

class ThreeDRotationLimits {
  final double? minVerticalAngle;
  final double? maxVerticalAngle;
  final double? minHorizontalAngle;
  final double? maxHorizontalAngle;

  const ThreeDRotationLimits({
    this.minVerticalAngle,
    this.maxVerticalAngle,
    this.minHorizontalAngle,
    this.maxHorizontalAngle,
  });
}

class ThreeDZoomConfig {
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool enableZoom;

  const ThreeDZoomConfig({
    this.initialZoom = 1.0,
    this.minZoom = 0.5,
    this.maxZoom = 5.0,
    this.enableZoom = true,
  }) : assert(initialZoom >= minZoom && initialZoom <= maxZoom,
            'initialZoom must be between minZoom and maxZoom');
}

class ThreeDViewerController {
  _ThreeDViewerState? _state;
  void toggleAnimation(bool play) => _state?._toggleAnimation(play);
  void setAnimationProgress(String name, double progress) => _state?._setAnimationProgress(name, progress);
}

class ThreeDViewer extends StatefulWidget {
  final String assetPath;
  final Color backgroundColor;
  final ThreeDZoomConfig zoomConfig;
  final bool enableRotate;
  final bool enablePan;
  final bool enableBoundaries;
  final ThreeDRotationLimits? rotationLimits;
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
    this.zoomConfig = const ThreeDZoomConfig(),
    this.enableRotate = true,
    this.enablePan = true,
    this.enableBoundaries = true,
    this.rotationLimits,
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
    if (mounted) setState(() => isServerRunning = true);
  }

  void _toggleAnimation(bool play) => webViewController?.evaluateJavascript(source: "window.toggleAnimation($play);");
  void _setAnimationProgress(String name, double progress) => webViewController?.evaluateJavascript(source: "window.setAnimationProgress('$name', $progress);");

  List<dynamic> _buildParams() {
    String path = widget.assetPath;
    if (!path.startsWith('http')) {
      if (!path.startsWith('/')) path = "/$path";
      path = "http://127.0.0.1:8080$path";
    }

    String hexColor = widget.backgroundColor == Colors.transparent 
        ? 'transparent' 
        : '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    return [
      path,                                     // 0
      hexColor,                                 // 1
      widget.zoomConfig.initialZoom,            // 2
      widget.autoPlay,                          // 3
      widget.zoomConfig.minZoom,                // 4
      widget.zoomConfig.maxZoom,                // 5
      widget.enableBoundaries,                  // 6
      widget.zoomConfig.enableZoom,             // 7
      widget.enableRotate,                      // 8
      widget.enablePan,                         // 9
      widget.customLoader == null,              // 10
      widget.initialCameraPosition?.join(',') ?? "null", // 11
      widget.initialTargetPosition?.join(',') ?? "null", // 12
      widget.rotationLimits?.minVerticalAngle ?? "null", // 13 (Degrees)
      widget.rotationLimits?.maxVerticalAngle ?? "null", // 14 (Degrees)
      widget.rotationLimits?.minHorizontalAngle ?? "null", // 15 (Degrees)
      widget.rotationLimits?.maxHorizontalAngle ?? "null", // 16 (Degrees)
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!isServerRunning) return const Center(child: CircularProgressIndicator());

    final String configString = _buildParams().join('|');
    final String initialUrl = "http://127.0.0.1:8080/assets/web_viewer/index.html#${Uri.encodeComponent(configString)}";

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            transparentBackground: true,
            supportZoom: false,
            cacheEnabled: true,
            disableContextMenu: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
            controller.addJavaScriptHandler(handlerName: 'onViewerReady', callback: (args) => _sendModelData());
            controller.addJavaScriptHandler(handlerName: 'onLoadStart', callback: (args) => setState(() => isLoadingModel = true));
            controller.addJavaScriptHandler(handlerName: 'onLoadComplete', callback: (args) async {
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) setState(() => isLoadingModel = false);
            });
            controller.addJavaScriptHandler(handlerName: 'onLoadError', callback: (args) => setState(() => isLoadingModel = false));
            controller.addJavaScriptHandler(handlerName: 'onAnimationsLoaded', callback: (args) {
              final List<dynamic> anims = args[0] as List<dynamic>;
              widget.onAnimationsLoaded?.call(anims.map((e) => ThreeDAnimation.fromMap(e as Map)).toList());
            });
          },
          onConsoleMessage: (controller, consoleMessage) => debugPrint("3D JS: ${consoleMessage.message}"),
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
    final params = _buildParams().map((e) => e is String ? "'$e'" : e.toString()).join(', ');
    webViewController?.evaluateJavascript(source: "if(window.loadModelWithConfig) window.loadModelWithConfig($params);");
  }
}
