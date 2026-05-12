class Subtask {
  final String id;
  final String title;
  final String status;
  final String username;
  final DateTime date;
  final DateTime? duedate;
  final String? description;
  final String? goal;
  final String? techstack;

  const Subtask({
    required this.id,
    required this.title,
    required this.status,
    this.username = '',
    required this.date,
    this.duedate,
    this.description,
    this.goal,
    this.techstack,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'].toString(),
        title: json['title'] as String,
        status: json['status'] as String,
        username: json['username'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        duedate: json['duedate'] != null
            ? DateTime.parse(json['duedate'] as String)
            : null,
        description: json['description'] as String?,
        goal: json['goal'] as String?,
        techstack: json['techstack'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'username': username,
        'date': date.toIso8601String(),
        if (duedate != null) 'duedate': duedate!.toIso8601String(),
        if (description != null) 'description': description,
        if (goal != null) 'goal': goal,
        if (techstack != null) 'techstack': techstack,
      };

  Subtask copyWith({String? status}) => Subtask(
        id: id,
        title: title,
        status: status ?? this.status,
        username: username,
        date: date,
        duedate: duedate,
        description: description,
        goal: goal,
        techstack: techstack,
      );
}
