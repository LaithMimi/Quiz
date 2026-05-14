import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Why is AIService a class instead of a set of top-level functions?
// Because grouping related behaviour into a class gives it a clear namespace
// and makes it easy to find every AI-related operation in one place.
// Notice also that every method is `static` — what does that tell you about
// whether you need to create an AIService *object* before calling it?
class AIService {
  // Why read the API key from a .env file rather than writing it directly
  // in the source code?  Think about what happens when you push your code
  // to GitHub — who else can read it?  The .env file is listed in .gitignore,
  // so the key stays private on your machine while the code stays shareable.
  // Why use a *getter* (`get _apiKey`) instead of a plain variable?
  // A getter is re-evaluated every call, so if dotenv hasn't loaded yet you
  // still get the most up-to-date value rather than a snapshot taken at
  // class initialisation.
  static String get _apiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  // Why store the endpoint as a constant rather than typing the URL every
  // time it's needed?  What would happen if OpenRouter changed their URL —
  // how many places would you need to update?
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // Why list *multiple* models instead of picking just the best one?
  // Free-tier models are rate-limited — they stop accepting requests once
  // you've sent too many in a short period.  If you only had one model,
  // what would your app do when that limit is hit?
  // The models are ordered deliberately: which factors might make you put
  // one model before another (capability, speed, reliability)?
  static const List<String> _models = [
    'google/gemma-4-26b-a4b-it:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-r1:free',
    'meta-llama/llama-4-maverick:free',
  ];

