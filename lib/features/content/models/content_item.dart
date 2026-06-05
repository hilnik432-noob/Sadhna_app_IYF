enum ContentType { gita, lecture, kirtan, book }

class ContentItem {
  final String id;
  final String title;
  final String subtitle;
  final ContentType type;
  final String thumbnailUrl;
  final String contentUrl;
  final String description;
  final int durationSeconds;

  const ContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.thumbnailUrl = '',
    required this.contentUrl,
    this.description = '',
    this.durationSeconds = 0,
  });

  String get typeLabel {
    switch (type) {
      case ContentType.gita: return 'Bhagavad Gita';
      case ContentType.lecture: return 'Lecture';
      case ContentType.kirtan: return 'Kirtan';
      case ContentType.book: return 'Book';
    }
  }

  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  factory ContentItem.fromMap(String id, Map<String, dynamic> map) {
    return ContentItem(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: ContentType.values.firstWhere((e) => e.name == map['type'], orElse: () => ContentType.lecture),
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      contentUrl: map['contentUrl'] ?? '',
      description: map['description'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}
