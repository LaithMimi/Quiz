class Task {
  final String id;
  final String title;
  final String columnId;
  final String username;
  final DateTime date;
  final DateTime? duedate;
  final String? description;
  final String? sharedWith; // email this task was assigned to
  final String? sharedBy;   // email of who assigned this task

  const Task({
    required this.id,
    required this.title,
    required this.columnId,
    this.username = '',
    required this.date,
    this.duedate,
    this.description,
    this.sharedWith,
    this.sharedBy,
  });

  //converting a Map from Firestore into a Task object
  factory Task.fromJson(Map<String, dynamic> json) {
    String id = json['id'].toString();
    String title = json['title'] as String;
    String columnId = json['columnId'] as String? ?? '';
    String username = json['username'] as String? ?? '';

    DateTime date;
    if (json['date'] != null) {
      date = DateTime.parse(json['date'] as String);
    } else {
      date = DateTime.now();
    }

    DateTime? duedate;
    if (json['duedate'] != null) {
      duedate = DateTime.parse(json['duedate'] as String);
    }

    String? description = json['description'] as String?;
    String? sharedWith = json['sharedWith'] as String?;
    String? sharedBy = json['sharedBy'] as String?;

    return Task(
      id: id,
      title: title,
      columnId: columnId,
      username: username,
      date: date,
      duedate: duedate,
      description: description,
      sharedWith: sharedWith,
      sharedBy: sharedBy,
    );
  }

  // Convert a Subtask into a Map so we can save it to Firestore
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'columnId': columnId,
      'username': username,
      'date': date.toIso8601String(),
    };

    if (duedate != null) {
      data['duedate'] = duedate!.toIso8601String();
    }
    if (description != null) {
      data['description'] = description;
    }
    if (sharedWith != null) {
      data['sharedWith'] = sharedWith;
    }
    if (sharedBy != null) {
      data['sharedBy'] = sharedBy;
    }

    return data;
  }

  // Create a copy of this task with some fields changed
  Task copyWith({
    String? title,
    String? columnId,
    String? username,
    DateTime? date,
    DateTime? duedate,
    String? description,
    String? sharedWith,
    String? sharedBy,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      columnId: columnId ?? this.columnId,
      username: username ?? this.username,
      date: date ?? this.date,
      duedate: duedate ?? this.duedate,
      description: description ?? this.description,
      sharedWith: sharedWith ?? this.sharedWith,
      sharedBy: sharedBy ?? this.sharedBy,
    );
  }
}
