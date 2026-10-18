import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  const PostRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PostEntity>> getPosts() async {
    return await remoteDataSource.fetchPostsFromApi();
  }
}
