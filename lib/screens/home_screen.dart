import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/task_card.dart';
import '../widgets/streak_box.dart';
import '../providers/task_provider.dart';
import '../services/stt_service.dart';
import '../services/gpt_service.dart';
import '../services/tts_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'conversation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Guest';
  int _streak = 0;
  String _currentMood = 'neutral';
  String _wakeWord = 'Hey YOG';
  String _language = 'Hinglish';
  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';

  final List<Map<String, String>> _chatMessages = [];
  final List<Map<String, String>> _conversationHistory = [];
  final ScrollController _scrollController = ScrollController();

  final SttService _sttService = SttService();
  final GptService _gptService = GptService();
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _sttService.initialize();
    _sttService.onStopped = () {
      if (!mounted) return;
      if (_isListening && !_isProcessing && _recognizedText.trim().isNotEmpty) {
        setState(() { _isListening = false; });
        _processUserMessage();
      } else if (_isListening) {
        setState(() { _isListening = false; });
      }
    };
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _streak = prefs.getInt('streak') ?? 0;
      _currentMood = prefs.getString('last_mood') ?? 'neutral';
      _wakeWord = prefs.getString('wake_word') ?? 'Hey YOG';
      _language = prefs.getString('user_language') ?? prefs.getString('yog_language') ?? 'Hinglish';
    });
  }

  void _toggleListening() {
    if (_isProcessing) return;
    if (_isListening) {
      _sttService.stopListening();
      final text = _recognizedText.trim();
      setState(() { _isListening = false; });
      if (text.isNotEmpty) {
        _processUserMessage();
      }
    } else {
      setState(() { _isListening = true; _recognizedText = ''; });
      _sttService.startListening((text) {
        if (!mounted) return;
        setState(() { _recognizedText = text; });
      }, language: _language);
    }
  }

  Future<void> _processUserMessage() async {
    await _sttService.stopListening();
    final userText = _recognizedText.trim();

    if (userText.isEmpty) {
      // YOG initiates
      const greetings = [
        'Bol yaar, kya chal raha hai?',
        'Haan bhai, sun raha hoon!',
        'Bata kya help chahiye?',
        'Main hoon na, bol freely!',
      ];
      final greeting = greetings[Random().nextInt(greetings.length)];
      setState(() {
        _chatMessages.add({'role': 'yog', 'text': greeting});
        _isListening = false;
      });
      _scrollToBottom();
      await _ttsService.speak(greeting, language: _language);
      return;
    }

    setState(() {
      _chatMessages.add({'role': 'user', 'text': userText});
      _isProcessing = true;
      _recognizedText = '';
    });
    _scrollToBottom();

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'User';
    final userTone = prefs.getString('user_tone') ?? prefs.getString('yog_tone') ?? 'yaar';
    final userLanguage = prefs.getString('user_language') ?? prefs.getString('yog_language') ?? 'Hinglish';
    final tuYaAap = prefs.getBool('tu_ya_aap') ?? true;
    final streak = prefs.getInt('streak') ?? 0;

    final user = UserModel(
      id: '1',
      naam: userName,
      language: userLanguage,
      tone: userTone,
      plan: 'premium',
      streak: streak,
      lastMood: _currentMood,
      tuYaAap: tuYaAap,
    );

    final taskProvider = context.read<TaskProvider>();
    final taskSummary = taskProvider.tasks.isEmpty
        ? 'No tasks scheduled yet.'
        : taskProvider.tasks.take(5).map((t) =>
            '- ${t.title} (${t.category}${t.time != null ? ", ${t.time!.hour}:${t.time!.minute.toString().padLeft(2, '0')}" : ""})'
          ).join('\n');

    final responseData = await _gptService.getResponse(
      message: userText,
      user: user,
      currentTasks: taskSummary,
      conversationHistory: _conversationHistory,
    );

    final yogReply = responseData['response'] ?? 'Sorry yaar, kuch gadbad ho gayi.';
    final detectedMood = responseData['mood'] ?? 'neutral';

    setState(() {
      _currentMood = detectedMood;
      _chatMessages.add({'role': 'yog', 'text': yogReply});
      _isProcessing = false;
      _isListening = false;
    });
    _scrollToBottom();

    await prefs.setString('last_mood', detectedMood);

    _conversationHistory.add({'role': 'user', 'content': userText});
    _conversationHistory.add({'role': 'assistant', 'content': yogReply});
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeRange(0, 2);
    }

    UserService.saveMood(detectedMood);
    UserService.saveConversation(userMessage: userText, yogReply: yogReply, mood: detectedMood);

    // Extract tasks
    final extractedRaw = responseData['extracted_tasks'];
    if (extractedRaw is List && extractedRaw.isNotEmpty && mounted) {
      final notifService = NotificationService();
      final today = DateTime.now();
      final List<TaskModel> newTasks = [];
      for (final t in extractedRaw) {
        if (t is Map<String, dynamic>) {
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

    await _ttsService.speak(yogReply, language: _language);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $_userName!';
    if (hour < 17) return 'Good Afternoon, $_userName!';
    return 'Good Evening, $_userName!';
  }

  @override
  void dispose() {
    _sttService.stopListening();
    _ttsService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      _loadUserData();
                    },
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.backgroundCardMedium,
                      child: Icon(Icons.person, size: 20, color: AppTheme.textWhite),
                    ),
                  ),
                  const Text(
                    'SayNote AI',
                    style: TextStyle(
                      color: AppTheme.primaryPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      _loadUserData();
                    },
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.backgroundCardMedium,
                      child: Icon(Icons.settings_rounded, size: 20, color: AppTheme.textWhite),
                    ),
                  ),
                ],
              ),
            ),

            // YOG Avatar + Status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  YogAvatar(size: 100, showGlow: true, isPulsing: _isListening || _isProcessing, mood: _currentMood),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing ? 'YOG soch raha hai...' : _isListening ? 'Sun raha hoon...' : 'Tap mic to talk to YOG',
                    style: TextStyle(
                      color: _isListening ? AppTheme.primaryPurple : AppTheme.textGray,
                      fontSize: 12,
                      fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isListening ? AppTheme.error : AppTheme.primaryPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppTheme.error : AppTheme.primaryPurple).withOpacity(0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  if (_isListening && _recognizedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                      child: Text(
                        _recognizedText,
                        style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Chat / Conversation area
            if (_chatMessages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(messages: _chatMessages))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_rounded, color: AppTheme.primaryPurple, size: 16),
                        SizedBox(width: 8),
                        Text('View Full Conversation', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),

            Expanded(
              child: _chatMessages.isEmpty
                  ? _buildDefaultContent()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _chatMessages.length + (_recognizedText.isNotEmpty && _isListening ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _chatMessages.length) {
                          return _buildChatBubble('user', _recognizedText, isLive: true);
                        }
                        final msg = _chatMessages[index];
                        return _buildChatBubble(msg['role']!, msg['text']!);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(_getGreeting(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          const SizedBox(height: 4),
          const Text('YOG is ready for you today', style: TextStyle(fontSize: 13, color: AppTheme.textGray)),
          const SizedBox(height: 24),

          // Tasks
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCardDark,
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AppTheme.primaryPurple, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
                      child: Container(
                        decoration: const BoxDecoration(color: AppTheme.backgroundCardMedium, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.add, color: AppTheme.textWhite, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<TaskProvider>(
                  builder: (_, provider, __) {
                    if (provider.tasks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Say "$_wakeWord" and tell YOG your tasks!', style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                      );
                    }
                    return Column(
                      children: provider.todayTasks.take(3).map((task) => TaskCard(task: task, onToggle: () => provider.toggleComplete(task.id))).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Streak
          Consumer<TaskProvider>(
            builder: (_, provider, __) {
              final consistency = provider.tasks.isEmpty ? 0 : (provider.completedCount / provider.tasks.length * 100).toInt();
              final level = (_streak ~/ 7) + 1;
              return Row(
                children: [
                  StreakBox(emoji: '🔥', title: '$_streak Days', subtitle: 'Streak'),
                  const SizedBox(width: 12),
                  StreakBox(emoji: '⭐', title: '$consistency%', subtitle: 'Done'),
                  const SizedBox(width: 12),
                  StreakBox(emoji: '⚡', title: 'Lv $level', subtitle: 'Level'),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String role, String text, {bool isLive = false}) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryPurple.withOpacity(0.2) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? AppTheme.primaryPurple.withOpacity(0.4) : Colors.white10,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isLive ? AppTheme.primaryPurple : AppTheme.textWhite,
            fontSize: 14,
            fontStyle: isLive ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
