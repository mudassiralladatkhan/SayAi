import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class GptService {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  final String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final String _model = 'llama-3.3-70b-versatile';

  Future<Map<String, dynamic>> getResponse({
    required String message,
    required UserModel user,
    required String currentTasks,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    String tonePrompt = '';
    switch (user.tone) {
      case 'yaar':
        tonePrompt = 'casual friendly companion, use yaar bhai chal';
        break;
      case 'coach':
        tonePrompt = 'strict intense motivational coach, use Come on No excuses';
        break;
      case 'friend':
        tonePrompt = 'fun jokey casual best friend with heavy Hinglish';
        break;
      case 'mentor':
        tonePrompt = 'wise calm thoughtful mentor, ask deep questions';
        break;
      default:
        tonePrompt = 'casual friendly companion, use yaar bhai';
    }

    final respect = user.tuYaAap ? 'casual tu/tum' : 'formal aap';

    String lang = '';
    switch (user.language) {
      case 'Hindi':
        lang = 'pure Hindi Devanagari script';
        break;
      case 'English':
        lang = 'pure English only';
        break;
      default:
        lang = 'Hinglish mix of Hindi and English';
    }

    final systemPrompt = '''
You are YOG, a voice AI assistant for Indian user named ${user.naam}.
Language: $lang. Tone: $tonePrompt. Address user with: $respect.
User mood: ${user.lastMood}. Streak: ${user.streak} days.
Today tasks: $currentTasks

IMPORTANT: Respond ONLY with a JSON object. No markdown. No extra text.
Example format:
{"response":"Haan yaar, kya haal hai!","mood":"happy","includeShayari":false,"shayari":"","extracted_tasks":[]}

Rules:
- response: your short reply (2-3 sentences)
- mood: one of happy/sad/neutral/motivated/stressed/excited
- includeShayari: true only if mood is very strong
- shayari: 2-line Hindi shayari, else empty string
- extracted_tasks: list of tasks if user mentions scheduling, else empty list
- Each task: {"title":"...","time":"HH:MM AM/PM","duration":"X min","category":"Work/Health/Learning/Personal/General"}
''';

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory.take(10),
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 512,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 20));

      print('🌐 Groq Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'] as String;
        print('🤖 Groq content: $content');

        // Parse the JSON response
        try {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic> && decoded.containsKey('response')) {
            return decoded;
          }
        } catch (parseErr) {
          print('⚠️ JSON parse error: $parseErr');
        }

        // Fallback: try to extract JSON block manually
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end > start) {
          try {
            final decoded = jsonDecode(content.substring(start, end + 1));
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {}
        }

        // Last resort: return raw text as reply so user isn't stuck
        return {
          'response': content.trim().isNotEmpty ? content.trim() : 'Haan yaar, bol kya hua?',
          'mood': 'neutral',
          'includeShayari': false,
          'shayari': '',
          'extracted_tasks': [],
        };

      } else {
        print('❌ Groq API Error ${response.statusCode}: ${response.body}');
        return _fallbackResponse();
      }

    } on SocketException {
      return {
        'response': 'Internet nahi hai yaar! Wi-Fi check karo. 🌐',
        'mood': 'sad',
        'includeShayari': false,
        'shayari': '',
        'extracted_tasks': [],
      };
    } on TimeoutException {
      return {
        'response': 'Response aane mein time lag raha hai. Thodi der baad try karo! ⏳',
        'mood': 'neutral',
        'includeShayari': false,
        'shayari': '',
        'extracted_tasks': [],
      };
    } catch (e) {
      print('❌ Groq Exception: $e');
      return _fallbackResponse();
    }
  }

  Map<String, dynamic> _fallbackResponse() {
    return {
      'response': 'Kuch technical gadbad hai yaar. App restart karo ek baar! 🔄',
      'mood': 'neutral',
      'includeShayari': false,
      'shayari': '',
      'extracted_tasks': [],
    };
  }
}
