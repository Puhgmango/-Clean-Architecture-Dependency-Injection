import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cadi/features/posts/domain/entities/post_entity.dart';
import 'package:cadi/features/posts/domain/usecases/get_posts_usecase.dart';
import 'package:cadi/features/posts/presentation/cubit/post_cubit.dart';
import 'package:cadi/features/posts/presentation/cubit/post_state.dart';

class MockGetPostsUseCase extends Mock implements GetPostsUseCase {}

void main() {
  late PostCubit postCubit;
  late MockGetPostsUseCase mockGetPostsUseCase;

  setUp(() {
    mockGetPostsUseCase = MockGetPostsUseCase();
    postCubit = PostCubit(mockGetPostsUseCase);
  });

  tearDown(() => postCubit.close());

  const tPosts = [
    PostEntity(
      id: 1,
      title: 'MacBook Air M3',
      body: 'Laptop mỏng nhẹ hiệu năng cao',
      category: 'laptops',
      price: 1299.0,
      rating: 4.9,
      thumbnail: 'https://example.com/macbook.jpg',
    ),
  ];

  blocTest<PostCubit, PostState>(
    'Phát ra [PostLoading, PostLoaded] khi gọi loadPosts() thành công',
    build: () {
      when(() => mockGetPostsUseCase()).thenAnswer((_) async => tPosts);
      return postCubit;
    },
    act: (cubit) => cubit.loadPosts(),
    expect: () => [
      PostLoading(),
      const PostLoaded(tPosts),
    ],
    verify: (_) {
      verify(() => mockGetPostsUseCase()).called(1);
    },
  );
}
