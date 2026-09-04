import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  Future<String> summarizeNotes(String notes) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenRouter API key not found.');
    }

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'openai/gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful study assistant. Summarize student session notes clearly and briefly.',
          },
          {
            'role': 'user',
            'content': 'Summarize these session notes:\n\n$notes',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI request failed: ${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return data['choices'][0]['message']['content'].toString();
  }
}