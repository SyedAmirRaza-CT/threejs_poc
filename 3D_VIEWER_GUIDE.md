# 3D Viewer Full Guide

This guide explains how to use all features of the Flutter `ThreeDViewer` widget, from positioning to animation control and offline use.

## 1. Positioning and Camera [X, Y, Z]

Three.js uses a 3D Cartesian coordinate system. Every position is defined by three numbers:

### X-Axis (Horizontal)
*   **Positive (+X):** Right.
*   **Negative (-X):** Left.
*   **Example:** `[5, 0, 0]` puts the camera on the right.

### Y-Axis (Vertical)
*   **Positive (+Y):** Up.
*   **Negative (-Y):** Down.
*   **Example:** `[0, 10, 0]` gives a "Bird's Eye View".

### Z-Axis (Depth)
*   **Positive (+Z):** Back (Zoom out).
*   **Negative (-Z):** Front (Into the screen).
*   **Example:** `[0, 0, 5]` is standard "Front View".

---

## 2. Interaction and Constraints

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enableZoom` | `bool` | `true` | Allows pinch-to-zoom. |
| `enableRotate` | `bool` | `true` | Allows swiping to spin the model. |
| `enablePan` | `bool` | `true` | Allows moving the model sideways. |
| `enableBoundaries` | `bool` | `true` | Prevents the model from being panned off-screen. |
| `initialZoom` | `double` | `1.0` | 1.0 is fit-to-screen. 2.0 is double size. |
| `minZoom` | `double` | `0.5` | Minimum zoom-out level. |
| `maxZoom` | `double` | `10.0` | Maximum zoom-in level. |

---

## 3. Animation Control

The viewer automatically detects all animations in your GLB file.

### Automatic Start
Use `autoPlay: true` to start the first animation immediately.

### Manual Control (Scrubbing)
1.  **Initialize a Controller:**
    ```dart
    final ThreeDViewerController _controller = ThreeDViewerController();
    ```
2.  **Pass it to the widget:**
    ```dart
    ThreeDViewer(
      controller: _controller,
      onAnimationsLoaded: (animations) {
        // 'animations' is a list of all names found in the file
      },
    )
    ```
3.  **Control via slider:**
    ```dart
    _controller.setAnimationProgress("AnimationName", 0.5); // Jump to 50% frame
    ```

---

## 4. UI Customization

### Transparency
To make the background transparent and show your Flutter UI behind the model:
```dart
ThreeDViewer(
  backgroundColor: Colors.transparent,
)
```

### Custom Loader
Replace the default blue spinner with your own Flutter widget:
```dart
ThreeDViewer(
  customLoader: Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        Text("Loading 3D Data..."),
      ],
    ),
  ),
)
```

---

## 5. Assets and Offline Use

### Local Assets
Files must be placed in `assets/animation/` and registered in `pubspec.yaml`.
*   **GLB:** Single file, recommended.
*   **glTF:** Requires `.gltf` + `.bin` + textures.

### Remote URLs
Simply pass a full URL:
```dart
ThreeDViewer(
  assetPath: 'https://myserver.com/model.glb',
)
```
*Note: Your server must have **CORS** enabled (`Access-Control-Allow-Origin: *`).*

### Offline Mode
The Three.js engine and all scripts are stored in `assets/web_viewer/`. This ensures the viewer works perfectly without an internet connection for local models.

---

## 6. Pro Tips for Perfect Framing

| View Type | Camera Position | Target Position | Description |
| :--- | :--- | :--- | :--- |
| **Front Center** | `[0, 0, 5]` | `[0, 0, 0]` | Standard straight-on view. |
| **Angled High** | `[5, 5, 5]` | `[0, 0, 0]` | Looking down from the corner. |
| **Focus on Head** | `[0, 1.8, 3]` | `[0, 1.8, 0]` | Camera at head-height, looking at face. |
