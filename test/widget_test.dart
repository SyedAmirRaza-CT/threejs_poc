import 'package:flutter_test/flutter_test.dart';
import 'package:threejs_poc/main.dart';

void main() {
  testWidgets('Dashboard renders successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the dashboard header is present.
    expect(find.text('3D Model Dashboard'), findsOneWidget);
    expect(find.text('Select a model to view:'), findsOneWidget);

    // Verify that the model cards are rendered.
    expect(find.text('Girl Model'), findsOneWidget);
    expect(find.text('Fox Model'), findsOneWidget);
    expect(find.text('Blood Vessel'), findsOneWidget);
    expect(find.text('BrainStem (Remote)'), findsOneWidget);
  });
}
