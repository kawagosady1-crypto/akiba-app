import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'plans.dart';
import 'sheets.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

Color get _heroBg => pal.heroBg;
Color get _heroTrack => pal.heroTrack;
Color get _gold => pal.ring;
Color get _mint => pal.soft;
Color get _ink => pal.ink;
Color get _green => pal.accent;

// ======================= Ring =======================

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color fill;
  final double stroke;
  _RingPainter(this.value, this.track, this.fill, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(c, r, bg);
    final v = value.clamp(0.0, 1.0).toDouble();
    if (v <= 0) return;
    final fg = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -pi / 2, 2 * pi * v, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.fill != fill || old.track != track;
}

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final Widget? center;
  final Color track;
  final Color fill;
  final double stroke;
  ProgressRing({
    super.key,
    required this.value,
    this.size = 112,
    this.center,
    this.track,
    this.fill,
    this.stroke = 11,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.isNaN ? 0.0 : value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, track ?? _heroTrack, fill ?? _gold, stroke),
          child: Center(child: center),
        ),
      ),
    );
  }
}

/// A number that counts up when it changes.
class CountUp extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final bool hidden;
  const CountUp(this.value, {super.key, this.style, this.hidden = false});

  @override
  Widget build(BuildContext context) {
    if (hidden) return Text('••••••', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(num0(v), style: style),
    );
  }
}

