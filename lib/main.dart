import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'event_store.dart';
import 'magic_background.dart';
import 'members.dart';
import 'models.dart';

// SEVENTEEN 應援色
const kRoseQuartz = Color(0xFFF7CAC9);
const kSerenity = Color(0xFF92A8D1);
const kGold = Color(0xFFE8C87E);

void main() {
  runApp(const SvtCafeApp());
}

class SvtCafeApp extends StatelessWidget {
  const SvtCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVT 生咖雷達',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'NotoSansTC',
        fontFamilyFallback: const ['NotoSansKR'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: kSerenity,
          brightness: Brightness.dark,
          secondary: kRoseQuartz,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const HomeScreen(),
    );
  }
}

/// 漸層發光文字(標題用)
class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final List<Color> colors;
  const GradientText(this.text,
      {super.key, this.fontSize = 18, this.colors = const [kRoseQuartz, kSerenity]});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: colors)
          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
    );
  }
}

/// 玻璃質感卡片
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? glow;
  final VoidCallback? onTap;
  const GlassCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.glow,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (glow != null)
            BoxShadow(
                color: glow!.withValues(alpha: 0.28),
                blurRadius: 18,
                spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.07),
            child: InkWell(
              onTap: onTap,
              splashColor: kSerenity.withValues(alpha: 0.15),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (glow ?? Colors.white).withValues(alpha: 0.22)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CafeEvent> _events = [];
  DateTime? _updatedAt;
  bool _loading = true;
  String? _memberFilter;
  String? _regionFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await EventStore.load();
    if (!mounted) return;
    setState(() {
      _events = result.events;
      _updatedAt = result.updatedAt;
      _loading = false;
    });
  }

  List<CafeEvent> get _filtered => _events.where((e) {
        if (_memberFilter != null && e.memberId != _memberFilter) return false;
        if (_regionFilter != null && e.region != _regionFilter) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visible =
        _filtered.where((e) => e.sortBucket(now) != 3).toList();
    final ended = _filtered.where((e) => e.sortBucket(now) == 3).toList();
    return MagicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const GradientText('💎 SVT 生咖雷達',
              fontSize: 22, colors: [kRoseQuartz, kSerenity, kGold]),
          actions: [
            IconButton(
              tooltip: '重新整理',
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kRoseQuartz))
            : RefreshIndicator(
                color: kRoseQuartz,
                backgroundColor: const Color(0xFF2A2145),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    _sectionTitle('生日倒數'),
                    _BirthdayStrip(now: now),
                    _sectionTitle('生日咖啡廳活動',
                        trailing: _updatedAt == null
                            ? null
                            : '資料檢查:${DateFormat('M/d HH:mm').format(_updatedAt!.toLocal())}'),
                    _buildFilters(),
                    const SizedBox(height: 4),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                            child: Text('目前沒有符合條件的活動\n執行爬蟲後就會出現囉!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54))),
                      )
                    else
                      ...visible.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: _EventCard(event: e, now: now),
                          )),
                    if (ended.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    HistoryScreen(events: ended)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.history,
                                    size: 16, color: Colors.white38),
                                const SizedBox(width: 6),
                                Text('歷史活動 (${ended.length})',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white54)),
                                const Spacer(),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: kGold),
          const SizedBox(width: 6),
          GradientText(title, fontSize: 18),
          const Spacer(),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('全部成員', _memberFilter == null,
                  () => setState(() => _memberFilter = null)),
              ...kMembers.map((m) => _chip(
                  m.nameEn,
                  _memberFilter == m.id,
                  () => setState(() =>
                      _memberFilter = _memberFilter == m.id ? null : m.id),
                  color: m.color)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('全部地區', _regionFilter == null,
                  () => setState(() => _regionFilter = null)),
              for (final code in const ['TW', 'KR', 'US', 'SG'])
                _chip(
                    regionLabel(code),
                    _regionFilter == code,
                    () => setState(() => _regionFilter =
                        _regionFilter == code ? null : code)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Color? color}) {
    final accent = color ?? kSerenity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        selected: selected,
        showCheckmark: false,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: accent.withValues(alpha: 0.38),
        side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// 兵役狀態小徽章;不需顯示的成員回傳 null
Widget? militaryBadge(Member m, DateTime now) {
  final info = kMilitary[m.id];
  if (info == null) return null;
  final today = DateTime(now.year, now.month, now.day);

  var status = info.status;
  // 已過入伍日 → 服役中;已過退伍日 → 退伍
  if (status == MilitaryStatus.scheduled &&
      info.start != null &&
      !today.isBefore(info.start!)) {
    status = MilitaryStatus.serving;
  }
  if (status == MilitaryStatus.serving &&
      info.end != null &&
      today.isAfter(info.end!)) {
    status = MilitaryStatus.discharged;
  }

  final (IconData, String, Color)? badge = switch (status) {
    MilitaryStatus.serving when info.end != null => (
        Icons.shield_outlined,
        '退伍${info.endEstimated ? '≈' : ''}D-${info.end!.difference(today).inDays}',
        const Color(0xFFA5D6A7),
      ),
    MilitaryStatus.serving => (
        Icons.shield_outlined,
        '服役中',
        const Color(0xFFA5D6A7),
      ),
    MilitaryStatus.scheduled => (
        Icons.event_note,
        '入伍D-${info.start!.difference(today).inDays}',
        Colors.orangeAccent,
      ),
    MilitaryStatus.discharged => (Icons.military_tech, '已退伍', kGold),
    _ => null,
  };
  if (badge == null) return null;
  final (icon, text, color) = badge;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    ),
  );
}

