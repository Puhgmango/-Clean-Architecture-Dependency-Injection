import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
    required super.category,
    required super.price,
    required super.rating,
    required super.thumbnail,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: (json['title'] ?? 'Không có tiêu đề') as String,
      body: (json['description'] ?? '') as String,
      category: (json['category'] ?? 'general') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      thumbnail: (json['thumbnail'] ?? '') as String,
    );
  }
}