// ======================= Home =======================

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenHistory;
  const HomeScreen({super.key, required this.onOpenHistory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  // ---------- actions ----------
  void _quickSave(Goal g, double amount) {
    if (amount <= 0) return;
    HapticFeedback.mediumImpact();
    final wasMet = app.currentStat(g).met;
    final ids = app.addSaving(
      amount: amount,
      goalId: g.id,
      location: app.quickLocation,
      date: DateTime.now(),
    );
    final nowMet = app.currentStat(g).met;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(tf('savedMsg', {'a': money(amount)})),
        action: SnackBarAction(
            label: t('undo'), onPressed: () => app.deleteTxns(ids)),
      ));
    if (!wasMet && nowMet) _celebrate();
  }

  void _celebrate() {
    HapticFeedback.heavyImpact();
    var open = true;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (open && ctx.mounted) Navigator.of(ctx).pop();
        });
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (c, v, child) => Transform.scale(scale: v, child: child),
            child: Material(
              color: _heroBg,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, size: 64, color: _gold),
                    const SizedBox(height: 12),
                    Text(t('targetMet'),
                        style: TextStyle(
                            color: _ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) => open = false);
  }

  Future<void> _extend(Goal g) async {
    final today = dayOnly(DateTime.now());
    final first = addDays(today, 1);
    final init = g.deadline.isBefore(first) ? first : addDays(g.deadline, 7);
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: addDays(today, 3650),
    );
    if (d != null) {
      g.deadline = dayOnly(d);
      app.updateGoal(g);
    }
  }

  void _showBreakdown() {
    final goals = app.activeGoals;
    final locs = app.balanceByLocation().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Widget head(String s) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(s,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
            );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('totalBalance'), style: theme.textTheme.bodyMedium),
              Text(money(app.totalNetSaved),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              head(t('byGoal')),
              for (final g in goals) statRow(g.name, money(app.balance(g.id))),
              if (app.bufferBalance.abs() > 0.5)
                statRow(t('buffer'), money(app.bufferBalance)),
              head(t('byLocation')),
              if (locs.isEmpty) Text(t('nothingYet')),
              for (final e in locs) statRow(e.key, money(e.value)),
              if (app.hasIncome) ...[
                head(t('wallet')),
                Text(t('walletHelp'), style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                statRow(t('wallet'), money(app.walletBalance), bold: true),
              ],
              if (app.debts.isNotEmpty) ...[
                head(t('debtsTitle')),
                statRow(t('owedToMe'), money(app.owedToMe)),
                statRow(t('iOwe'), money(app.iOwe)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------- pieces ----------
  Widget _balanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _showBreakdown,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('totalBalance'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CountUp(app.totalNetSaved,
                                hidden: app.hideBalance,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('TZS',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    if (app.hasIncome)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${t('wallet')}: ${app.hideBalance ? '••••' : compact(app.walletBalance)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: app.hideBalance ? t('showBalance') : t('hideBalance'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  app.toggleHideBalance();
                },
                icon: Icon(app.hideBalance
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, Goal g) {
    final saved = app.balance(g.id);
    final frac = app.moneyFraction(g);
    final left = daysBetween(dayOnly(DateTime.now()), g.deadline);
    final photo = g.photoPath;
    final hasPhoto = photo != null && photo.isNotEmpty && File(photo).existsSync();
    Widget chip(IconData i, String s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: _heroTrack.withAlpha(230),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 13, color: _mint),
            const SizedBox(width: 4),
            Text(s, style: TextStyle(color: _ink, fontSize: 11.5)),
          ]),
        );
    return GestureDetector(
      onTap: () => showGoalSheet(context, goal: g),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _heroBg,
          borderRadius: BorderRadius.circular(26),
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(File(photo)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      _heroBg.withAlpha(200), BlendMode.srcOver),
                )
              : null,
        ),
        child: Row(
          children: [
            ProgressRing(
              value: frac,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(frac * 100).round()}%',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text(t('savedShort'),
                      style: TextStyle(color: _mint, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (g.locked) ...[
                      Icon(Icons.lock_outline, size: 14, color: _mint),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _mint, fontSize: 13.5)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CountUp(saved,
                        hidden: app.hideBalance,
                        style: TextStyle(
                            color: _ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                  ),
                  Text('/ ${num0(g.target)} TZS',
                      style: TextStyle(color: _mint, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    chip(Icons.hourglass_bottom,
                        left >= 0 ? '$left ${t('daysShort')}' : t('deadlinePassed')),
                    chip(Icons.event, fmtDate(g.deadline)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(BuildContext context, Goal g) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = app.currentStat(g);
    final done = app.balance(g.id) >= g.target;
    final label = switch (g.period) {
      'week' => t('thisWeekShort'),
      'month' => t('thisMonthShort'),
      _ => t('today'),
    };
    final remaining = s.shortfall.ceilToDouble();
    final target = s.target.ceilToDouble();
    final buttons = <Widget>[];
    if (!done) {
      if (remaining > 0) {
        buttons.add(Expanded(
          child: FilledButton.icon(
            onPressed: () => _quickSave(g, remaining),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text('+${compact(remaining)}'),
          ),
        ));
        if (target > remaining) {
          buttons.add(const SizedBox(width: 8));
          buttons.add(Expanded(
            child: OutlinedButton(
              onPressed: () => _quickSave(g, target),
              child: Text('+${compact(target)}'),
            ),
          ));
        }
      } else {
        for (final a in [1000.0, 5000.0]) {
          if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
          buttons.add(Expanded(
            child: OutlinedButton(
              onPressed: () => _quickSave(g, a),
              child: Text('+${compact(a)}'),
            ),
          ));
        }
      }
      buttons.add(const SizedBox(width: 8));
      buttons.add(IconButton.filledTonal(
        tooltip: t('otherAmount'),
        onPressed: () => showLogSheet(context, goalId: g.id),
        icon: const Icon(Icons.edit_outlined),
      ));
    }
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            if (g.isFixed) ...[
              const SizedBox(width: 6),
              Icon(Icons.push_pin_outlined, size: 14, color: cs.onSurfaceVariant),
            ],
            const Spacer(),
            Text('${compact(s.actual)} / ${compact(target)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          if (done)
            Row(children: [
              Icon(Icons.emoji_events, color: _gold, size: 30),
              const SizedBox(width: 8),
              Text(t('goalDone'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ])
          else if (s.met)
            Row(children: [
              Icon(Icons.check_circle, color: _green, size: 28),
              const SizedBox(width: 8),
              Text(t('done'),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (s.extra > 0) ...[
                const SizedBox(width: 10),
                Text('+${compact(s.extra)} ${t('extraShort')}',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
              ],
            ])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(num0(remaining),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Text(t('left'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0.0,
                end: target <= 0 ? 1.0 : (s.actual / target).clamp(0.0, 1.0).toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (c, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: s.met ? _green : cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: buttons),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String value,
      String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _info(String text, {String? action, VoidCallback? onAction}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(t('close'))),
          if (action != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onAction?.call();
              },
              child: Text(action),
            ),
        ],
      ),
    );
  }

  Widget _tiles(BuildContext context, Goal g) {
    final streak = app.streak(g);
    final ahead = app.moneyFraction(g) >= app.timeFraction(g) - 0.02;
    final finish = app.projectedFinish(g);
    final left = daysBetween(dayOnly(DateTime.now()), g.deadline);
    final isMain = g.type == 'main';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _tile(context, Icons.local_fire_department, const Color(0xFFD85A30),
            '$streak', t('streak'),
            onTap: () => _info(t('streakInfo'))),
        _tile(
            context,
            ahead ? Icons.trending_up : Icons.trending_down,
            ahead ? _green : const Color(0xFFBA7517),
            ahead ? t('ahead') : t('behindShort'),
            t('pace'),
            onTap: () => _info(tf('paceInfo', {
                  'a': '${(app.timeFraction(g) * 100).round()}%',
                  'b': '${(app.moneyFraction(g) * 100).round()}%',
                }))),
        _tile(
            context,
            Icons.flag_outlined,
            const Color(0xFF378ADD),
            finish == null ? '—' : '${monthShort(finish.month)} ${finish.year}',
            t('finish'),
            onTap: () => showWhatIf(context, g)),
        isMain
            ? _tile(context, Icons.savings_outlined, const Color(0xFFBA7517),
                compact(app.totalExtra(g)), t('extraShortLabel'),
                onTap: () => _info(tf('extraInfo', {
                      'a': money(app.totalExtra(g)),
                      'b': money(app.bufferBalance),
                    })))
            : _tile(context, Icons.hourglass_bottom, const Color(0xFF7F77DD),
                left >= 0 ? '$left' : '0', t('daysLeft')),
      ],
    );
  }

  Widget _weekChart(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final days = List<DateTime>.generate(7, (i) => addDays(today, i - 6));
    final vals = days.map((d) => app.totalOn('saving', d)).toList();
    final maxV = vals.fold<double>(0, (a, b) => max(a, b));
    final total = vals.fold<double>(0, (a, b) => a + b);
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(t('last7'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(compact(total),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: money(vals[i]),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: 0.0,
                                  end: maxV <= 0 ? 0.0 : vals[i] / maxV),
                              duration: Duration(milliseconds: 500 + i * 60),
                              curve: Curves.easeOutCubic,
                              builder: (c, v, _) => Container(
                                height: max(4.0, 62 * v),
                                decoration: BoxDecoration(
                                  color: i == 6
                                      ? _green
                                      : _green.withAlpha(90),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(weekdayShort(days[i].weekday).substring(0, 1),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight:
                                      i == 6 ? FontWeight.w800 : FontWeight.w400)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  Widget _banner(BuildContext context, IconData icon, Color color, String text,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right, color: color),
            ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _banners(BuildContext context, Goal? g) {
    final out = <Widget>[];
    const amber = Color(0xFFBA7517);
    const red = Color(0xFFE24B4A);
    const blue = Color(0xFF378ADD);

    for (final r in app.requests) {
      out.add(_banner(
        context,
        r.isReady ? Icons.lock_open : Icons.schedule,
        blue,
        tf('requestBanner', {
          'a': compact(r.amount),
          's': r.isReady ? t('readyWord') : t('waitWord'),
        }),
        () => _info(
          '${money(r.amount)} · ${goalLabel(r.goalId)} · ${t('why_${r.reason}')}',
          action: r.isReady ? t('withdrawNow') : t('cancelRequest'),
          onAction: () {
            if (r.isReady) {
              app.completeRequest(r);
            } else {
              app.cancelRequest(r);
            }
          },
        ),
      ));
    }

    if (g != null) {
      final stats = app.periodStats(g);
      final prev = stats.length >= 2 ? stats[stats.length - 2] : null;
      final done = app.balance(g.id) >= g.target;
      if (done) {
        out.add(_banner(context, Icons.emoji_events, _green, t('goalDone'), () {
          _info(t('goalDone'),
              action: t('startNewGoal'),
              onAction: () {
                if (g.type == 'main') {
                  app.archiveGoal(g);
                  showGoalSheet(context, type: 'main');
                } else {
                  app.archiveGoal(g);
                }
              });
        }));
      } else if (prev != null && !prev.met) {
        final cur = app.currentStat(g);
        String msg;
        if (g.isFixed) {
          final f = app.finishAt(g, g.fixedAmount!);
          final params = {
            'a': moneyUp(prev.shortfall),
            'b': '${moneyUp(g.fixedAmount!)} ${perLabel(g)}',
            'c': f == null ? '-' : fmtDate(f),
          };
          msg = prev.actual <= 0 ? tf('missedFixed', params) : tf('shortFixed', params);
        } else {
          msg = prev.actual <= 0
              ? tf('missedPrev', {'b': moneyUp(cur.target)})
              : tf('shortPrev', {'a': moneyUp(prev.shortfall), 'b': moneyUp(cur.target)});
        }
        out.add(_banner(
          context,
          Icons.warning_amber_rounded,
          amber,
          tf('shortBanner', {'a': compact(prev.shortfall)}),
          () => _info(msg,
              action: g.isFixed ? null : t('extendDeadline'),
              onAction: g.isFixed ? null : () => _extend(g)),
        ));
      }
    }

    for (final p in app.plansDueToday) {
      out.add(_banner(
        context,
        Icons.repeat,
        pal.accent,
        tf('planBanner', {'a': compact(p.amount), 'g': goalLabel(p.goalId)}),
        () => _info(
          tf('planNotif', {'a': money(p.amount), 'g': goalLabel(p.goalId)}),
          action: t('saveNow'),
          onAction: () {
            HapticFeedback.mediumImpact();
            final ids = app.confirmPlan(p);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(tf('savedMsg', {'a': money(p.amount)})),
                action: SnackBarAction(
                    label: t('undo'), onPressed: () => app.deleteTxns(ids)),
              ));
          },
        ),
      ));
    }

    for (final b in app.billsDueSoon) {
      out.add(_banner(
        context,
        Icons.receipt_long_outlined,
        b.daysToDue < 0 ? red : amber,
        tf('billBanner', {
          'n': b.name,
          'a': compact(b.amount),
          's': b.daysToDue < 0
              ? t('overdue')
              : tf('dueInDays', {'n': '${b.daysToDue}'}),
        }),
        () => _info(
          tf('billNotif', {'n': b.name, 'a': money(b.amount), 'd': '${b.dueDay}'}),
          action: t('markPaid'),
          onAction: () {
            HapticFeedback.mediumImpact();
            app.payBill(b, location: app.quickLocation);
          },
        ),
      ));
    }

    for (final d in app.debtsDueSoon) {
      out.add(_banner(
        context,
        d.direction == 'owedToMe' ? Icons.call_received : Icons.call_made,
        d.direction == 'owedToMe' ? _green : red,
        tf(d.direction == 'owedToMe' ? 'debtBannerIn' : 'debtBannerOut',
            {'p': d.person, 'a': compact(d.remaining)}),
        () => _info(tf('debtProgress', {'a': money(d.paid), 'b': money(d.amount)})),
      ));
    }

    for (final l in app.activeLoans()) {
      out.add(_banner(
        context,
        Icons.handshake_outlined,
        const Color(0xFF7F77DD),
        tf('oweBanner', {'a': compact(app.outstanding(l)), 'g': goalLabel(l.goalId)}),
        () => showLogSheet(context, kind: 'saving', goalId: l.goalId),
      ));
    }

    for (final c in app.categoriesNearLimit()) {
      final lim = app.limits[c]!;
      final pct = (app.monthSpent(c) / lim * 100).round();
      out.add(_banner(
        context,
        Icons.speed,
        pct > 100 ? red : amber,
        tf('limitBanner', {'c': t('cat_$c'), 'p': '$pct'}),
        () => _info(tf('limitStatusNamed', {
          'c': t('cat_$c'),
          'a': money(app.monthSpent(c)),
          'b': money(lim),
        })),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final goals = app.activeGoals;
    if (_page >= goals.length) _page = goals.isEmpty ? 0 : goals.length - 1;
    final g = goals.isEmpty ? null : goals[_page];

    final children = <Widget>[
      _balanceCard(context),
      const SizedBox(height: 14),
    ];

    if (g == null) {
      children.add(_panel(
        context,
        child: Column(children: [
          Icon(Icons.savings_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 10),
          Text(t('noMainGoal'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => showGoalSheet(context, type: 'main'),
            child: Text(t('createGoal')),
          ),
        ]),
      ));
    } else {
      children.add(SizedBox(
        height: 172,
        child: PageView(
          controller: _pager,
          onPageChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => _page = i);
          },
          children: [
            for (final x in goals)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _hero(context, x),
              ),
          ],
        ),
      ));
      if (goals.length > 1) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < goals.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ));
      }
      children.add(const SizedBox(height: 14));
      children.addAll(_banners(context, g));
      children.add(_todayCard(context, g));
      children.add(const SizedBox(height: 12));
      children.add(_tiles(context, g));
      children.add(const SizedBox(height: 12));
    }

    if (g == null) children.addAll(_banners(context, null));
    children.add(_weekChart(context));
    children.add(const SizedBox(height: 12));

    // Recent entries
    final recent = app.sortedTxns.take(3).toList();
    children.add(_panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(t('recent'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            TextButton(onPressed: widget.onOpenHistory, child: Text(t('seeAll'))),
          ]),
          if (recent.isEmpty) Text(t('noEntries')),
          for (final x in recent) TxnTile(x),
        ],
      ),
    ));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: children,
    );
  }
}
