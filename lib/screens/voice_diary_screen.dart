import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/yog_avatar.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class VoiceDiaryEntry {
  final String id;
  final String transcript;
  final DateTime timestamp;
  final String mood;

  VoiceDiaryEntry({
    required this.id,
    required this.transcript,
    required this.timestamp,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'transcript': transcript,
    'timestamp': timestamp.toIso8601String(),
    'mood': mood,
  };

  factory VoiceDiaryEntry.fromJson(Map<String, dynamic> json) => VoiceDiaryEntry(
    id: json['id'] ?? '',
    transcript: json['transcript'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    mood: json['mood'] ?? 'neutral',
  );
}

class VoiceDiaryScreen extends StatefulWidget {
  const VoiceDiaryScreen({Key? key}) : super(key: key);

  @override
  State<VoiceDiaryScreen> createState() => _VoiceDiaryScreenState();
}

class _VoiceDiaryScreenState extends State<VoiceDiaryScreen> {
  int _currentIndex = 2;
  bool _isRecording = false;
  String _liveText = '';
  final List<VoiceDiaryEntry> _entries = [];

  final SttService _sttService = SttService();
  final TtsService _ttsService = TtsService();

  static const _prefsKey = 'diary_entries';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      _entries.clear();
      _entries.addAll(raw.map((e) {
        try {
          return VoiceDiaryEntry.fromJson(jsonDecode(e));
        } catch (_) {
          return null;
        }
      }).whereType<VoiceDiaryEntry>());
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // Mood color mapping
  Color _moodColor(String mood) {
    switch (mood) {
      case 'happy': return const Color(0xFF4CAF50);
      case 'sad': return const Color(0xFF2196F3);
      case 'stressed': return const Color(0xFFF44336);
      case 'motivated': return const Color(0xFFFF9800);
      case 'excited': return const Color(0xFFE91E63);
      default: return AppTheme.primaryPurple;
    }
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'stressed': return '😰';
      case 'motivated': return '💪';
      case 'excited': return '🎉';
      default: return '😐';
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _sttService.stopListening();
      if (_liveText.trim().isNotEmpty) {
        final newEntry = VoiceDiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          transcript: _liveText.trim(),
          timestamp: DateTime.now(),
          mood: 'neutral',
        );
        setState(() {
          _entries.insert(0, newEntry);
          _liveText = '';
        });
        await _saveEntries(); // 💾 persist
      }
      setState(() { _isRecording = false; });
    } else {
      final ok = await _sttService.initialize();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required!'), backgroundColor: AppTheme.error),
        );
        return;
      }
      setState(() { _isRecording = true; _liveText = ''; });
      _sttService.startListening((text) {
        setState(() { _liveText = text; });
      });
    }
  }

  @override
  void dispose() {
    _sttService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          const Text(
                            '🎙️ Voice Diary',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
                          ),
                          const SizedBox(height: 24),

                          // Record Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isRecording
                                    ? [const Color(0xFF3D0070), const Color(0xFF1A0040)]
                                    : [AppTheme.backgroundCardMedium, AppTheme.backgroundCardDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isRecording ? AppTheme.primaryPurple : Colors.white10,
                              ),
                            ),
                            child: Column(
                              children: [
                                YogAvatar(size: 80, showGlow: _isRecording, isPulsing: _isRecording),
                                const SizedBox(height: 16),
                                Text(
                                  _isRecording ? 'YOG is listening...' : 'Tap to speak your diary',
                                  style: TextStyle(
                                    color: _isRecording ? AppTheme.primaryPurple : AppTheme.textGray,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_liveText.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '"$_liveText"',
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: _toggleRecording,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording ? AppTheme.error : AppTheme.primaryPurple,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isRecording ? AppTheme.error : AppTheme.primaryPurple).withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Past Entries Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Past Entries',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_entries.length} entries',
                                style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Entries List
                  _entries.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyDiary())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: _buildEntryCard(_entries[index]),
                            ),
                            childCount: _entries.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
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

  Widget _buildEntryCard(VoiceDiaryEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _moodColor(entry.mood).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_moodEmoji(entry.mood), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                DateFormat('hh:mm a').format(entry.timestamp),
                style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM').format(entry.timestamp),
                style: const TextStyle(color: AppTheme.textGray, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${entry.transcript}"',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _ttsService.speak(entry.transcript),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: AppTheme.textGray, size: 16),
                const SizedBox(width: 4),
                const Text('Replay', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDiary() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Text('📔', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Abhi koi diary entry nahi hai!',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Upar mic dabao aur YOG ko\napna din batao! 🎙️',
            style: TextStyle(color: AppTheme.textGray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
