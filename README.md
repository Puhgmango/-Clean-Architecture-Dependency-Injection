# Kiến trúc ứng dụng Flutter: Clean Architecture & Dependency Injection


---

## 1. Giới thiệu

Ứng dụng **Product Catalog** đọc danh sách sản phẩm từ REST API công khai **DummyJSON** (`GET https://dummyjson.com/products?limit=20`), hiển thị tên, giá, ảnh; có ô tìm kiếm và màn hình chi tiết khi bấm vào sản phẩm. Mỗi sản phẩm gồm `id`, `title`, `description`, `category`, `price`, `rating`, `thumbnail`.

Mục tiêu của dự án là **chứng minh kiến trúc**, không phải nhiều tính năng:

1. Chia ứng dụng thành 3 lớp: **Presentation / Domain / Data**.
2. Áp dụng **Dependency Inversion Principle**: lớp trên phụ thuộc interface, không phụ thuộc cài đặt cụ thể.
3. Dùng **Dependency Injection** bằng `get_it` để lắp các lớp lại với nhau.
4. **Unit test tầng Domain** với dependency được mock qua abstract interface.
5. Chứng minh **Presentation không phụ thuộc trực tiếp Data Source**.

## 2. Vì sao cần Clean Architecture

Nếu gọi API, parse JSON và xử lý logic ngay trong Widget thì khó test (phải chạy cả giao diện và mạng), khó đổi nguồn dữ liệu (phải sửa nhiều màn hình) và khó làm nhóm (nhiều người sửa chung một file). Clean Architecture tách trách nhiệm để mỗi lớp chỉ làm một việc.

## 3. Ba lớp của ứng dụng

```
┌──────────────────────────────────────────────┐
│  Presentation  (Widget, Cubit, State)        │
│   ┌──────────────────────────────────────┐   │
│   │  Data  (API, Model, Repository Impl) │   │
│   │   ┌──────────────────────────────┐   │   │
│   │   │  Domain (Entity, UseCase,    │   │   │
│   │   │   Repository interface)      │   │   │
│   │   └──────────────────────────────┘   │   │
│   └──────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
        Mũi tên phụ thuộc luôn chỉ vào Domain
```

| Lớp | Vai trò | Thư mục |
|---|---|---|
| **Presentation** | Hiển thị giao diện, giữ trạng thái (Initial, Loading, Loaded, Error), gọi UseCase | `lib/features/posts/presentation/` |
| **Domain** | Entity, UseCase và interface Repository. Dart thuần, không phụ thuộc Flutter hay `http` | `lib/features/posts/domain/` |
| **Data** | Gọi API, parse JSON, cài đặt Repository | `lib/features/posts/data/` |

**Dependency Rule:** code ở lớp trong không được biết gì về lớp ngoài. Domain không import Flutter, `http`, hay file nào trong `data/` và `presentation/`.

## 4. Dependency Inversion Principle (DIP)

Nguyên lý D trong SOLID: *module cấp cao không nên phụ thuộc module cấp thấp; cả hai nên phụ thuộc vào abstraction.*

```
GetPostsUseCase ──► PostRepository (interface, Domain) ◄── PostRepositoryImpl ──► PostRemoteDataSource ──► API
```

- `PostRepository` là `abstract interface class` đặt ở Domain, mô tả "cần lấy dữ liệu gì".
- `PostRepositoryImpl` ở Data cài đặt interface đó, quyết định "lấy bằng cách nào".
- `GetPostsUseCase` chỉ biết interface, không biết `PostRepositoryImpl` hay API tồn tại.

Khi đổi nguồn dữ liệu (REST sang GraphQL, thêm cache), chỉ sửa lớp Data; Domain và Presentation giữ nguyên.

## 5. Chi tiết lớp Domain (phần của người A)

### 5.1 Entity: `domain/entities/post_entity.dart`

`PostEntity` là đối tượng nghiệp vụ thuần, kế thừa `Equatable` để so sánh theo giá trị. Các trường: `id`, `title`, `body`, `category`, `price`, `rating`, `thumbnail`. Entity **không có `fromJson`** và không biết gì về định dạng JSON của API (việc đó thuộc `PostModel` ở lớp Data).

### 5.2 Repository interface: `domain/repositories/post_repository.dart`

