import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../services/stt_service.dart';
import '../services/gpt_service.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class VoiceCaptureScreen extends StatefulWidget {
  const VoiceCaptureScreen({Key? key}) : super(key: key);

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _yogResponse = '';

  final SttService _sttService = SttService();
  final GptService _gptService = GptService();
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    bool initialized = await _sttService.initialize();
    if (initialized) {
      _startListening();
    }
  }

  void _startListening() {
    _startTimer();
    setState(() { _isRecording = true; _recognizedText = ''; _yogResponse = ''; });
    _sttService.startListening((text) {
      setState(() {
        _recognizedText = text;
      });
    });
  }

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _stopAndProcess() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _timer?.cancel();
    });
    await _sttService.stopListening();
    
    // Fallback if no text
    if (_recognizedText.trim().isEmpty) {
      _recognizedText = "Hi YOG, kaisa hai bhai?";
    }

    // Load user settings from SharedPreferences so language & tone are applied
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Rahul';
    final userTone = prefs.getString('user_tone') ?? 'yaar';
    final userLanguage = prefs.getString('user_language') ?? 'Hinglish';
    final tuYaAap = prefs.getBool('tu_ya_aap') ?? true;
    final streak = prefs.getInt('streak') ?? 7;

    final user = UserModel(
      id: '1',
      naam: userName,
      language: userLanguage,
      tone: userTone,
      plan: 'premium',
      streak: streak,
      lastMood: 'neutral',
      tuYaAap: tuYaAap,
    );

    // Build a real task summary to give YOG context
    final taskProvider = context.read<TaskProvider>();
    final taskSummary = taskProvider.tasks.isEmpty
        ? 'No tasks scheduled yet.'
        : taskProvider.tasks.take(5).map((t) =>
            '- ${t.title} (${t.category}${t.time != null ? ", ${t.time!.hour}:${t.time!.minute.toString().padLeft(2, '0')}" : ""})'
          ).join('\n');

    final responseData = await _gptService.getResponse(
      message: _recognizedText,
      user: user,
      currentTasks: taskSummary,
    );
    
    final yogReply = responseData['response'] ?? 'Sorry yaar, kuch gadbad ho gayi.';

    // Extract and persist tasks from AI response
    final extractedRaw = responseData['extracted_tasks'];
    if (extractedRaw is List && extractedRaw.isNotEmpty && mounted) {
      final taskProvider = context.read<TaskProvider>();
      final notifService = NotificationService();
      final today = DateTime.now();
      final List<TaskModel> newTasks = [];

      for (final t in extractedRaw) {
        if (t is Map<String, dynamic>) {
          // Parse the time string like "5:00 PM"
          DateTime? taskTime;
          try {
            final timeParts = (t['time'] ?? '').toString().split(':');
            if (timeParts.length >= 2) {
              int hour = int.parse(timeParts[0].trim());
              final minPart = timeParts[1].trim();
              final minuteStr = minPart.replaceAll(RegExp(r'[^0-9]'), '');
              int minute = int.parse(minuteStr);
              if (minPart.toUpperCase().contains('PM') && hour != 12) hour += 12;
              if (minPart.toUpperCase().contains('AM') && hour == 12) hour = 0;
              taskTime = DateTime(today.year, today.month, today.day, hour, minute);
            }
          } catch (_) {}

          final task = TaskModel(
            id: DateTime.now().microsecondsSinceEpoch.toString() + newTasks.length.toString(),
            title: t['title'] ?? 'New Task',
            time: taskTime,
            duration: t['duration'] ?? '30 min',
            category: t['category'] ?? 'General',
            date: today.toIso8601String().split('T')[0],
          );
          newTasks.add(task);
          await notifService.showTaskAddedNotification(task);
        }
      }
      if (newTasks.isNotEmpty) {
        await taskProvider.addTasks(newTasks);
      }
    }

    setState(() {
      _isProcessing = false;
      _yogResponse = yogReply;
    });

    await _ttsService.speak(_yogResponse);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ttsService.stop();
    _sttService.stopListening();
    super.dispose();
  }

  String get _formattedTime {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), 
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), 
                  Expanded(
                    child: Text(
                      _isProcessing ? 'YOG is thinking...' : 'YOG is listening...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '😊 Good',
                      style: TextStyle(color: AppTheme.success, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),

            YogAvatar(size: 130, showGlow: true, isPulsing: _isRecording || _isProcessing),
            
            const SizedBox(height: 32),

            // Transcript or Response
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _yogResponse.isNotEmpty ? _yogResponse : _recognizedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textWhite,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _formattedTime,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: AppTheme.textWhite),
            ),
            
            const SizedBox(height: 40),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionBtn(Icons.close, 'CANCEL', () => Navigator.pop(context), false),
                const SizedBox(width: 24),
                _buildActionBtn(Icons.stop, 'STOP', _stopAndProcess, true),
                const SizedBox(width: 24),
                _buildActionBtn(_isRecording ? Icons.pause : Icons.mic, _isRecording ? 'PAUSE' : 'SPEAK', () {
                  if (_isRecording) {
                    setState(() { _isRecording = false; _timer?.cancel(); });
                    _sttService.stopListening();
                  } else {
                    _startListening();
                  }
                }, false),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, bool isStop) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isStop ? 64 : 56,
            height: isStop ? 64 : 56,
            decoration: BoxDecoration(
              color: isStop ? AppTheme.error : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.textWhite, size: isStop ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textGray)),
      ],
    );
  }
}
