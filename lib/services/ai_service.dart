import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// All methods are `static`, which means you don’t need to create an AIService
// object before calling them. You can call AIService.generateTasksFromDocument()
// directly without instantiating the class.
class AIService {
  // Using a getter ensures the API key is always fetched fresh from dotenv.
  // If dotenv loads later, you’ll still get the updated value instead of a stale snapshot.
  static String get _apiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  // Storing the endpoint as a constant avoids repetition and makes it easy to
  // update in one place if OpenRouter changes their URL.
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // Multiple models are listed because free-tier models are rate-limited.
  // If one model rejects requests due to limits, the code can fall back to another.
  // Ordering reflects capability, speed, and reliability.
  static const List<String> _models = [
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
    'qwen/qwen3-next-80b-a3b-instruct:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-v4-flash:free',
    'meta-llama/llama-4-maverick:free',
  ];

  // _sendWithFallback is private because callers don’t need to know which model
  // was used — they only care about the result. It accepts a list of messages
  // because the API uses conversation history, allowing multi-turn exchanges.
  static Future<String> _sendWithFallback(List<Map<String, dynamic>> messages) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      // Authorization must include "Bearer " to indicate OAuth2-style token.
      'Authorization': 'Bearer $_apiKey',
    };

    // Initialising lastError before the loop ensures you have a meaningful error
    // if all models fail. A try/catch inside the loop would complicate control flow.
    String lastError = 'All models failed';

    for (String model in _models) {
      Map<String, dynamic> requestBody = {
        'model': model,
        'messages': messages,
      };

      // Await ensures the HTTP request completes before moving on.
      http.Response response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        // jsonEncode converts the Map into a JSON string, since HTTP bodies are bytes.
        body: jsonEncode(requestBody),
      );

      // Check 200 first because it’s the common success path.
      if (response.statusCode == 200) {
        return response.body;
      }

      // 429 is temporary (rate limit), so retrying with another model makes sense.
      if (response.statusCode == 429) {
        lastError = 'Rate limited on $model, trying next...';
        continue;
      }

      // Other errors (like 400 or 401) indicate a permanent issue, so fail fast.
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    // If all models returned 429, throw an exception so the caller must handle it.
    throw Exception(lastError);
  }

  // Some models wrap JSON in markdown fences (```), so _cleanJson strips them.
  // Regex handles variations like ```json or extra newlines better than simple replace.
  static String _cleanJson(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }
    return cleaned;
  }

  // Returning List<Map<String, String>> is simpler than defining a custom class,
  // but you lose type safety, autocomplete, and readability benefits of a typed model.
  static Future<List<Map<String, String>>> generateTasksFromDocument(String content) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        // System message defines behaviour, user message provides data.
        'content': '''You are a project management assistant.
Analyze the following scope of work document and extract every actionable task.
Return a JSON object with a single "tasks" array. Each task must have exactly:
- title: short, actionable name (max 60 characters)
- description: what this task involves (1-2 sentences)
Respond with raw JSON only. No markdown, no code fences.''',
      },
      {
        'role': 'user',
        'content': content,
      },
    ];

    String responseBody = await _sendWithFallback(messages);

    // The API wraps replies in `choices`, so you must navigate into choices[0].message.content.
    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String rawContent = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(rawContent)) as Map<String, dynamic>;

    List<dynamic> rawTasks = result['tasks'] as List<dynamic>;
    List<Map<String, String>> taskList = [];

    for (dynamic item in rawTasks) {
      Map<String, dynamic> taskMap = item as Map<String, dynamic>;
      String title = taskMap['title'] as String? ?? '';

      // Skip tasks with empty titles to avoid meaningless blank entries in the UI.
      if (title.isEmpty) {
        continue;
      }

      Map<String, String> task = {
        'title': title,
        // Fallback to empty string prevents null errors if description is missing.
        'description': taskMap['description'] as String? ?? '',
      };

      taskList.add(task);
    }

    return taskList;
  }

  // Separation of concerns: one method extracts tasks, another elaborates on a single task.
  // Lazy generation saves resources by only fetching details when needed.
  static Future<Map<String, String>> generateTaskDetails(String title) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': '''You are a project management assistant.
Given a task title, respond with a JSON object containing exactly one field:
- description: a clear 1-2 sentence explanation of what this task involves

Respond with raw JSON only. No markdown, no code blocks.''',
      },
      {
        'role': 'user',
        // Adding "Task title:" label gives the model context about the string.
        'content': 'Task title: $title',
      },
    ];

    String responseBody = await _sendWithFallback(messages);

    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String content = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(content)) as Map<String, dynamic>;

    // Returning a Map allows future expansion (e.g., priority, estimatedHours).
    return {
      'description': result['description'] as String? ?? '',
    };
  }
}
