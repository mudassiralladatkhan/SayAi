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

  Future<void> speak(String text, {String language = 'Hinglish'}) async {
    if (text.trim().isEmpty) return;
    if (!_isReady) {
      await _initTts();
    }

    // Set language based on user preference
    if (language == 'English') {
      await _flutterTts.setLanguage('en-IN');
    } else if (language == 'Hindi') {
      await _flutterTts.setLanguage('hi-IN');
    } else {
      // Hinglish - use hi-IN for Hindi accent on Roman text
      await _flutterTts.setLanguage('hi-IN');
    }

    final cleanText = _removeEmojis(text);
    if (cleanText.trim().isEmpty) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(cleanText);
    } catch (e) {
      // Silently fail — TTS is non-critical
    }
  }

  String _removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{200D}]|[\u{20E3}]|[\u{E0020}-\u{E007F}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
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
