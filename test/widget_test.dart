import 'package:flutter_test/flutter_test.dart';

import 'package:tiptap/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TiptapApp());
    await tester.pumpAndSettle();
    expect(find.byType(TiptapApp), findsOneWidget);
  });
}
