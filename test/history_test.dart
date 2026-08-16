import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kpop_event/main.dart';

Future<void> settle(WidgetTester tester) async {
  // 星空背景是無限動畫,不能用 pumpAndSettle
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('歷史活動是獨立子頁,可用年份篩選', (WidgetTester tester) async {
    await tester.pumpWidget(const SvtCafeApp());
    await settle(tester);

    // 首頁不顯示已結束活動(8/9 結束的 Aug95 台北生咖)
    expect(find.textContaining('Aug95'), findsNothing);

    // 捲到歷史活動入口
    final entry = find.textContaining('歷史活動');
    await tester.scrollUntilVisible(entry, 400,
        scrollable: find.byType(Scrollable).first);
    await settle(tester);
    // 直接觸發入口的 onTap:畫面底部邊緣的 hit-test 在測試環境不可靠,
    // 這裡要驗證的是導頁與年份篩選邏輯
    final ink = tester.widget<InkWell>(
        find.ancestor(of: entry, matching: find.byType(InkWell)).first);
    ink.onTap!();
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
