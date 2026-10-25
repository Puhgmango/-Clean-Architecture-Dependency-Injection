import 'package:flutter/material.dart';

import '../models/product.dart';
import '../viewmodels/product_viewmodel.dart';

class ProductView extends StatefulWidget {
  final ProductViewModel viewModel;

  const ProductView({super.key, required this.viewModel});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog • MVVM')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: vm.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm kiếm sản phẩm...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: vm,
              builder: (context, _) => switch (vm.state) {
                ViewState.loading =>
                  const Center(child: CircularProgressIndicator()),
                ViewState.error => _ErrorView(
                    message: vm.errorMessage,
                    onRetry: vm.fetchProducts,
                  ),
                ViewState.success => _ProductList(products: vm.products),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;

  const _ProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm phù hợp'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return ListTile(
          leading: Image.network(
            p.thumbnail,
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
          title: Text(p.title),
          subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
          onTap: () => _showDetail(context, p),
        );
      },
    );
  }

  void _showDetail(BuildContext context, Product p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${p.category} • đánh giá ${p.rating}'),
            const SizedBox(height: 8),
            Text(p.description),
          ],
        ),
      ),
    );
  }
}