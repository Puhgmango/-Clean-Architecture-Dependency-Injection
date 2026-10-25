import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ServiceException implements Exception {
  final String message;
  ServiceException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  final http.Client _client;

  ProductService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _client
          .get(Uri.parse('https://dummyjson.com/products?limit=20'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ServiceException('Máy chủ trả về lỗi ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['products'] as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServiceException {
      rethrow;
    } on TimeoutException {
      throw ServiceException('Hết thời gian chờ, hãy thử lại');
    } on FormatException {
      throw ServiceException('Dữ liệu trả về không hợp lệ');
    } catch (_) {
      throw ServiceException('Không kết nối được mạng');
    }
  }
}
