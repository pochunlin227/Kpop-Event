import 'package:flutter_test/flutter_test.dart';

import 'package:kpop_event/main.dart';

void main() {
  testWidgets('App 可以啟動並顯示標題', (WidgetTester tester) async {
    await tester.pumpWidget(const SvtCafeApp());
    expect(find.textContaining('生咖雷達'), findsOneWidget);
  });
}
