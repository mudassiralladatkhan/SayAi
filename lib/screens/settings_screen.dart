import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../providers/task_provider.dart';
import '../services/user_service.dart';
import 'pricing_screen.dart';
import 'profile_screen.dart';
import 'alarm_screen.dart';
import 'night_checkin_screen.dart';
import '../services/notification_service.dart';
import 'auth_screen.dart';

// ─────────────────────────────────────────────
//  SUB-PAGE: Personalize YOG
// ─────────────────────────────────────────────
class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({Key? key}) : super(key: key);
  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  String _selectedTone = 'yaar';
  String _selectedLanguage = 'Hinglish';
  bool _tuYaAap = true;
  bool _shayariEnabled = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'Guest';
      _selectedTone = prefs.getString('user_tone') ?? 'yaar';
      _selectedLanguage = prefs.getString('user_language') ?? 'Hinglish';
      _tuYaAap = prefs.getBool('tu_ya_aap') ?? true;
      _shayariEnabled = prefs.getBool('shayari_enabled') ?? true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim().isEmpty ? 'Guest' : _nameController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_tone', _selectedTone);
    await prefs.setString('user_language', _selectedLanguage);
    await prefs.setBool('tu_ya_aap', _tuYaAap);
    await prefs.setBool('shayari_enabled', _shayariEnabled);

    // Sync to Firestore
    await UserService.saveProfile(
      name: name,
      tone: _selectedTone,
      language: _selectedLanguage,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Saved! ✅'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = [
      {'key': 'yaar', 'label': 'Yaar 😎', 'desc': 'Chill & casual'},
      {'key': 'coach', 'label': 'Coach 💪', 'desc': 'Push & motivate'},
      {'key': 'friend', 'label': 'Friend 😂', 'desc': 'Fun & jokey'},
      {'key': 'mentor', 'label': 'Mentor 🧠', 'desc': 'Wise & calm'},
    ];
    final langs = ['Hinglish', 'Hindi', 'English'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personalize YOG', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            _label('👤 Your Name'),
            const SizedBox(height: 10),
            _card(child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: AppTheme.textGray),
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryPurple),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            )),
            const SizedBox(height: 24),

            // Tone
            _label('🎭 YOG\'s Personality'),
            const SizedBox(height: 4),
            Text('How should YOG talk to you?', style: TextStyle(color: AppTheme.textGray.withOpacity(0.7), fontSize: 12)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.6,
              children: tones.map((t) {
                final isSelected = _selectedTone == t['key'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedTone = t['key']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.backgroundCardMedium,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryPurple : Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(t['label']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(t['desc']!, style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.textGray, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Language
            _label('🌐 Language'),
            const SizedBox(height: 10),
            Row(
              children: langs.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLanguage = lang),
                    child: Container(
                      margin: EdgeInsets.only(right: lang != langs.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryPurple : AppTheme.backgroundCardMedium,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryPurple : Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: Text(lang, style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textGray,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Respect
            _label('🙏 Respect Level'),
            const SizedBox(height: 10),
            _card(child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tuYaAap ? 'Casual — "Tu/Tum" 😎' : 'Formal — "Aap" 🙏',
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(_tuYaAap ? 'YOG will talk like a friend' : 'YOG will be more respectful',
                        style: const TextStyle(color: AppTheme.textGray, fontSize: 11)),
                  ],
                )),
                Switch(value: _tuYaAap, onChanged: (v) => setState(() => _tuYaAap = v), activeColor: AppTheme.primaryPurple),
              ],
            )),
            const SizedBox(height: 12),

            // Shayari
            _label('✨ Shayari Mode'),
            const SizedBox(height: 10),
            _card(child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOG shares shayari on strong moods',
                        style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    const Text('2-line Hinglish shayari when you\'re very happy/sad',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                  ],
                )),
                Switch(value: _shayariEnabled, onChanged: (v) => setState(() => _shayariEnabled = v), activeColor: AppTheme.primaryPurple),
              ],
            )),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold));
  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: AppTheme.backgroundCardMedium, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: child,
  );
}

