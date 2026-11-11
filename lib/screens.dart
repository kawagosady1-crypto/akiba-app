import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'i18n.dart';
import 'home.dart';
import 'insights.dart';
import 'plans.dart';
import 'profile.dart';
import 'settings.dart';
import 'sheets.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================= Onboarding =======================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  final _amount = TextEditingController();
  final _startCtl = TextEditingController();
  String _startLocation = app.locations.isNotEmpty ? app.locations.first : '';
  DateTime _deadline = addDays(dayOnly(DateTime.now()), 90);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _amount.dispose();
    _startCtl.dispose();
    super.dispose();
  }

  double get _amt => double.tryParse(_amount.text) ?? 0;
  double get _startAmt => double.tryParse(_startCtl.text) ?? 0;

  Future<void> _pickDeadline() async {
    final today = dayOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: addDays(today, 1),
      lastDate: addDays(today, 3650),
    );
    if (d != null) setState(() => _deadline = d);
  }

  void _start() {
    if (_goal.text.trim().isEmpty) {
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
    final today = dayOnly(DateTime.now());
    app.completeOnboarding(
      _name.text,
      Goal(
        id: newId(),
        name: _goal.text.trim(),
        type: 'main',
        target: _amt,
        start: today,
        deadline: dayOnly(_deadline),
      ),
      startAmount: _startAmt,
      startLocation: _startLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dayOnly(DateTime.now());
    final days = max(1, daysBetween(today, _deadline) + 1);
    final need = _amt - _startAmt;
    final preview = need > 0 ? need / days : 0.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Icon(Icons.savings, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(t('welcome'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(t('welcomeSub'),
                textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(t('language'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {app.lang},
              onSelectionChanged: (s) => setState(() => app.setLang(s.first)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: t('yourName'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Text(t('firstGoal'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _goal,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: t('goalName'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: t('goalAmount'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: t('alreadySaved'),
                  helperText: t('alreadySavedHelp'),
                  border: const OutlineInputBorder()),
            ),
            if (_startAmt > 0) ...[
              const SizedBox(height: 12),
              Text(t('whereKept'), style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
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
              label: Text(
                  '${t('deadline')}: ${fmtDate(_deadline)}  ($days ${t('days').toLowerCase()})'),
            ),
            if (preview > 0) ...[
              const SizedBox(height: 16),
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(t('dailyTargetPreview'),
                          style: TextStyle(color: cs.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(moneyUp(preview),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(t('changeLater'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onPrimaryContainer)),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(t('start')),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Shell (bottom tabs) =======================

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListenableBuilder(
          listenable: app,
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: Text(t('history'))),
            body: const HistoryScreen(),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData selected, String label) {
    final cs = Theme.of(context).colorScheme;
    final on = _index == i;
    return Expanded(
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        radius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: on ? cs.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(on ? selected : icon,
                  color: on ? cs.onSecondaryContainer : cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                    color: on ? cs.onSurface : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final pages = <Widget>[
          HomeScreen(onOpenHistory: _openHistory),
          const PlansScreen(),
          const InsightsScreen(),
          const RewardsScreen(),
        ];
        final titles = ['', t('planTab'), t('insights'), t('rewards')];
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            toolbarHeight: _index == 0 ? 70 : null,
            title: _index == 0
                ? InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Row(
                      children: [
                        Avatar(
                            photo: app.profilePhoto,
                            name: app.userName.isEmpty ? 'Akiba' : app.userName,
                            size: 44),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t('hello'),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              Text(app.userName.isEmpty ? 'Akiba' : app.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              if (app.motto.isNotEmpty)
                                Text(app.motto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: pal.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(titles[_index],
                    style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: t('history'),
                onPressed: _openHistory,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: t('settings'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey('tab$_index${app.lang}'),
              child: pages[_index],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            shape: const CircleBorder(),
            elevation: 2,
            tooltip: t('log'),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (app.activeGoals.isEmpty) {
                showGoalSheet(context, type: 'main');
              } else {
                showLogSheet(context);
              }
            },
            child: const Icon(Icons.add, size: 30),
          ),
          bottomNavigationBar: BottomAppBar(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, Icons.home, t('home')),
                _navItem(1, Icons.event_note_outlined, Icons.event_note, t('planTab')),
                const SizedBox(width: 64),
                _navItem(2, Icons.insights_outlined, Icons.insights, t('insights')),
                _navItem(3, Icons.emoji_events_outlined, Icons.emoji_events,
                    t('rewards')),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================= History =======================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _mode = 'periods';
  String _filter = 'all';

  Widget _periods(BuildContext context) {
    final g = app.mainGoal;
    if (g == null) return Center(child: Text(t('noMainGoal')));
    final stats = app.periodStats(g).reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: stats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = stats[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(periodTitle(s, g)),
          subtitle: Text(
              '${t('target')}: ${num0(s.target.ceil())}   ${t('actual')}: ${num0(s.actual)}'),
          trailing: StatusChip(s.status),
        );
      },
    );
  }

  Widget _entries(BuildContext context) {
    var list = app.sortedTxns;
    if (_filter != 'all') list = list.where((x) => x.kind == _filter).toList();
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in ['all', 'saving', 'spending', 'withdrawal', 'income'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t('filter_$f')),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(t('noEntries')))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final x = list[i];
                    return Dismissible(
                      key: ValueKey(x.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => confirmDialog(
                          context, t('deleteEntry'),
                          okLabel: t('delete')),
                      onDismissed: (_) => app.deleteTxn(x.id),
                      child: TxnTile(x),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'periods', label: Text(t('periodsTab'))),
                ButtonSegment(value: 'entries', label: Text(t('entries'))),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        ),
        Expanded(
            child:
                _mode == 'periods' ? _periods(context) : _entries(context)),
      ],
    );
  }
}
