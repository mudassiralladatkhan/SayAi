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
    if (user.language == 'English') {
      switch (user.tone) {
        case 'yaar':
          tonePrompt = 'casual friendly companion, like a close buddy. Use words like dude, bro, mate.';
          break;
        case 'coach':
          tonePrompt = 'strict intense motivational coach. Push hard, no excuses.';
          break;
        case 'friend':
          tonePrompt = 'fun jokey casual best friend. Crack jokes, tease lightly.';
          break;
        case 'mentor':
          tonePrompt = 'wise calm thoughtful mentor. Ask deep questions, give perspective.';
          break;
        default:
          tonePrompt = 'casual friendly companion.';
      }
    } else {
      switch (user.tone) {
        case 'yaar':
          tonePrompt = 'casual friendly companion, use yaar bhai chal type language.';
          break;
        case 'coach':
          tonePrompt = 'strict intense motivational coach, push hard, no excuses.';
          break;
        case 'friend':
          tonePrompt = 'fun jokey casual best friend, crack jokes, tease.';
          break;
        case 'mentor':
          tonePrompt = 'wise calm thoughtful mentor, ask deep questions.';
          break;
        default:
          tonePrompt = 'casual friendly companion.';
      }
    }

    final respect = (user.language == 'English') ? '' : (user.tuYaAap ? 'Use casual tu/tum to address the user.' : 'Use formal aap to address the user.');

    String lang = '';
    switch (user.language) {
      case 'Hindi':
        lang = 'Respond in Hindi using Devanagari script (like: हाय, क्या हाल है?). Every word in Devanagari.';
        break;
      case 'English':
        lang = 'Respond in English only. No Hindi words. Example: "Hey, how are you? How is your day going?"';
        break;
      default:
        lang = '''Respond in Hinglish using ONLY Roman/English alphabet.
CORRECT examples: "Arey yaar, kya haal hai?", "Tera din kaisa gaya?", "Chal bata kya scene hai"
WRONG (NEVER DO THIS): "अरे यार, क्या हाल है?" - this is Devanagari, NOT allowed for Hinglish.
Hinglish = Hindi words spelled in English letters. NEVER use Devanagari script (अ आ इ ई उ ऊ etc). Use ONLY a-z English letters.''';
    }

    final systemPrompt = '''
You are YOG, a personal voice AI assistant for ${user.naam}.

LANGUAGE RULE (STRICTLY FOLLOW):
$lang

TONE: $tonePrompt
ADDRESS: $respect

CRITICAL RULES:
- Give ONLY one response in the EXACT language specified above. Do NOT give translations or responses in multiple languages.
- Respond naturally to what the user actually said. Do NOT give generic greetings unless the user greeted you first.
- Keep responses short (1-3 sentences), natural, and conversational.
- Detect the user's mood from their message.
- If user mentions tasks/schedule, extract them.

User context: Streak ${user.streak} days. Tasks: $currentTasks

Respond ONLY with a JSON object. No markdown. No extra text.
{"response":"your reply here","mood":"detected_mood","includeShayari":false,"shayari":"","extracted_tasks":[]}

mood must be one of: happy/sad/neutral/motivated/stressed/excited/angry/anxious/calm/tired/confused
extracted_tasks format: [{"title":"...","time":"HH:MM AM/PM","duration":"X min","category":"Work/Health/Learning/Personal/General"}]
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
