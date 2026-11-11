import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';

/// The single app state, used by every screen.
final AppState app = AppState();

const String bufferId = 'buffer';
const List<String> categories = [
  'food',
  'transport',
  'airtime',
  'bills',
  'family',
  'other'
];
const List<String> incomeSources = ['salary', 'business', 'gift', 'other'];
const List<String> withdrawReasons = [
  'emergency',
  'planned',
  'goalReached',
  'other'
];
const List<String> defaultLocations = [
  'M-Pesa',
  'Mixx by Yas',
  'Airtel Money',
  'Bank',
  'Cash'
];
const List<String> periodTypes = ['day', 'week', 'month'];
const List<String> badgeIds = [
  'firstSave',
  'streak7',
  'streak30',
  'saved100k',
  'saved1m',
  'goalDone',
  'noSpend7',
  'loanRepaid',
  'challengeDone',
];
const List<String> challengeTypes = ['week52', 'nospend', 'streak30'];
const double week52Total = 1378000; // 1,000 + 2,000 + ... + 52,000

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;
String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
bool sameDay(DateTime a, DateTime b) => daysBetween(a, b) == 0;
bool inRange(DateTime d, DateTime from, DateTime to) =>
    !dayOnly(d).isBefore(dayOnly(from)) && !dayOnly(d).isAfter(dayOnly(to));

final Random _rnd = Random();
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(99999)}';

/// Simple FNV-1a hash so the PIN is not stored as plain text.
String hashPin(String pin) {
  var h = 0x811c9dc5;
  for (final c in 'akiba:$pin'.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16);
}

void _add(Map<String, double> m, DateTime d, double v) {
  m.update(dayKey(d), (x) => x + v, ifAbsent: () => v);
}

// ======================= Models =======================

class Goal {
  final String id;
  String name;
  String type; // 'main' or 'mini'
  double target;
  DateTime start;
  DateTime deadline;
  String extraDest; // 'goal' or 'buffer'
  bool archived;
  String period; // 'day', 'week' or 'month'
  double? fixedAmount; // null = automatic target
  bool locked; // 24-hour cooling-off before withdrawals
  String? photoPath;

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.start,
    required this.deadline,
    this.extraDest = 'goal',
    this.archived = false,
    this.period = 'day',
    this.fixedAmount,
    this.locked = false,
    this.photoPath,
  });

  bool get isFixed => fixedAmount != null && fixedAmount! > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'target': target,
        'start': start.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'extraDest': extraDest,
        'archived': archived,
        'period': period,
        'fixedAmount': fixedAmount,
        'locked': locked,
        'photoPath': photoPath,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        target: (j['target'] as num).toDouble(),
        start: DateTime.parse(j['start'] as String),
        deadline: DateTime.parse(j['deadline'] as String),
        extraDest: (j['extraDest'] as String?) ?? 'goal',
        archived: (j['archived'] as bool?) ?? false,
        period: (j['period'] as String?) ?? 'day',
        fixedAmount:
            ((j['fixedAmount'] ?? j['fixedDaily']) as num?)?.toDouble(),
        locked: (j['locked'] as bool?) ?? false,
        photoPath: j['photoPath'] as String?,
      );
}

class Txn {
  final String id;
  String kind; // 'saving', 'spending', 'withdrawal', 'income'
  double amount;
  String goalId; // saving / withdrawal
  String category; // spending
  String location;
  String source; // 'manual' now; 'sms', 'mpesa', 'bank' later
  String externalRef;
  DateTime date;
  String note;
  String reason; // withdrawal reason or income source
  bool isLoan; // withdrawal to pay back
  int loanDays; // pay-back plan length
  String loanId; // on a saving: the loan it repays

  Txn({
    required this.id,
    required this.kind,
    required this.amount,
    this.goalId = '',
    this.category = '',
    this.location = '',
    this.source = 'manual',
    this.externalRef = '',
    required this.date,
    this.note = '',
    this.reason = '',
    this.isLoan = false,
    this.loanDays = 0,
    this.loanId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'amount': amount,
        'goalId': goalId,
        'category': category,
        'location': location,
        'source': source,
        'externalRef': externalRef,
        'date': date.toIso8601String(),
        'note': note,
        'reason': reason,
        'isLoan': isLoan,
        'loanDays': loanDays,
        'loanId': loanId,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        kind: j['kind'] as String,
        amount: (j['amount'] as num).toDouble(),
        goalId: (j['goalId'] as String?) ?? '',
        category: (j['category'] as String?) ?? '',
        location: (j['location'] as String?) ?? '',
        source: (j['source'] as String?) ?? 'manual',
        externalRef: (j['externalRef'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        note: (j['note'] as String?) ?? '',
        reason: (j['reason'] as String?) ?? '',
        isLoan: (j['isLoan'] as bool?) ?? false,
        loanDays: (j['loanDays'] as num?)?.toInt() ?? 0,
        loanId: (j['loanId'] as String?) ?? '',
      );
}

class WithdrawRequest {
  final String id;
  final String goalId;
  final double amount;
  final String location;
  final String reason;
  final bool isLoan;
  final int loanDays;
  final String note;
  final DateTime requestedAt;

  WithdrawRequest({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.location,
    required this.reason,
    required this.isLoan,
    required this.loanDays,
    required this.note,
    required this.requestedAt,
  });

  DateTime get readyAt => requestedAt.add(const Duration(hours: 24));
  bool get isReady => !DateTime.now().isBefore(readyAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'location': location,
        'reason': reason,
        'isLoan': isLoan,
        'loanDays': loanDays,
        'note': note,
        'requestedAt': requestedAt.toIso8601String(),
      };

  factory WithdrawRequest.fromJson(Map<String, dynamic> j) => WithdrawRequest(
        id: j['id'] as String,
        goalId: j['goalId'] as String,
        amount: (j['amount'] as num).toDouble(),
        location: (j['location'] as String?) ?? '',
        reason: (j['reason'] as String?) ?? 'other',
        isLoan: (j['isLoan'] as bool?) ?? false,
        loanDays: (j['loanDays'] as num?)?.toInt() ?? 0,
        note: (j['note'] as String?) ?? '',
        requestedAt: DateTime.parse(j['requestedAt'] as String),
      );
}

class Challenge {
  final String id;
  final String type; // 'week52', 'nospend', 'streak30'
  final DateTime start;
  bool active;

  Challenge(
      {required this.id,
      required this.type,
      required this.start,
      this.active = true});

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'start': start.toIso8601String(),
        'active': active,
      };

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        type: j['type'] as String,
        start: DateTime.parse(j['start'] as String),
        active: (j['active'] as bool?) ?? true,
      );
}

class ChallengeProgress {
  final double value;
  final double goal;
  final bool done;
  final bool ended;
  final int week; // week52 only
  final double weekTarget; // week52 only
  final double weekSaved; // week52 only

