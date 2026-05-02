import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isReady = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("hi-IN"); // Default Hinglish/Hindi support
    await _flutterTts.setPitch(1.1); // Slightly higher, friendly
    await _flutterTts.setSpeechRate(0.5); // Adjusted for clarity (0.5 is usually normal on Android)
    await _flutterTts.setVolume(1.0);
    _isReady = true;
  }

  Future<void> speak(String text) async {
    if (!_isReady) await _initTts();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setLanguage(String langCode) async {
    await _flutterTts.setLanguage(langCode);
  }
}
