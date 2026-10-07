import 'package:flutter_test/flutter_test.dart';
import 'package:video_interview_project/main.dart';

void main() {
  testWidgets('OneGlobe app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const OneGlobeApp());

    expect(find.text('Video Interview'), findsOneWidget);
  });
}