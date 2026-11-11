import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'sheets.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

int _newNotifId(int base) => base + Random().nextInt(900000);

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: child,
    ),
  );
}

InputDecoration _box(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder());

Widget _title(BuildContext context, String s) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(s, style: Theme.of(context).textTheme.titleLarge),
    );

Widget _label(BuildContext context, String s) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(s, style: Theme.of(context).textTheme.labelLarge),
    );

// ======================= What-if planner =======================

Future<void> showWhatIf(BuildContext context, Goal g) =>
    _sheet<void>(context, _WhatIf(goal: g));

class _WhatIf extends StatefulWidget {
  final Goal goal;
  const _WhatIf({required this.goal});

  @override
  State<_WhatIf> createState() => _WhatIfState();
}

class _WhatIfState extends State<_WhatIf> {
  late double _amount;
  late double _max;

  @override
  void initState() {
    super.initState();
    final cur = app.currentStat(widget.goal).target;
    final base = cur > 0 ? cur : 1000.0;
    _amount = (base / 500).ceil() * 500.0;
    _max = max(5000.0, ((base * 3) / 500).ceil() * 500.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = widget.goal;
    final f = app.finishAt(g, _amount);
    final isLate = f != null && f.isAfter(g.deadline);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, t('whatIf')),
          Text(g.name, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          Center(
            child: Text('${num0(_amount)} TZS',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Center(child: Text(perLabel(g))),
          Slider(
            value: _amount.clamp(500, _max).toDouble(),
            min: 500,
            max: _max,
            divisions: ((_max - 500) / 500).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _amount = v);
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: pal.heroBg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(Icons.flag, color: pal.ring),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('finish'), style: TextStyle(color: pal.soft)),
                    Text(f == null ? '—' : fmtDate(f),
                        style: TextStyle(
                            color: pal.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text(
                      isLate ? t('afterDeadline') : t('beforeDeadline'),
                      style: TextStyle(color: isLate ? pal.ring : pal.soft),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (g.type == 'main')
            FilledButton(
              onPressed: () {
                app.setTargetMode(g, fixedAmount: _amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('settingsSaved'))));
              },
              child: Text(t('useAmount')),
            ),
        ],
      ),
    );
  }
}

// ======================= Split plan =======================

class _SplitEditor extends StatefulWidget {
  const _SplitEditor();