/// 上方橫向的成員生日倒數卡片
class _BirthdayStrip extends StatelessWidget {
  final DateTime now;
  const _BirthdayStrip({required this.now});

  @override
  Widget build(BuildContext context) {
    final sorted = [...kMembers]..sort(
        (a, b) => a.daysUntilBirthday(now).compareTo(b.daysUntilBirthday(now)));
    return SizedBox(
      height: 196,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final m = sorted[i];
          final days = m.daysUntilBirthday(now);
          final isToday = days == 0;
          final isNext = i == 0;
          return Container(
            width: 118,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassCard(
              padding: const EdgeInsets.all(10),
              glow: (isToday || isNext) ? m.color : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(member: m, highlight: isToday || isNext),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(m.nameEn,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white)),
                      ),
                      if (isToday)
                        const Text(' 🎂', style: TextStyle(fontSize: 11))
                      else if (isNext)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Icon(Icons.auto_awesome,
                              size: 12, color: m.color),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (militaryBadge(m, now) case final badge?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: badge,
                    ),
                  isToday
                      ? const GradientText('今天生日!',
                          fontSize: 13, colors: [kRoseQuartz, kGold])
                      : Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: '${m.birthMonth}/${m.birthDay}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: m.color,
                                    fontWeight: FontWeight.w600)),
                            TextSpan(
                                text: '  $days 天',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ]),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 歷史活動子頁:已結束的活動,可依年份篩選
class HistoryScreen extends StatefulWidget {
  final List<CafeEvent> events;
  const HistoryScreen({super.key, required this.events});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _yearFilter;

