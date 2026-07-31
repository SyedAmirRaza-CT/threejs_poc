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
  final double? minPolarAngle;
  final double? maxPolarAngle;
  final double? minAzimuthalAngle;
  final double? maxAzimuthalAngle;

  const ThreeDRotationLimits({
    this.minPolarAngle,
    this.maxPolarAngle,
    this.minAzimuthalAngle,
    this.maxAzimuthalAngle,
  });

  double? _toRad(double? degrees) =>
      degrees != null ? degrees * (math.pi / 180.0) : null;

  double? get minPolarRad => _toRad(minPolarAngle);
  double? get maxPolarRad => _toRad(maxPolarAngle);
  double? get minAzimuthalRad => _toRad(minAzimuthalAngle);
  double? get maxAzimuthalRad => _toRad(maxAzimuthalAngle);
}

class ThreeDZoomConfig {
  /// The starting zoom level. 1.0 is standard fit.
  final double initialZoom;

  /// Minimum zoom-out level (e.g. 0.5 allows zooming out to half size).
  final double minZoom;

  /// Maximum zoom-in level (e.g. 5.0 allows zooming in 5x closer).
  final double maxZoom;

  /// Whether pinch-to-zoom is enabled.
  final bool enableZoom;

  const ThreeDZoomConfig({
    this.initialZoom = 1.0,
    this.minZoom = 0.5,
    this.maxZoom = 5.0,
    this.enableZoom = true,
  }) : assert(initialZoom >= minZoom && initialZoom <= maxZoom,
            'initialZoom must be between minZoom and maxZoom');

  /// Creates a copy of this config but with the given fields replaced with the new values.
  ThreeDZoomConfig copyWith({
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    bool? enableZoom,
  }) {
    return ThreeDZoomConfig(
      initialZoom: initialZoom ?? this.initialZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      enableZoom: enableZoom ?? this.enableZoom,
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
    this.enablePan = false,
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
    if (mounted) {
      setState(() => isServerRunning = true);
    }
  }

  void _toggleAnimation(bool play) {
    webViewController?.evaluateJavascript(source: "window.toggleAnimation($play);");
  }

  void _setAnimationProgress(String name, double progress) {
    webViewController?.evaluateJavascript(source: "window.setAnimationProgress('$name', $progress);");
  }

  void _setAnimationTime(String name, double time) {
    webViewController?.evaluateJavascript(source: "window.setAnimationTime('$name', $time);");
  }

  @override
  Widget build(BuildContext context) {
    if (!isServerRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    String path = widget.assetPath;
    final bool isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (!isRemote) {
      if (!path.startsWith('/')) path = "/$path";
      path = "http://127.0.0.1:8080$path";
    }

    String hexColor = widget.backgroundColor == Colors.transparent 
        ? 'transparent' 
        : '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    String cameraPosStr = widget.initialCameraPosition?.join(',') ?? "null";
    String targetPosStr = widget.initialTargetPosition?.join(',') ?? "null";

    // Build configuration hash (17 parameters)
    final String config = [
      path,
      hexColor,
      widget.zoomConfig.initialZoom,
      widget.autoPlay,
      widget.zoomConfig.minZoom,
      widget.zoomConfig.maxZoom,
      widget.enableBoundaries,
      widget.zoomConfig.enableZoom,
      widget.enableRotate,
      widget.enablePan,
      widget.customLoader == null, // showNativeLoader
      cameraPosStr,
      targetPosStr,
      widget.rotationLimits?.minPolarRad ?? "null",
      widget.rotationLimits?.maxPolarRad ?? "null",
      widget.rotationLimits?.minAzimuthalRad ?? "null",
      widget.rotationLimits?.maxAzimuthalRad ?? "null",
    ].join('|');

    final String initialUrl = "http://127.0.0.1:8080/assets/web_viewer/index.html#${Uri.encodeComponent(config)}";

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
            controller.addJavaScriptHandler(
              handlerName: 'onViewerReady',
              callback: (args) => _sendModelData(),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadStart',
              callback: (args) => setState(() => isLoadingModel = true),
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadComplete',
              callback: (args) async {
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) setState(() => isLoadingModel = false);
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'onLoadError',
              callback: (args) {
                if (mounted) setState(() => isLoadingModel = false);
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'onAnimationsLoaded',
              callback: (args) {
                final List<dynamic> anims = args[0] as List<dynamic>;
                widget.onAnimationsLoaded?.call(anims.map((e) => ThreeDAnimation.fromMap(e as Map)).toList());
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
      if (!path.startsWith('/')) path = "/$path";
      path = "http://127.0.0.1:8080$path";
    }

    String hexColor = widget.backgroundColor == Colors.transparent 
        ? 'transparent' 
        : '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    
    String cameraPosStr = widget.initialCameraPosition?.join(',') ?? "null";
    String targetPosStr = widget.initialTargetPosition?.join(',') ?? "null";

    webViewController?.evaluateJavascript(
      source: "if(window.loadModelWithConfig) window.loadModelWithConfig('$path', '$hexColor', ${widget.zoomConfig.initialZoom}, ${widget.zoomConfig.enableZoom}, ${widget.autoPlay}, '$cameraPosStr', '$targetPosStr', ${widget.enableRotate}, ${widget.enablePan}, ${widget.customLoader == null}, ${widget.zoomConfig.minZoom}, ${widget.zoomConfig.maxZoom}, ${widget.enableBoundaries}, '${widget.rotationLimits?.minPolarRad ?? "null"}', '${widget.rotationLimits?.maxPolarRad ?? "null"}', '${widget.rotationLimits?.minAzimuthalRad ?? "null"}', '${widget.rotationLimits?.maxAzimuthalRad ?? "null"}');",
    );
  }
}