  @override
  State<_SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<_SplitEditor> {
  late Map<String, int> _plan;

  @override
  void initState() {
    super.initState();
    _plan = Map<String, int>.from(app.splitPlan);
  }

  int get _total => _plan.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = [...app.activeGoals.map((g) => g.id), bufferId];
    final ok = _total == 100;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, t('splitTitle')),
          Text(t('splitHelp'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (final id in ids) ...[
            Row(children: [
              Expanded(child: Text(goalLabel(id))),
              Text('${_plan[id] ?? 0}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            Slider(
              value: (_plan[id] ?? 0).toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _plan[id] = v.round()),
            ),
          ],
          Text('${t('total')}: $_total%',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ok ? Colors.green.shade700 : theme.colorScheme.error)),
          if (!ok)
            Text(t('splitMust100'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: ok || _total == 0
                ? () {
                    app.setSplitPlan(_plan);
                    Navigator.pop(context);
                  }
                : null,
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }
}

// ======================= Recurring plan sheet =======================

class _PlanSheet extends StatefulWidget {
  final SavePlan? plan;
  const _PlanSheet({this.plan});

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late String _goalId;
  late final TextEditingController _amount;
  late String _freq;
  late int _weekday;
  late int _monthDay;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    final goals = app.activeGoals;
    _goalId = p?.goalId ?? (goals.isNotEmpty ? goals.first.id : bufferId);
    _amount = TextEditingController(text: p == null ? '' : p.amount.round().toString());
    _freq = p?.frequency ?? 'weekly';
    _weekday = p?.weekday ?? 5;
    _monthDay = p?.monthDay ?? 1;
    _time = TimeOfDay(hour: p?.hour ?? 18, minute: p?.minute ?? 0);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = double.tryParse(_amount.text) ?? 0;
    if (a <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    final p = SavePlan(
      id: widget.plan?.id ?? newId(),
      goalId: _goalId,
      amount: a,
      frequency: _freq,
      weekday: _weekday,
      monthDay: _monthDay,
      hour: _time.hour,
      minute: _time.minute,
      lastDone: widget.plan?.lastDone,
      notifId: widget.plan?.notifId ?? _newNotifId(100000),
    );
    app.upsertPlan(p);
    await Reminders.requestPermission();
    await Reminders.schedulePlan(p);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final p = widget.plan!;
    app.deletePlan(p);
    await Reminders.cancelId(p.notifId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, widget.plan == null ? t('newPlan') : t('editPlan')),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _box(t('amount')),
          ),
          _label(context, t('goal')),
          chipWrap([
            for (final g in app.activeGoals)
              ChoiceChip(
                label: Text(g.name),
                selected: _goalId == g.id,
                onSelected: (_) => setState(() => _goalId = g.id),
              ),
            ChoiceChip(
              label: Text(t('buffer')),
              selected: _goalId == bufferId,
              onSelected: (_) => setState(() => _goalId = bufferId),
            ),
          ]),
          _label(context, t('howOften')),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'daily', label: Text(t('daily'))),
              ButtonSegment(value: 'weekly', label: Text(t('weekly'))),
              ButtonSegment(value: 'monthly', label: Text(t('monthly'))),
            ],
            selected: {_freq},
            onSelectionChanged: (s) => setState(() => _freq = s.first),
          ),
          if (_freq == 'weekly') ...[
            const SizedBox(height: 12),
            chipWrap([
              for (var d = 1; d <= 7; d++)
                ChoiceChip(
                  label: Text(weekdayShort(d)),
                  selected: _weekday == d,
                  onSelected: (_) => setState(() => _weekday = d),
                ),
            ]),
          ],
          if (_freq == 'monthly') ...[
            const SizedBox(height: 12),
            Text('${t('dayOfMonth')}: $_monthDay'),
            Slider(
              value: _monthDay.toDouble(),
              min: 1,
              max: 28,
              divisions: 27,
              label: '$_monthDay',
              onChanged: (v) => setState(() => _monthDay = v.round()),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(t('reminderTime')),
            trailing: Text(_time.format(context)),
            onTap: () async {
              final tm = await showTimePicker(context: context, initialTime: _time);
              if (tm != null) setState(() => _time = tm);
            },
          ),
          if (_error != null) Text(_error!, style: TextStyle(color: cs.error)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(t('save'))),
          if (widget.plan != null)
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(t('delete')),
            ),
        ],
      ),
    );
  }
}

// ======================= Bill sheet =======================

class _BillSheet extends StatefulWidget {
  final Bill? bill;
  const _BillSheet({this.bill});

  @override
  State<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<_BillSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.bill?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.bill == null ? '' : widget.bill!.amount.round().toString());
  late int _day = widget.bill?.dueDay ?? 1;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = double.tryParse(_amount.text) ?? 0;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = t('required'));
      return;
    }
    if (a <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    final b = Bill(
      id: widget.bill?.id ?? newId(),
      name: _name.text.trim(),
      amount: a,
      dueDay: _day,
      lastPaidMonth: widget.bill?.lastPaidMonth ?? '',
      notifId: widget.bill?.notifId ?? _newNotifId(1000000),
    );
    app.upsertBill(b);
    await Reminders.requestPermission();
    await Reminders.scheduleBill(b);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final b = widget.bill!;
    app.deleteBill(b);
    await Reminders.cancelId(b.notifId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, widget.bill == null ? t('newBill') : t('editBill')),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _box(t('billName')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _box(t('amount')),
          ),
          _label(context, '${t('dueEveryMonth')}: $_day'),
          Slider(
            value: _day.toDouble(),
            min: 1,
            max: 28,
            divisions: 27,
            label: '$_day',
            onChanged: (v) => setState(() => _day = v.round()),
          ),
          Text(t('billReminderHelp'), style: Theme.of(context).textTheme.bodySmall),
          if (_error != null) Text(_error!, style: TextStyle(color: cs.error)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(t('save'))),
          if (widget.bill != null)
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(t('delete')),
            ),
        ],
      ),
    );
  }
}