```dart
abstract interface class PostRepository {
  Future<List<PostEntity>> getPosts();
}
```

Đây là "bản hợp đồng" giữa Domain và Data. Lỗi được xử lý theo kiểu **ném exception** (không dùng `Either`).

### 5.3 UseCase: `domain/usecases/get_posts_usecase.dart`

`GetPostsUseCase` là một hành động nghiệp vụ: lấy danh sách sản phẩm.

- Nhận `PostRepository` qua constructor (constructor injection), nên thay bằng mock được khi test.
- Gọi được như một hàm nhờ `call()`.
- **Hiện tại UseCase chỉ đóng vai trò điều phối:** gọi Repository và trả kết quả, chưa có luật nghiệp vụ riêng (lọc, sắp xếp, kiểm tra). Lý do: ứng dụng là bản minh họa kiến trúc với logic đơn giản. Đây là một hạn chế đã biết, xem mục 13.

### 5.4 Failure và xử lý lỗi

- `core/error/failures.dart` định nghĩa `Failure` (kế thừa `Equatable`, có `message`) và `ServerFailure`.
- `PostRemoteDataSourceImpl` ném `ServerFailure` khi API trả mã khác 200.
- `PostCubit` bắt lỗi theo hai nhánh: `on Failure catch (f)` hiển thị `f.message`; mọi lỗi khác hiển thị thông báo chung "Đã xảy ra lỗi không xác định". Nhờ vậy giao diện không hiện thông điệp kỹ thuật thô.

## 6. Luồng dữ liệu

```
Người dùng mở màn hình
   → PostPage
   → PostCubit.loadPosts()
   → GetPostsUseCase()
   → PostRepository            (interface, Domain)
   → PostRepositoryImpl        (được DI lắp vào, Data)
   → PostRemoteDataSource      (gọi REST API DummyJSON)
   → API
```

Dữ liệu quay ngược lại: API → `PostModel` → `PostEntity` → UseCase → Cubit phát `PostLoaded` → giao diện cập nhật. Nếu lỗi, Cubit phát `PostError` với thông báo tương ứng.

## 7. Dependency Injection

- Công cụ: **get_it** (service locator, biến toàn cục `sl`), đăng ký **thủ công**.
- File cấu hình: `lib/core/di/injection.dart`, hàm `configureDependencies()` đăng ký theo thứ tự từ ngoài vào trong:
  1. `http.Client` (lazy singleton)
  2. `PostRemoteDataSource` → `PostRemoteDataSourceImpl`
  3. `PostRepository` → `PostRepositoryImpl` (đăng ký theo kiểu **interface**)
  4. `GetPostsUseCase`
  5. `PostCubit` bằng `registerFactory` (mỗi màn hình một instance mới)
- `main()` gọi `WidgetsFlutterBinding.ensureInitialized()` rồi `await configureDependencies()` trước `runApp`. `MultiBlocProvider` lấy `PostCubit` từ `sl`.
- Chỉ `injection.dart` (composition root) biết cả ba lớp; các lớp còn lại nhận dependency qua constructor.
- **Về `injectable`:** thư viện `injectable`, `injectable_generator`, `build_runner` có trong `pubspec.yaml` và file `injection.dart` còn khai báo một `@module`, nhưng nhóm **không dùng để sinh code** (file `injection.config.dart` đang rỗng). DI thực tế chạy hoàn toàn bằng đăng ký thủ công ở trên. Xem mục 13 và 14.

## 8. Unit test

**Tầng Domain:** `test/features/posts/domain/get_posts_usecase_test.dart`

UseCase chỉ phụ thuộc interface `PostRepository`, nên trong test thay bản thật bằng `MockPostRepository` (`mocktail`). Test chạy trong mili-giây, không cần mạng, không cần Data layer.

| Trường hợp | Trạng thái |
|---|---|
| Repository trả danh sách, UseCase trả đúng danh sách; `verify` gọi đúng 1 lần, `verifyNoMoreInteractions` | Đã có |
| Danh sách rỗng, repository ném lỗi | Chưa có (xem mục 14) |

**Tầng Presentation:** `test/features/posts/presentation/post_cubit_test.dart`

