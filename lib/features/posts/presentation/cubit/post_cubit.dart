import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  final GetPostsUseCase _getPostsUseCase;
  List<PostEntity> _allPosts = const [];

  PostCubit(this._getPostsUseCase,)
      : super(PostInitial());

  Future<void> loadPosts() async {
    emit(PostLoading());
    try {
      _allPosts = await _getPostsUseCase();
      emit(PostLoaded(_allPosts));
    } on Failure catch (f) {
      emit(PostError(f.message));
    } catch (_) {
      emit(const PostError('Đã xảy ra lỗi không xác định'));
    }
  }
}