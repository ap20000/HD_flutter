import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorSpecialty;
  final String title;
  final String content;
  final String? image;
  final String category;
  final DateTime createdAt;

  const Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorSpecialty,
    required this.title,
    required this.content,
    this.image,
    required this.category,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final profile = author['profile'] ?? {};
    final docDetails = author['doctorDetails'] ?? {};
    return Story(
      id: json['_id'] ?? '',
      authorId: author['_id'] ?? '',
      authorName: author['name'] ?? 'Doctor',
      authorAvatar: profile['avatar'],
      authorSpecialty: docDetails['speciality'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
      category: json['category'] ?? 'Health Tips',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        authorSpecialty,
        title,
        content,
        image,
        category,
        createdAt,
      ];
}

class GroupedStories extends Equatable {
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorSpecialty;
  final List<Story> stories;

  const GroupedStories({
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorSpecialty,
    required this.stories,
  });

  @override
  List<Object?> get props => [
        authorId,
        authorName,
        authorAvatar,
        authorSpecialty,
        stories,
      ];
}
