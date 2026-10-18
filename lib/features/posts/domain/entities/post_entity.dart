import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final int id;
  final String title;
  final String body;
  final String category;
  final double price;
  final double rating;
  final String thumbnail;

  const PostEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.price,
    required this.rating,
    required this.thumbnail,
  });

  @override
  List<Object?> get props =>
      [id, title, body, category, price, rating, thumbnail];
}
