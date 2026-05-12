class Task {
  final String id;
  final String title;
  final String status;

  const Task({required this.id, required this.title, required this.status});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'].toString(),
        title: json['title'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
      };

  Task copyWith({String? status}) =>
      Task(id: id, title: title, status: status ?? this.status);
}