// ======================= Debt sheet =======================

class _DebtSheet extends StatefulWidget {
  final Debt? debt;
  const _DebtSheet({this.debt});

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  late final TextEditingController _person =
      TextEditingController(text: widget.debt?.person ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.debt == null ? '' : widget.debt!.amount.round().toString());
  late final TextEditingController _note =
      TextEditingController(text: widget.debt?.note ?? '');
  late String _dir = widget.debt?.direction ?? 'owedToMe';
  late DateTime? _due = widget.debt?.dueDate;
  String? _error;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final a = double.tryParse(_amount.text) ?? 0;
    if (_person.text.trim().isEmpty) {
      setState(() => _error = t('required'));
      return;
    }
    if (a <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    app.upsertDebt(Debt(
      id: widget.debt?.id ?? newId(),
      person: _person.text.trim(),
      direction: _dir,
      amount: a,
      paid: widget.debt?.paid ?? 0,
      dueDate: _due,
      note: _note.text.trim(),
    ));
    Navigator.pop(context);
  }

  Future<void> _pay() async {
    final d = widget.debt!;
    final v = await askText(context, t('recordPayment'),
        number: true, initial: d.remaining.round().toString());
    final a = double.tryParse(v?.trim() ?? '') ?? 0;
    if (a <= 0) return;
    app.payDebt(d, a);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, t('deleteEntry'), okLabel: t('delete'));
    if (!ok || !mounted) return;
    app.deleteDebt(widget.debt!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = widget.debt;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(context, d == null ? t('newDebt') : d.person),
          if (d != null) ...[
            progressBar(d.amount <= 0 ? 0.0 : d.paid / d.amount),
            const SizedBox(height: 6),
            Text(tf('debtProgress', {'a': money(d.paid), 'b': money(d.amount)})),
            const SizedBox(height: 12),
            if (!d.settled)
              FilledButton.icon(
                onPressed: _pay,
                icon: const Icon(Icons.payments_outlined),
                label: Text(t('recordPayment')),
              ),
            const Divider(height: 28),
          ],
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'owedToMe', label: Text(t('owedToMe'))),
              ButtonSegment(value: 'iOwe', label: Text(t('iOwe'))),
            ],
            selected: {_dir},
            onSelectionChanged: (s) => setState(() => _dir = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _person,
            textCapitalization: TextCapitalization.words,
            decoration: _box(t('person')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _box(t('amount')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final today = dayOnly(DateTime.now());
              final x = await showDatePicker(
                context: context,
                initialDate: _due ?? addDays(today, 7),
                firstDate: addDays(today, -365),
                lastDate: addDays(today, 3650),
              );
              if (x != null) setState(() => _due = x);
            },
            icon: const Icon(Icons.event),
            label: Text(_due == null ? t('dueOptional') : '${t('due')} ${fmtDate(_due!)}'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: _box(t('note'))),
          if (_error != null) Text(_error!, style: TextStyle(color: cs.error)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(t('save'))),
          if (d != null)
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(t('delete')),
            ),
        ],
      ),
    );
  }
}

