import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquafeed/main.dart';

void main() {
  testWidgets('AquaFeed UI test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AquaFeedApp()));

    // Verify that AquaFeed title is present
    expect(find.text('AquaFeed'), findsOneWidget);
  });
}
