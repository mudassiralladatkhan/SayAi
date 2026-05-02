import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isReady = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // Get available languages on this device
      final languages = await _flutterTts.getLanguages as List?;

      // Try hi-IN first, fall back to en-IN, then en-US
      String selectedLang = 'en-US';
      if (languages != null) {
        if (languages.contains('hi-IN')) {
          selectedLang = 'hi-IN';
        } else if (languages.contains('en-IN')) {
          selectedLang = 'en-IN';
        } else if (languages.contains('en-US')) {
          selectedLang = 'en-US';
        }
      }

      await _flutterTts.setLanguage(selectedLang);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);

      // On Android, set the engine explicitly
      await _flutterTts.awaitSpeakCompletion(true);

      _isReady = true;
    } catch (e) {
      // TTS init failed — mark as not ready, will retry on speak()
      _isReady = false;
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!_isReady) {
      await _initTts();
    }
    try {
      await _flutterTts.stop(); // Stop any ongoing speech first
      await _flutterTts.speak(text);
    } catch (e) {
      // Silently fail — TTS is non-critical
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    try {
      await _flutterTts.setLanguage(langCode);
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
