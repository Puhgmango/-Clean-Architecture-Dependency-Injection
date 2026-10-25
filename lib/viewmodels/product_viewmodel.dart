import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

enum ViewState { loading, success, error }

class ProductViewModel extends ChangeNotifier {
  final ProductService _service;

  ProductViewModel(this._service);

  ViewState _state = ViewState.loading;
  List<Product> _all = [];
  List<Product> _visible = [];
  String _errorMessage = '';
  String _query = '';
  bool _disposed = false;

  ViewState get state => _state;
  List<Product> get products => _visible;
  String get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _state = ViewState.loading;
    notifyListeners();
    try {
      _all = await _service.fetchProducts();
      _applyFilter();
      _state = ViewState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    }
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final keyword = _query.trim().toLowerCase();
    _visible = keyword.isEmpty
        ? _all
        : _all.where((p) => p.title.toLowerCase().contains(keyword)).toList();
  }

  // Tránh lỗi nếu View đã đóng mà request còn chạy
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}