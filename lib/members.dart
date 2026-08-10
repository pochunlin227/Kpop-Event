/// SEVENTEEN 13 位成員資料
library;

import 'package:flutter/material.dart';
import 'models.dart';

const List<Member> kMembers = [
  Member(id: 'scoups', nameEn: 'S.Coups', nameKo: '에스쿱스', nameZh: '崔勝澈', birthMonth: 8, birthDay: 8, color: Color(0xFFE57373)),
  Member(id: 'jeonghan', nameEn: 'Jeonghan', nameKo: '정한', nameZh: '尹淨漢', birthMonth: 10, birthDay: 4, color: Color(0xFFBA68C8)),
  Member(id: 'joshua', nameEn: 'Joshua', nameKo: '조슈아', nameZh: '洪知秀', birthMonth: 12, birthDay: 30, color: Color(0xFF64B5F6)),
  Member(id: 'jun', nameEn: 'Jun', nameKo: '준', nameZh: '文俊輝', birthMonth: 6, birthDay: 10, color: Color(0xFF4DB6AC)),
  Member(id: 'hoshi', nameEn: 'Hoshi', nameKo: '호시', nameZh: '權順榮', birthMonth: 6, birthDay: 15, color: Color(0xFFFFB74D)),
  Member(id: 'wonwoo', nameEn: 'Wonwoo', nameKo: '원우', nameZh: '全圓佑', birthMonth: 7, birthDay: 17, color: Color(0xFF7986CB)),
  Member(id: 'woozi', nameEn: 'Woozi', nameKo: '우지', nameZh: '李知勳', birthMonth: 11, birthDay: 22, color: Color(0xFFF06292)),
  Member(id: 'dk', nameEn: 'DK', nameKo: '도겸', nameZh: '李碩珉', birthMonth: 2, birthDay: 18, color: Color(0xFFFFD54F)),
  Member(id: 'mingyu', nameEn: 'Mingyu', nameKo: '민규', nameZh: '金珉奎', birthMonth: 4, birthDay: 6, color: Color(0xFFA1887F)),
  Member(id: 'the8', nameEn: 'The8', nameKo: '디에잇', nameZh: '徐明浩', birthMonth: 11, birthDay: 7, color: Color(0xFF90A4AE)),
  Member(id: 'seungkwan', nameEn: 'Seungkwan', nameKo: '승관', nameZh: '夫勝寬', birthMonth: 1, birthDay: 16, color: Color(0xFF81C784)),
  Member(id: 'vernon', nameEn: 'Vernon', nameKo: '버논', nameZh: '崔韓率', birthMonth: 2, birthDay: 18, color: Color(0xFF4FC3F7)),
  Member(id: 'dino', nameEn: 'Dino', nameKo: '디노', nameZh: '李燦', birthMonth: 2, birthDay: 11, color: Color(0xFF9575CD)),
];

/// 兵役狀態(2026-08 更新;來源:Pledis 公告/媒體報導)
enum MilitaryStatus { serving, scheduled, discharged, exempt, notRequired, tba }

class MilitaryInfo {
  final MilitaryStatus status;
  final DateTime? start;
  final DateTime? end;
  final bool endEstimated; // 退伍日為推估(官方未公布)
  const MilitaryInfo(this.status, {this.start, this.end, this.endEstimated = false});
}

final Map<String, MilitaryInfo> kMilitary = {
  // 免役(膝傷判定 5 級)
  'scoups': const MilitaryInfo(MilitaryStatus.exempt),
  // 2024-09-26 入伍(社會服務),2026-06-26 退伍
  'jeonghan': MilitaryInfo(MilitaryStatus.discharged,
      start: DateTime(2024, 9, 26), end: DateTime(2026, 6, 26)),
  // 美國籍,無兵役義務
  'joshua': const MilitaryInfo(MilitaryStatus.notRequired),
  // 中國籍,無兵役義務
  'jun': const MilitaryInfo(MilitaryStatus.notRequired),
  // 現役陸軍 2025-09-16 ~ 2027-03-15
  'hoshi': MilitaryInfo(MilitaryStatus.serving,
      start: DateTime(2025, 9, 16), end: DateTime(2027, 3, 15)),
  // 社會服務 2025-04-03 ~ 2027-01-02
  'wonwoo': MilitaryInfo(MilitaryStatus.serving,
      start: DateTime(2025, 4, 3), end: DateTime(2027, 1, 2)),
  // 現役 2025-09-15 ~ 2027-03-14
  'woozi': MilitaryInfo(MilitaryStatus.serving,
      start: DateTime(2025, 9, 15), end: DateTime(2027, 3, 14)),
  // 2026-09-08 入伍(現役陸軍),退伍日推估 18 個月
  'dk': MilitaryInfo(MilitaryStatus.scheduled,
      start: DateTime(2026, 9, 8),
      end: DateTime(2028, 3, 7),
      endEstimated: true),
  // 2026-09-10 入伍(替代役),2028 年 6 月結束(日期推估)
  'mingyu': MilitaryInfo(MilitaryStatus.scheduled,
      start: DateTime(2026, 9, 10),
      end: DateTime(2028, 6, 9),
      endEstimated: true),
  // 中國籍,無兵役義務
  'the8': const MilitaryInfo(MilitaryStatus.notRequired),
  // 2026-10-26 入伍(陸軍軍樂隊),2028 年 4 月退伍(日期推估)
  'seungkwan': MilitaryInfo(MilitaryStatus.scheduled,
      start: DateTime(2026, 10, 26),
      end: DateTime(2028, 4, 25),
      endEstimated: true),
  // 2026-08-20 入伍(替代役),退伍日推估 21 個月
  'vernon': MilitaryInfo(MilitaryStatus.scheduled,
      start: DateTime(2026, 8, 20),
      end: DateTime(2028, 5, 19),
      endEstimated: true),
  // 2026-10-26 入伍(陸軍軍樂隊,與勝寬同日),2028 年 4 月退伍(日期推估)
  'dino': MilitaryInfo(MilitaryStatus.scheduled,
      start: DateTime(2026, 10, 26),
      end: DateTime(2028, 4, 25),
      endEstimated: true),
};

Member? memberById(String? id) {
  if (id == null) return null;
  for (final m in kMembers) {
    if (m.id == id) return m;
  }
  return null;
}
