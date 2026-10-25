import 'package:flutter/material.dart';

import 'services/product_service.dart';
import 'viewmodels/product_viewmodel.dart';
import 'views/product_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = ProductViewModel(ProductService());
  runApp(MyApp(viewModel: viewModel));
}

class MyApp extends StatelessWidget {
  final ProductViewModel viewModel;

  const MyApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: ProductView(viewModel: viewModel),
    );
  }
}