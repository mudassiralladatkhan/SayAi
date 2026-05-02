import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class GptService {
  // Groq API — fast, reliable, free tier
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  final String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final String _model = 'llama3-70b-8192';

  Future<Map<String, dynamic>> getResponse({
    required String message,
    required UserModel user,
    required String currentTasks,
  }) async {
    String tonePrompt = '';
    switch (user.tone) {
      case 'yaar':
        tonePrompt = 'You are a casual, friendly, chill companion. Use "yaar", "bhai", "chal". Be motivating but relaxed.';
        break;
      case 'coach':
        tonePrompt = 'You are a strict, pushing, intense motivational coach. Use "Come on!", "No excuses!". Be high energy.';
        break;
      case 'friend':
        tonePrompt = 'You are a fun, jokey, very casual best friend. Use lots of humor and heavy Hinglish.';
        break;
      case 'mentor':
        tonePrompt = 'You are a wise, calm, thoughtful mentor. Ask deep questions, be philosophical.';
        break;
      default:
        tonePrompt = 'You are a casual, friendly companion. Use "yaar", "bhai". Be motivating.';
    }

    String respect = user.tuYaAap ? 'Use casual "tu" or "tum".' : 'Use formal "aap".';

    String languageInstruction = '';
    switch (user.language) {
      case 'Hindi':
        languageInstruction = 'STRICTLY reply in pure Hindi (Devanagari script). Do NOT use English words.';
        break;
      case 'English':
        languageInstruction = 'STRICTLY reply in pure English. Do NOT use Hindi or Hinglish.';
        break;
      default: // Hinglish
        languageInstruction = 'Reply in Hinglish — a natural mix of Hindi and English, as Indian friends speak.';
    }

    final systemPrompt = '''
You are YOG (Your Own Guide), a voice-first AI life assistant for an Indian user named ${user.naam}.
LANGUAGE RULE (MANDATORY): $languageInstruction
Tone: $tonePrompt
Respect level: $respect
User's current mood: ${user.lastMood}.
User's current streak: ${user.streak} days.
Today's scheduled tasks: $currentTasks

RULES:
1. Always reply in Hinglish (mix Hindi + English naturally).
2. Keep your response SHORT and conversational (2-3 sentences max).
3. If the user mentions scheduling something (e.g. "gym at 6", "meeting tomorrow 3pm"), extract it as a task.
4. If the user's mood is very strong (happy/sad/stressed), include a short 2-line Hinglish shayari.
5. OUTPUT ONLY VALID RAW JSON — no markdown, no code blocks, no extra text before or after.

JSON format:
{
  "response": "YOG's reply in Hinglish",
  "mood": "happy|sad|neutral|motivated|stressed|excited",
  "includeShayari": true|false,
  "shayari": "2 line shayari if needed, else empty string",
  "extracted_tasks": [
    {"title": "Task name", "time": "5:00 PM", "duration": "30 min", "category": "Work|Health|Learning|Personal|General"}
  ]
}
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];

        // Strip any accidental markdown wrapping
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();

        // Extract only the JSON object
        int start = content.indexOf('{');
        int end = content.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          content = content.substring(start, end + 1);
        }

        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception('Invalid JSON format from Groq');
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return _fallbackResponse();
      }
    } on SocketException catch (_) {
      return {
        "response": "Internet connection nahi mil raha yaar. Wi-Fi check kar lo ek baar! 🌐",
        "mood": "sad",
        "includeShayari": false,
        "shayari": "",
        "extracted_tasks": [],
      };
    } on TimeoutException catch (_) {
      return {
        "response": "Internet bahut slow hai yaar. YOG wait kar karke thak gaya! ⏳",
        "mood": "stressed",
        "includeShayari": false,
        "shayari": "",
        "extracted_tasks": [],
      };
    } catch (e) {
      print('Groq API Exception: $e');
      return _fallbackResponse();
    }
  }

  Map<String, dynamic> _fallbackResponse() {
    return {
      "response": "Yaar, abhi network thoda slow hai! Thodi der baad try karo. Tab tak apna kaam karte raho! 💪",
      "mood": "neutral",
      "includeShayari": false,
      "shayari": "",
      "extracted_tasks": [],
    };
  }
}