// ======================= Plans tab =======================

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  Widget _section(BuildContext context, String title, VoidCallback onAdd,
      List<Widget> children,
      {String? empty}) {
    final theme = Theme.of(context);
    return SectionCard(
      title: title,
      trailing: IconButton.filledTonal(
        visualDensity: VisualDensity.compact,
        onPressed: onAdd,
        icon: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.isEmpty && empty != null
            ? [Text(empty, style: theme.textTheme.bodySmall)]
            : children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final active = app.activeGoals;
    final finished = app.finishedGoals;

    String planWhen(SavePlan p) => switch (p.frequency) {
          'daily' => t('daily'),
          'monthly' => '${t('monthly')} · ${p.monthDay}',
          _ => '${t('weekly')} · ${weekdayLong(p.weekday)}',
        };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        // Goals
        for (final g in active)
          GoalCard(g, onTap: () => showGoalSheet(context, goal: g)),
        OutlinedButton.icon(
          onPressed: () => showGoalSheet(context,
              type: app.mainGoal == null ? 'main' : 'mini'),
          icon: const Icon(Icons.add),
          label: Text(app.mainGoal == null ? t('createGoal') : t('addMini')),
        ),
        const SizedBox(height: 16),

        // Auto-split
        SectionCard(
          title: t('splitTitle'),
          trailing: TextButton(
            onPressed: () => _sheet<void>(context, const _SplitEditor()),
            child: Text(t('edit')),
          ),
          child: app.splitPlan.isEmpty
              ? Text(t('splitEmpty'), style: theme.textTheme.bodySmall)
              : Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final e in app.splitPlan.entries)
                    if (e.key == bufferId || app.goalById(e.key) != null)
                      Chip(label: Text('${goalLabel(e.key)} ${e.value}%')),
                ]),
        ),

        // Recurring plans
        _section(
          context,
          t('plansTitle'),
          () => _sheet<void>(context, const _PlanSheet()),
          [
            for (final p in app.plans)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.repeat, color: cs.onPrimaryContainer),
                ),
                title: Text('${money(p.amount)} → ${goalLabel(p.goalId)}'),
                subtitle: Text(planWhen(p)),
                trailing: p.dueToday
                    ? FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          app.confirmPlan(p);
                        },
                        child: Text(t('saveNow')),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _sheet<void>(context, _PlanSheet(plan: p)),
              ),
          ],
          empty: t('plansEmpty'),
        ),

        // Bills
        _section(
          context,
          t('billsTitle'),
          () => _sheet<void>(context, const _BillSheet()),
          [
            for (final b in app.bills)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: b.paidThisMonth
                      ? cs.primaryContainer
                      : (b.daysToDue < 0 ? cs.errorContainer : cs.tertiaryContainer),
                  child: Icon(
                      b.paidThisMonth ? Icons.check : Icons.receipt_long_outlined,
                      color: b.paidThisMonth
                          ? cs.onPrimaryContainer
                          : (b.daysToDue < 0
                              ? cs.onErrorContainer
                              : cs.onTertiaryContainer)),
                ),
                title: Text('${b.name} · ${compact(b.amount)}'),
                subtitle: Text(b.paidThisMonth
                    ? t('paidThisMonth')
                    : b.daysToDue < 0
                        ? t('overdue')
                        : tf('dueInDays', {'n': '${b.daysToDue}'})),
                trailing: b.paidThisMonth
                    ? null
                    : TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          app.payBill(b, location: app.quickLocation);
                        },
                        child: Text(t('markPaid')),
                      ),
                onTap: () => _sheet<void>(context, _BillSheet(bill: b)),
              ),
          ],
          empty: t('billsEmpty'),
        ),

        // Money owed
        _section(
          context,
          t('debtsTitle'),
          () => _sheet<void>(context, const _DebtSheet()),
          [
            if (app.debts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: _miniStat(context, Icons.call_received, Colors.green.shade700,
                        compact(app.owedToMe), t('owedToMe')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniStat(context, Icons.call_made, cs.error,
                        compact(app.iOwe), t('iOwe')),
                  ),
                ]),
              ),
            for (final d in app.debts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    d.direction == 'owedToMe' ? Icons.call_received : Icons.call_made,
                    color: d.direction == 'owedToMe' ? Colors.green.shade700 : cs.error),
                title: Text(d.person,
                    style: TextStyle(
                        decoration: d.settled ? TextDecoration.lineThrough : null)),
                subtitle: Text(d.settled
                    ? t('settled')
                    : '${compact(d.remaining)} ${t('left')}'
                        '${d.dueDate == null ? '' : ' · ${shortDate(d.dueDate!)}'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _sheet<void>(context, _DebtSheet(debt: d)),
              ),
          ],
          empty: t('debtsEmpty'),
        ),

        if (app.bufferBalance.abs() > 0.5)
          SectionCard(
            title: t('buffer'),
            child: statRow(t('balance'), money(app.bufferBalance), bold: true),
          ),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(t('completed'), style: theme.textTheme.titleMedium),
          for (final g in finished)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(g.name),
              subtitle: Text('${money(app.balance(g.id))} ${t('of')} ${money(g.target)}'),
            ),
        ],
      ],
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, Color color, String value,
      String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withAlpha(30), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ]),
    );
  }
}
