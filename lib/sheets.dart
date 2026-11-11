import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'state.dart';
import 'widgets.dart';

Widget _label(BuildContext context, String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(s, style: Theme.of(context).textTheme.labelLarge),
    );

InputDecoration _box(String label, {String? helper}) => InputDecoration(
    labelText: label, helperText: helper, border: const OutlineInputBorder());

// ======================= Goal sheet =======================

Future<void> showGoalSheet(BuildContext context,
    {Goal? goal, String type = 'mini'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: GoalSheet(goal: goal, type: type),
    ),
  );
}

class GoalSheet extends StatefulWidget {
  final Goal? goal;
  final String type;
  const GoalSheet({super.key, this.goal, required this.type});

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _start;
  late DateTime _deadline;
  late String _type;
  late String _extraDest;
  late String _period;
  late bool _locked;
  late String _startLocation;
  String? _photo;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _amount = TextEditingController(
        text: g == null ? '' : g.target.round().toString());
    final opening = g == null ? null : app.openingTxn(g.id);
    _start = TextEditingController(
        text: opening == null ? '' : opening.amount.round().toString());
    _startLocation = opening?.location ??
        (app.locations.isNotEmpty ? app.locations.first : '');
    _deadline = g?.deadline ?? addDays(dayOnly(DateTime.now()), 90);
    _type = g?.type ?? widget.type;
    _extraDest = g?.extraDest ?? 'goal';
    _period = g?.period ?? 'day';
    _locked = g?.locked ?? false;
    _photo = g?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _start.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;
  double get _startAmt => double.tryParse(_start.text) ?? 0;

  Future<void> _pickDeadline() async {
    final today = dayOnly(DateTime.now());
    final first = addDays(today, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(first) ? first : _deadline,
      firstDate: first,
      lastDate: addDays(today, 3650),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Future<void> _pickPhoto() async {
    final p = await Photos.pickGoalPhoto();
    if (p != null && mounted) setState(() => _photo = p);
  }

  void _save() {
    final today = dayOnly(DateTime.now());
    if (_name.text.trim().isEmpty) {
      setState(() => _error = t('required'));
      return;
    }
    if (_amt <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    if (_startAmt >= _amt) {
      setState(() => _error = t('startTooBig'));
      return;
    }
    if (!dayOnly(_deadline).isAfter(today)) {
      setState(() => _error = t('deadlinePast'));
      return;
    }
    final g = widget.goal;
    if (g == null) {
      app.addGoal(
        Goal(
          id: newId(),
          name: _name.text.trim(),
          type: _type,
          target: _amt,
          start: today,
          deadline: dayOnly(_deadline),
          extraDest: _extraDest,
          period: _period,
          locked: _locked,
          photoPath: _photo,
        ),
        startAmount: _startAmt,
        startLocation: _startLocation,
      );
    } else {
      g.name = _name.text.trim();
      g.target = _amt;
      g.deadline = dayOnly(_deadline);
      g.extraDest = _extraDest;
      g.period = _period;
      g.locked = _locked;
      g.photoPath = _photo;
      app.setOpening(g, _startAmt, _startLocation);
    }
    Navigator.pop(context);
  }

  void _archive() {
    app.archiveGoal(widget.goal!);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, t('deleteGoalConfirm'),
        okLabel: t('delete'));
    if (!ok || !mounted) return;
    app.deleteGoal(widget.goal!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final canChooseType = widget.goal == null && app.mainGoal == null;
    final days = max(1, daysBetween(today, _deadline) + 1);
    final periods = _period == 'day'
        ? days
        : _period == 'week'
            ? (days / 7).ceil()
            : max(1, (days / 30).round());
    final need = _amt - _startAmt;
    final preview = need > 0 ? need / periods : 0.0;
    final perWord = _period == 'week'
        ? t('perWeek')
        : _period == 'month'
            ? t('perMonth')
            : t('perDay');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.goal == null ? t('newGoal') : t('editGoal'),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (canChooseType) ...[
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'main', label: Text(t('mainGoal'))),
                ButtonSegment(value: 'mini', label: Text(t('miniGoal'))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
          ],
          // Photo
          if (_photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoalPhoto(_photo, height: 140),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t('changePhoto')),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _photo = null),
                  icon: const Icon(Icons.close),
                  label: Text(t('removePhoto')),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(t('addPhoto')),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _box(t('goalName')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: _box(t('goalAmount')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _start,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: _box(t('alreadySaved'), helper: t('alreadySavedHelp')),
          ),
          if (_startAmt > 0) ...[
            _label(context, t('whereKept')),
            chipWrap([
              for (final l in app.locations)
                ChoiceChip(
                  label: Text(l),
                  selected: _startLocation == l,
                  onSelected: (_) => setState(() => _startLocation = l),
                ),
            ]),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDeadline,
            icon: const Icon(Icons.event),
            label: Text('${t('deadline')}: ${fmtDate(_deadline)}  ($days ${t('days').toLowerCase()})'),
          ),
          _label(context, t('targetPeriod')),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final p in periodTypes)
                ButtonSegment(value: p, label: Text(periodName(p))),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          if (preview > 0) ...[
            const SizedBox(height: 12),
            Text('${t('target')}: ${moneyUp(preview)} $perWord',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
          ],
          if (_type == 'main') ...[
            _label(context, t('extraGoesTo')),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'goal', label: Text(t('mainGoal'))),
                ButtonSegment(value: 'buffer', label: Text(t('buffer'))),
              ],
              selected: {_extraDest},
              onSelectionChanged: (s) => setState(() => _extraDest = s.first),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _locked,
            onChanged: (v) => setState(() => _locked = v),
            title: Text(t('lockGoal')),
            subtitle: Text(t('lockGoalHelp')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(t('save'))),
          if (widget.goal != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _archive, child: Text(t('archive'))),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(t('deleteGoal')),
            ),
          ],
        ],
      ),
    );
  }
}

