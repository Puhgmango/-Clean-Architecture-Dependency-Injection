# Kiến trúc ứng dụng Flutter: Clean Architecture \& Dependency Injection

## 1\. Giới thiệu

Dự án xây dựng một ứng dụng Flutter đọc dữ liệu từ REST API (`\\\[ĐIỀN: tên API và đường dẫn, ví dụ JSONPlaceholder /posts]`) theo kiến trúc 3 lớp rõ ràng. Mục tiêu không phải là nhiều tính năng mà là **chứng minh được kiến trúc**:

1. Chia ứng dụng thành 3 lớp: **Presentation / Domain / Data**.
2. Áp dụng **Dependency Inversion Principle**: các lớp phụ thuộc vào interface, không phụ thuộc vào cài đặt cụ thể.
3. Dùng **Dependency Injection** (`get\\\_it` + `injectable`) để lắp các lớp lại với nhau.
4. **Unit test tầng Domain** với dependency được mock (abstract interface).
5. Chứng minh tầng **Presentation không phụ thuộc trực tiếp Data Source**.

## 2\. Vì sao cần Clean Architecture

Nếu viết gọi API, parse JSON và xử lý logic ngay trong Widget thì:

* Khó test, vì muốn kiểm tra một hàm phải chạy cả giao diện và mạng.
* Khó thay đổi, vì đổi nguồn dữ liệu phải sửa khắp các màn hình.
* Khó làm việc nhóm, vì nhiều người cùng sửa một file.

Clean Architecture tách trách nhiệm để mỗi lớp chỉ làm một việc và thay đổi ở lớp này không phá lớp kia.

## 3\. Ba lớp của ứng dụng

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

|Lớp|Vai trò|Thư mục|
|-|-|-|
|**Presentation**|Hiển thị giao diện, giữ trạng thái màn hình (Loading, Loaded, Error), gọi UseCase|`lib/features/posts/presentation/`|
|**Domain**|Luật nghiệp vụ. Dart thuần, không phụ thuộc Flutter hay thư viện ngoài|`lib/features/posts/domain/`|
|**Data**|Lấy dữ liệu thật: gọi API, parse JSON, cài đặt Repository|`lib/features/posts/data/`|

### Quy tắc phụ thuộc (Dependency Rule)

> Code ở lớp trong không được biết gì về lớp ngoài. Domain \\\*\\\*không\\\*\\\* import Flutter, `http`, hay bất kỳ file nào trong `data/` và `presentation/`.

## 4\. Dependency Inversion Principle (DIP)

Nguyên lý D trong SOLID: *module cấp cao không nên phụ thuộc module cấp thấp; cả hai nên phụ thuộc vào abstraction.*

Áp dụng trong dự án:

```
GetPostsUsecase ──► PostRepository (interface, nằm ở Domain) ◄── PostRepositoryImpl ──► API
```

* `PostRepository` là **abstract class** định nghĩa ở Domain, mô tả "cần lấy dữ liệu gì".
* `PostRepositoryImpl` ở lớp Data **cài đặt** interface đó, quyết định "lấy bằng cách nào".
* `GetPostsUsecase` chỉ biết interface, không biết `PostRepositoryImpl` hay API tồn tại.

Nhờ vậy, khi đổi nguồn dữ liệu (REST sang GraphQL, thêm cache local), chỉ cần sửa lớp Data; Domain và Presentation giữ nguyên.

## 5\. Chi tiết lớp Domain (phần của người A)

### 5.1 Entity: `domain/entities/post\\\_entity.dart`

Đối tượng nghiệp vụ thuần của ứng dụng (một bài viết). Chỉ chứa các trường nghiệp vụ, **không có `fromJson`** và không biết gì về định dạng API.

Các trường: `\\\[ĐIỀN: ví dụ id, title, body]`.

### 5.2 Repository interface: `domain/repositories/post\\\_repository.dart`

Abstract class, "bản hợp đồng" giữa Domain và Data.

```dart
// Ví dụ minh họa, đối chiếu với file thật của nhóm
abstract class PostRepository {
  Future<...> getPosts();   // \\\[ĐIỀN: kiểu trả về thực tế, ví dụ Either<Failure, List<PostEntity>>]
}
```

### 5.3 UseCase: `domain/usecases/get\\\_posts\\\_usecase.dart`

Một hành động nghiệp vụ: lấy danh sách bài viết.

* Nhận `PostRepository` qua constructor (constructor injection).
* Quy tắc nghiệp vụ: `\\\[ĐIỀN: ví dụ loại bỏ bài viết có tiêu đề rỗng, giới hạn số bài]`.
* Gọi được như một hàm nhờ `call()`.

### 5.4 Failure: `core/error/failures.dart`

