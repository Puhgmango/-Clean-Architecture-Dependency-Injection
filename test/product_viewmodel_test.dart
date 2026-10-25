import 'package:cadi/models/product.dart';
import 'package:cadi/services/product_service.dart';
import 'package:cadi/viewmodels/product_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductService extends Mock implements ProductService {}

Product makeProduct(int id, String title) => Product(
      id: id,
      title: title,
      description: '',
      category: 'test',
      price: 1,
      rating: 4,
      thumbnail: '',
    );

void main() {
  late MockProductService service;
  late ProductViewModel vm;

  setUp(() {
    service = MockProductService();
    vm = ProductViewModel(service);
  });

  test('thành công: loading → success', () async {
    when(() => service.fetchProducts()).thenAnswer(
        (_) async => [makeProduct(1, 'Essence Mascara'), makeProduct(2, 'Red Lipstick')]);
    final states = <ViewState>[];
    vm.addListener(() => states.add(vm.state));

    await vm.fetchProducts();

    expect(states, [ViewState.loading, ViewState.success]);
    expect(vm.products.length, 2);
  });

  test('thất bại: loading → error và giữ thông báo lỗi', () async {
    when(() => service.fetchProducts())
        .thenAnswer((_) async => throw ServiceException('Không có mạng'));
    final states = <ViewState>[];
    vm.addListener(() => states.add(vm.state));

    await vm.fetchProducts();

    expect(states, [ViewState.loading, ViewState.error]);
    expect(vm.errorMessage, 'Không có mạng');
  });

  test('search không phân biệt hoa thường', () async {
    when(() => service.fetchProducts()).thenAnswer(
        (_) async => [makeProduct(1, 'Essence Mascara'), makeProduct(2, 'Red Lipstick')]);
    await vm.fetchProducts();

    vm.search('  MASCARA ');

    expect(vm.products.length, 1);
    expect(vm.products.first.title, 'Essence Mascara');
  });
}