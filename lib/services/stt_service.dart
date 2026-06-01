import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  Function()? onStopped;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('STT Error: ${val.errorMsg}'),
        onStatus: (val) {
          print('STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            onStopped?.call();
          }
        },
      );
      print('STT initialized: $_isInitialized');
    }
    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult, {String language = 'Hinglish'}) async {
    if (!_isInitialized) await initialize();

    if (_isInitialized) {
      String localeId = 'en_IN';
      final locales = await _speech.locales();
      final localeIds = locales.map((l) => l.localeId).toList();

      if (language == 'English') {
        if (localeIds.contains('en_IN')) {
          localeId = 'en_IN';
        } else if (localeIds.contains('en_US')) {
          localeId = 'en_US';
        }
      } else if (language == 'Hindi') {
        if (localeIds.contains('hi_IN')) {
          localeId = 'hi_IN';
        }
      } else {
        // Hinglish - prefer hi_IN for better recognition of mixed speech
        if (localeIds.contains('hi_IN')) {
          localeId = 'hi_IN';
        } else if (localeIds.contains('en_IN')) {
          localeId = 'en_IN';
        }
      }

      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
        },
        localeId: localeId,
        pauseFor: const Duration(seconds: 5),
        listenFor: const Duration(seconds: 30),
        partialResults: true,
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