Dùng `bloc_test` và `MockGetPostsUseCase` để kiểm tra Cubit phát ra chuỗi `[PostLoading, PostLoaded]` khi tải thành công. Chưa có test cho nhánh lỗi.

**Tầng Data:** chưa có test.

Chạy test:

```bash
flutter test
flutter test test/features/posts/domain
```

## 9. Chứng minh Presentation không phụ thuộc Data Source

1. **Kiểm tra import:** trong VS Code, `Ctrl+Shift+F`, tìm `data/` trong thư mục `lib/features/posts/presentation`. Kết quả phải rỗng. Presentation chỉ import `domain/entities`, `domain/usecases`, `core/error/failures.dart` và các file cùng lớp.
2. **Kiểm tra bằng test:** `post_cubit_test.dart` tạo `PostCubit` với `MockGetPostsUseCase`, không cần bất kỳ lớp Data nào. Nếu Cubit phụ thuộc trực tiếp Data thì không làm được như vậy.
3. **Kiểm tra bằng DI:** chỉ `core/di/injection.dart` import cả ba lớp; Cubit nhận `GetPostsUseCase` qua constructor.

## 10. Cấu trúc thư mục

```
lib/
├── main.dart
├── core/
│   ├── di/            injection.dart
│   └── error/         failures.dart
└── features/posts/
    ├── data/          datasources/, models/, repositories/
    ├── domain/        entities/, repositories/, usecases/
    └── presentation/  cubit/, pages/
test/
└── features/posts/
    ├── domain/        get_posts_usecase_test.dart
    └── presentation/  post_cubit_test.dart
```

## 11. Bảng phân công (phần người A)

Nhóm gồm 2 sinh viên. Tóm tắt theo vai trò:

| Vai trò | Người phụ trách | Nội dung chính | File chính |
|---|---|---|---|
| **Logic** | Phạm Viết Duy | Entity, interface Repository, UseCase, Failure, unit test Domain bằng mock | `domain/`, `core/error/failures.dart`, `test/.../domain/` |
| **State Management** | Phạm Viết Duy | `PostState`, `PostCubit` (chỉ gọi UseCase), test Cubit bằng `bloc_test` | `presentation/cubit/`, `test/.../presentation/` |
| **Database/API** | Cao Minh Phụng | Kết nối REST API DummyJSON, `PostModel`, DataSource, `PostRepositoryImpl`, test Data | `data/`, `test/.../data/` |
| **UI Design** | Cao Minh Phụng | Màn hình danh sách, tìm kiếm, chi tiết sản phẩm, trạng thái loading/lỗi | `presentation/pages/post_page.dart` |
| **Báo cáo** | Phạm Viết Duy (kiến trúc, hạn chế) / Cao Minh Phụng (hướng dẫn chạy) | README và báo cáo | `README.md` |
| **Slide** | Cao Minh Phụng (dàn ý) / Phạm Viết Duy (soạn slide) | Slide thuyết trình 8-10 trang | file `.pptx` |
| **Tích hợp (chung)** | Phạm Viết Duy + Cao Minh Phụng | DI bằng get_it, `main.dart`, chạy `flutter analyze` và `flutter test` | `core/di/injection.dart`, `lib/main.dart` |


## 12. Công cụ và tài liệu tham khảo

| Thư viện | Phiên bản | Vai trò |
|---|---|---|
| `http` | ^1.2.0 | Gọi REST API |
| `flutter_bloc` | ^8.1.4 | Quản lý state bằng Cubit |
| `equatable` | ^2.0.5 | So sánh object (Entity, State) |
| `get_it` | ^7.6.7 | Service locator cho DI |
| `mocktail` | ^1.0.3 | Tạo mock để unit test |
| `bloc_test` | ^9.1.6 | Test Cubit |
| `injectable`, `injectable_generator`, `build_runner` | ^2.3.5, ^2.4.2, ^2.4.8 | Có khai báo nhưng chưa dùng để sinh code (xem mục 7) |

- Clean Architecture của Robert C. Martin; nguyên lý SOLID.

## 13. Hạn chế của dự án

Nhóm nhận thấy các hạn chế sau trong phiên bản hiện tại:

