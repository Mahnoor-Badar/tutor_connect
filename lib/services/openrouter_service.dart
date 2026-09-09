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
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'openrouter/free',
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

    if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your OpenRouter API key.');
    }

    if (response.statusCode == 402) {
      throw Exception('No credits available for this OpenRouter request.');
    }

    if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment and try again.');
    }

    if (response.statusCode >= 500) {
      throw Exception('OpenRouter service is temporarily unavailable.');
    }

    if (response.statusCode != 200) {
      throw Exception('Unable to get a response from the AI.\n${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['choices'][0]['message']['content'].toString();
  }
}