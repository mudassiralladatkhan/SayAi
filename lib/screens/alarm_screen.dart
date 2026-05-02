import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../providers/task_provider.dart';
import '../services/tts_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  int _snoozeCount = 0;
  String _userName = 'Guest';
  String _customMessage = '';
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _customMessage = prefs.getString('custom_alarm_message') ?? '';
    });
    _playAlarmTTS();
  }

  void _playAlarmTTS() {
    final message = _getMessage();
    _ttsService.speak(message);
  }

  String _getMessage() {
    if (_snoozeCount == 1) return "Theek hai $_userName, 10 min!";
    if (_snoozeCount == 2) return "Parat snooze? He last snooze ahe tuz!";
    
    // First ring
    if (_customMessage.isNotEmpty) {
      // Replace {name} placeholder if they used it
      return _customMessage.replaceAll('{name}', _userName);
    }
    return "Utho $_userName! Aaj ka din start karna hai. Pehla task tumhara intezar kar raha hai.";
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _handleSnooze() {
    _ttsService.stop();
    setState(() {
      _snoozeCount++;
    });
    // Add logic to reschedule alarm
    if (_snoozeCount >= 3) {
      // Third attempt: hide snooze
    } else {
      _playAlarmTTS();
    }
  }

  void _handleWakeUp() {
    _ttsService.stop();
    // Add logic to dismiss alarm and go home
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black, // Pure black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            children: [
              // Time Display
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: AppTheme.textWhite,
                  letterSpacing: -2,
                ),
              ),
              
              // Date Display
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textWhite,
                  letterSpacing: 3.0,
                ),
              ),
              
              const SizedBox(height: 60),

              // YOG Avatar
              YogAvatar.alarm(size: 130),
              const SizedBox(height: 12),
              
              // YOG Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'YOG',
                  style: TextStyle(color: AppTheme.textWhite, fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 24),

              // Speech Bubble
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: -10,
                    child: CustomPaint(
                      painter: TrianglePainter(color: AppTheme.primaryPurple),
                      size: const Size(20, 10),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Task Card
              Consumer<TaskProvider>(
                builder: (_, provider, __) {
                  final pendingTasks = provider.todayTasks.where((t) => !t.completed).toList();
                  if (pendingTasks.isEmpty) {
                    return const SizedBox.shrink(); // No tasks
                  }
                  final firstTask = pendingTasks.first;
                  final taskTimeStr = firstTask.time != null 
                      ? DateFormat('h:mm a').format(firstTask.time!) 
                      : 'Anytime today';
                      
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fitness_center, color: AppTheme.primaryPurple),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Aaj ka pehla kaam:', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(firstTask.title, style: const TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(taskTimeStr, style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              // Buttons
              Row(
                children: [
                  if (_snoozeCount < 3)
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleSnooze,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: const Center(
                            child: Text(
                              '😴 Snooze - 10 min',
                              style: TextStyle(color: AppTheme.textWhite, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_snoozeCount < 3) const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleWakeUp,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '✅ Main Uth Gaya!',
                            style: TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Bottom Text
              const Text(
                'YOG ne uthaya — ab uthna padega! 😄',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
