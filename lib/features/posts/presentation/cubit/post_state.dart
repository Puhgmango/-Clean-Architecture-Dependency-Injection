import 'package:equatable/equatable.dart';
import '../../domain/entities/post_entity.dart';

sealed class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

final class PostInitial extends PostState {}

final class PostLoading extends PostState {}

final class PostLoaded extends PostState {
  final List<PostEntity> posts;
  const PostLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

final class PostError extends PostState {
  final String message;
  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}
