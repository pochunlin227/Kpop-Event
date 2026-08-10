import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kpop_event/main.dart';

Future<void> settle(WidgetTester tester) async {
  // 星空背景是無限動畫,不能用 pumpAndSettle
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('歷史活動是獨立子頁,可用年份篩選', (WidgetTester tester) async {
    await tester.pumpWidget(const SvtCafeApp());
    await settle(tester);

    // 首頁不顯示已結束活動(8/9 結束的 Aug95 台北生咖)
    expect(find.textContaining('Aug95'), findsNothing);

    // 捲到歷史活動入口並點擊
    final entry = find.textContaining('歷史活動');
    await tester.scrollUntilVisible(entry, 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(entry);
    await settle(tester);

    // 子頁:年份篩選與已結束活動
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('全部年份'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    // 清單是延遲載入,捲動到 Aug95 那筆
    await tester.scrollUntilVisible(find.textContaining('Aug95'), 400,
        scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Aug95'), findsWidgets);

    // 點 2026 年份篩選仍看得到(活動都是 2026 年結束)
    await tester.tap(find.text('2026'));
    await settle(tester);
    await tester.scrollUntilVisible(find.textContaining('Aug95'), 400,
        scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Aug95'), findsWidgets);
  });
}
