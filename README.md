# Chủ đề 04: Kiến trúc ứng dụng Flutter — Mô hình MVVM & Quản lý trạng thái tách biệt

Ứng dụng **Product Catalog** đọc danh sách sản phẩm từ REST API công khai [DummyJSON](https://dummyjson.com), xây dựng theo mô hình **MVVM** với luồng dữ liệu một chiều. Dự án được làm để minh họa cách tách biệt giao diện, logic xử lý và tầng gọi mạng trong Flutter.


---

## 1. Thông tin nhóm

| STT | Họ và tên | MSSV | Phụ trách |
|---|---|---|---|
| 1 | Phạm Viết Duy | 106230008 | Business Logic, State Management (ViewModel), soạn slide |
| 2 | Cao Minh Phụng | 106230023 | Database/API (Model, Service), UI Design (View), dàn ý slide |

Tỷ lệ đóng góp: 50% – 50%. Hai thành viên review chéo phần của nhau.

Trường Đại học Bách khoa, Khoa Điện tử và Trí tuệ nhân tạo.

## 2. Yêu cầu của đề

**Nội dung:**

- Cấu trúc MVVM: phân tách rõ ràng giữa **Model** (dữ liệu và parse JSON), **View** (giao diện người dùng) và **ViewModel** (logic nghiệp vụ và quản lý trạng thái).
- Luồng dữ liệu một chiều (Unidirectional Data Flow): người dùng tương tác → ViewModel xử lý → View cập nhật trạng thái.
- Tách biệt tầng dịch vụ mạng (Network Service): đóng gói tác vụ gọi REST API (`http`) độc lập, không phụ thuộc vào widget.
- Cơ chế liên kết View – ViewModel và cập nhật giao diện bằng `ChangeNotifier` / `ListenableBuilder`.

**Yêu cầu demo:**

- Ứng dụng đọc dữ liệu từ REST API theo đúng cấu trúc MVVM (tách các thư mục `models/`, `services/`, `viewmodels/`, `views/`).
- Giao diện xử lý và phản hồi trực quan 3 trạng thái: **Đang tải (Loading)**, **Thành công (Success)** và **Báo lỗi kèm nút Thử lại (Error & Retry)**.
- Chứng minh tầng View không chứa code gọi mạng trực tiếp hay giải mã JSON thô; View chỉ lắng nghe và hiển thị trạng thái từ ViewModel.

## 3. Tính năng

- Tải danh sách 20 sản phẩm từ DummyJSON (tên, giá, ảnh, danh mục, đánh giá).
- Tìm kiếm sản phẩm theo tên (không phân biệt hoa thường, bỏ khoảng trắng thừa).
- Xem chi tiết sản phẩm bằng bottom sheet.
- Hiển thị 3 trạng thái: Loading, Success, Error kèm nút **Thử lại**.

## 4. Kiến trúc MVVM

```
┌────────┐  sự kiện   ┌─────────────┐   gọi    ┌──────────┐   tạo    ┌────────┐
│  View  │ ─────────► │  ViewModel  │ ───────► │ Service  │ ───────► │ Model  │
│        │ ◄───────── │ (state)     │          │ (http)   │          │ (JSON) │
└────────┘   state    └─────────────┘          └──────────┘          └────────┘
         notifyListeners()
```

| Thành phần | Thư mục | Vai trò |
|---|---|---|
| **Model** | `lib/models/` | Lớp dữ liệu thuần `Product`, có `fromJson` để giải mã JSON. Không import widget, không gọi mạng. |
| **Service** | `lib/services/` | `ProductService` đóng gói việc gọi REST API bằng `http`, giải mã JSON thành danh sách `Product`, đổi lỗi kỹ thuật thành `ServiceException` có thông báo dễ hiểu. |
| **ViewModel** | `lib/viewmodels/` | `ProductViewModel extends ChangeNotifier`: giữ trạng thái (`ViewState`), gọi Service, xử lý tìm kiếm, gọi `notifyListeners()` khi trạng thái đổi. Không import widget. |
| **View** | `lib/views/` | `ProductView` lắng nghe ViewModel bằng `ListenableBuilder` và vẽ giao diện theo trạng thái. Không gọi mạng, không giải mã JSON. |

### Luồng dữ liệu một chiều

1. Người dùng mở màn hình hoặc bấm **Thử lại** → View gọi `viewModel.fetchProducts()`.
2. ViewModel đặt trạng thái `loading`, gọi `notifyListeners()`.
3. ViewModel gọi `ProductService.fetchProducts()`; Service gọi API, giải mã JSON bằng `Product.fromJson`.
4. ViewModel nhận danh sách (hoặc lỗi), đặt trạng thái `success` (hoặc `error`) rồi gọi `notifyListeners()`.
5. `ListenableBuilder` trong View tự build lại theo trạng thái mới.

Sự kiện đi **lên** (View → ViewModel), trạng thái đi **xuống** (ViewModel → View). View không tự sửa dữ liệu.

### Liên kết View – ViewModel

```dart
// ViewModel: phát tín hiệu khi trạng thái đổi
class ProductViewModel extends ChangeNotifier {
  ViewState _state = ViewState.loading;
  // ... đổi state xong thì gọi notifyListeners();
}

// View: lắng nghe và vẽ lại
ListenableBuilder(
  listenable: viewModel,
  builder: (context, _) => switch (viewModel.state) {
    ViewState.loading => const CircularProgressIndicator(),
    ViewState.error => _ErrorView(onRetry: viewModel.fetchProducts),
    ViewState.success => _ProductList(products: viewModel.products),
  },
)
```

Cách khác (không dùng trong dự án này): `Provider` với `ChangeNotifierProvider`.

### Khởi tạo và liên kết phụ thuộc

Trong `main.dart`, các lớp được lắp bằng constructor, không dùng thư viện DI:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = ProductViewModel(ProductService());
  runApp(MyApp(viewModel: viewModel));
}
```

Chỉ `main.dart` biết cả Service, ViewModel và View. View chỉ biết ViewModel, ViewModel chỉ biết Service.

## 5. Cấu trúc thư mục

```
lib/
├── main.dart
├── models/
│   └── product.dart
├── services/
│   └── product_service.dart
├── viewmodels/
│   └── product_viewmodel.dart
└── views/
    └── product_view.dart
