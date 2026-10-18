import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostsUseCase {
  final PostRepository _repository;

  const GetPostsUseCase(this._repository);

  Future<List<PostEntity>> call() async {
    return await _repository.getPosts();
  }
}
