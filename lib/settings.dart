import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// True while the PIN screen should cover the app.
final ValueNotifier<bool> appLocked = ValueNotifier<bool>(false);

Future<String?> askPin(BuildContext context, String title) {
  final ctl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        obscureText: true,
        maxLength: 6,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
            border: const OutlineInputBorder(), helperText: t('pinHelp')),
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

// ======================= Lock screen =======================

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (app.useBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _bio() async {
    final ok = await Bio.authenticate();
    if (ok) appLocked.value = false;
  }

  void _check(String v) {
    if (v.length < 4) return;
    if (app.checkPin(v)) {
      appLocked.value = false;
    } else if (v.length >= 6) {
      setState(() => _error = t('wrongPin'));
      _pin.clear();
    }
  }

  void _submit() {
    if (app.checkPin(_pin.text)) {
      appLocked.value = false;
    } else {
      setState(() => _error = t('wrongPin'));
      _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: cs.primary),
                const SizedBox(height: 16),
                Text('Akiba',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(t('enterPin')),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _pin,
                    autofocus: !app.useBiometric,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(letterSpacing: 12),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _check,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), counterText: ''),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: cs.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _submit, child: Text(t('unlock'))),
                if (app.useBiometric) ...[
                  const SizedBox(height: 16),
                  IconButton.filledTonal(
                    iconSize: 36,
                    onPressed: _bio,
                    icon: const Icon(Icons.fingerprint),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= Settings =======================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Draft values: applied only when Save is tapped.
  late String _lang = app.lang;
  late String _themeMode = app.themeMode;
  late String _color = app.colorTheme;
  late int _saveFirst = app.saveFirstPercent;
  late bool _reminderOn = app.reminderOn;
  late int _hour = app.reminderHour;
  late int _minute = app.reminderMinute;
  late List<String> _locations = List<String>.from(app.locations);
  late String _period = app.mainGoal?.period ?? 'day';
  late bool _fixedOn = app.mainGoal?.isFixed ?? false;
  late final TextEditingController _fixed = TextEditingController(
      text: app.mainGoal?.isFixed == true
          ? app.mainGoal!.fixedAmount!.round().toString()
          : '');
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _fixed.addListener(() => setState(() {}));
    Bio.available().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  @override
  void dispose() {
    _fixed.dispose();
    super.dispose();
  }

  double? get _fixedValue {
    if (!_fixedOn) return null;
    final v = double.tryParse(_fixed.text) ?? 0;
    return v > 0 ? v : null;
  }

  bool get _dirty {
    final g = app.mainGoal;
    final locChanged = _locations.length != app.locations.length ||
        !_locations.every(app.locations.contains);
    final targetChanged = g != null &&
        (_period != g.period ||
            (_fixedValue ?? -1) != (g.isFixed ? g.fixedAmount! : -1));
    return _lang != app.lang ||
        _themeMode != app.themeMode ||
        _color != app.colorTheme ||
        _saveFirst != app.saveFirstPercent ||
        _reminderOn != app.reminderOn ||
        _hour != app.reminderHour ||
        _minute != app.reminderMinute ||
        locChanged ||
        targetChanged;
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _save() async {
    if (_fixedOn && _fixedValue == null) {
      _snack(t('invalidAmount'));
      return;
    }
    final langChanged = _lang != app.lang;
    final reminderChanged = _reminderOn != app.reminderOn ||
        _hour != app.reminderHour ||
        _minute != app.reminderMinute ||
        _lang != app.lang;
    var reminderOk = _reminderOn;
    if (reminderChanged) {
      if (_reminderOn) {
        await Reminders.requestPermission();
        reminderOk = await Reminders.schedule(_hour, _minute);
      } else {
        await Reminders.cancel();
      }
    }
    app.applySettings(
      lang: _lang,
      themeMode: _themeMode,
      colorTheme: _color,
      saveFirstPercent: _saveFirst,
      reminderOn: reminderOk,
      reminderHour: _hour,
      reminderMinute: _minute,
      locations: _locations,
      period: _period,
      fixedAmount: _fixedValue,
    );
    if (langChanged) {
      for (final p in app.plans) {
        await Reminders.schedulePlan(p);
      }
      for (final b in app.bills) {
        await Reminders.scheduleBill(b);
      }
    }
    if (!mounted) return;
    setState(() {});
    _snack(reminderChanged && _reminderOn && !reminderOk
        ? t('reminderFailed')
        : t('settingsSaved'));
  }

  Future<void> _maybeLeave() async {
    final leave =
        await confirmDialog(context, t('unsavedAsk'), okLabel: t('discard'));
    if (leave && mounted) Navigator.pop(context);
  }

  // ---------- target ----------
  Widget _targetSection(BuildContext context) {
    final theme = Theme.of(context);
    final g = app.mainGoal;
    if (g == null) return Text(t('noMainGoal'));
    final per = switch (_period) {
      'week' => t('perWeek'),
      'month' => t('perMonth'),
      _ => t('perDay'),
    };
    final children = <Widget>[
      Text(t('targetPeriod'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final p in periodTypes)
            ButtonSegment(value: p, label: Text(periodName(p))),
        ],
        selected: {_period},
        onSelectionChanged: (s) => setState(() => _period = s.first),
      ),
      const SizedBox(height: 12),
      Text(t('targetAmountMode'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'auto', label: Text(t('auto'))),
          ButtonSegment(value: 'fixed', label: Text(t('fixed'))),
        ],
        selected: {_fixedOn ? 'fixed' : 'auto'},
        onSelectionChanged: (s) => setState(() {
          _fixedOn = s.first == 'fixed';
          if (_fixedOn && (double.tryParse(_fixed.text) ?? 0) <= 0) {
            final v = app.autoTargetNow(g).ceil();
            _fixed.text = (v > 0 ? v : 1000).toString();
          }
        }),
      ),
      const SizedBox(height: 12),
    ];
    if (!_fixedOn) {
      children.add(Text(
          tf('autoExplain', {'a': '${moneyUp(app.autoTargetNow(g))} ${perLabel(g)}'}),
          style: theme.textTheme.bodySmall));
    } else {
      children.add(TextField(
        controller: _fixed,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
            labelText: '${t('fixedAmount')} ($per)',
            border: const OutlineInputBorder()),
      ));
      if (_period == g.period && _fixedValue != null) {
        final f = app.finishAt(g, _fixedValue!);
        if (f != null) {
          final isLate = f.isAfter(g.deadline);
          final finishText = tf('fixedFinish', {
            'a': '${moneyUp(_fixedValue!)} $per',
            'b': fmtDate(f),
          });
          final verdict = isLate
              ? tf('fixedLate', {'c': fmtDate(g.deadline)})
              : t('fixedEarly');
          children.add(Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$finishText $verdict',
              style: TextStyle(
                  color: isLate ? theme.colorScheme.error : Colors.green.shade700),
            ),
          ));
        }
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  // ---------- appearance ----------
  Widget _appearance(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    IconData modeIcon(String m) => switch (m) {
          'light' => Icons.light_mode_outlined,
          'dark' => Icons.dark_mode_outlined,
          'black' => Icons.contrast,
          _ => Icons.phone_android,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (final m in themeModes)
              Material(
                color: _themeMode == m ? cs.secondaryContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _themeMode = m),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(modeIcon(m), size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                          child: Text(t('mode_$m'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: _themeMode == m
                                      ? FontWeight.w700
                                      : FontWeight.w400))),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(t('colorTheme'), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in colorThemes)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: paletteFor(c).heroTrack,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _color == c ? paletteFor(c).soft : Colors.transparent,
                          width: 3),
                    ),
                    child: _color == c
                        ? Icon(Icons.check, color: paletteFor(c).ink, size: 20)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(t('color_$c'), style: theme.textTheme.labelSmall),
                ]),
              ),
          ],
        ),
      ],
    );
  }

  // ---------- security (applied at once: each has its own confirmation) ----------
  Future<void> _togglePin(bool on) async {
    if (!on) {
      final ok = await confirmDialog(context, t('pinOffAsk'), okLabel: t('ok'));
      if (ok) app.setPin(null);
      return;
    }
    final a = await askPin(context, t('newPin'));
    if (a == null || a.length < 4) {
      if (a != null && mounted) _snack(t('pinTooShort'));
      return;
    }
    if (!mounted) return;
    final b = await askPin(context, t('repeatPin'));
    if (b != a) {
      if (mounted) _snack(t('pinMismatch'));
      return;
    }
    app.setPin(a);
    if (mounted) _snack(t('pinSet'));
  }

  Future<void> _toggleBio(bool on) async {
    if (on) {
      final ok = await Bio.authenticate();
      if (!ok) return;
    }
    app.setBiometric(on);
  }

  // ---------- data ----------
  Future<void> _addLocation() async {
    final v = await askText(context, t('addLocation'));
    final x = v?.trim() ?? '';
    if (x.isNotEmpty && !_locations.contains(x)) {
      setState(() => _locations.add(x));
    }
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: app.exportJson()));
    if (mounted) _snack(t('backupCopied'));
  }

  Future<void> _shareBackup() async {
    final ok = await BackupFiles.share();
    if (!ok && mounted) _snack(t('backupFailed'));
  }

  Future<void> _restoreText(String v) async {
    final ok = await confirmDialog(context, t('restoreAsk'), okLabel: t('restore'));
    if (!ok) return;
    final done = app.importJson(v);
    if (!mounted) return;
    if (done) {
      setState(() {
        _lang = app.lang;
        _themeMode = app.themeMode;
        _color = app.colorTheme;
        _saveFirst = app.saveFirstPercent;
        _reminderOn = app.reminderOn;
        _hour = app.reminderHour;
        _minute = app.reminderMinute;
        _locations = List<String>.from(app.locations);
        _period = app.mainGoal?.period ?? 'day';
        _fixedOn = app.mainGoal?.isFixed ?? false;
      });
    }
    _snack(done ? t('restored') : t('restoreFailed'));
  }

  Future<void> _restorePaste() async {
    final v = await askText(context, t('pasteBackup'), maxLines: 6);
    if (v == null || v.trim().isEmpty) return;
    await _restoreText(v);
  }

  Future<void> _restoreFile() async {
    final v = await BackupFiles.pick();
    if (v == null) {
      if (mounted) _snack(t('restoreFailed'));
      return;
    }
    if (mounted) await _restoreText(v);
  }

  Future<void> _reset() async {
    final ok =
        await confirmDialog(context, t('resetConfirm'), okLabel: t('delete'));
    if (!ok || !mounted) return;
    await Reminders.cancel();
    for (final p in app.plans) {
      await Reminders.cancelId(p.notifId);
    }
    for (final b in app.bills) {
      await Reminders.cancelId(b.notifId);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    app.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final dirty = _dirty;
        Widget header(String s) => Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(s,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
            );
        final time = TimeOfDay(hour: _hour, minute: _minute).format(context);
        return PopScope(
          canPop: !dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _maybeLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(t('settings')),
              actions: [
                if (dirty)
                  TextButton(onPressed: _save, child: Text(t('save'))),
              ],
            ),
            bottomNavigationBar: dirty
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            child: Text(t('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(t('save')),
                          ),
                        ),
                      ]),
                    ),
                  )
                : null,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                header(t('language')),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {_lang},
                  onSelectionChanged: (s) => setState(() => _lang = s.first),
                ),
                header(t('appearance')),
                _appearance(context),
                header(t('savingTarget')),
                _targetSection(context),
                header(t('reminder')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reminderOn,
                  onChanged: (v) => setState(() => _reminderOn = v),
                  title: Text(t('dailyReminder')),
                  subtitle: Text(t('reminderHelp')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _reminderOn,
                  leading: const Icon(Icons.schedule),
                  title: Text(t('reminderTime')),
                  trailing: Text(time),
                  onTap: _reminderOn
                      ? () async {
                          final tm = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _hour, minute: _minute),
                          );
                          if (tm != null) {
                            setState(() {
                              _hour = tm.hour;
                              _minute = tm.minute;
                            });
                          }
                        }
                      : null,
                ),
                header(t('saveFirst')),
                Text(t('saveFirstHelp'), style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                chipWrap([
                  for (final p in [0, 5, 10, 15, 20, 30])
                    ChoiceChip(
                      label: Text(p == 0 ? t('off') : '$p%'),
                      selected: _saveFirst == p,
                      onSelected: (_) => setState(() => _saveFirst = p),
                    ),
                ]),
                header(t('locations')),
                chipWrap([
                  for (final l in _locations)
                    InputChip(
                      label: Text(l),
                      onDeleted: _locations.length > 1
                          ? () => setState(() => _locations.remove(l))
                          : null,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(t('addLocation')),
                    onPressed: _addLocation,
                  ),
                ]),
                header(t('security')),
                Text(t('securityNow'), style: theme.textTheme.bodySmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: app.hasPin,
                  onChanged: _togglePin,
                  title: Text(t('pinLock')),
                  subtitle: Text(t('pinLockHelp')),
                ),
                if (app.hasPin && _bioAvailable)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: app.useBiometric,
                    onChanged: _toggleBio,
                    title: Text(t('fingerprint')),
                  ),
                header(t('backup')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ios_share),
                  title: Text(t('shareBackup')),
                  subtitle: Text(t('shareBackupSub')),
                  onTap: _shareBackup,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(t('restoreFile')),
                  onTap: _restoreFile,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_all_outlined),
                  title: Text(t('copyBackup')),
                  subtitle: Text(t('copyBackupSub')),
                  onTap: _copyBackup,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_paste),
                  title: Text(t('restore')),
                  onTap: _restorePaste,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined, color: cs.error),
                  title: Text(t('resetAll'), style: TextStyle(color: cs.error)),
                  onTap: _reset,
                ),
                header(t('about')),
                const Text('Akiba 4.0'),
              ],
            ),
          ),
        );
      },
    );
  }
}
