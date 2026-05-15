// A Task represents one card on the kanban board.
// All fields are "final" which means they can't be changed after creation.
// To update a task you use copyWith() to make a new copy with the changed values.
class Task {
  final String id;           // unique ID that Firestore gives each task
  final String title;        // the name of the task shown on the card
  final String columnId;     // which column this task lives in
  final String username;     // who the task is assigned to
  final DateTime date;       // when the task was created
  final DateTime? duedate;   // when the task must be done (optional, can be null)
  final String? description; // extra details about the task (optional)
  final String? sharedWith;  // if we sent this task to someone, their email goes here
  final String? sharedBy;    // if someone sent us this task, their email goes here
  final bool isCompleted;    // is this task done? true = yes, false = not yet

  // This is how we create a new Task object.
  // "required" means you MUST provide that value when creating a Task.
  // Fields without "required" are optional and have default values.
  const Task({
    required this.id,
    required this.title,
    required this.columnId,
    this.username = '',        // default is empty string if nobody is assigned
    required this.date,
    this.duedate,              // optional — no default needed
    this.description,
    this.sharedWith,
    this.sharedBy,
    this.isCompleted = false,  // new tasks start as not completed
  });

  // Firestore sends us data as a Map (like a dictionary/key-value pairs).
  // This factory constructor reads that Map and builds a proper Task object.
  // The word "factory" just means this is a special constructor that can do extra logic.
  factory Task.fromJson(Map<String, dynamic> json) {
    // Pull each field out of the map and convert it to the right type
    String id = json['id'].toString();
    String title = json['title'] as String;

    // Use empty string as fallback if the field is missing in Firestore
    String columnId = json['columnId'] as String? ?? '';
    String username = json['username'] as String? ?? '';

    // Dates are stored as text strings in Firestore, so we parse them back into DateTime
    DateTime date;
    if (json['date'] != null) {
      date = DateTime.parse(json['date'] as String);
    } else {
      // If somehow there's no date saved, just use right now
      date = DateTime.now();
    }

    // Due date is optional, so we only parse it if it's actually there
    DateTime? duedate;
    if (json['duedate'] != null) {
      duedate = DateTime.parse(json['duedate'] as String);
    }

    // These are all optional fields — they'll be null if not saved
    String? description = json['description'] as String?;
    String? sharedWith = json['sharedWith'] as String?;
    String? sharedBy = json['sharedBy'] as String?;

    // Old tasks saved before this feature existed won't have isCompleted,
    // so we treat them as not completed (false) if the field is missing
    bool isCompleted = false;
    if (json['isCompleted'] != null) {
      isCompleted = json['isCompleted'] as bool;
    }

    // Now build and return the Task object with all the values we read
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
      isCompleted: isCompleted,
    );
  }

  // Firestore needs data as a Map to save it.
  // This converts our Task object back into that Map format.
  Map<String, dynamic> toJson() {
    // Start with the fields every task always has
    Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'columnId': columnId,
      'username': username,
      'date': date.toIso8601String(), // converts DateTime to a text string
      'isCompleted': isCompleted,
    };

    // Only add optional fields if they actually have a value (not null)
    // This keeps our Firestore documents clean
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

  // Sentinel used by copyWith to distinguish "caller passed null intentionally"
  // from "caller didn't pass this field at all".
  static const Object _absent = Object();

  // Since all Task fields are final (can't be changed), we can't do task.title = "New".
  // Instead, copyWith makes a new Task that is identical except for the fields you specify.
  // Example: task.copyWith(title: "New Title") gives you a new Task with everything
  // the same but with a different title.
  //
  // For nullable fields like duedate, pass the value you want (including null to clear it).
  // Omitting the parameter keeps the existing value.
  Task copyWith({
    String? title,
    String? columnId,
    String? username,
    DateTime? date,
    Object? duedate = _absent,   // Object? so null can be passed intentionally
    String? description,
    String? sharedWith,
    String? sharedBy,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      columnId: columnId ?? this.columnId,
      username: username ?? this.username,
      date: date ?? this.date,
      // If the caller passed nothing, keep existing. If they passed null, clear it.
      duedate: duedate == _absent ? this.duedate : duedate as DateTime?,
      description: description ?? this.description,
      sharedWith: sharedWith ?? this.sharedWith,
      sharedBy: sharedBy ?? this.sharedBy,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
