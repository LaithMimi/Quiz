import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Read the API key from the .env file at runtime
  static String get _apiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // Models are tried in order — if one is rate-limited the next one is used
  static const List<String> _models = [
    'google/gemma-4-26b-a4b-it:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-r1:free',
    'meta-llama/llama-4-maverick:free',
  ];

  // Send the same request to each model in order until one succeeds
  // Returns the raw response body string, or throws if all models fail
  static Future<String> _sendWithFallback(List<Map<String, dynamic>> messages) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    String lastError = 'All models failed';

    for (String model in _models) {
      Map<String, dynamic> requestBody = {
        'model': model,
        'messages': messages,
      };

      http.Response response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      // Success — return the raw response body
      if (response.statusCode == 200) {
        return response.body;
      }

      // Rate-limited — try the next model
      if (response.statusCode == 429) {
        lastError = 'Rate limited on $model, trying next...';
        continue;
      }

      // Any other error (401, 400, etc.) — stop immediately, no point retrying
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    // All models were rate-limited
    throw Exception(lastError);
  }

  // Strip markdown code fences that some models add around JSON
  static String _cleanJson(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }
    return cleaned;
  }

  // Read a full document and extract all actionable tasks from it
  // Throws an exception with the actual error message if all models fail
  static Future<List<Map<String, String>>> generateTasksFromDocument(String content) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
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

    // Parse the response JSON
    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String rawContent = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(rawContent)) as Map<String, dynamic>;

    // Convert each item in the tasks array into a Map<String, String>
    List<dynamic> rawTasks = result['tasks'] as List<dynamic>;
    List<Map<String, String>> taskList = [];

    for (dynamic item in rawTasks) {
      Map<String, dynamic> taskMap = item as Map<String, dynamic>;
      String title = taskMap['title'] as String? ?? '';

      // Skip tasks that have no title
      if (title.isEmpty) {
        continue;
      }

      Map<String, String> task = {
        'title': title,
        'description': taskMap['description'] as String? ?? '',
      };

      taskList.add(task);
    }

    return taskList;
  }

  // Generate description for a single task based on its title
  // Throws an exception with the actual error message if all models fail
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
        'content': 'Task title: $title',
      },
    ];

    String responseBody = await _sendWithFallback(messages);

    // Parse the response JSON
    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String content = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(content)) as Map<String, dynamic>;

    return {
      'description': result['description'] as String? ?? '',
    };
  }
}