test/
└── viewmodels/
    └── product_viewmodel_test.dart
```

## 6. Ba trạng thái của giao diện

| Trạng thái | ViewModel | View hiển thị |
|---|---|---|
| **Loading** | `ViewState.loading` | Vòng quay `CircularProgressIndicator` |
| **Success** | `ViewState.success`, có danh sách `products` | Danh sách sản phẩm (`ListView`); không có kết quả thì hiện "Không tìm thấy sản phẩm phù hợp" |
| **Error & Retry** | `ViewState.error`, có `errorMessage` | Biểu tượng lỗi, thông báo và nút **Thử lại** (gọi lại `fetchProducts()`) |

## 7. Chứng minh View không gọi mạng và không giải mã JSON

1. **Kiểm tra mã nguồn:** tìm các từ khóa `http`, `jsonDecode`, `dart:convert` trong thư mục `lib/views/` — kết quả phải rỗng.

   ```powershell
   Select-String -Path lib\views\*.dart -Pattern "http|jsonDecode|dart:convert"
   ```

   Trong VS Code: `Ctrl+Shift+F`, tìm `http` và `jsonDecode`, giới hạn trong `lib/views`.

2. **Kiểm tra bằng unit test:** `ProductViewModel` chạy được với một Service giả (`mocktail`), không cần Internet và không cần giao diện, chứng tỏ logic và trạng thái nằm ở ViewModel.

## 8. Unit test

File: `test/viewmodels/product_viewmodel_test.dart`, dùng `mocktail` để tạo `MockProductService`.

| Trường hợp | Kết quả mong đợi |
|---|---|
| Service trả danh sách | Chuỗi trạng thái `loading → success`, có dữ liệu |
| Service ném `ServiceException` | Chuỗi trạng thái `loading → error`, giữ nguyên thông báo lỗi |
| Tìm kiếm với chuỗi có khoảng trắng và chữ hoa | Lọc đúng sản phẩm, không phân biệt hoa thường |


## 9. Hướng dẫn chạy

Yêu cầu: Flutter SDK (Dart `>=3.2.0`), có kết nối Internet.

```bash
git clone <đường-dẫn-repo>
cd <thư-mục-dự-án>
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Có thể chạy trên Android hoặc Windows nếu máy đã cài môi trường tương ứng (`flutter devices` để xem thiết bị).

Để thử trạng thái lỗi: tắt mạng rồi mở lại app, màn hình báo lỗi kèm nút **Thử lại**; bật mạng và bấm **Thử lại** thì danh sách tải được.

## 10. Công nghệ sử dụng

| Thư viện | Phiên bản | Vai trò |
|---|---|---|
| `flutter` | SDK | Framework giao diện |
| `http` | ^1.2.0 | Gọi REST API trong `ProductService` |
| `mocktail` | ^1.0.3 | Tạo Service giả khi test |
| `flutter_lints` | ^3.0.0 | Quy tắc phân tích tĩnh |

`ChangeNotifier` và `ListenableBuilder` có sẵn trong Flutter nên không cần thư viện quản lý state bên ngoài.

Nguồn dữ liệu: `GET https://dummyjson.com/products?limit=20`.

## 11. Hạn chế và hướng phát triển

**Hạn chế:**

- ViewModel và Service được tạo thủ công trong `main.dart`, chưa có cơ chế Dependency Injection.
- Trạng thái trong ViewModel là các biến có thể thay đổi (chưa bất biến), `ChangeNotifier` thông báo toàn bộ người nghe mỗi lần đổi.
- Xử lý lỗi còn đơn giản (một thông báo văn bản); test chưa bao phủ Service và Model.
- Chưa có phân trang, cache hoặc chế độ ngoại tuyến.

**Hướng phát triển:**

- Thêm lớp Repository giữa ViewModel và Service để thay đổi nguồn dữ liệu dễ hơn.
- Dùng `Provider` hoặc `Riverpod` để cấp ViewModel cho cây widget.
- Thêm phân trang, cache cục bộ và test cho `ProductService`, `Product.fromJson`.


## 12. Phân công công việc (WBS)

| Vai trò | Người phụ trách | File chính |
|---|---|---|
| Business Logic, State Management | Phạm Viết Duy | `viewmodels/product_viewmodel.dart`, `test/viewmodels/` |
| Database/API | Cao Minh Phụng | `models/product.dart`, `services/product_service.dart` |
| UI Design | Cao Minh Phụng | `views/product_view.dart` |
| Báo cáo, slide | Cả hai (Duy soạn slide, Phụng dàn ý) | `README.md`, file slide |
| Tích hợp | Cả hai | `main.dart`, `pubspec.yaml`, chạy `flutter analyze` và `flutter test` |


## 13. Tài liệu tham khảo

- Flutter, *Architecting Flutter apps* — https://docs.flutter.dev/app-architecture
- Flutter, *Simple app state management* — https://docs.flutter.dev/data-and-backend/state-mgmt/simple
- Flutter API: `ChangeNotifier`, `ListenableBuilder` — https://api.flutter.dev
- Gói `http` — https://pub.dev/packages/http
- Gói `mocktail` — https://pub.dev/packages/mocktail
- DummyJSON (REST API dữ liệu mẫu) — https://dummyjson.com
