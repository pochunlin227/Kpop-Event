/// 資料模型:SEVENTEEN 成員與生日咖啡廳活動
library;

import 'package:flutter/material.dart';

class Member {
  final String id;
  final String nameEn;
  final String nameKo;
  final String nameZh;
  final int birthMonth;
  final int birthDay;
  final Color color;

  const Member({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.nameZh,
    required this.birthMonth,
    required this.birthDay,
    required this.color,
  });

  /// 下一次生日(含今天)
  DateTime nextBirthday(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    var next = DateTime(from.year, birthMonth, birthDay);
    if (next.isBefore(today)) {
      next = DateTime(from.year + 1, birthMonth, birthDay);
    }
    return next;
  }

  int daysUntilBirthday(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    return nextBirthday(from).difference(today).inDays;
  }
}

/// 地區代碼 → 顯示名稱
const Map<String, String> kRegionNames = {
  'TW': '台灣',
  'KR': '韓國',
  'US': '美國',
  'SG': '新加坡',
  'JP': '日本',
};

String regionLabel(String code) => kRegionNames[code] ?? code;

class CafeEvent {
  final String id;
  final String title;
  final String? memberId;
  final String? region; // TW / KR / null
  final String status; // candidate / confirmed
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final DateTime? signupStart;
  final DateTime? signupEnd;
  final String? location;
  final String sourceUrl;
  final String source; // threads / instagram / news / web
  final DateTime? foundAt;

  const CafeEvent({
    required this.id,
    required this.title,
    this.memberId,
    this.region,
    required this.status,
    this.eventStart,
    this.eventEnd,
    this.signupStart,
    this.signupEnd,
    this.location,
    required this.sourceUrl,
    required this.source,
    this.foundAt,
  });

  factory CafeEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? s) => s == null ? null : DateTime.tryParse(s);
    return CafeEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      memberId: json['member'] as String?,
      region: json['region'] as String?,
      status: (json['status'] as String?) ?? 'candidate',
      eventStart: parse(json['eventStart'] as String?),
      eventEnd: parse(json['eventEnd'] as String?),
      signupStart: parse(json['signupStart'] as String?),
      signupEnd: parse(json['signupEnd'] as String?),
      location: json['location'] as String?,
      sourceUrl: json['sourceUrl'] as String,
      source: (json['source'] as String?) ?? 'web',
      foundAt: parse(json['foundAt'] as String?),
    );
  }

  /// 結束日以「當天結束」計算(日期含當日)
  DateTime? get _effectiveEnd => eventEnd?.add(const Duration(days: 1));
  DateTime? get _effectiveSignupEnd => signupEnd?.add(const Duration(days: 1));

  /// 活動目前的階段標籤
  ({String label, Color color}) statusBadge(DateTime now) {
    if (signupStart != null && now.isBefore(signupStart!)) {
      return (label: '報名即將開始', color: Colors.orangeAccent);
    }
    if (signupStart != null &&
        _effectiveSignupEnd != null &&
        !now.isBefore(signupStart!) &&
        now.isBefore(_effectiveSignupEnd!)) {
      return (label: '報名中', color: Colors.greenAccent);
    }
    if (_effectiveEnd != null && !now.isBefore(_effectiveEnd!)) {
      return (label: '已結束', color: Colors.white38);
    }
    if (eventStart != null &&
        _effectiveEnd != null &&
        !now.isBefore(eventStart!) &&
        now.isBefore(_effectiveEnd!)) {
      return (label: '活動進行中', color: Colors.pinkAccent);
    }
    if (eventStart != null && now.isBefore(eventStart!)) {
      return (label: '即將舉辦', color: Colors.lightBlueAccent);
    }
    return (label: '待確認詳情', color: Colors.blueGrey);
  }

  /// 排序權重:進行中 0 > 即將開始 1 > 待確認 2 > 已結束 3
  int sortBucket(DateTime now) {
    if (_effectiveEnd != null && !now.isBefore(_effectiveEnd!)) return 3;
    if (eventStart == null) return 2;
    if (!now.isBefore(eventStart!)) return 0;
    return 1;
  }
}