  ChallengeProgress({
    required this.value,
    required this.goal,
    required this.done,
    required this.ended,
    this.week = 0,
    this.weekTarget = 0,
    this.weekSaved = 0,
  });

  double get fraction => goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
}

enum DayStatus { above, on, short, missed, pending, done }

/// One saving period (a day, week or month) of a goal.
class PeriodStat {
  final DateTime start;
  final DateTime end;
  final double target;
  final double actual;
  PeriodStat(this.start, this.end, this.target, this.actual);

  bool get met => actual >= target - 0.5;
  double get extra => max(0.0, actual - target);
  double get shortfall => max(0.0, target - actual);
  bool get isCurrent => inRange(DateTime.now(), start, end);

  DayStatus get status {
    if (target <= 0.5) return actual > 0 ? DayStatus.above : DayStatus.done;
    if (met) return actual > target + 0.5 ? DayStatus.above : DayStatus.on;
    if (isCurrent) return DayStatus.pending;
    return actual <= 0 ? DayStatus.missed : DayStatus.short;
  }
}

class SavePlan {
  final String id;
  String goalId;
  double amount;
  String frequency; // 'daily', 'weekly', 'monthly'
  int weekday; // 1 = Monday ... 7 = Sunday
  int monthDay; // 1..28
  int hour;
  int minute;
  DateTime? lastDone;
  final int notifId;

  SavePlan({
    required this.id,
    required this.goalId,
    required this.amount,
    this.frequency = 'weekly',
    this.weekday = 5,
    this.monthDay = 1,
    this.hour = 18,
    this.minute = 0,
    this.lastDone,
    required this.notifId,
  });

  bool get dueToday {
    final now = DateTime.now();
    final due = switch (frequency) {
      'daily' => true,
      'monthly' => now.day == monthDay,
      _ => now.weekday == weekday,
    };
    return due && !(lastDone != null && sameDay(lastDone!, now));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'frequency': frequency,
        'weekday': weekday,
        'monthDay': monthDay,
        'hour': hour,
        'minute': minute,
        'lastDone': lastDone?.toIso8601String(),
        'notifId': notifId,
      };

  factory SavePlan.fromJson(Map<String, dynamic> j) => SavePlan(
        id: j['id'] as String,
        goalId: j['goalId'] as String,
        amount: (j['amount'] as num).toDouble(),
        frequency: (j['frequency'] as String?) ?? 'weekly',
        weekday: (j['weekday'] as num?)?.toInt() ?? 5,
        monthDay: (j['monthDay'] as num?)?.toInt() ?? 1,
        hour: (j['hour'] as num?)?.toInt() ?? 18,
        minute: (j['minute'] as num?)?.toInt() ?? 0,
        lastDone: j['lastDone'] == null ? null : DateTime.parse(j['lastDone'] as String),
        notifId: (j['notifId'] as num?)?.toInt() ?? 2000,
      );
}

class Bill {
  final String id;
  String name;
  double amount;
  int dueDay; // 1..28, every month
  String lastPaidMonth; // 'YYYY-M' or ''
  final int notifId;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.lastPaidMonth = '',
    required this.notifId,
  });

  static String monthKey(DateTime d) => '${d.year}-${d.month}';
  bool get paidThisMonth => lastPaidMonth == monthKey(DateTime.now());
  DateTime get dueDate {
    final n = DateTime.now();
    return DateTime(n.year, n.month, dueDay);
  }

  /// Days until this month's due date (negative = overdue).
  int get daysToDue => daysBetween(DateTime.now(), dueDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDay': dueDay,
        'lastPaidMonth': lastPaidMonth,
        'notifId': notifId,
      };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        dueDay: (j['dueDay'] as num?)?.toInt() ?? 1,
        lastPaidMonth: (j['lastPaidMonth'] as String?) ?? '',
        notifId: (j['notifId'] as num?)?.toInt() ?? 3000,
      );
}

class Debt {
  final String id;
  String person;
  String direction; // 'owedToMe' or 'iOwe'
  double amount;
  double paid;
  DateTime? dueDate;
  String note;

  Debt({
    required this.id,
    required this.person,
    required this.direction,
    required this.amount,
    this.paid = 0,
    this.dueDate,
    this.note = '',
  });

  double get remaining => max(0.0, amount - paid);
  bool get settled => remaining <= 0.5;

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'direction': direction,
        'amount': amount,
        'paid': paid,
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
      };

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id'] as String,
        person: j['person'] as String,
        direction: (j['direction'] as String?) ?? 'owedToMe',
        amount: (j['amount'] as num).toDouble(),
        paid: (j['paid'] as num?)?.toDouble() ?? 0,
        dueDate: j['dueDate'] == null ? null : DateTime.parse(j['dueDate'] as String),
        note: (j['note'] as String?) ?? '',
      );
}

/// A short insight shown in Stats.
class Tip {
  final String icon; // 'up', 'down', 'star', 'fire', 'pie'
  final String text;
  Tip(this.icon, this.text);
}

// ======================= State =======================

class AppState extends ChangeNotifier {
  static const String _key = 'akiba_data_v1';
  SharedPreferences? _prefs;