// ─────────────────────────────────────────────
//  SUB-PAGE: Notifications
// ─────────────────────────────────────────────
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);
  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _taskReminders = true;
  bool _morningBriefing = true;
  bool _streakAlerts = true;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 7, minute: 0);
  final TextEditingController _customAlarmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _taskReminders = prefs.getBool('notif_tasks') ?? true;
      _morningBriefing = prefs.getBool('notif_morning') ?? true;
      _streakAlerts = prefs.getBool('notif_streak') ?? true;
      
      final hour = prefs.getInt('alarm_hour') ?? 7;
      final minute = prefs.getInt('alarm_minute') ?? 0;
      _alarmTime = TimeOfDay(hour: hour, minute: minute);
      _customAlarmController.text = prefs.getString('custom_alarm_message') ?? '';
    });
  }

  Future<void> _save(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _pickAlarmTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              surface: AppTheme.backgroundCardMedium,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('alarm_hour', picked.hour);
      await prefs.setInt('alarm_minute', picked.minute);
      
      // Schedule actual OS background alarm
      await NotificationService().scheduleDailyAlarm(picked);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Morning alarm set to ${picked.format(context)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundMain,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Notifications', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _notifTile('🔔 Task Reminders', 'Notify when a task is due', _taskReminders, (v) {
              setState(() => _taskReminders = v);
              _save('notif_tasks', v);
            }),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: AppTheme.backgroundCardMedium, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
              child: ListTile(
                leading: const Icon(Icons.alarm, color: AppTheme.primaryPurple),
                title: const Text('Wake-up Alarm', style: TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
                subtitle: Text('Rings at ${_alarmTime.format(context)}', style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textGray),
                onTap: _pickAlarmTime,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.backgroundCardMedium, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personalize Alarm Message', style: TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customAlarmController,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Utho {name}! Workout time!',
                      hintStyle: TextStyle(color: AppTheme.textGray.withOpacity(0.5), fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('custom_alarm_message', val.trim());
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text('Use {name} to include your name.', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _notifTile('☀️ Morning Briefing', 'Daily summary after alarm', _morningBriefing, (v) {
              setState(() => _morningBriefing = v);
              _save('notif_morning', v);
            }),
            const SizedBox(height: 12),
            _notifTile('🔥 Streak Alerts', 'Remind to keep your streak alive', _streakAlerts, (v) {
              setState(() => _streakAlerts = v);
              _save('notif_streak', v);
            }),
            const SizedBox(height: 40),
            
            // Demo Buttons
            const Align(alignment: Alignment.centerLeft, child: Text('TEST SCREENS', style: TextStyle(color: AppTheme.textGray, fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alarm, color: Colors.white),
                label: const Text('Test Alarm Screen', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()));
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.nightlight_round, color: Colors.white),
                label: const Text('Test Night Check-in', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D1B69),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NightCheckinScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sub, style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
            ],
          )),
          Switch(value: val, onChanged: onChanged, activeColor: AppTheme.primaryPurple),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-PAGE: About
// ─────────────────────────────────────────────
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundMain,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('About SayNote AI', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2D1B69), Color(0xFF1A0A3E)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.5), blurRadius: 20)]),
                    child: const Icon(Icons.mic, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('SayNote AI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('Your voice-first AI life assistant\nPowered by Groq & LLaMA 3',
                      style: TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('🤖 AI Model', 'LLaMA 3 70B via Groq'),
            const SizedBox(height: 8),
            _infoRow('🏗️ Built with', 'Flutter + Dart'),
            const SizedBox(height: 8),
            _infoRow('💾 Storage', 'Local (SharedPreferences)'),
            const SizedBox(height: 8),
            _infoRow('🔒 Privacy', 'Your data stays on device'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SETTINGS HUB SCREEN
// ─────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 3;
  String _userName = 'Guest';
  String _tone = 'yaar';
  String _language = 'Hinglish';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _tone = prefs.getString('user_tone') ?? 'yaar';
      _language = prefs.getString('user_language') ?? 'Hinglish';
      _isPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  String _toneLabel(String t) {
    switch (t) {
      case 'yaar': return 'Yaar 😎';
      case 'coach': return 'Coach 💪';
      case 'friend': return 'Friend 😂';
      case 'mentor': return 'Mentor 🧠';
      default: return 'Yaar 😎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text('Settings', style: TextStyle(color: AppTheme.textWhite, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Customize your experience', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                    const SizedBox(height: 24),

                    // User Card — taps to Profile
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2D1B69), Color(0xFF1A0A3E)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 12)],
                              ),
                              child: Center(
                                child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'Y',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_userName, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text('$_language • ${_toneLabel(_tone)}',
                                      style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textGray),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section: YOG
                    _sectionHeader('YOG'),
                    const SizedBox(height: 10),
                    _navTile(
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      label: 'Personalize YOG',
                      subtitle: 'Tone, language, shayari',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalizeScreen()));
                        _load();
                      },
                    ),
                    const SizedBox(height: 8),
                    _navTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFFF9800),
                      label: 'Notifications',
                      subtitle: 'Reminders & briefings',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen())),
                    ),
                    const SizedBox(height: 28),

                    // Section: Account
                    _sectionHeader('Account'),
                    const SizedBox(height: 10),
                    _navTile(
                      icon: Icons.workspace_premium_outlined,
                      iconColor: const Color(0xFFFFD700),
                      label: 'Plan',
                      subtitle: _isPremium ? '⭐ Premium — Active' : 'Free Plan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())),
                    ),
                    const SizedBox(height: 8),
                    _navTile(
                      icon: Icons.delete_outline,
                      iconColor: const Color(0xFFE53935),
                      label: 'Clear All Data',
                      subtitle: 'Delete tasks & diary entries',
                      onTap: () => _confirmClear(context),
                    ),
                    const SizedBox(height: 8),
                    _navTile(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFE53935),
                      label: 'Sign Out',
                      subtitle: 'Log out of your account',
                      onTap: () => _confirmSignOut(context),
                    ),
                    const SizedBox(height: 28),

                    // Section: Support
                    _sectionHeader('App'),
                    const SizedBox(height: 10),
                    _navTile(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF26C6DA),
                      label: 'About SayNote AI',
                      subtitle: 'Version, credits & tech',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Text('SayNote AI v1.0.0 • Made with ❤️ for India',
                          style: TextStyle(color: AppTheme.textGray.withOpacity(0.4), fontSize: 11)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(color: AppTheme.textGray.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _navTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppTheme.textGray, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will be logged out and returned to the login screen.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Sign out from Firebase
              await FirebaseAuth.instance.signOut();
              // Clear onboarding flag so next login goes through onboarding
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_onboarded', false);
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete all your tasks and diary entries. This cannot be undone.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              // Clear TaskProvider (updates UI immediately)
              if (mounted) {
                await context.read<TaskProvider>().clearAll();
              }
              // Clear diary entries from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('diary_entries');
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All tasks and diary entries cleared ✅'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
