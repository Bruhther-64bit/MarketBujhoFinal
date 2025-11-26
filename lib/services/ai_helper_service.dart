import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product_model.dart'; // Assuming this path is correct

class AiHelperService {
  // 🔴 IMPORTANT: Insert your actual Gemini API Key here.
  static const String _apiKey = 'AIzaSyDuATilc6kig-wV8HiT5BcymSk7JyFg3cY'; 

  // FIX: Using the correct model identifier.
  static const String _model = 'gemini-2.5-flash';

  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _systemInstruction = 
      'You are MarketBujho AI, a helpful shopping assistant focused on Bangladesh. '
      'Give specific, practical advice. If you talk about prices, keep it approximate and do NOT claim to know live prices. '
      'Always encourage the user to double-check prices on the linked sites.';


  /// Ask the AI shopping assistant a question.
  Future<String> askShoppingAssistant(
    String userQuestion, {
    List<Product>? contextProducts,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Error: API Key is missing. Please set your actual key in AiHelperService._apiKey.';
    }
    if (userQuestion.trim().isEmpty) {
      return 'Please enter a question.';
    }

    final buffer = StringBuffer();
    
    // Add products context if provided
    if (contextProducts != null && contextProducts.isNotEmpty) {
      buffer.writeln('Here are some products the user has found:');
      for (var p in contextProducts.take(8)) {
        buffer.writeln(
            '- Title: ${p.title}\n  Price: ${p.price ?? 'N/A'}\n  Site: ${p.source ?? ''}\n  Link: ${p.link}\n  Description: ${p.snippet ?? ''}\n');
      }
      buffer.writeln(
          'Use these products as examples when answering, if they are relevant.');
    }
    
    buffer.writeln('\nUser question: $userQuestion');

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {
            'text': _systemInstruction,
          }
        ]
      },
      'contents': [
        {
          'parts': [
            {
              'text': buffer.toString(),
            }
          ],
        }
      ],
    });

    // Use exponential backoff for retries
    const int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      final uri = Uri.parse('$_endpoint?key=$_apiKey');

      try {
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          // 🛑 FIX: Reverting to explicit list checks to avoid NoSuchMethodError on 'firstOrNull'
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            return 'I did not get any response.';
          }

          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content == null) return 'I did not get any response.';

          final parts = content['parts'] as List?;
          if (parts == null || parts.isEmpty) {
            return 'I did not get any response.';
          }

          final text = parts[0]['text']?.toString();
          if (text == null || text.trim().isEmpty) {
            return 'I did not get any response.';
          }
          // -----------------------------------------------------------------

          return text.trim();

        } else if (response.statusCode >= 500 && currentRetry < maxRetries - 1) {
          currentRetry++;
          final delay = Duration(milliseconds: 1000 * (1 << currentRetry));
          await Future.delayed(delay);

        } else {
          print(
              'Gemini API error: HTTP ${response.statusCode} ${response.body}');
          
          if (response.statusCode == 400 || response.statusCode == 403) {
             return 'API Error: Please check if your API Key is correct and if you have enabled the Gemini API in your project.';
          }
          return 'Sorry, I could not generate a response right now.';
        }
      } catch (e) {
        if (currentRetry < maxRetries - 1) {
          currentRetry++;
          final delay = Duration(milliseconds: 1000 * (1 << currentRetry));
          await Future.delayed(delay);
        } else {
          print('Gemini API exception: $e');
          return 'Something went wrong while talking to AI.';
        }
      }
    }
    return 'Failed to get a response after multiple retries.';
  }
}