  // Why is _sendWithFallback a *private* helper (leading underscore) rather
  // than a public method?  Ask yourself: does any code *outside* this class
  // need to know which model was used, or do callers just want the result?
  // Keeping it private hides the retry logic so callers think in terms of
  // "send a message" rather than "try model A, then B, then C".
  //
  // Why does it accept `List<Map<String, dynamic>> messages` instead of a
  // plain String?  The OpenAI-style chat API uses a *conversation history*
  // (a list of role/content pairs).  What advantage does this give you over
  // a single string — could you ever send multi-turn conversations this way?
  static Future<String> _sendWithFallback(List<Map<String, dynamic>> messages) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      // Why must Authorization carry the prefix "Bearer "?
      // The HTTP spec defines several authentication *schemes*.  "Bearer"
      // tells the server this is an OAuth2-style token, not a username/
      // password.  What would happen if you forgot the prefix?
      'Authorization': 'Bearer $_apiKey',
    };

    // Why initialise lastError *before* the loop?
    // If every model is rate-limited, the loop ends without throwing — so
    // something outside the loop must remember what went wrong.
    // Could you have used a `try/catch` inside the loop instead?  What
    // are the trade-offs?
    String lastError = 'All models failed';

    for (String model in _models) {
      Map<String, dynamic> requestBody = {
        'model': model,
        'messages': messages,
      };

      // Why `await` here?  HTTP requests can take hundreds of milliseconds.
      // Without `await`, the code would move on to the next line while the
      // request is still in-flight — what would `response` contain then?
      http.Response response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        // Why encode the body as JSON rather than sending the Map directly?
        // HTTP bodies are *bytes*, not Dart objects.  jsonEncode converts the
        // Map into a JSON string that the server can read on the other end.
        body: jsonEncode(requestBody),
      );

      // Why check for 200 before checking for 429?
      // 200 is the "happy path" — the most common outcome when things work.
      // Checking it first keeps the success branch at the top where it's easy
      // to see, and avoids accidentally entering a failure branch on success.
      if (response.statusCode == 200) {
        return response.body;
      }

      // Why treat 429 differently from all other error codes?
      // 429 means "Too Many Requests" — it's a *temporary* condition.
      // Retrying with a different model is a sensible response.
      // But 401 means your API key is wrong — would retrying on a different
      // model fix that?  That's why non-429 errors stop immediately.
      if (response.statusCode == 429) {
        lastError = 'Rate limited on $model, trying next...';
        continue; // `continue` skips the rest of this loop iteration and tries the next model
      }

      // Why throw immediately for unexpected errors rather than `continue`?
      // If you got a 400 (bad request), every model would give the same error
      // because *your request* is malformed — the problem isn't which model
      // you chose.  Failing fast surfaces the real problem sooner.
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    // Reaching here means every model returned 429.
    // Why throw instead of returning an empty string?
    // An empty string would be silently treated as valid JSON later and cause
    // a confusing crash.  An exception forces the caller to handle the failure
    // explicitly — what does the caller do with this exception?
    throw Exception(lastError);
  }

  // Why do some models wrap their JSON output in markdown code fences (```)?
  // Because they're trained to format responses for *humans* reading them in
  // a chat UI, where code blocks look nicer.  But here you need raw JSON so
  // jsonDecode can parse it.  Why use a RegExp rather than simple string
  // replacement — what edge cases does the regex handle that plain replace
  // would miss?
  static String _cleanJson(String raw) {
    String cleaned = raw.trim();
    // Why check `startsWith('```')` before running the replacement?
    // It avoids running the regex at all when no fences are present — a small
    // but illustrative example of doing less work when you already know the
    // answer.
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }
    return cleaned;
  }

  // Why does this method return `List<Map<String, String>>` rather than,
  // say, a custom `Task` class?  A Map is simpler to create and requires no
  // extra file — but what would you *lose* by not having a typed class?
  // (Hint: think about autocomplete, compile-time checks, and readability
  // elsewhere in the codebase.)
  static Future<List<Map<String, String>>> generateTasksFromDocument(String content) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        // Why split the conversation into a "system" message and a "user" message
        // rather than putting everything in one message?
        // The system message sets the AI's *behaviour* (what it should do and
        // how it should format output) while the user message provides the *data*
        // to act on.  Keeping them separate makes it easy to reuse the same
        // instructions with different documents.
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

    // Why navigate `decoded['choices'][0]['message']['content']` rather than
    // using the top-level response body directly?
    // The OpenAI chat-completions API wraps the model's reply in a `choices`
    // array (you could have asked for multiple completions).  The actual text
    // lives inside `choices[0].message.content`.
    // What would happen if `choices` were empty — how could you guard against it?
    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String rawContent = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(rawContent)) as Map<String, dynamic>;

    List<dynamic> rawTasks = result['tasks'] as List<dynamic>;
    List<Map<String, String>> taskList = [];

    for (dynamic item in rawTasks) {
      Map<String, dynamic> taskMap = item as Map<String, dynamic>;
      String title = taskMap['title'] as String? ?? '';

      // Why skip tasks with an empty title instead of adding them?
      // A task with no name is meaningless to the user — it would show up as
      // a blank card in the UI.  Defensive filtering here prevents bad data
      // from ever reaching the display layer.  Where else in the app might
      // you need to handle the case where the AI returns incomplete data?
      if (title.isEmpty) {
        continue;
      }

      Map<String, String> task = {
        'title': title,
        // Why use `?? ''` as a fallback for description?
        // The `as String?` cast acknowledges that the AI *might* omit the field.
        // Rather than crashing with a null error, a blank description is a
        // safe default.  Is a blank description actually better than an error
        // here, or might it hide a bug in the prompt?
        'description': taskMap['description'] as String? ?? '',
      };

      taskList.add(task);
    }

    return taskList;
  }

  // Why is this a separate method from generateTasksFromDocument rather than
  // generating details for all tasks inside that method?
  // Separation of concerns: one method extracts *what* tasks exist, another
  // elaborates on a *single* task on demand.  When would calling this lazily
  // (only when the user opens a task) be better than eagerly generating
  // descriptions for every task upfront?
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
        // Why interpolate the title with a label ("Task title: ") rather than
        // sending the title alone?  The label gives the model context about
        // what kind of string follows.  Try removing it mentally — would the
        // model still understand what you're asking?
        'content': 'Task title: $title',
      },
    ];

    String responseBody = await _sendWithFallback(messages);

    Map<String, dynamic> decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    String content = decoded['choices'][0]['message']['content'] as String;
    Map<String, dynamic> result = jsonDecode(_cleanJson(content)) as Map<String, dynamic>;

    // Why return a Map with one key instead of just returning the String directly?
    // Consistency with generateTasksFromDocument and room to grow — if you
    // later want to add an `estimatedHours` or `priority` field, callers don't
    // need to change their code.  Is that flexibility worth the extra wrapping
    // here, or is it over-engineering?
    return {
      'description': result['description'] as String? ?? '',
    };
  }
}
