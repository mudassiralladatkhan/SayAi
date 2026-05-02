import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('STT Error: \$val'),
        onStatus: (val) => print('STT Status: \$val'),
      );
    }
    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) await initialize();
    
    if (_isInitialized) {
      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
        },
        localeId: 'hi_IN',
        pauseFor: const Duration(seconds: 3),
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
