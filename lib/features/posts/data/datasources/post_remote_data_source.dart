import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/failures.dart';
import '../models/post_model.dart';

abstract interface class PostRemoteDataSource {
  Future<List<PostModel>> fetchPostsFromApi();
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final http.Client client;

  const PostRemoteDataSourceImpl(this.client);

  @override
  Future<List<PostModel>> fetchPostsFromApi() async {
    // Gọi REST API thực tế trả về danh sách sản phẩm kèm ảnh, giá, đánh giá
    final response = await client.get(
      Uri.parse('https://dummyjson.com/products?limit=20'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedBody = json.decode(response.body);
      final List<dynamic> productsJson =
          decodedBody['products'] as List<dynamic>;

      return productsJson
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw const ServerFailure('Lỗi kết nối máy chủ REST API');
    }
  }
}
