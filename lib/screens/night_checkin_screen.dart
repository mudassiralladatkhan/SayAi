import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../providers/task_provider.dart';
import 'voice_diary_screen.dart';
import 'voice_capture_screen.dart';

class NightCheckinScreen extends StatefulWidget {
  const NightCheckinScreen({Key? key}) : super(key: key);

  @override
  State<NightCheckinScreen> createState() => _NightCheckinScreenState();
}

class _NightCheckinScreenState extends State<NightCheckinScreen> {
  int _selectedMood = -1; // 0: Sad, 1: Okay, 2: Good, 3: Happy, 4: Great
  final TextEditingController _textController = TextEditingController();
  
  String _userName = 'Guest';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _streak = prefs.getInt('streak') ?? 0;
    });
  }

  Future<void> _saveCheckin() async {
    final prefs = await SharedPreferences.getInstance();
    
    final moodStr = _selectedMood >= 0 ? moods[_selectedMood]['label'] : 'neutral';
    final text = _textController.text.trim();
    final entryText = text.isNotEmpty ? text : "Completed my night check-in.";

    final newEntry = VoiceDiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transcript: "Night Check-in: $entryText",
      timestamp: DateTime.now(),
      mood: moodStr!.toLowerCase(),
    );

    final raw = prefs.getString('diary_entries');
    List<dynamic> jsonList = raw != null ? jsonDecode(raw) : [];
    jsonList.insert(0, newEntry.toJson());
    await prefs.setString('diary_entries', jsonEncode(jsonList));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Night check-in saved to Voice Diary! 🌙'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  final List<Map<String, String>> moods = [
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😄', 'label': 'Great'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.access_time, size: 14, color: AppTheme.textWhite),
              SizedBox(width: 4),
              Text('10:30 PM', style: TextStyle(fontSize: 12, color: AppTheme.textWhite)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            const Text('🌙', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Good Night, $_userName',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
            ),
            const SizedBox(height: 8),
            const Text(
              'YOG ka raat ka sawaal time',
              style: TextStyle(fontSize: 14, color: AppTheme.textGray),
            ),
            const SizedBox(height: 32),

            // YOG Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  YogAvatar.small(),
                  const SizedBox(height: 16),
                  Consumer<TaskProvider>(
                    builder: (_, provider, __) {
                      final pendingTasks = provider.todayTasks.where((t) => !t.completed).toList();
                      final prompt = pendingTasks.isNotEmpty 
                          ? '$_userName, aaj ka din kaisa raha?\nKya "${pendingTasks.first.title}" reh gaya? 🤔'
                          : '$_userName, aaj ka din kaisa raha?\nSaare tasks complete ho gaye! 🌟';
                      return Text(
                        prompt,
                        style: const TextStyle(fontSize: 16, color: AppTheme.textWhite),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mood Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('AAJ KA MOOD:', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                bool isSelected = _selectedMood == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = index),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryPurple : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(moods[index]['emoji']!, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        moods[index]['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Task Review
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('AAJ KA TASKS:', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Consumer<TaskProvider>(
              builder: (_, provider, __) {
                final todayTasks = provider.todayTasks;
                if (todayTasks.isEmpty) {
                  return const Text('Aaj koi tasks nahi the.', style: TextStyle(color: AppTheme.textGray));
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: todayTasks.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTaskReviewRow(t.completed, t.title),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Streak Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AAJ KA STREAK:', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text('🔥 $_streak Days', style: const TextStyle(color: AppTheme.gold, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Kal bhi karo — streak mat todna!', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // YOG Ko Bolo
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('YOG KO BOLO', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceCaptureScreen()));
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: AppTheme.textWhite, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Apna din bolo YOG ko (Text reply)',
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveCheckin,
                child: const Text('Raat ko save karo ✓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskReviewRow(bool completed, String title) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppTheme.success : AppTheme.error,
          ),
          child: Icon(
            completed ? Icons.check : Icons.close,
            size: 14,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: completed ? AppTheme.textWhite : AppTheme.textGray,
            fontSize: 14,
            decoration: completed ? null : TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}
