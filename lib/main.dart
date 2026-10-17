import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/posts/presentation/cubit/post_cubit.dart';
import 'features/posts/presentation/pages/post_page.dart';

Future<void> main() async {
  // Bắt buộc gọi trước khi khởi tạo các phụ thuộc bất đồng bộ trước runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo toàn bộ Dependency Graph
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Lấy PostCubit từ Service Locator (get_it) và gọi sự kiện tải dữ liệu ngay
        BlocProvider<PostCubit>(
          create: (_) => sl<PostCubit>()..loadPosts(),
        ),
      ],
      child: MaterialApp(
        title: 'Clean Architecture Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const PostPage(),
      ),
    );
  }
}