  String lang = 'sw';
  String userName = '';
  bool onboarded = false;
  List<Goal> goals = [];
  List<Txn> txns = [];
  List<WithdrawRequest> requests = [];
  List<Challenge> challenges = [];
  List<String> locations = List<String>.from(defaultLocations);
  Map<String, double> limits = {};
  int saveFirstPercent = 10;
  bool reminderOn = false;
  int reminderHour = 20;
  int reminderMinute = 0;
  String pinHash = '';
  bool useBiometric = false;
  bool hideBalance = false;
  String lastLocation = '';
  // profile
  String profilePhoto = '';
  String phone = '';
  String email = '';
  String city = '';
  String motto = '';
  // appearance
  String themeMode = 'system'; // system, light, dark, black
  String colorTheme = 'green'; // green, blue, purple, gold, coral
  // plans
  Map<String, int> splitPlan = {};
  List<SavePlan> plans = [];
  List<Bill> bills = [];
  List<Debt> debts = [];

  bool get hasPin => pinHash.isNotEmpty;

  // ---------- persistence ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    currentLang = lang;
  }

  Map<String, dynamic> _toJson() => {
        'version': 2,
        'lang': lang,
        'userName': userName,
        'onboarded': onboarded,
        'locations': locations,
        'limits': limits,
        'saveFirstPercent': saveFirstPercent,
        'reminderOn': reminderOn,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'pinHash': pinHash,
        'useBiometric': useBiometric,
        'hideBalance': hideBalance,
        'lastLocation': lastLocation,
        'profilePhoto': profilePhoto,
        'phone': phone,
        'email': email,
        'city': city,
        'motto': motto,
        'themeMode': themeMode,
        'colorTheme': colorTheme,
        'splitPlan': splitPlan,
        'plans': plans.map((x) => x.toJson()).toList(),
        'bills': bills.map((x) => x.toJson()).toList(),
        'debts': debts.map((x) => x.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'txns': txns.map((x) => x.toJson()).toList(),
        'requests': requests.map((r) => r.toJson()).toList(),
        'challenges': challenges.map((c) => c.toJson()).toList(),
      };

  List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
    if (v is! List) return <T>[];
    return v.map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
  }

  void _fromJson(Map<String, dynamic> j) {
    final g = _list(j['goals'], Goal.fromJson);
    final x = _list(j['txns'], Txn.fromJson);
    goals = g;
    txns = x;
    requests = _list(j['requests'], WithdrawRequest.fromJson);
    challenges = _list(j['challenges'], Challenge.fromJson);
    lang = (j['lang'] as String?) ?? 'sw';
    userName = (j['userName'] as String?) ?? '';
    onboarded = (j['onboarded'] as bool?) ?? true;
    final locs = j['locations'];
    locations = locs is List && locs.isNotEmpty
        ? locs.map((e) => e.toString()).toList()
        : List<String>.from(defaultLocations);
    final lim = j['limits'];
    limits = {};
    if (lim is Map) {
      lim.forEach((k, v) {
        if (v is num && v > 0) limits[k.toString()] = v.toDouble();
      });
    }
    saveFirstPercent = (j['saveFirstPercent'] as num?)?.toInt() ?? 10;
    reminderOn = (j['reminderOn'] as bool?) ?? false;
    reminderHour = (j['reminderHour'] as num?)?.toInt() ?? 20;
    reminderMinute = (j['reminderMinute'] as num?)?.toInt() ?? 0;
    pinHash = (j['pinHash'] as String?) ?? '';
    useBiometric = (j['useBiometric'] as bool?) ?? false;
    hideBalance = (j['hideBalance'] as bool?) ?? false;
    lastLocation = (j['lastLocation'] as String?) ?? '';
    profilePhoto = (j['profilePhoto'] as String?) ?? '';
    phone = (j['phone'] as String?) ?? '';
    email = (j['email'] as String?) ?? '';
    city = (j['city'] as String?) ?? '';
    motto = (j['motto'] as String?) ?? '';
    themeMode = (j['themeMode'] as String?) ?? 'system';
    colorTheme = (j['colorTheme'] as String?) ?? 'green';
    splitPlan = {};
    final sp = j['splitPlan'];
    if (sp is Map) {
      sp.forEach((k, v) {
        if (v is num && v > 0) splitPlan[k.toString()] = v.toInt();
      });
    }
    plans = _list(j['plans'], SavePlan.fromJson);
    bills = _list(j['bills'], Bill.fromJson);
    debts = _list(j['debts'], Debt.fromJson);
  }

  void _changed() {
    notifyListeners();
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  /// Backup text. The PIN is left out on purpose.
  String exportJson() {
    final j = _toJson();
    j['pinHash'] = '';
    j['useBiometric'] = false;
    return jsonEncode(j);
  }

  bool importJson(String raw) {
    try {
      final j = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (j['goals'] is! List || j['txns'] is! List) return false;
      final keepPin = pinHash;
      final keepBio = useBiometric;
      _fromJson(j);
      pinHash = keepPin;
      useBiometric = keepBio;
      currentLang = lang;
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetAll() {
    goals = [];
    txns = [];
    requests = [];
    challenges = [];
    limits = {};
    userName = '';
    onboarded = false;
    reminderOn = false;
    pinHash = '';
    useBiometric = false;
    locations = List<String>.from(defaultLocations);
    profilePhoto = '';
    phone = '';
    email = '';
    city = '';
    motto = '';
    splitPlan = {};
    plans = [];
    bills = [];
    debts = [];
    _changed();
  }

  // ---------- settings ----------
  void setLang(String l) {
    lang = l;
    currentLang = l;
    _changed();
  }

  void setName(String n) {
    userName = n.trim();
    _changed();
  }

  void addLocation(String l) {
    final v = l.trim();
    if (v.isEmpty || locations.contains(v)) return;
    locations.add(v);
    _changed();
  }

  void removeLocation(String l) {
    if (locations.length <= 1) return;
    locations.remove(l);
    _changed();
  }

  void setLimit(String category, double? amount) {
    if (amount == null || amount <= 0) {
      limits.remove(category);
    } else {
      limits[category] = amount;
    }
    _changed();
  }

  void setSaveFirst(int percent) {
    saveFirstPercent = percent.clamp(0, 100).toInt();
    _changed();
  }

  void setReminder(bool on, int hour, int minute) {
    reminderOn = on;
    reminderHour = hour;
    reminderMinute = minute;
    _changed();
  }

  void setPin(String? pin) {
    pinHash = (pin == null || pin.isEmpty) ? '' : hashPin(pin);
    if (pinHash.isEmpty) useBiometric = false;
    _changed();
  }

  bool checkPin(String pin) => hasPin && hashPin(pin) == pinHash;

  void toggleHideBalance() {
    hideBalance = !hideBalance;
    _changed();
  }

  void setBiometric(bool on) {
    useBiometric = on && hasPin;
    _changed();
  }

  void completeOnboarding(String name, Goal g,
      {double startAmount = 0, String startLocation = ''}) {
    userName = name.trim();
    goals.add(g);
    _setOpeningNoSave(g, startAmount, startLocation);
    onboarded = true;
    _changed();
  }

  // ---------- starting amount ----------
  /// The money already saved when the goal was created.
  Txn? openingTxn(String goalId) {
    for (final x in txns) {
      if (x.kind == 'saving' && x.goalId == goalId && x.reason == 'opening') {
        return x;
      }
    }
    return null;
  }

  double openingAmount(String goalId) => openingTxn(goalId)?.amount ?? 0;

  void _setOpeningNoSave(Goal g, double amount, String location) {
    final existing = openingTxn(g.id);
    if (amount <= 0) {
      if (existing != null) txns.remove(existing);
      return;
    }
    // Dated the day before the goal starts so it counts as already saved.
    final date = addDays(dayOnly(g.start), -1);
    if (existing != null) {
      existing.amount = amount;
      existing.location = location;
      existing.date = date;
    } else {
      txns.add(Txn(
          id: newId(),
          kind: 'saving',
          amount: amount,
          goalId: g.id,
          location: location,
          date: date,
          reason: 'opening'));
    }
  }

  void setOpening(Goal g, double amount, String location) {
    _setOpeningNoSave(g, amount, location);
    _changed();
  }

  // ---------- time vs money ----------
  int dayNumber(Goal g) =>
      max(1, daysBetween(g.start, DateTime.now()) + 1);

  int totalDays(Goal g) => max(1, daysBetween(g.start, g.deadline) + 1);

  double timeFraction(Goal g) =>
      (dayNumber(g) / totalDays(g)).clamp(0.0, 1.0).toDouble();

  double moneyFraction(Goal g) => g.target <= 0
      ? 0.0
      : (balance(g.id) / g.target).clamp(0.0, 1.0).toDouble();

  String get quickLocation => lastLocation.isNotEmpty
      ? lastLocation
      : (locations.isNotEmpty ? locations.first : '');

  // ---------- goals ----------
  Goal? get mainGoal {
    for (final g in goals) {
      if (g.type == 'main' && !g.archived) return g;
    }
    return null;
  }

  List<Goal> get miniGoals =>
      goals.where((g) => g.type == 'mini' && !g.archived).toList();

  List<Goal> get activeGoals {
    final m = mainGoal;
    return [if (m != null) m, ...miniGoals];
  }

  List<Goal> get finishedGoals => goals.where((g) => g.archived).toList();

  Goal? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  void addGoal(Goal g, {double startAmount = 0, String startLocation = ''}) {
    goals.add(g);
    _setOpeningNoSave(g, startAmount, startLocation);
    _changed();
  }

  void updateGoal(Goal g) => _changed();

  void archiveGoal(Goal g) {
    g.archived = true;
    _changed();
  }

  void deleteGoal(Goal g) {
    goals.removeWhere((x) => x.id == g.id);
    txns.removeWhere((x) => x.goalId == g.id);
    requests.removeWhere((r) => r.goalId == g.id);
    _changed();
  }

  void setTargetMode(Goal g, {String? period, double? fixedAmount, bool clearFixed = false}) {
    if (period != null) g.period = period;
    if (clearFixed) {
      g.fixedAmount = null;
    } else if (fixedAmount != null && fixedAmount > 0) {
      g.fixedAmount = fixedAmount;
    }
    _changed();
  }

  // ---------- balances ----------
  double _sum(bool Function(Txn x) test) {
    var s = 0.0;
    for (final x in txns) {
      if (test(x)) s += x.amount;
    }
    return s;
  }

  double savedFor(String goalId) =>
      _sum((x) => x.kind == 'saving' && x.goalId == goalId);

  double withdrawnFrom(String goalId) =>
      _sum((x) => x.kind == 'withdrawal' && x.goalId == goalId);

  /// Money in the goal now: savings minus withdrawals.
  double balance(String goalId) => savedFor(goalId) - withdrawnFrom(goalId);

  double get bufferBalance => balance(bufferId);

  double netBefore(String goalId, DateTime day) {
    final d = dayOnly(day);
    var s = 0.0;
    for (final x in txns) {
      if (x.goalId != goalId || !x.date.isBefore(d)) continue;
      if (x.kind == 'saving') s += x.amount;
      if (x.kind == 'withdrawal') s -= x.amount;
    }
    return s;
  }

  double savedInRange(String goalId, DateTime from, DateTime to) => _sum((x) =>
      x.kind == 'saving' && x.goalId == goalId && inRange(x.date, from, to));

  double totalOn(String kind, DateTime day) =>
      _sum((x) => x.kind == kind && sameDay(x.date, day));

  double totalBetween(String kind, DateTime from, DateTime to) =>
      _sum((x) => x.kind == kind && inRange(x.date, from, to));

  /// Total net savings across every goal and the buffer.
  double get totalNetSaved => _sum((x) => x.kind == 'saving') - _sum((x) => x.kind == 'withdrawal');

  Map<String, double> balanceByLocation() {
    final m = <String, double>{};
    for (final x in txns) {
      if (x.kind != 'saving' && x.kind != 'withdrawal') continue;
      final k = x.location.isEmpty ? '-' : x.location;
      final v = x.kind == 'saving' ? x.amount : -x.amount;
      m.update(k, (a) => a + v, ifAbsent: () => v);
    }
    m.removeWhere((k, v) => v.abs() < 0.5);
    return m;
  }

  Map<String, double> spendingByCategory(DateTime from, DateTime to) {
    final m = <String, double>{};
    for (final x in txns) {
      if (x.kind == 'spending' && inRange(x.date, from, to)) {
        m.update(x.category, (v) => v + x.amount, ifAbsent: () => x.amount);
      }
    }
    return m;
  }

  DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

  double monthSpent(String category, [DateTime? month]) {
    final m = month ?? DateTime.now();
    return _sum((x) =>
        x.kind == 'spending' &&
        x.category == category &&
        inRange(x.date, monthStart(m), monthEnd(m)));
  }

  /// Categories at 80% or more of their monthly limit.
  List<String> categoriesNearLimit() {
    final out = <String>[];
    limits.forEach((c, lim) {
      if (lim > 0 && monthSpent(c) >= lim * 0.8) out.add(c);
    });
    return out;
  }

  // ---------- periods and targets ----------
  DateTime periodEnd(Goal g, DateTime start) {
    final s = dayOnly(start);
    switch (g.period) {
      case 'week':
        return addDays(s, 6);
      case 'month':
        return DateTime(s.year, s.month + 1, 0);
      default:
        return s;
    }
  }

  int periodsLeft(Goal g, DateTime periodStart) {
    final dl = dayOnly(g.deadline);
    final s0 = dayOnly(periodStart);
    if (g.period == 'day') return max(1, daysBetween(s0, dl) + 1);
    var n = 0;
    var s = s0;
    while (!s.isAfter(dl) && n < 2000) {
      n++;
      s = addDays(periodEnd(g, s), 1);
    }
    return max(1, n);
  }

  double _targetFrom(Goal g, double remaining, DateTime periodStart) {
    if (remaining <= 0) return 0;
    if (g.isFixed) return min(g.fixedAmount!, remaining);
    return remaining / periodsLeft(g, periodStart);
  }

  /// One entry per period from the goal's start until the current period.
  List<PeriodStat> periodStats(Goal g) {
    final today = dayOnly(DateTime.now());
    final startDay = dayOnly(g.start);
    final saveByDay = <String, double>{};
    final netByDay = <String, double>{};
    final bufByDay = <String, double>{};
    var before = 0.0;
    for (final x in txns) {
      if (x.goalId == g.id) {
        if (x.kind == 'saving') {
          if (x.date.isBefore(startDay)) {
            before += x.amount;
          } else {
            _add(saveByDay, x.date, x.amount);
            _add(netByDay, x.date, x.amount);
          }
        } else if (x.kind == 'withdrawal') {
          if (x.date.isBefore(startDay)) {
            before -= x.amount;
          } else {
            _add(netByDay, x.date, -x.amount);
          }
        }
      } else if (x.goalId == bufferId &&
          x.kind == 'saving' &&
          g.type == 'main') {
        _add(bufByDay, x.date, x.amount);
      }
    }
    final out = <PeriodStat>[];
    var s = startDay;
    var guard = 0;
    while (!s.isAfter(today) && guard < 4000) {
      guard++;
      final e = periodEnd(g, s);
      final target = _targetFrom(g, g.target - before, s);
      var actual = 0.0;
      var net = 0.0;
      for (var d = s; !d.isAfter(e); d = addDays(d, 1)) {
        final k = dayKey(d);
        actual += (saveByDay[k] ?? 0.0) + (bufByDay[k] ?? 0.0);
        net += netByDay[k] ?? 0.0;
      }
      out.add(PeriodStat(s, e, target, actual));
      before += net;
      s = addDays(e, 1);
    }
    return out;
  }

  PeriodStat currentStat(Goal g) {
    final s = periodStats(g);
    if (s.isNotEmpty) return s.last;
    final today = dayOnly(DateTime.now());
    return PeriodStat(today, periodEnd(g, today),
        _targetFrom(g, g.target - balance(g.id), today), 0);
  }

  PeriodStat? statContaining(Goal g, DateTime day) {
    for (final s in periodStats(g)) {
      if (inRange(day, s.start, s.end)) return s;
    }
    return null;
  }

  /// The current period's automatic target, ignoring any fixed amount.
  double autoTargetNow(Goal g) {
    final cur = currentStat(g);
    final remaining = g.target - netBefore(g.id, cur.start);
    if (remaining <= 0) return 0;
    return remaining / periodsLeft(g, cur.start);
  }

  /// Target of the next period, optionally after a planned withdrawal.
  double nextTarget(Goal g, {double extraWithdraw = 0}) {
    final cur = currentStat(g);
    final nextStart = addDays(cur.end, 1);
    final remaining = g.target - (balance(g.id) - extraWithdraw);
    return _targetFrom(g, remaining, nextStart);
  }

  /// End of the period in which the goal is reached at [perPeriod].
  DateTime? finishAt(Goal g, double perPeriod, {double extraWithdraw = 0}) {
    if (perPeriod <= 0) return null;
    final cur = currentStat(g);
    final remaining = g.target - (netBefore(g.id, cur.start) - extraWithdraw);
    if (remaining <= 0) return dayOnly(DateTime.now());
    final n = (remaining / perPeriod).ceil();
    var e = cur.end;
    for (var i = 1; i < n && i < 5000; i++) {
      e = periodEnd(g, addDays(e, 1));
    }
    return e;
  }

  double totalExtra(Goal g) {
    var sum = 0.0;
    for (final s in periodStats(g)) {
      sum += s.extra;
    }
    return sum;
  }

  int streak(Goal g) {
    final s = periodStats(g);
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      final d = s[i];
      if (i == s.length - 1 && !d.met) continue; // current period not over
      if (d.met) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int bestStreak(Goal g) {
    var best = 0;
    var run = 0;
    for (final s in periodStats(g)) {
      if (s.met) {
        run++;
        if (run > best) best = run;
      } else if (!s.isCurrent) {
        run = 0;
      }
    }
    return best;
  }

  /// Finish date at the pace of the last 14 days.
  DateTime? projectedFinish(Goal g) {
    final remaining = g.target - balance(g.id);
    if (remaining <= 0) return null;
    final today = dayOnly(DateTime.now());
    var from = addDays(today, -13);
    if (from.isBefore(dayOnly(g.start))) from = dayOnly(g.start);
    final net = _sum((x) =>
            x.kind == 'saving' && x.goalId == g.id && inRange(x.date, from, today)) -
        _sum((x) =>
            x.kind == 'withdrawal' &&
            x.goalId == g.id &&
            inRange(x.date, from, today));
    final days = daysBetween(from, today) + 1;
    final avg = net / max(1, days);
    if (avg <= 0) return null;
    return addDays(today, (remaining / avg).ceil());
  }

  // ---------- transactions ----------
  /// Returns the ids of the entries made, so they can be undone.
  List<String> addSaving({
    required double amount,
    required String goalId,
    required String location,
    required DateTime date,
    String note = '',
    String loanId = '',
  }) {
    final day = dayOnly(date);
    final g = goalById(goalId);
    Txn make(String gid, double a) => Txn(
        id: newId(),
        kind: 'saving',
        amount: a,
        goalId: gid,
        location: location,
        date: day,
        note: note,
        loanId: gid == goalId ? loanId : '');
    final st = (g != null &&
            g.type == 'main' &&
            g.extraDest == 'buffer' &&
            loanId.isEmpty)
        ? statContaining(g, day)
        : null;
    final made = <Txn>[];
    if (g != null && st != null) {
      // Only the part up to the period target goes to the goal; the rest is extra.
      final target = st.target.ceilToDouble();
      final already = savedInRange(g.id, st.start, st.end);
      final goalPart = min(amount, max(0.0, target - already));
      final extraPart = amount - goalPart;
      if (goalPart > 0) made.add(make(g.id, goalPart));
      if (extraPart > 0) made.add(make(bufferId, extraPart));
    } else {
      made.add(make(goalId, amount));
    }
    txns.addAll(made);
    if (location.isNotEmpty) lastLocation = location;
    _changed();
    return made.map((x) => x.id).toList();
  }

  void addSpending({
    required double amount,
    required String category,
    String location = '',
    required DateTime date,
    String note = '',
  }) {
    txns.add(Txn(
        id: newId(),
        kind: 'spending',
        amount: amount,
        category: category,
        location: location,
        date: dayOnly(date),
        note: note));
    _changed();
  }

  void addIncome({
    required double amount,
    required String source,
    String location = '',
    required DateTime date,
    String note = '',
  }) {
    txns.add(Txn(
        id: newId(),
        kind: 'income',
        amount: amount,
        reason: source,
        location: location,
        date: dayOnly(date),
        note: note));
    _changed();
  }

  void addWithdrawal({
    required double amount,
    required String goalId,
    required String location,
    required String reason,
    bool isLoan = false,
    int loanDays = 0,
    required DateTime date,
    String note = '',
  }) {
    txns.add(Txn(
        id: newId(),
        kind: 'withdrawal',
        amount: amount,
        goalId: goalId,
        location: location,
        reason: reason,
        isLoan: isLoan,
        loanDays: isLoan ? loanDays : 0,
        date: dayOnly(date),
        note: note));
    _changed();
  }

  void requestWithdrawal(WithdrawRequest r) {
    requests.add(r);
    _changed();
  }

  void completeRequest(WithdrawRequest r) {
    requests.removeWhere((x) => x.id == r.id);
    final amount = min(r.amount, balance(r.goalId));
    if (amount > 0) {
      addWithdrawal(
          amount: amount,
          goalId: r.goalId,
          location: r.location,
          reason: r.reason,
          isLoan: r.isLoan,
          loanDays: r.loanDays,
          date: DateTime.now(),
          note: r.note);
    } else {
      _changed();
    }
  }

  void cancelRequest(WithdrawRequest r) {
    requests.removeWhere((x) => x.id == r.id);
    _changed();
  }

  void deleteTxns(List<String> ids) {
    txns.removeWhere((x) => ids.contains(x.id));
    _changed();
  }

  void deleteTxn(String id) {
    txns.removeWhere((x) => x.id == id);
    _changed();
  }

  List<Txn> get sortedTxns {
    final list = List<Txn>.from(txns);
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return list;
  }

  // ---------- loans ----------
  double repaidFor(String loanId) =>
      _sum((x) => x.kind == 'saving' && x.loanId == loanId);

  double outstanding(Txn loan) => max(0.0, loan.amount - repaidFor(loan.id));

  List<Txn> activeLoans([String? goalId]) {
    final list = txns
        .where((x) =>
            x.kind == 'withdrawal' &&
            x.isLoan &&
            (goalId == null || x.goalId == goalId) &&
            outstanding(x) > 0.5)
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // ---------- badges ----------
  Set<String> earnedBadges() {
    final out = <String>{};
    if (txns.any((x) => x.kind == 'saving')) out.add('firstSave');
    var best = 0;
    for (final g in goals.where((g) => g.type == 'main')) {
      best = max(best, bestStreak(g));
    }
    if (best >= 7) out.add('streak7');
    if (best >= 30) out.add('streak30');
    final net = totalNetSaved;
    if (net >= 100000) out.add('saved100k');
    if (net >= 1000000) out.add('saved1m');
    if (goals.any((g) => balance(g.id) >= g.target)) out.add('goalDone');
    if (_longestNoSpendRun() >= 7) out.add('noSpend7');
    if (txns.any((x) => x.kind == 'withdrawal' && x.isLoan && outstanding(x) <= 0.5)) {
      out.add('loanRepaid');
    }
    if (challenges.any((c) => challengeProgress(c).done)) {
      out.add('challengeDone');
    }
    return out;
  }

  int _longestNoSpendRun() {
    if (!txns.any((x) => x.kind == 'spending')) return 0;
    var first = dayOnly(DateTime.now());
    for (final x in txns) {
      if (x.date.isBefore(first)) first = dayOnly(x.date);
    }
    final spendDays = <String>{
      for (final x in txns.where((t) => t.kind == 'spending')) dayKey(x.date)
    };
    final yesterday = addDays(dayOnly(DateTime.now()), -1);
    var best = 0;
    var run = 0;
    for (var d = first; !d.isAfter(yesterday); d = addDays(d, 1)) {
      if (spendDays.contains(dayKey(d))) {
        run = 0;
      } else {
        run++;
        if (run > best) best = run;
      }
    }
    return best;
  }


  // ---------- profile and settings (applied on Save) ----------
  void saveProfile({
    required String name,
    required String photo,
    required String phone,
    required String email,
    required String city,
    required String motto,
  }) {
    userName = name.trim();
    profilePhoto = photo;
    this.phone = phone.trim();
    this.email = email.trim();
    this.city = city.trim();
    this.motto = motto.trim();
    _changed();
  }

  void applySettings({
    required String lang,
    required String themeMode,
    required String colorTheme,
    required int saveFirstPercent,
    required bool reminderOn,
    required int reminderHour,
    required int reminderMinute,
    required List<String> locations,
    String? period,
    double? fixedAmount,
  }) {
    this.lang = lang;
    currentLang = lang;
    this.themeMode = themeMode;
    this.colorTheme = colorTheme;
    this.saveFirstPercent = saveFirstPercent.clamp(0, 100).toInt();
    this.reminderOn = reminderOn;
    this.reminderHour = reminderHour;
    this.reminderMinute = reminderMinute;
    if (locations.isNotEmpty) this.locations = List<String>.from(locations);
    final g = mainGoal;
    if (g != null) {
      if (period != null) g.period = period;
      g.fixedAmount = (fixedAmount != null && fixedAmount > 0) ? fixedAmount : null;
    }
    _changed();
  }

  // ---------- wallet ----------
  bool get hasIncome => txns.any((x) => x.kind == 'income');

  /// Everyday money: income - spending - saved + withdrawn.
  double get walletBalance =>
      _sum((x) => x.kind == 'income') -
      _sum((x) => x.kind == 'spending') -
      _sum((x) => x.kind == 'saving' && x.reason != 'opening') +
      _sum((x) => x.kind == 'withdrawal');

  // ---------- split plan ----------
  int get splitTotal {
    var t = 0;
    splitPlan.forEach((k, v) {
      if (k == bufferId || goalById(k) != null) t += v;
    });
    return t;
  }

  bool get splitReady => splitTotal == 100;

  void setSplitPlan(Map<String, int> plan) {
    splitPlan = Map<String, int>.from(plan)..removeWhere((k, v) => v <= 0);
    _changed();
  }

  List<String> addSplitSaving({
    required double amount,
    required String location,
    required DateTime date,
    String note = '',
  }) {
    final parts = splitPlan.entries
        .where((e) => e.value > 0 && (e.key == bufferId || goalById(e.key) != null))
        .toList();
    final ids = <String>[];
    var left = amount;
    for (var i = 0; i < parts.length; i++) {
      final last = i == parts.length - 1;
      final a = last ? left : (amount * parts[i].value / 100).roundToDouble();
      left -= a;
      if (a > 0) {
        ids.addAll(addSaving(
            amount: a, goalId: parts[i].key, location: location, date: date, note: note));
      }
    }
    return ids;
  }

  // ---------- recurring plans ----------
  void upsertPlan(SavePlan p) {
    plans.removeWhere((x) => x.id == p.id);
    plans.add(p);
    _changed();
  }

  void deletePlan(SavePlan p) {
    plans.removeWhere((x) => x.id == p.id);
    _changed();
  }

  List<String> confirmPlan(SavePlan p) {
    p.lastDone = DateTime.now();
    return addSaving(
        amount: p.amount, goalId: p.goalId, location: quickLocation, date: DateTime.now());
  }

  List<SavePlan> get plansDueToday =>
      plans.where((p) => p.dueToday && (p.goalId == bufferId || goalById(p.goalId) != null)).toList();

  // ---------- bills ----------
  void upsertBill(Bill b) {
    bills.removeWhere((x) => x.id == b.id);
    bills.add(b);
    bills.sort((a, c) => a.dueDay.compareTo(c.dueDay));
    _changed();
  }

  void deleteBill(Bill b) {
    bills.removeWhere((x) => x.id == b.id);
    _changed();
  }

  void payBill(Bill b, {String location = ''}) {
    b.lastPaidMonth = Bill.monthKey(DateTime.now());
    addSpending(
        amount: b.amount,
        category: 'bills',
        location: location,
        date: DateTime.now(),
        note: b.name);
  }

  /// Unpaid bills due within 3 days or overdue this month.
  List<Bill> get billsDueSoon =>
      bills.where((b) => !b.paidThisMonth && b.daysToDue <= 3).toList();

  // ---------- money owed ----------
  void upsertDebt(Debt d) {
    debts.removeWhere((x) => x.id == d.id);
    debts.add(d);
    _changed();
  }

  void deleteDebt(Debt d) {
    debts.removeWhere((x) => x.id == d.id);
    _changed();
  }

  void payDebt(Debt d, double amount) {
    d.paid = min(d.amount, d.paid + amount);
    _changed();
  }

  double get owedToMe => debts
      .where((d) => d.direction == 'owedToMe')
      .fold<double>(0, (a, d) => a + d.remaining);

  double get iOwe =>
      debts.where((d) => d.direction == 'iOwe').fold<double>(0, (a, d) => a + d.remaining);

  List<Debt> get debtsDueSoon => debts
      .where((d) =>
          !d.settled &&
          d.dueDate != null &&
          daysBetween(DateTime.now(), d.dueDate!) <= 3)
      .toList();

  // ---------- calendar ----------
  /// Status of one day for the saving calendar:
  /// 'met', 'short', 'missed', 'saved', 'none', 'future', 'today'.
  Map<String, String> calendarStatus(DateTime month) {
    final out = <String, String>{};
    final today = dayOnly(DateTime.now());
    final g = mainGoal;
    final byDay = <String, PeriodStat>{};
    if (g != null && g.period == 'day') {
      for (final s in periodStats(g)) {
        byDay[dayKey(s.start)] = s;
      }
    }
    final last = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= last; d++) {
      final day = DateTime(month.year, month.month, d);
      final k = dayKey(day);
      if (day.isAfter(today)) {
        out[k] = 'future';
        continue;
      }
      final st = byDay[k];
      if (st != null) {
        if (st.met && st.target > 0.5) {
          out[k] = 'met';
        } else if (sameDay(day, today)) {
          out[k] = st.actual > 0 ? 'short' : 'today';
        } else if (st.target <= 0.5) {
          out[k] = st.actual > 0 ? 'met' : 'none';
        } else {
          out[k] = st.actual > 0 ? 'short' : 'missed';
        }
      } else {
        out[k] = totalOn('saving', day) > 0 ? 'saved' : 'none';
      }
    }
    return out;
  }

  // ---------- smart tips ----------
  List<Tip> tips() {
    final out = <Tip>[];
    final today = dayOnly(DateTime.now());
    final thisFrom = addDays(today, -6);
    final prevFrom = addDays(today, -13);
    final prevTo = addDays(today, -7);
    final now = spendingByCategory(thisFrom, today);
    final before = spendingByCategory(prevFrom, prevTo);
    String? bestCat;
    var bestChange = 0.0;
    now.forEach((c, v) {
      final b = before[c] ?? 0;
      if (b > 0 && v >= 1000) {
        final ch = (v - b) / b;
        if (ch.abs() > bestChange.abs()) {
          bestChange = ch;
          bestCat = c;
        }
      }
    });
    if (bestCat != null && bestChange.abs() >= 0.3) {
      out.add(Tip(
          bestChange > 0 ? 'up' : 'down',
          tf(bestChange > 0 ? 'tipCatUp' : 'tipCatDown', {
            'c': t('cat_$bestCat'),
            'p': '${(bestChange.abs() * 100).round()}',
          })));
    }
    final byWeekday = List<double>.filled(7, 0);
    for (final x in txns) {
      if (x.kind == 'saving' && x.reason != 'opening' && inRange(x.date, addDays(today, -55), today)) {
        byWeekday[x.date.weekday - 1] += x.amount;
      }
    }
    final top = byWeekday.reduce((a, b) => a > b ? a : b);
    if (top > 0) {
      final i = byWeekday.indexOf(top);
      out.add(Tip('star', tf('tipBestDay', {'d': weekdayLong(i + 1)})));
    }
    final mFrom = monthStart(today);
    final inc = totalBetween('income', mFrom, today);
    if (inc > 0) {
      final net = totalBetween('saving', mFrom, today) - totalBetween('withdrawal', mFrom, today);
      out.add(Tip('pie', tf('tipRate', {'p': '${(net / inc * 100).round()}'})));
    }
    final g = mainGoal;
    if (g != null) {
      final s = streak(g);
      if (s >= 3) out.add(Tip('fire', tf('tipStreak', {'n': '$s'})));
    }
    return out;
  }

  // ---------- challenges ----------
  void startChallenge(String type) {
    for (final c in challenges) {
      if (c.type == type && c.active) return;
    }
    challenges.add(Challenge(id: newId(), type: type, start: dayOnly(DateTime.now())));
    _changed();
  }

  void stopChallenge(Challenge c) {
    c.active = false;
    _changed();
  }

  Challenge? activeChallenge(String type) {
    for (final c in challenges) {
      if (c.type == type && c.active) return c;
    }
    return null;
  }

  ChallengeProgress challengeProgress(Challenge c) {
    final today = dayOnly(DateTime.now());
    final start = dayOnly(c.start);
    final elapsed = daysBetween(start, today);
    switch (c.type) {
      case 'week52':
        final week = min(52, elapsed ~/ 7 + 1);
        final total = totalBetween('saving', start, today) -
            totalBetween('withdrawal', start, today);
        final weekStart = addDays(start, (week - 1) * 7);
        return ChallengeProgress(
          value: max(0.0, total),
          goal: week52Total,
          done: total >= week52Total,
          ended: elapsed >= 364,
          week: week,
          weekTarget: week * 1000.0,
          weekSaved: totalBetween('saving', weekStart, today),
        );
      case 'nospend':
        final last = addDays(start, 29);
        final until = last.isBefore(addDays(today, -1)) ? last : addDays(today, -1);
        var count = 0;
        for (var d = start; !d.isAfter(until); d = addDays(d, 1)) {
          if (totalOn('spending', d) <= 0) count++;
        }
        return ChallengeProgress(
          value: count.toDouble(),
          goal: 10,
          done: count >= 10,
          ended: elapsed >= 30,
        );
      default: // streak30: longest run of days with any saving
        final saveDays = <String>{
          for (final x in txns.where(
              (t) => t.kind == 'saving' && !t.date.isBefore(start)))
            dayKey(x.date)
        };
        var best = 0;
        var run = 0;
        for (var d = start; !d.isAfter(today); d = addDays(d, 1)) {
          if (saveDays.contains(dayKey(d))) {
            run++;
            if (run > best) best = run;
          } else if (!sameDay(d, today)) {
            run = 0;
          }
        }
        return ChallengeProgress(
          value: best.toDouble(),
          goal: 30,
          done: best >= 30,
          ended: false,
        );
    }
  }
}
