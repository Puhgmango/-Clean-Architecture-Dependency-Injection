import '../entities/post_entity.dart';

abstract interface class PostRepository {
  Future<List<PostEntity>> getPosts();
}
