import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get _apiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  static const List<String> _models = [
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
    'qwen/qwen3-next-80b-a3b-instruct:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-v4-flash:free',
    'meta-llama/llama-4-maverick:free',
  ];

  static Future<String> _sendWithFallback(List<Map<String, dynamic>> messages) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    // tracks the last error for when all models are exhausted; a try/catch inside the loop would complicate flow
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

      if (response.statusCode == 200) {
        return response.body;
      }

      // 429 is a rate limit — temporary, so retrying with another model makes sense
      if (response.statusCode == 429) {
        lastError = 'Rate limited on $model, trying next...';
        continue;
      }

      // other errors (400, 401, etc.) indicate a permanent issue, so fail fast
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    throw Exception(lastError);
  }

  // some models wrap JSON in markdown fences (```), so this strips them
  static String _cleanJson(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }
    return cleaned;
  }

  static Future<List<Map<String, String>>> generateTasksFromDocument(String content) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': '''You are a project management assistant.
          Analyze the following scope of work document and extract every actionable task.
          Return a JSON object with a single "tasks" array. Each task must have exactly:
          - title: short, actionable name (max 30 characters)
          - description: what this task involves (1-2 sentences)
          Respond with raw JSON only. No markdown, no code fences.''',
      },
      {
        'role': 'user',
        'content': content,
      },
    ];

    String responseBody = await _sendWithFallback(messages);

    // the API wraps replies in "choices[0].message.content"
    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String rawContent = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(rawContent)) as Map<String, dynamic>;

    List<dynamic> rawTasks = result['tasks'] as List<dynamic>;
    List<Map<String, String>> taskList = [];

    for (dynamic item in rawTasks) {
      Map<String, dynamic> taskMap = item as Map<String, dynamic>;
      String title = taskMap['title'] as String? ?? '';

      //skip tasks with empty titles to avoid meaningless blank entries in the UI.
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

    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String content = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(content)) as Map<String, dynamic>;

    return {
      'description': result['description'] as String? ?? '',
    };
  }
}
