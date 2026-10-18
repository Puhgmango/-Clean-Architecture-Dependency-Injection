import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_cubit.dart';
import '../cubit/post_state.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Product Catalog',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại từ REST API',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => context.read<PostCubit>().loadPosts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm trực quan
          Container(
            color: Colors.indigo.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Danh sách dữ liệu lắng nghe từ PostCubit
          Expanded(
            child: BlocBuilder<PostCubit, PostState>(
              builder: (context, state) {
                return switch (state) {
                  PostInitial() || PostLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  PostError(:final message) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Lỗi tải dữ liệu: $message',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  PostLoaded(:final posts) => _buildProductList(context, posts),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<PostEntity> allPosts) {
    final filtered = allPosts.where((p) {
      return p.title.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm phù hợp.'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PostCubit>().loadPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showDetailSheet(
                  context, item), // Bấm vào mới hiện thông tin thêm
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Ảnh Thumbnail sản phẩm
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 65,
                        height: 65,
                        color: Colors.grey.shade100,
                        child: item.thumbnail.isNotEmpty
                            ? Image.network(
                                item.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey),
                              )
                            : const Icon(Icons.shopping_bag,
                                color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Chỉ hiển thị Tên sản phẩm và Giá tiền
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Hộp thoại hiển thị thông tin chi tiết khi người dùng bấm vào sản phẩm
  void _showDetailSheet(BuildContext context, PostEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.thumbnail,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  item.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              item.body,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Giá: \$${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
