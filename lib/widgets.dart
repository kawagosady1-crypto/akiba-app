import 'dart:io';

import 'package:flutter/material.dart';

import 'format.dart';
import 'i18n.dart';
import 'state.dart';

Color statusColor(DayStatus s) => switch (s) {
      DayStatus.above => Colors.green.shade700,
      DayStatus.on => Colors.teal.shade600,
      DayStatus.short => Colors.orange.shade800,
      DayStatus.missed => Colors.red.shade700,
      DayStatus.pending => Colors.grey.shade600,
      DayStatus.done => Colors.blueGrey.shade600,
    };

String statusLabel(DayStatus s) => switch (s) {
      DayStatus.above => t('statusAbove'),
      DayStatus.on => t('statusOn'),
      DayStatus.short => t('statusShort'),
      DayStatus.missed => t('statusMissed'),
      DayStatus.pending => t('statusPending'),
      DayStatus.done => t('statusDone'),
    };

String goalLabel(String id) {
  if (id == bufferId) return t('buffer');
  return app.goalById(id)?.name ?? '-';
}

/// "Today's target" / "This week's target" / "This month's target".
String targetLabel(Goal g) => switch (g.period) {
      'week' => t('weekTarget'),
      'month' => t('monthTarget'),
      _ => t('todayTarget'),
    };

String savedPeriodLabel(Goal g) => switch (g.period) {
      'week' => t('savedThisWeek'),
      'month' => t('savedThisMonth'),
      _ => t('savedToday'),
    };

String perLabel(Goal g) => switch (g.period) {
      'week' => t('perWeek'),
      'month' => t('perMonth'),
      _ => t('perDay'),
    };

String periodName(String p) => switch (p) {
      'week' => t('weekly'),
      'month' => t('monthly'),
      _ => t('daily'),
    };

/// Label for a period row in History.
String periodTitle(PeriodStat s, Goal g) {
  if (g.period == 'day') return fmtDate(s.start);
  if (g.period == 'month') return '${monthLong(s.start.month)} ${s.start.year}';
  return '${shortDate(s.start)} - ${shortDate(s.end)}';
}

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? color;
  final Widget? trailing;
  const SectionCard(
      {super.key, this.title, required this.child, this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
      ),
    );
  }
}

Widget statRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget progressBar(double value, {Color? color, double height = 8}) {
  return LinearProgressIndicator(
    value: value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble(),
    minHeight: height,
    color: color,
    borderRadius: BorderRadius.circular(8),
  );
}

class StatusChip extends StatelessWidget {
  final DayStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TxnTile extends StatelessWidget {
  final Txn tx;
  const TxnTile(this.tx, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    IconData icon;
    Color bg;
    Color fg;
    String title;
    String sign;
    Color amountColor;
    switch (tx.kind) {
      case 'saving':
        icon = Icons.savings_outlined;
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        title = tx.reason == 'opening'
            ? '${goalLabel(tx.goalId)} · ${t('startingAmount')}'
            : tx.loanId.isNotEmpty
                ? '${goalLabel(tx.goalId)} · ${t('repayment')}'
                : goalLabel(tx.goalId);
        sign = '+';
        amountColor = cs.primary;
        break;
      case 'withdrawal':
        icon = Icons.call_made;
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        title = '${t('withdrawal')} · ${goalLabel(tx.goalId)}';
        sign = '-';
        amountColor = Colors.orange.shade800;
        break;
      case 'income':
        icon = Icons.payments_outlined;
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        title = '${t('income')} · ${t('src_${tx.reason}')}';
        sign = '+';
        amountColor = cs.tertiary;
        break;
      default:
        icon = Icons.shopping_bag_outlined;
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        title = t('cat_${tx.category}');
        sign = '-';
        amountColor = cs.error;
    }
    final parts = <String>[
      shortDate(tx.date),
      if (tx.kind == 'withdrawal') t('why_${tx.reason}'),
      if (tx.isLoan) t('loan'),
      if (tx.location.isNotEmpty) tx.location,
      if (tx.note.isNotEmpty) tx.note,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: bg,
        child: Icon(icon, color: fg),
      ),
      title: Text(title),
      subtitle: Text(parts.join(' · ')),
      trailing: Text(
        '$sign${num0(tx.amount)}',
        style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
      ),
    );
  }
}

class GoalPhoto extends StatelessWidget {
  final String? path;
  final double height;
  const GoalPhoto(this.path, {super.key, this.height = 130});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    final f = File(p);
    if (!f.existsSync()) return const SizedBox.shrink();
    return Image.file(
      f,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  const GoalCard(this.goal, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayOnly(DateTime.now());
    final saved = app.balance(goal.id);
    final double pct = goal.target <= 0
        ? 0.0
        : (saved / goal.target).clamp(0.0, 1.0).toDouble();
    final done = saved >= goal.target;
    final left = daysBetween(today, goal.deadline);
    final cur = app.currentStat(goal);
    final dayOfText = tf('dayOf', {
      'a': app.dayNumber(goal).toString(),
      'b': app.totalDays(goal).toString(),
    });
    final dueText = left >= 0
        ? '$dayOfText · $left ${t('daysLeft')}'
        : t('deadlinePassed');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoalPhoto(goal.photoPath),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (goal.locked) ...[
                        Icon(Icons.lock_outline,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(goal.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        goal.type == 'main' ? t('mainGoal') : t('miniGoal'),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  progressBar(pct, height: 10),
                  const SizedBox(height: 8),
                  Text(
                      '${money(saved)} ${t('of')} ${money(goal.target)}  ·  ${(pct * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 4),
                  Text(
                    done
                        ? t('goalDone')
                        : '${moneyUp(cur.target)} ${perLabel(goal)}  ·  ${t('due')} ${fmtDate(goal.deadline)}  ·  $dueText',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message,
    {String? okLabel, String? title}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel ?? t('ok'))),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(BuildContext context, String title,
    {int maxLines = 1, bool number = false, String initial = ''}) async {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: Text(t('ok'))),
      ],
    ),
  );
}

Widget chipWrap(List<Widget> chips) =>
    Wrap(spacing: 8, runSpacing: 4, children: chips);
