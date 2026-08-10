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

Member? memberById(String? id) {
  if (id == null) return null;
  for (final m in kMembers) {
    if (m.id == id) return m;
  }
  return null;
}
