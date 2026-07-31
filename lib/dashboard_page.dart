import 'package:flutter/material.dart';
import 'three_d_viewer_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a model to view:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildModelCard(
              context,
              title: 'Girl Model',
              icon: Icons.person,
              color: Colors.pinkAccent,
              path: 'assets/animation/girl.glb',
              zoom: 0.5,
              autoPlay: false, // Start girl paused
            ),
            const SizedBox(height: 20),
            _buildModelCard(
              context,
              title: 'Fox Model',
              icon: Icons.pets,
              color: Colors.orangeAccent,
              path: 'assets/animation/Fox.glb',
              zoom: 1.0,
              autoPlay: true, // Start fox playing
            ),
            const SizedBox(height: 20),
            _buildModelCard(
              context,
              title: 'Blood Vessel 2',
              icon: Icons.biotech,
              color: Colors.redAccent,
              path: 'assets/animation/blood_vesel.glb',
              zoom: 1.0,
              autoPlay: false,
            ),
            const SizedBox(height: 20),
            _buildModelCard(
              context,
              title: 'BrainStem (Remote)',
              icon: Icons.psychology,
              color: Colors.blueGrey,
              path: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/BrainStem/glTF-Binary/BrainStem.glb',
              zoom: 1,
              autoPlay: true,
              cameraPosition: [5, 2, 1], // Angled view
              targetPosition: [0, 1, 0], // Focus on the model's head
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String path,
    double zoom = 1.0,
    bool autoPlay = true,
    List<double>? cameraPosition,
    List<double>? targetPosition,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // UniqueKey ensures a completely new WebView instance is created
              builder: (context) => ThreeDViewerPage(
                key: UniqueKey(), 
                modelPath: path,
                initialZoom: zoom,
                autoPlay: autoPlay,
                initialCameraPosition: cameraPosition,
                initialTargetPosition: targetPosition,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
