import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Guest';
  String _tone = 'yaar';
  String _language = 'Hinglish';
  int _streak = 0;
  bool _isPremium = false;
  DateTime _memberSince = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _tone = prefs.getString('user_tone') ?? 'yaar';
      _language = prefs.getString('user_language') ?? 'Hinglish';
      _streak = prefs.getInt('streak') ?? 0;
      _isPremium = prefs.getBool('is_premium') ?? false;
      final savedDate = prefs.getString('member_since');
      if (savedDate != null) {
        _memberSince = DateTime.tryParse(savedDate) ?? DateTime.now();
      } else {
        prefs.setString('member_since', DateTime.now().toIso8601String());
      }
    });
  }

  String _toneEmoji(String tone) {
    switch (tone) {
      case 'yaar': return '😎 Yaar';
      case 'coach': return '💪 Coach';
      case 'friend': return '😂 Friend';
      case 'mentor': return '🧠 Mentor';
      default: return '😎 Yaar';
    }
  }

  String _initial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : 'Y';

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D1B69), Color(0xFF1A0A3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    // Avatar circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initial(_userName),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'YOG Mode: ${_toneEmoji(_tone)}',
                      style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${DateFormat('d MMM yyyy').format(_memberSince)}',
                      style: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Row(
                children: [
                  _statBox('🔥', '$_streak', 'Day Streak'),
                  const SizedBox(width: 12),
                  _statBox('✅', '${taskProvider.completedCount}', 'Tasks Done'),
                  const SizedBox(width: 12),
                  _statBox('📋', '${taskProvider.tasks.length}', 'Total Tasks'),
                ],
              ),
              const SizedBox(height: 20),

              // Completion Rate
              _buildCompletionCard(taskProvider),
              const SizedBox(height: 20),

              // Recent Tasks
              _buildRecentTasksCard(taskProvider),
              const SizedBox(height: 20),

              // Info tiles
              _buildInfoTile(Icons.language_outlined, 'YOG Language', _language),
              const SizedBox(height: 8),
              _buildInfoTile(Icons.auto_awesome, 'YOG Personality', _toneEmoji(_tone)),
              const SizedBox(height: 8),
              _buildInfoTile(Icons.workspace_premium_outlined, 'Plan', _isPremium ? '⭐ Premium' : 'Free'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCardMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.textGray, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(TaskProvider provider) {
    final total = provider.tasks.length;
    final done = provider.completedCount;
    final rate = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Completion Rate',
              style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(rate * 100).round()}% tasks completed ($done of $total)',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasksCard(TaskProvider provider) {
    final recent = provider.tasks.take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 Recent Tasks',
              style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...recent.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      t.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: t.completed ? AppTheme.success : AppTheme.textGray,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(
                          color: t.completed ? AppTheme.textGray : AppTheme.textWhite,
                          fontSize: 13,
                          decoration: t.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Text(t.category,
                        style: const TextStyle(
                            color: AppTheme.primaryPurple, fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryPurple, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textGray, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