1. **UseCase chưa có luật nghiệp vụ riêng.** `GetPostsUseCase` chỉ chuyển tiếp lời gọi tới Repository. Phần lớn giá trị của UseCase (gom logic, tái sử dụng, test) chưa được thể hiện.
2. **Tìm kiếm nằm ở lớp Presentation.** Việc lọc theo từ khóa được thực hiện trong `PostPage` (lưu từ khóa bằng `setState` rồi lọc danh sách ngay trong Widget). Đây là logic về dữ liệu nên đúng ra thuộc Domain để có thể test độc lập.
3. **Xử lý lỗi chưa đầy đủ.** Chỉ có `ServerFailure` cho mã trạng thái khác 200. Các lỗi như mất mạng, hết thời gian chờ, JSON sai định dạng chưa được Repository đổi thành `Failure` mà chỉ rơi vào thông báo chung ở Cubit. Lời gọi API cũng chưa đặt timeout.
4. **Cấu hình `injectable` còn dư.** Thư viện có trong `pubspec.yaml` và còn một `@module` nhưng không dùng để sinh code; `injection.config.dart` rỗng. DI chạy bằng đăng ký thủ công.
5. **Test còn ít.** Mới có một test cho Domain và một cho Cubit (chỉ trường hợp thành công). Chưa có test cho danh sách rỗng, trường hợp lỗi, `PostModel.fromJson`, `PostRepositoryImpl`; chưa có widget test.
6. **Đặt tên chưa khớp nội dung.** Thư mục và class dùng tên `Post...` trong khi dữ liệu là sản phẩm.
7. **Model kế thừa Entity** (`PostModel extends PostEntity`). Cách này gọn nhưng làm Data và Domain gắn chặt hơn so với việc tách riêng Model và ánh xạ sang Entity.
8. **Giá trị mặc định có thể gây hiểu nhầm.** Khi API không trả `rating`, `PostModel` gán mặc định `5.0`, khiến sản phẩm chưa có đánh giá hiển thị như điểm tối đa.
9. **Phạm vi chức năng nhỏ.** Chỉ có một feature, một UseCase, tải 20 sản phẩm một lần, chưa phân trang, chưa lưu cache hay hỗ trợ ngoại tuyến.
10. **Dùng service locator.** `get_it` là service locator nên dependency được lấy từ biến toàn cục `sl`; việc kiểm soát phụ thuộc phụ thuộc vào kỷ luật của lập trình viên (chỉ dùng `sl` ở composition root và `main.dart`).

## 14. Hướng phát triển

Theo thứ tự ưu tiên:

1. **Thêm luật nghiệp vụ vào Domain.** Ví dụ loại sản phẩm có tên rỗng hoặc giá âm trong `GetPostsUseCase`; tạo `SearchPostsUseCase` thuần (bỏ khoảng trắng, không phân biệt hoa thường) và để Cubit gọi nó, thay cho việc lọc trong Widget.
2. **Hoàn thiện xử lý lỗi.** Thêm `NetworkFailure`, đặt timeout cho lời gọi API, để `PostRepositoryImpl` bắt exception kỹ thuật và đổi thành `Failure`. Có thể dùng `Either<Failure, T>` để lỗi trở thành một phần của kiểu dữ liệu.
3. **Bổ sung test.** Danh sách rỗng, repository lỗi, từng luật nghiệp vụ, nhánh lỗi của Cubit, test `PostModel` và `PostRepositoryImpl`, widget test cho `PostPage`.
4. **Chốt hướng DI.** Hoặc dọn bỏ phần `injectable` còn dư (giữ Domain thuần Dart), hoặc dùng `injectable` thật với `@InjectableInit` và `build_runner`; có thể thay bằng Riverpod, nơi DI và state dùng chung một cơ chế và dễ override khi test.
5. **Đổi tên theo đúng nội dung** (`Product...`, thư mục `products`) và tách Model khỏi Entity bằng phương thức `toEntity()`.
6. **Mở rộng tính năng.** Thêm UseCase lấy chi tiết sản phẩm, phân trang, lọc theo danh mục; thêm `LocalDataSource` (cache) để Repository điều phối giữa mạng và bộ nhớ cục bộ, hỗ trợ ngoại tuyến.
7. **Tự động hóa chất lượng.** Cài `flutter_lints` để phân tích tĩnh, thiết lập CI (ví dụ GitHub Actions) chạy `flutter analyze` và `flutter test` mỗi lần đẩy code.
