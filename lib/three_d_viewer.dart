import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class ThreeDAnimation {
  final String name;
  final double duration;
  ThreeDAnimation({required this.name, required this.duration});
  factory ThreeDAnimation.fromMap(Map map) => ThreeDAnimation(
      name: map['name'] as String,
      duration: (map['duration'] as num).toDouble());
}

class ThreeDRotationLimits {
  final double? minVerticalAngle;
  final double? maxVerticalAngle;
  final double? minHorizontalAngle;
  final double? maxHorizontalAngle;
  const ThreeDRotationLimits({this.minVerticalAngle, this.maxVerticalAngle, this.minHorizontalAngle, this.maxHorizontalAngle});
  double? _toRad(double? deg) => deg != null ? deg * (math.pi / 180.0) : null;
  double? get minVerticalRad => _toRad(minVerticalAngle);
  double? get maxVerticalRad => _toRad(maxVerticalAngle);
  double? get minHorizontalRad => _toRad(minHorizontalAngle);
  double? get maxHorizontalRad => _toRad(maxHorizontalAngle);
}

class ThreeDZoomConfig {
  final double initialZoom;
  final double? minZoom;
  final double? maxZoom;
  final bool enableZoom;
  const ThreeDZoomConfig({this.initialZoom = 1.0, this.minZoom, this.maxZoom, this.enableZoom = true});
}

class ThreeDAutoRotateConfig {
  final bool autoRotate;
  final double speed;
  final bool clockwise;
  const ThreeDAutoRotateConfig({this.autoRotate = false, this.speed = 2.0, this.clockwise = true});
}

class ThreeDDebugConfig {
  final bool showGrid;
  final bool showAxes;
  final bool showTargetMarker;
  final bool showModelMarker;
  final bool showClickMarker;
  final bool showCameraInfo;
  final bool showHotspots;
  final bool showInteractiveParts;

  const ThreeDDebugConfig({
    this.showGrid = false,
    this.showAxes = false,
    this.showTargetMarker = false,
    this.showModelMarker = false,
    this.showClickMarker = false,
    this.showCameraInfo = false,
    this.showHotspots = false,
    this.showInteractiveParts = false,
  });

  factory ThreeDDebugConfig.all() => const ThreeDDebugConfig(
        showGrid: true,
        showAxes: true,
        showTargetMarker: true,
        showModelMarker: true,
        showClickMarker: true,
        showCameraInfo: true,
        showHotspots: true,
        showInteractiveParts: true,
      );
}

class ThreeDHotspot {
  final String id;
  final List<double> position;
  final String? label;
  final Color color;
  final double size;

  const ThreeDHotspot({
    required this.id,
    required this.position,
    this.label,
    this.color = Colors.yellow,
    this.size = 20.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pos': position,
        'label': label,
        'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'size': size,
      };
}

class ThreeDEnvironmentConfig {
  final String? hdrUrl;
  final double intensity;
  const ThreeDEnvironmentConfig({this.hdrUrl, this.intensity = 1.0});
}

class ThreeDViewerController {
  _ThreeDViewerState? _state;
  void toggleAnimation(bool play) => _state?._toggleAnimation(play);
  void setAnimationProgress(String name, double progress) => _state?._setAnimationProgress(name, progress);
  void setAutoRotate(bool enable, {double speed = 2.0, bool clockwise = true}) => _state?._setAutoRotate(enable, speed: speed, clockwise: clockwise);
  void goToView(double h, double v, double d, {double durationMillis = 1000}) => _state?._goToView(h, v, d, durationMillis);
  void setMaterialColor(String meshName, Color color) => _state?._setMaterialColor(meshName, color);
  void launchAR() => _state?._launchAR();
  void reset() => _state?._reset();
}

class ThreeDViewer extends StatefulWidget {
  final String assetPath;
  final Color backgroundColor;
  final ThreeDZoomConfig zoomConfig;
  final ThreeDAutoRotateConfig autoRotateConfig;
  final ThreeDEnvironmentConfig? environmentConfig;
  final ThreeDDebugConfig debugConfig;
  final List<ThreeDHotspot>? hotspots;
  final bool enableRotate;
  final bool enablePan;
  final bool enableBoundaries;
  final bool autoCenter;
  final bool showHotspots;
  final bool enableDoubleTapZoom;
  final ThreeDRotationLimits? rotationLimits;
  final List<double>? initialCameraPosition;
  final List<double>? initialTargetPosition;
  final bool autoPlay;
  final ThreeDViewerController? controller;
  final Function(List<ThreeDAnimation> animations)? onAnimationsLoaded;
  final Function(String id)? onHotspotTapped;
  final Function(String name)? onObjectDoubleTapped;
  final Widget? customLoader;

