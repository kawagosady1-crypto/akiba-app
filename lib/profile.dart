import 'dart:io';

import 'package:flutter/material.dart';

import 'format.dart';
import 'i18n.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Round profile picture, or initials when there is no photo.
class Avatar extends StatelessWidget {
  final String photo;
  final String name;
  final double size;
  final double border;
  const Avatar(
      {super.key,
      required this.photo,
      required this.name,
      this.size = 44,
      this.border = 2});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo.isNotEmpty && File(photo).existsSync();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: pal.accent, width: border),
        color: pal.ring,
        image: hasPhoto
            ? DecorationImage(image: FileImage(File(photo)), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(initials(name),
              style: TextStyle(
                  color: pal.heroBg,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.36)),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: app.userName);
  late final TextEditingController _phone = TextEditingController(text: app.phone);
  late final TextEditingController _email = TextEditingController(text: app.email);
  late final TextEditingController _city = TextEditingController(text: app.city);
  late final TextEditingController _motto = TextEditingController(text: app.motto);
  late String _photo = app.profilePhoto;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _email, _city, _motto]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _city, _motto]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != app.userName ||
      _phone.text.trim() != app.phone ||
      _email.text.trim() != app.email ||
      _city.text.trim() != app.city ||
      _motto.text.trim() != app.motto ||
      _photo != app.profilePhoto;

  Future<void> _pick() async {
    final p = await Photos.pickPhoto('profile');
    if (p != null && mounted) setState(() => _photo = p);
  }

  void _save() {
    app.saveProfile(
      name: _name.text,
      photo: _photo,
      phone: _phone.text,
      email: _email.text,
      city: _city.text,
      motto: _motto.text,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t('saved'))));
    Navigator.pop(context);
  }

  Future<void> _maybeLeave() async {
    final leave = await confirmDialog(context, t('unsavedAsk'),
        okLabel: t('discard'));
    if (leave && mounted) Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, TextCapitalization cap = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        textCapitalization: cap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = app.activeGoals;
    final chipStyle = TextStyle(color: pal.ink, fontSize: 12);
    Widget chip(String s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: pal.heroTrack, borderRadius: BorderRadius.circular(20)),
          child: Text(s, style: chipStyle),
        );
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybeLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('myProfile')),
          actions: [
            if (_dirty)
              TextButton(onPressed: _save, child: Text(t('save'))),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                  color: pal.heroBg, borderRadius: BorderRadius.circular(26)),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pick,
                    child: Stack(
                      children: [
                        Avatar(
                            photo: _photo,
                            name: _name.text.isEmpty ? 'Akiba' : _name.text,
                            size: 96,
                            border: 3),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: pal.accent,
                            child: Icon(Icons.photo_camera, size: 17, color: pal.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_photo.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _photo = ''),
                      child: Text(t('removePhoto'), style: TextStyle(color: pal.soft)),
                    )
                  else
                    const SizedBox(height: 10),
                  Text(_name.text.isEmpty ? 'Akiba' : _name.text,
                      style: TextStyle(
                          color: pal.ink, fontSize: 20, fontWeight: FontWeight.w800)),
                  if (_city.text.trim().isNotEmpty)
                    Text(_city.text.trim(), style: TextStyle(color: pal.soft)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                    chip('${compact(app.totalNetSaved)} ${t('savedShort')}'),
                    chip('${g.length} ${t('goals').toLowerCase()}'),
                    chip('${app.earnedBadges().length} ${t('badges').toLowerCase()}'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field(_name, t('name'), Icons.person_outline, cap: TextCapitalization.words),
            _field(_phone, t('phone'), Icons.phone_outlined, type: TextInputType.phone),
            _field(_email, t('email'), Icons.mail_outline, type: TextInputType.emailAddress),
            _field(_city, t('city'), Icons.place_outlined, cap: TextCapitalization.words),
            _field(_motto, t('motto'), Icons.format_quote_outlined,
                cap: TextCapitalization.sentences),
            Text(t('profilePrivate'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _dirty ? _save : null,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.save_outlined),
              label: Text(t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
