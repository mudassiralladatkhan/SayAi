import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/task_card.dart';
import '../widgets/streak_box.dart';
import '../providers/task_provider.dart';
import 'voice_capture_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Guest';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _streak = prefs.getInt('streak') ?? 0;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, $_userName! 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon, $_userName! ☀️';
    } else {
      return 'Good Evening, $_userName! 🌙';
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
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SayNote AI',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                              },
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.backgroundCardMedium,
                                child: Icon(Icons.person, size: 20, color: AppTheme.textWhite),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Greeting Section
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'YOG is ready for you today',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // YOG Avatar Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceCaptureScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2D1B69), AppTheme.backgroundMain],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5), width: 1),
                        ),
                        child: Column(
                          children: [
                            YogAvatar.normal(size: 100, isPulsing: true),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to talk to YOG',
                              style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Tasks
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundCardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          left: BorderSide(color: AppTheme.primaryPurple, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Tasks",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.backgroundCardMedium,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: AppTheme.textWhite, size: 20),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
                                  },
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Consumer<TaskProvider>(
                            builder: (_, provider, __) {
                              if (provider.tasks.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'YOG se bolo aur tasks ban jayenge! 🎤',
                                    style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              final displayTasks = provider.todayTasks.take(3).toList();
                              return Column(
                                children: displayTasks.map((task) => TaskCard(
                                  task: task,
                                  onToggle: () => provider.toggleComplete(task.id),
                                )).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Streak Row
                    Consumer<TaskProvider>(
                      builder: (_, provider, __) {
                        final consistency = provider.tasks.isEmpty 
                            ? 0 
                            : (provider.completedCount / provider.tasks.length * 100).toInt();
                        final level = (_streak ~/ 7) + 1; // 1 level per week of streak
                        
                        return Row(
                          children: [
                            StreakBox(emoji: '🔥', title: '$_streak Days', subtitle: 'Current Streak'),
                            const SizedBox(width: 12),
                            StreakBox(emoji: '⭐', title: '$consistency%', subtitle: 'Consistency'),
                            const SizedBox(width: 12),
                            StreakBox(emoji: '⚡', title: 'Level $level', subtitle: 'Discipline'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 100), // padding for mic
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onLongPress: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceCaptureScreen()));
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: AppTheme.textWhite, size: 32),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