Các loại lỗi ở mức nghiệp vụ (`\\\[ĐIỀN: ví dụ ServerFailure, NetworkFailure]`). Lớp trên chỉ thấy `Failure`, không thấy các exception kỹ thuật như `SocketException`.

## 6\. Luồng dữ liệu

```
Người dùng mở màn hình
   → PostPage
   → PostCubit.load()
   → GetPostsUsecase()
   → PostRepository            (interface, Domain)
   → PostRepositoryImpl        (được DI lắp vào, Data)
   → PostRemoteDataSource      (gọi REST API)
   → API
```

Dữ liệu quay ngược lại: API → Model → Entity → UseCase → Cubit (state mới) → giao diện cập nhật.

## 7\. Dependency Injection

* Công cụ: `get\\\_it` (service locator) và `injectable` (sinh code đăng ký từ annotation).
* File cấu hình: `lib/core/di/injection.dart`. File `injection.config.dart` được **sinh tự động**, không sửa tay.
* Sinh lại sau khi đổi annotation:

```bash
dart run build\\\_runner build --delete-conflicting-outputs
```

* Repository được đăng ký theo kiểu **interface** `PostRepository`, nên các lớp phía trên không biết bản cài đặt thật.
* Trong `main()`: `WidgetsFlutterBinding.ensureInitialized()` rồi `configureDependencies()` trước `runApp`. `MultiBlocProvider` lấy Cubit từ DI container.

## 8\. Unit test tầng Domain

File: `test/features/posts/domain/get\\\_posts\\\_usecase\\\_test.dart`

**Ý tưởng:** UseCase chỉ phụ thuộc interface `PostRepository`, nên trong test ta thay bản thật bằng một **mock** (`\\\[ĐIỀN: mocktail hoặc mockito]`). Test chạy trong mili-giây, không cần mạng, không cần Data layer.

Các trường hợp được kiểm tra (đối chiếu với file test thật):

|Trường hợp|Kết quả mong đợi|
|-|-|
|Repository trả danh sách|UseCase trả đúng danh sách `\\\[ĐIỀN nếu khác]`|
|Repository trả danh sách rỗng|UseCase trả danh sách rỗng|
|Repository báo lỗi|UseCase truyền lỗi lên đúng|
|Quy tắc nghiệp vụ `\\\[ĐIỀN]`|Dữ liệu được xử lý đúng quy tắc|
|Gọi repository|`verify` xác nhận gọi đúng 1 lần|

Chạy test:

```bash
flutter test test/features/posts/domain
```

## 9\. Chứng minh Presentation không phụ thuộc Data Source

1. **Kiểm tra import:** trong VS Code, bấm `Ctrl+Shift+F`, tìm `/data/` trong thư mục `lib/features/posts/presentation`. Kết quả phải **rỗng**.
2. **Kiểm tra bằng test:** `post\\\_cubit\\\_test.dart` mock `GetPostsUsecase` để test Cubit mà không cần bất kỳ lớp Data nào. Nếu Cubit phụ thuộc trực tiếp Data thì không làm được như vậy.
3. **Kiểm tra bằng DI:** chỉ `core/di/injection.dart` (composition root) biết cả ba lớp. Các lớp còn lại chỉ nhận dependency qua constructor.

## 10\. Cấu trúc thư mục

```
lib/
├── main.dart
├── core/
│   ├── di/            injection.dart, injection.config.dart
│   └── error/         failures.dart
└── features/posts/
    ├── data/          datasources/, models/, repositories/
    ├── domain/        entities/, repositories/, usecases/
    └── presentation/  cubit/, pages/
test/
└── features/posts/
    ├── domain/        get\\\_posts\\\_usecase\\\_test.dart
    └── presentation/  post\\\_cubit\\\_test.dart
```

## 11\. Phân công (phần người A)

|Nội dung|File|
|-|-|
|Entity, interface Repository, UseCase|`domain/entities/`, `domain/repositories/`, `domain/usecases/`|
|Failure|`core/error/failures.dart`|
|Unit test Domain|`test/features/posts/domain/get\\\_posts\\\_usecase\\\_test.dart`|
|Phần kiến trúc của README|file này|

Người thực hiện: `\\\[ĐIỀN: họ tên, MSSV]`

## 12\. Công cụ và tài liệu tham khảo

* Flutter, `get\\\_it`, `injectable`, `flutter\\\_bloc`, `mocktail`/`mockito`: `\\\[ĐIỀN: phiên bản trong pubspec.yaml]`
* Clean Architecture của Robert C. Martin; nguyên lý SOLID.
* Công cụ AI hỗ trợ: `\\\[ĐIỀN thật: dùng để làm gì, ví dụ giải thích khái niệm, tham khảo cấu trúc code; ghi theo đúng quy định của môn học]`