// ======================= Log sheet =======================

Future<void> showLogSheet(BuildContext context,
    {String kind = 'saving', String? goalId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: LogSheet(kind: kind, goalId: goalId),
    ),
  );
}

class LogSheet extends StatefulWidget {
  final String kind;
  final String? goalId;
  const LogSheet({super.key, required this.kind, this.goalId});

  @override
  State<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<LogSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _kind;
  late String _goalId;
  late String _location;
  String _category = 'food';
  String _paidFrom = '';
  String _source = 'salary';
  String _reason = 'planned';
  bool _isLoan = false;
  int _loanDays = 30;
  bool _repay = true;
  late DateTime _date;
  String? _error;

  static const List<int> _quick = [500, 1000, 2000, 5000, 10000];
  static const List<int> _loanChoices = [7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _kind = widget.kind;
    final goals = app.activeGoals;
    _goalId = widget.goalId ??
        (goals.isNotEmpty ? goals.first.id : bufferId);
    _location = app.locations.isNotEmpty ? app.locations.first : '';
    _date = dayOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;

  Future<void> _pickDate() async {
    final today = dayOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: addDays(today, -7),
      lastDate: today,
    );
    if (d != null) setState(() => _date = dayOnly(d));
  }

  // ---------- save ----------
  Future<void> _save() async {
    final amt = _amt;
    if (amt <= 0) {
      setState(() => _error = t('invalidAmount'));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final note = _note.text.trim();
    String? msg;

    switch (_kind) {
      case 'saving':
        if (_goalId == 'split') {
          app.addSplitSaving(
              amount: amt, location: _location, date: _date, note: note);
          msg = tf('savedMsg', {'a': money(amt)});
          break;
        }
        final loans = app.activeLoans(_goalId);
        app.addSaving(
          amount: amt,
          goalId: _goalId,
          location: _location,
          date: _date,
          note: note,
          loanId: (_repay && loans.isNotEmpty) ? loans.first.id : '',
        );
        msg = tf('savedMsg', {'a': money(amt)});
        final sg = app.goalById(_goalId);
        if (sg != null && sg.type == 'main') {
          final cur = app.currentStat(sg);
          if (cur.isCurrent && inRange(_date, cur.start, cur.end) && cur.extra > 0) {
            msg = tf('savedExtraMsg', {'a': money(amt), 'b': money(cur.extra)});
          }
        }
        break;

      case 'spending':
        app.addSpending(
          amount: amt,
          category: _category,
          location: _paidFrom,
          date: _date,
          note: note,
        );
        msg = tf('spentMsg', {'a': money(amt)});
        final lim = app.limits[_category];
        if (lim != null && lim > 0) {
          final used = app.monthSpent(_category);
          final params = {
            'c': t('cat_$_category'),
            'a': money(used),
            'b': money(lim),
          };
          if (used > lim) {
            msg = tf('limitOver', params);
          } else if (used >= lim * 0.8) {
            msg = tf('limitNear', params);
          }
        }
        break;

      case 'income':
        app.addIncome(
          amount: amt,
          source: _source,
          location: _location,
          date: _date,
          note: note,
        );
        msg = tf('incomeMsg', {'a': money(amt)});
        final pct = app.saveFirstPercent;
        final target = app.mainGoal?.id ?? bufferId;
        if (pct > 0) {
          final suggest = (amt * pct / 100).roundToDouble();
          final yes = await confirmDialog(
            context,
            tf('saveFirstAsk', {
              'p': '$pct',
              'a': money(suggest),
              'g': goalLabel(target),
            }),
            title: t('saveFirst'),
            okLabel: t('saveNow'),
          );
          if (!mounted) return;
          if (yes) {
            app.addSaving(
              amount: suggest,
              goalId: target,
              location: _location,
              date: _date,
              note: t('saveFirst'),
            );
            msg = tf('savedMsg', {'a': money(suggest)});
          }
        }
        break;

      case 'withdraw':
        final bal = app.balance(_goalId);
        if (amt > bal + 0.5) {
          setState(() => _error = tf('tooMuch', {'a': money(bal)}));
          return;
        }
        final wg = app.goalById(_goalId);
        final locked = wg?.locked ?? false;
        if (locked && _reason != 'emergency') {
          app.requestWithdrawal(WithdrawRequest(
            id: newId(),
            goalId: _goalId,
            amount: amt,
            location: _location,
            reason: _reason,
            isLoan: _isLoan,
            loanDays: _loanDays,
            note: note,
            requestedAt: DateTime.now(),
          ));
          msg = t('requestMade');
          break;
        }
        if (locked && _reason == 'emergency') {
          final ok = await confirmDialog(context, t('emergencyConfirm'),
              title: t('emergencyOverride'), okLabel: t('withdrawNow'));
          if (!ok || !mounted) return;
        }
        app.addWithdrawal(
          amount: amt,
          goalId: _goalId,
          location: _location,
          reason: _reason,
          isLoan: _isLoan,
          loanDays: _loanDays,
          date: _date,
          note: note,
        );
        msg = tf('withdrawMsg', {'a': money(amt)});
        break;
    }

    if (!mounted) return;
    Navigator.pop(context);
    if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- pieces ----------
  Widget _locationChips({bool optional = false}) => chipWrap([
        for (final l in app.locations)
          ChoiceChip(
            label: Text(l),
            selected: optional ? _paidFrom == l : _location == l,
            onSelected: (sel) => setState(() {
              if (optional) {
                _paidFrom = sel ? l : '';
              } else {
                _location = l;
              }
            }),
          ),
      ]);

  Widget _goalChips({required bool withdraw}) {
    final chips = <Widget>[];
    for (final g in app.activeGoals) {
      final bal = app.balance(g.id);
      if (withdraw && bal <= 0) continue;
      chips.add(ChoiceChip(
        avatar: g.locked ? const Icon(Icons.lock_outline, size: 16) : null,
        label: Text(withdraw ? '${g.name} (${num0(bal)})' : g.name),
        selected: _goalId == g.id,
        onSelected: (_) => setState(() => _goalId = g.id),
      ));
    }
    if (!withdraw && app.splitReady) {
      chips.insert(
          0,
          ChoiceChip(
            avatar: const Icon(Icons.call_split, size: 16),
            label: Text(t('splitChip')),
            selected: _goalId == 'split',
            onSelected: (_) => setState(() => _goalId = 'split'),
          ));
    }
    final buf = app.bufferBalance;
    if (!withdraw || buf > 0) {
      chips.add(ChoiceChip(
        label: Text(withdraw ? '${t('buffer')} (${num0(buf)})' : t('buffer')),
        selected: _goalId == bufferId,
        onSelected: (_) => setState(() => _goalId = bufferId),
      ));
    }
    if (chips.isEmpty) return Text(t('nothingToWithdraw'));
    return chipWrap(chips);
  }

  Widget _impactCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = app.goalById(_goalId);
    final amt = _amt;
    if (g == null || amt <= 0) return const SizedBox.shrink();
    String text;
    if (g.isFixed) {
      final before = app.finishAt(g, g.fixedAmount!);
      final after = app.finishAt(g, g.fixedAmount!, extraWithdraw: amt);
      if (before == null || after == null) return const SizedBox.shrink();
      text = tf('impactFixed', {'a': fmtDate(before), 'b': fmtDate(after)});
    } else {
      final before = app.nextTarget(g);
      final after = app.nextTarget(g, extraWithdraw: amt);
      text = tf('impactAuto', {
        'p': targetLabel(g).toLowerCase(),
        'a': moneyUp(before),
        'b': moneyUp(after),
      });
    }
    return Card(
      color: cs.tertiaryContainer,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(color: cs.onTertiaryContainer))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayOnly(DateTime.now());
    final yesterday = addDays(today, -1);
    final isOther = !sameDay(_date, today) && !sameDay(_date, yesterday);
    final g = app.goalById(_goalId);
    final loans = _kind == 'saving' ? app.activeLoans(_goalId) : <Txn>[];
    final lockedRequest =
        _kind == 'withdraw' && (g?.locked ?? false) && _reason != 'emergency';

    final children = <Widget>[
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'saving', label: Text(t('kindSave'))),
          ButtonSegment(value: 'spending', label: Text(t('kindSpend'))),
          ButtonSegment(value: 'withdraw', label: Text(t('kindWithdraw'))),
          ButtonSegment(value: 'income', label: Text(t('kindIncome'))),
        ],
        selected: {_kind},
        onSelectionChanged: (s) => setState(() {
          _kind = s.first;
          _error = null;
          if (_kind == 'withdraw' && _goalId == 'split') {
            final goals = app.activeGoals;
            _goalId = goals.isNotEmpty ? goals.first.id : bufferId;
          }
        }),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        style: theme.textTheme.headlineSmall,
        decoration: _box(t('amount')),
      ),
      const SizedBox(height: 8),
      chipWrap([
        for (final q in _quick)
          ActionChip(
            label: Text(num0(q)),
            onPressed: () => setState(() => _amount.text = q.toString()),
          ),
      ]),
    ];

    switch (_kind) {
      case 'saving':
        children.addAll([
          _label(context, t('goal')),
          _goalChips(withdraw: false),
          if (loans.isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _repay,
              onChanged: (v) => setState(() => _repay = v),
              title: Text(t('countAsRepay')),
              subtitle: Text(tf('owed', {'a': money(app.outstanding(loans.first))})),
            ),
          _label(context, t('location')),
          _locationChips(),
        ]);
        break;
      case 'spending':
        children.addAll([
          _label(context, t('category')),
          chipWrap([
            for (final c in categories)
              ChoiceChip(
                label: Text(t('cat_$c')),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ]),
          if ((app.limits[_category] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              tf('limitStatus', {
                'a': money(app.monthSpent(_category)),
                'b': money(app.limits[_category]!),
              }),
              style: theme.textTheme.bodySmall,
            ),
          ],
          _label(context, t('paidFrom')),
          _locationChips(optional: true),
        ]);
        break;
      case 'income':
        children.addAll([
          _label(context, t('incomeSource')),
          chipWrap([
            for (final s in incomeSources)
              ChoiceChip(
                label: Text(t('src_$s')),
                selected: _source == s,
                onSelected: (_) => setState(() => _source = s),
              ),
          ]),
          _label(context, t('receivedIn')),
          _locationChips(),
        ]);
        break;
      case 'withdraw':
        children.addAll([
          _label(context, t('withdrawFrom')),
          _goalChips(withdraw: true),
          _label(context, t('takenFrom')),
          _locationChips(),
          _label(context, t('reason')),
          chipWrap([
            for (final r in withdrawReasons)
              ChoiceChip(
                label: Text(t('why_$r')),
                selected: _reason == r,
                onSelected: (_) => setState(() => _reason = r),
              ),
          ]),
          if (_goalId != bufferId) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isLoan,
              onChanged: (v) => setState(() => _isLoan = v),
              title: Text(t('borrowFromSelf')),
              subtitle: Text(t('borrowHelp')),
            ),
            if (_isLoan) ...[
              chipWrap([
                for (final d in _loanChoices)
                  ChoiceChip(
                    label: Text('$d ${t('days').toLowerCase()}'),
                    selected: _loanDays == d,
                    onSelected: (_) => setState(() => _loanDays = d),
                  ),
              ]),
              if (_amt > 0) ...[
                const SizedBox(height: 8),
                Text(
                    tf('payBackPlan', {
                      'a': moneyUp(_amt / _loanDays),
                      'd': '$_loanDays'
                    }),
                    style: theme.textTheme.bodySmall),
              ],
            ],
          ],
          if (_goalId != bufferId) _impactCard(context),
          if (lockedRequest) ...[
            const SizedBox(height: 12),
            Text(t('lockedNotice'),
                style: TextStyle(color: theme.colorScheme.primary)),
          ],
        ]);
        break;
    }

    children.addAll([
      if (_kind != 'withdraw') ...[
        _label(context, t('date')),
        chipWrap([
          ChoiceChip(
            label: Text(t('today')),
            selected: sameDay(_date, today),
            onSelected: (_) => setState(() => _date = today),
          ),
          ChoiceChip(
            label: Text(t('yesterday')),
            selected: sameDay(_date, yesterday),
            onSelected: (_) => setState(() => _date = yesterday),
          ),
          ChoiceChip(
            label: Text(isOther ? fmtDate(_date) : t('otherDay')),
            selected: isOther,
            onSelected: (_) => _pickDate(),
          ),
        ]),
      ],
      const SizedBox(height: 16),
      TextField(controller: _note, decoration: _box(t('note'))),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _save,
        icon: Icon(lockedRequest ? Icons.schedule : Icons.check),
        label: Text(lockedRequest ? t('requestWithdraw') : t('save')),
      ),
    ]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
