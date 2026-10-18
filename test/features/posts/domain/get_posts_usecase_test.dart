import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cadi/features/posts/domain/entities/post_entity.dart';
import 'package:cadi/features/posts/domain/repositories/post_repository.dart';
import 'package:cadi/features/posts/domain/usecases/get_posts_usecase.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late GetPostsUseCase useCase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    useCase = GetPostsUseCase(mockPostRepository);
  });

  const tPosts = [
    PostEntity(
      id: 1,
      title: 'iPhone 15 Pro',
      body: 'Điện thoại Apple dùng chip A17 Pro',
      category: 'smartphones',
      price: 999.0,
      rating: 4.8,
      thumbnail: 'https://example.com/iphone.jpg',
    ),
  ];

  test(
    'Nên trả về danh sách PostEntity từ PostRepository khi gọi GetPostsUseCase',
    () async {
      when(() => mockPostRepository.getPosts()).thenAnswer((_) async => tPosts);

      final result = await useCase();

      expect(result, equals(tPosts));
      verify(() => mockPostRepository.getPosts()).called(1);
      verifyNoMoreInteractions(mockPostRepository);
    },
  );
}