  int _yearOf(CafeEvent e) =>
      (e.eventEnd ?? e.eventStart ?? e.foundAt ?? DateTime(2000)).year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = widget.events.map(_yearOf).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final shown = widget.events
        .where((e) => _yearFilter == null || _yearOf(e) == _yearFilter)
        .toList();
    return MagicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white70),
          title: const GradientText('🕰 歷史活動',
              fontSize: 20, colors: [kSerenity, kRoseQuartz]),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('全部年份',
                          style: TextStyle(
                              fontSize: 13,
                              color: _yearFilter == null
                                  ? Colors.white
                                  : Colors.white70)),
                      selected: _yearFilter == null,
                      showCheckmark: false,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      selectedColor: kSerenity.withValues(alpha: 0.38),
                      side: BorderSide(
                          color: _yearFilter == null
                              ? kSerenity.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.18)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => setState(() => _yearFilter = null),
                    ),
                  ),
                  ...years.map((y) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text('$y',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _yearFilter == y
                                      ? Colors.white
                                      : Colors.white70)),
                          selected: _yearFilter == y,
                          showCheckmark: false,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          selectedColor: kRoseQuartz.withValues(alpha: 0.38),
                          side: BorderSide(
                              color: _yearFilter == y
                                  ? kRoseQuartz.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.18)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => setState(
                              () => _yearFilter = _yearFilter == y ? null : y),
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const Center(
                      child: Text('這一年沒有紀錄',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 40),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Opacity(
                          opacity: 0.72,
                          child: _EventCard(event: shown[i], now: now),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 發光圓形頭像(照片來源見 ATTRIBUTIONS.md)
class _Avatar extends StatelessWidget {
  final Member member;
  final bool highlight;
  const _Avatar({required this.member, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            member.color,
            Colors.white.withValues(alpha: 0.9),
            member.color,
            kSerenity,
            member.color,
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: member.color.withValues(alpha: highlight ? 0.55 : 0.25),
              blurRadius: highlight ? 16 : 8,
              spreadRadius: highlight ? 1 : 0),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: Image.asset(
          'assets/avatars/${member.id}.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            color: member.color.withValues(alpha: 0.3),
            alignment: Alignment.center,
            child: Text(member.nameEn[0],
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CafeEvent event;
  final DateTime now;
  const _EventCard({required this.event, required this.now});

  @override
  Widget build(BuildContext context) {
    final member = memberById(event.memberId);
    final badge = event.statusBadge(now);
    final df = DateFormat('M/d');
    final active = badge.label == '活動進行中' || badge.label == '報名中';

    return GlassCard(
      glow: active ? (member?.color ?? kRoseQuartz) : null,
      onTap: () => launchUrl(Uri.parse(event.sourceUrl),
          mode: LaunchMode.externalApplication),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag(badge.label, badge.color, filled: true),
              const SizedBox(width: 6),
              if (member != null) _tag(member.nameEn, member.color),
              const SizedBox(width: 6),
              if (event.region != null)
                _tag(regionLabel(event.region!), const Color(0xFF7BD8C2)),
              const Spacer(),
              _sourceTag(),
            ],
          ),
          const SizedBox(height: 10),
          Text(event.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 8),
          if (event.eventStart != null)
            _infoRow(Icons.auto_awesome,
                '活動:${df.format(event.eventStart!)}${event.eventEnd != null ? ' ~ ${df.format(event.eventEnd!)}' : ''}'),
          if (event.signupStart != null)
            _infoRow(Icons.how_to_reg,
                '報名:${df.format(event.signupStart!)}${event.signupEnd != null ? ' ~ ${df.format(event.signupEnd!)}' : ''}'),
          if (event.location != null) _infoRow(Icons.place, event.location!),
          const SizedBox(height: 2),
          Row(
            children: [
              if (event.foundAt != null)
                Text('發現於 ${DateFormat('M/d').format(event.foundAt!.toLocal())}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white38)),
              const Spacer(),
              const Text('查看來源 →',
                  style: TextStyle(fontSize: 12, color: kSerenity)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.3 : 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
        boxShadow: filled
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: -1)
              ]
            : null,
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.white, 0.45))),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: kSerenity.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: Colors.white70))),
      ]),
    );
  }

  Widget _sourceTag() {
    final (label, color) = switch (event.source) {
      'threads' => ('Threads', Colors.white70),
      'instagram' => ('IG', const Color(0xFFCE93D8)),
      'stellar' => ('生咖地圖', kRoseQuartz),
      'accupass' => ('報名頁', kGold),
      'news' => ('新聞', const Color(0xFF9FA8DA)),
      _ => ('網頁', Colors.white54),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
