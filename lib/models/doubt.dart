class Doubt {
  const Doubt({
    this.id,
    required this.imagePath,
    required this.title,
    required this.solution,
    required this.createdAt,
  });

  final int? id;
  final String imagePath;
  final String title;
  final String solution;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'image_path': imagePath,
        'title': title,
        'solution': solution,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Doubt.fromMap(Map<String, Object?> map) => Doubt(
        id: map['id'] as int?,
        imagePath: map['image_path'] as String,
        title: map['title'] as String,
        solution: map['solution'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
