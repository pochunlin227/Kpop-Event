/// 活動資料來源:內建資料檔 + 可選的遠端更新網址
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'models.dart';

/// 之後把爬蟲放上排程(例如 GitHub Actions)後,
/// 填入 events.json 的公開網址即可讓 App 線上更新。
const String kRemoteEventsUrl = '';

class EventStore {
  /// 讀取活動:優先抓遠端,失敗或未設定則用內建資料
  static Future<({List<CafeEvent> events, DateTime? updatedAt, bool fromRemote})>
      load({bool tryRemote = true}) async {
    if (tryRemote && kRemoteEventsUrl.isNotEmpty) {
      try {
        final resp = await http
            .get(Uri.parse(kRemoteEventsUrl))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final p = _parse(utf8.decode(resp.bodyBytes));
          return (events: p.events, updatedAt: p.updatedAt, fromRemote: true);
        }
      } catch (_) {
        // 離線或抓取失敗 → 改用內建資料
      }
    }
    final raw = await rootBundle.loadString('data/events.json');
    final p = _parse(raw);
    return (events: p.events, updatedAt: p.updatedAt, fromRemote: false);
  }

  static ({List<CafeEvent> events, DateTime? updatedAt}) _parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final events = (json['events'] as List<dynamic>)
        .map((e) => CafeEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    // 進行中 > 即將開始 > 待確認 > 已結束;同組內活動日近的在前、新發現的在前
    final now = DateTime.now();
    events.sort((a, b) {
      final bucket = a.sortBucket(now).compareTo(b.sortBucket(now));
      if (bucket != 0) return bucket;
      if (a.eventStart != null && b.eventStart != null) {
        return a.eventStart!.compareTo(b.eventStart!);
      }
      final at = a.foundAt ?? DateTime(2000);
      final bt = b.foundAt ?? DateTime(2000);
      return bt.compareTo(at);
    });
    final updatedAt = json['updatedAt'] == null
        ? null
        : DateTime.tryParse(json['updatedAt'] as String);
    return (events: events, updatedAt: updatedAt);
  }
}