  const ThreeDViewer({
    super.key,
    required this.assetPath,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.zoomConfig = const ThreeDZoomConfig(),
    this.autoRotateConfig = const ThreeDAutoRotateConfig(),
    this.debugConfig = const ThreeDDebugConfig(),
    this.environmentConfig,
    this.hotspots,
    this.enableRotate = true,
    this.enablePan = true,
    this.enableBoundaries = true,
    this.autoCenter = false,
    this.showHotspots = false,
    this.enableDoubleTapZoom = false,
    this.rotationLimits,
    this.initialCameraPosition,
    this.initialTargetPosition,
    this.autoPlay = true,
    this.controller,
    this.onAnimationsLoaded,
    this.onHotspotTapped,
    this.onObjectDoubleTapped,
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
  bool isInitialLoadSent = false;
  final Key _webViewKey = UniqueKey();

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
  void _setAnimationProgress(String name, double p) => webViewController?.evaluateJavascript(source: "window.setAnimationProgress('$name', $p);");
  void _setAutoRotate(bool enable, {double speed = 2.0, bool clockwise = true}) {
    double finalSpeed = clockwise ? speed : -speed;
    webViewController?.evaluateJavascript(source: "window.setAutoRotate($enable, $finalSpeed);");
  }
  void _goToView(double h, double v, double d, double dur) => webViewController?.evaluateJavascript(source: "window.goToView($h, $v, $d, $dur);");
  void _setMaterialColor(String name, Color c) {
    String hex = "#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
    webViewController?.evaluateJavascript(source: "window.setMaterialColor('$name', '$hex');");
  }
  void _launchAR() => webViewController?.evaluateJavascript(source: "window.launchAR();");
  void _reset() => webViewController?.evaluateJavascript(source: "window.resetToInitial();");

  List<dynamic> _buildParams() {
    String path = widget.assetPath;
    if (!path.startsWith('http')) {
      if (!path.startsWith('/')) path = "/$path";
      path = "http://127.0.0.1:8080$path";
    }
    String hex = widget.backgroundColor == Colors.transparent ? 'transparent' : '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    double initialSpeed = widget.autoRotateConfig.clockwise ? widget.autoRotateConfig.speed : -widget.autoRotateConfig.speed;
    return [
      path, hex, widget.zoomConfig.initialZoom, widget.autoPlay, 
      widget.zoomConfig.minZoom ?? "null", widget.zoomConfig.maxZoom ?? "null", 
      widget.enableBoundaries, widget.zoomConfig.enableZoom, widget.enableRotate, widget.enablePan, 
      widget.customLoader == null, 
      widget.initialCameraPosition?.join(',') ?? "null", 
      widget.initialTargetPosition?.join(',') ?? "null",
      widget.rotationLimits?.minVerticalAngle ?? "null",
      widget.rotationLimits?.maxVerticalAngle ?? "null",
      widget.rotationLimits?.minHorizontalAngle ?? "null",
      widget.rotationLimits?.maxHorizontalAngle ?? "null",
      widget.autoCenter,
      widget.autoRotateConfig.autoRotate,
      initialSpeed,
      widget.environmentConfig?.hdrUrl ?? "null",
      widget.environmentConfig?.intensity ?? 1.0,
      jsonEncode(widget.hotspots?.map((e) => e.toMap()).toList() ?? []),
      widget.debugConfig.showGrid,
      widget.debugConfig.showAxes,
      widget.debugConfig.showTargetMarker,
      widget.debugConfig.showModelMarker,
      widget.debugConfig.showClickMarker,
      widget.debugConfig.showCameraInfo,
      widget.debugConfig.showHotspots || widget.showHotspots,
      widget.enableDoubleTapZoom,
      widget.debugConfig.showInteractiveParts,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!isServerRunning) return const Center(child: CircularProgressIndicator());
    final String initialUrl = "http://127.0.0.1:8080/assets/web_viewer/index.html";

    return Stack(
      children: [
        InAppWebView(
          key: _webViewKey,
          initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            transparentBackground: true,
            supportZoom: false,
            useShouldOverrideUrlLoading: true,
            disableContextMenu: true,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri != null && (uri.toString().endsWith('.glb') || uri.toString().endsWith('.usdz'))) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onWebViewCreated: (controller) {
            webViewController = controller;
            controller.addJavaScriptHandler(handlerName: 'onViewerReady', callback: (args) {
              if (!isInitialLoadSent) {
                isInitialLoadSent = true;
                _sendModelData();
              }
            });
            controller.addJavaScriptHandler(handlerName: 'onLoadStart', callback: (args) => setState(() => isLoadingModel = true));
            controller.addJavaScriptHandler(handlerName: 'onLoadComplete', callback: (args) async {
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) setState(() => isLoadingModel = false);
            });
            controller.addJavaScriptHandler(handlerName: 'onLoadError', callback: (args) { if (mounted) setState(() => isLoadingModel = false); });
            controller.addJavaScriptHandler(handlerName: 'onAnimationsLoaded', callback: (args) {
              final List<dynamic> anims = args[0] as List<dynamic>;
              widget.onAnimationsLoaded?.call(anims.map((e) => ThreeDAnimation.fromMap(e as Map)).toList());
            });
            controller.addJavaScriptHandler(handlerName: 'onHotspotTapped', callback: (args) => widget.onHotspotTapped?.call(args[0].toString()));
            controller.addJavaScriptHandler(handlerName: 'onObjectDoubleTapped', callback: (args) => widget.onObjectDoubleTapped?.call(args[0].toString()));
            controller.addJavaScriptHandler(handlerName: 'onDebugPoint', callback: (args) {
              if (widget.debugConfig.showCameraInfo) {
                final data = args[0] as Map;
                final x = (data['x'] as num).toStringAsFixed(3);
                final y = (data['y'] as num).toStringAsFixed(3);
                final z = (data['z'] as num).toStringAsFixed(3);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: SelectableText("Coord: [$x, $y, $z]"), duration: const Duration(seconds: 5)));
              }
            });

            controller.addJavaScriptHandler(
              handlerName: 'onLaunchAR',
              callback: (args) async {
                final modelUrl = args[0] as String;
                final isAndroid = Theme.of(context).platform == TargetPlatform.android;
                if (isAndroid) {
                  final arUrl = "https://arvr.google.com/scene-viewer/1.0?file=$modelUrl&mode=ar_only";
                  await launchUrl(Uri.parse(arUrl), mode: LaunchMode.externalApplication);
                } else {
                  webViewController?.evaluateJavascript(source: "window.triggerAppleAR('$modelUrl');");
                }
              },
            );
          },
          onConsoleMessage: (controller, msg) => debugPrint("3D JS: ${msg.message}"),
        ),
        if (widget.customLoader != null)
          Positioned.fill(child: IgnorePointer(ignoring: !isLoadingModel, child: AnimatedOpacity(opacity: isLoadingModel ? 1.0 : 0.0, duration: const Duration(milliseconds: 500), child: widget.customLoader!))),
      ],
    );
  }

  void _sendModelData() {
    final p = _buildParams().map((e) => (e is String && e != "null") ? "'$e'" : e.toString()).join(', ');
    webViewController?.evaluateJavascript(source: "if(window.loadModelWithConfig) window.loadModelWithConfig($p);");
  }
}
