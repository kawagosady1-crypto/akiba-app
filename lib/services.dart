import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'format.dart';
import 'i18n.dart';
import 'state.dart';

// ======================= Daily reminder =======================

class Reminders {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const int _id = 1;

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    try {
      await _init();
      final a = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await a?.requestNotificationsPermission();
      return ok ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Repeats every day at hour:minute (phone's local time).
  static Future<bool> schedule(int hour, int minute) async {
    try {
      await _init();
      await _plugin.cancel(_id);
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, hour, minute);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      final when = tz.TZDateTime.from(at, tz.UTC);
      await _plugin.zonedSchedule(
        _id,
        t('reminderTitle'),
        t('reminderBody'),
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            t('reminderChannel'),
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancel() async {
    await cancelId(_id);
  }

  static Future<void> cancelId(int id) async {
    try {
      await _init();
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static NotificationDetails _details(String channelId, String channelName) =>
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName,
            importance: Importance.high, priority: Priority.high),
      );

  static Future<void> _repeat(int id, String title, String body, DateTime first,
      DateTimeComponents match, String channelId, String channelName) async {
    await _init();
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(first, tz.UTC),
      _details(channelId, channelName),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  }

  /// Reminder for a recurring saving plan.
  static Future<void> schedulePlan(SavePlan p) async {
    try {
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, p.hour, p.minute);
      DateTimeComponents match = DateTimeComponents.time;
      if (p.frequency == 'weekly') {
        while (at.weekday != p.weekday || !at.isAfter(now)) {
          at = at.add(const Duration(days: 1));
        }
        match = DateTimeComponents.dayOfWeekAndTime;
      } else if (p.frequency == 'monthly') {
        at = DateTime(now.year, now.month, p.monthDay, p.hour, p.minute);
        if (!at.isAfter(now)) {
          at = DateTime(now.year, now.month + 1, p.monthDay, p.hour, p.minute);
        }
        match = DateTimeComponents.dayOfMonthAndTime;
      } else if (!at.isAfter(now)) {
        at = at.add(const Duration(days: 1));
      }
      final body = tf('planNotif', {
        'a': money(p.amount),
        'g': p.goalId == bufferId ? t('buffer') : (app.goalById(p.goalId)?.name ?? ''),
      });
      await _repeat(p.notifId, 'Akiba', body, at, match, 'saving_plans',
          t('plansTitle'));
    } catch (_) {}
  }

  /// Reminder two days before a bill is due, every month at 9:00.
  static Future<void> scheduleBill(Bill b) async {
    try {
      final now = DateTime.now();
      final day = b.dueDay > 2 ? b.dueDay - 2 : b.dueDay;
      var at = DateTime(now.year, now.month, day, 9, 0);
      if (!at.isAfter(now)) at = DateTime(now.year, now.month + 1, day, 9, 0);
      final body = tf('billNotif', {
        'n': b.name,
        'a': money(b.amount),
        'd': '${b.dueDay}',
      });
      await _repeat(b.notifId, 'Akiba', body, at,
          DateTimeComponents.dayOfMonthAndTime, 'bills', t('billsTitle'));
    } catch (_) {}
  }
}

// ======================= Backup file =======================

class BackupFiles {
  /// Saves the backup as a .json file and opens the share sheet
  /// (WhatsApp, Google Drive, email...).
  static Future<bool> share() async {
    try {
      final dir = await getTemporaryDirectory();
      final n = DateTime.now();
      final name =
          'akiba-backup-${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}.json';
      final f = File('${dir.path}/$name');
      await f.writeAsString(app.exportJson());
      await Share.shareXFiles([XFile(f.path, mimeType: 'application/json')],
          subject: 'Akiba backup');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lets the user pick a backup file and returns its text.
  static Future<String?> pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = r?.files.single.path;
      if (path == null) return null;
      final text = await File(path).readAsString();
      jsonDecode(text); // throws if it is not a backup
      return text;
    } catch (_) {
      return null;
    }
  }
}

// ======================= Home-screen widget =======================

class HomeWidgetSync {
  static Timer? _timer;

  /// Updates the widget shortly after the data changes.
  static void schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), _update);
  }

