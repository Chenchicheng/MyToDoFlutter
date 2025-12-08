class Todo {
  final int? id;
  final String title;
  final String? description;
  final String? date;
  final int completed;
  final String? createdAt;
  final String taskType;
  final String? period;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.date,
    this.completed = 0,
    this.createdAt,
    this.taskType = 'daily',
    this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'completed': completed,
      'created_at': createdAt,
      'task_type': taskType,
      'period': period,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: map['date'] as String?,
      completed: map['completed'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
      taskType: map['task_type'] as String? ?? 'daily',
      period: map['period'] as String?,
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    int? completed,
    String? createdAt,
    String? taskType,
    String? period,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      taskType: taskType ?? this.taskType,
      period: period ?? this.period,
    );
  }

  bool get isCompleted => completed == 1;
}