  static Future<void> _update() async {
    try {
      final g = app.mainGoal;
      final balance = app.hideBalance ? '••••••' : 'TZS ${num0(app.totalNetSaved)}';
      String goalLine = 'Akiba';
      String todayLine = '';
      if (g != null) {
        final pct = (app.moneyFraction(g) * 100).round();
        goalLine = '${g.name} · $pct%';
        final s = app.currentStat(g);
        todayLine = s.met
            ? t('widgetDone')
            : tf('widgetLeft', {'a': num0(s.shortfall.ceil())});
      }
      await HomeWidget.saveWidgetData<String>('balance', balance);
      await HomeWidget.saveWidgetData<String>('goal', goalLine);
      await HomeWidget.saveWidgetData<String>('today', todayLine);
      await HomeWidget.saveWidgetData<String>('label', t('totalBalance'));
      await HomeWidget.updateWidget(
        androidName: 'AkibaWidgetProvider',
        qualifiedAndroidName: 'com.akiba.akiba.AkibaWidgetProvider',
      );
    } catch (_) {}
  }
}

// ======================= Fingerprint =======================

class Bio {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: t('bioReason'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

// ======================= Goal photo =======================

class Photos {
  static Future<String?> pickGoalPhoto() => pickPhoto('goal');

  static Future<String?> pickPhoto(String prefix) async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (x == null) return null;
      final dir = await getApplicationDocumentsDirectory();
      final dot = x.path.lastIndexOf('.');
      final ext = dot > 0 ? x.path.substring(dot) : '.jpg';
      final dest =
          '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(x.path).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }
}

// ======================= Monthly report (PDF) =======================

class Reports {
  /// Keeps only characters the built-in PDF font can draw.
  static String _safe(String s) =>
      String.fromCharCodes(s.runes.map((r) => r < 256 ? r : 63));

  static String _monthTitle(DateTime m) =>
      '${monthLong(m.month)} ${m.year}';

  static Future<bool> shareMonthly(DateTime month) async {
    try {
      final from = app.monthStart(month);
      final to = app.monthEnd(month);
      final income = app.totalBetween('income', from, to);
      final saved = app.totalBetween('saving', from, to);
      final withdrawn = app.totalBetween('withdrawal', from, to);
      final spent = app.totalBetween('spending', from, to);
      final cats = app.spendingByCategory(from, to).entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final green = PdfColor.fromInt(0xFF0F7B5F);

      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          pw.Text(_safe('Akiba'),
              style: pw.TextStyle(
                  fontSize: 26, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 4),
          pw.Text(_safe('${t('reportTitle')} - ${_monthTitle(month)}'),
              style: const pw.TextStyle(fontSize: 16)),
          if (app.userName.isNotEmpty)
            pw.Text(_safe(app.userName),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          pw.Text(_safe(t('reportSummary')),
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [_safe(t('item')), _safe(t('amountShort'))],
            data: [
              [_safe(t('legendIncome')), money(income)],
              [_safe(t('legendSaved')), money(saved)],
              [_safe(t('legendWithdrawn')), money(withdrawn)],
              [_safe(t('netSaved')), money(saved - withdrawn)],
              [_safe(t('legendSpent')), money(spent)],
            ],
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.Text(_safe(t('goals')),
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 8),
          if (app.activeGoals.isEmpty)
            pw.Text(_safe(t('nothingYet')))
          else
            pw.TableHelper.fromTextArray(
              headers: [
                _safe(t('goal')),
                _safe(t('saved')),
                _safe(t('target')),
                '%'
              ],
              data: [
                for (final g in app.activeGoals)
                  [
                    _safe(g.name),
                    money(app.balance(g.id)),
                    money(g.target),
                    g.target <= 0
                        ? '0'
                        : (app.balance(g.id) / g.target * 100)
                            .clamp(0, 100)
                            .toStringAsFixed(0),
                  ]
              ],
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 20),
          pw.Text(_safe(t('spendingByCatShort')),
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 8),
          if (cats.isEmpty)
            pw.Text(_safe(t('nothingYet')))
          else
            pw.TableHelper.fromTextArray(
              headers: [_safe(t('category')), _safe(t('amountShort')), _safe(t('limit'))],
              data: [
                for (final e in cats)
                  [
                    _safe(t('cat_${e.key}')),
                    money(e.value),
                    app.limits[e.key] == null ? '-' : money(app.limits[e.key]!),
                  ]
              ],
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 20),
          pw.Text(
              _safe('${t('badges')}: ${app.earnedBadges().length} / ${badgeIds.length}'),
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(_safe('${t('reportMade')} ${fmtDate(DateTime.now())}'),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ));
      final bytes = await doc.save();
      final name =
          'Akiba-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';
      return await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (_) {
      return false;
    }
  }
}
