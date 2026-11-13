# Product Store Viva Defense & Examination Guide

This guide is designed to help you answer any viva question about this project confidently. It explains the project architecture, logic, API integration, Flutter syntax, state management, and common exam questions.

---

## 📑 Quick Reference Summary

- **Project Title**: Product Store App
- **Language**: Dart (Flutter Framework)
- **API Used**: DummyJSON REST API (`https://dummyjson.com/products`)
- **State Management**: `Provider` (`ChangeNotifierProvider`, `ChangeNotifier`)
- **Local Persistence / Cache**: `Hive` (NoSQL key-value store)
- **Image Caching**: `cached_network_image`
- **Design System**: Material 3 (with responsive layout for mobile and tablet)

---

## 1. Project Architecture & Code Flow

### The 4 Layers (Clean Architecture & Separation of Concerns):
1. **Presentation Layer (`lib/presentation/`)**:
   - Contains UI widgets and screens (`SplashScreen`, `HomeScreen`, `DetailScreen`, `ProductFormScreen`, `ProductCard`, `MessageView`).
   - Does **not** know how data is fetched or saved. It only listens to the provider and renders UI.
2. **Provider Layer (`lib/providers/`)**:
   - `ProductProvider` and `ThemeProvider`.
   - Extends `ChangeNotifier`. Manages the list of products, current search query, active category filter, sort option, and pagination states.
   - Calls `notifyListeners()` when data changes so UI widgets listening to it automatically rebuild.
3. **Repository Layer (`lib/data/repository/`)**:
   - `ProductRepository`: Acts as the **single source of truth**.
   - Mediates between the Remote API (`RemoteDataSource`) and Local Database (`LocalDataSource`).
   - If internet is working: fetches from API and caches to Hive.
   - If offline or API fails: reads directly from Hive cache.
4. **Data Source Layer (`lib/data/datasource/`)**:
   - `RemoteDataSource`: Uses `http.Client` to perform network calls.
   - `LocalDataSource`: Uses `Hive` to store and retrieve JSON data on disk.

---

## 2. Step-by-Step Code Flow

### Question: "What happens when the app starts?"
1. `main()` in `lib/main.dart` is called:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Hive.initFlutter();
   ```
2. Hive initializes and opens two boxes: `products_box` (for cached items) and `meta_box` (for deleted IDs, favorites, and theme).
3. `ProductRepository` is instantiated and injected into `ProductProvider` using `MultiProvider`.
4. `MyApp` launches `SplashScreen`.
5. `SplashScreen` runs an animation for 2.2 seconds, then navigates to `HomeScreen` using `Navigator.pushReplacement`.
6. `HomeScreen.initState()` calls `context.read<ProductProvider>().loadFirstPage()`.
7. `loadFirstPage()` fetches from the API (or local cache if offline) and updates the UI via `notifyListeners()`.

---

## 3. How API Integration Works

### Question: "How does your app communicate with the public API?"
- Located in `lib/data/datasource/remote_datasource.dart`:
```dart
final url = Uri.parse('https://dummyjson.com/products?limit=20&skip=0');
final response = await http.get(url).timeout(const Duration(seconds: 15));
```
- **HTTP GET Request**: We use the `http` package to send an HTTP GET request.
- **Timeout Handling**: We set a 15-second timeout using `.timeout(...)` to prevent the app from hanging on slow networks.
- **Status Code Verification**: If `response.statusCode == 200`, the call was successful.
- **JSON Decoding**: `jsonDecode(response.body)` converts the raw JSON string into a Dart `Map<String, dynamic>`.
- **Model Conversion**: `Product.fromJson(item)` converts each JSON object in the `products` list into a strongly-typed Dart `Product` instance.

---

## 4. How JSON Parsing Works

### Question: "Explain the `Product.fromJson` factory constructor."
- Located in `lib/data/model/product.dart`:
```dart
factory Product.fromJson(Map<String, dynamic> json) {
  return Product(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: (json['title'] ?? '') as String,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    ...
  );
}
```
- A **factory constructor** returns a new instance of the class created from the input map.
- We use `(json['price'] as num?)?.toDouble() ?? 0.0` instead of a direct cast because the API might send `price` as an integer (`10`) or a floating point number (`10.99`). Casting to `num` safely handles both and prevents runtime type errors.

---

## 5. How State Management Works (Provider)

### Question: "Why did you choose Provider and how does it work?"
- **Why Provider?**
  - Officially recommended by Flutter team, clean, simple, and follows the Observer pattern.
- **Key Concepts**:
  - `ChangeNotifier`: A class that can be extended to provide change notifications. `ProductProvider` extends `ChangeNotifier`.
  - `notifyListeners()`: Called inside provider methods whenever state changes (e.g. data loaded, product deleted, search query updated).
  - `context.watch<ProductProvider>()`: Rebuilds the widget whenever `notifyListeners()` is called.
  - `context.read<ProductProvider>()`: Reads the provider without listening to updates (used in callbacks like `onPressed` or `initState`).
  - `context.select<T, R>()`: Rebuilds only when a specific property changes (e.g. favorite status of a specific product ID).

---

## 6. How Local Cache & Offline Mode Work (Hive)

### Question: "How does the app work offline?"
- Hive is a lightweight, fast, pure Dart key-value NoSQL database.
- Whenever API data arrives, `ProductRepository` loops through items and writes them to Hive:
  ```dart
  local.saveProduct(product);
  ```
- If the device is offline or the network call throws a `SocketException` or `TimeoutException`:
  1. The `catch` block in `ProductRepository.getProducts` intercepts the error.
  2. It retrieves all cached products stored in Hive (`local.getAll()`).
  3. Returns `PageResult(items: pagedItems, fromCache: true)`.
  4. The provider detects `isOffline = true` and shows the amber offline banner at the top of `HomeScreen`.

---

## 7. How CRUD Operations Are Implemented

### Question: "How do Create, Read, Update, and Delete work?"
1. **Create (Add Product)**:
   - User fills in the form in `ProductFormScreen`.
   - New ID is generated using `DateTime.now().millisecondsSinceEpoch`.
   - Saved locally in Hive with `isLocal: true`.
   - Immediately prepended to `_localItems` list in provider.
2. **Read**:
   - `HomeScreen` displays the paginated list.
   - Tapping an item navigates to `DetailScreen` using its ID.
3. **Update (Edit Product)**:
   - In `DetailScreen`, tapping Edit opens `ProductFormScreen` with pre-filled controllers.
   - When saved, `updateProduct` updates the record in Hive and marks it with `edited: true`.
   - Even when fresh data is fetched from the API, the repository checks `saved.edited == true` and retains the user's edits!
4. **Delete**:
   - In `DetailScreen`, tapping Delete displays a confirmation `AlertDialog`.
   - When confirmed, `deleteProduct` removes the item from Hive.
   - If the item originated from the API, its ID is stored in `deleted_ids` in Hive so subsequent API fetches do not re-insert it.

---

## 8. How Pagination & Infinite Scroll Work

### Question: "How did you implement pagination?"
- The DummyJSON API supports pagination via query parameters: `limit` (how many items to return) and `skip` (how many items to skip).
- **Infinite Scrolling**:
  - We attach a listener to `ScrollController`:
    ```dart
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMore();
    }
    ```
  - When the user scrolls within 300 pixels of the bottom, `loadMore()` requests the next page (`skip += 20`).
  - New items are appended to `_apiItems = [..._apiItems, ...result.items]`.
  - We also include a manual "Load More Products" button as an alternative.

---

## 9. How Debounced Search Works

### Question: "What is debounced search and why do we use it?"
- In `HomeScreen`, `_onSearchChanged` uses a `Timer`:
  ```dart
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    context.read<ProductProvider>().setQuery(query);
  });
  ```
- Without debouncing, typing a 10-letter word triggers 10 instantaneous search operations.
- With debouncing, we cancel previous timers on each keystroke and wait until the user pauses for 400ms before filtering the list. This provides smooth, lag-free UI performance.

---

## 10. How Responsive UI Works

### Question: "How does your app adapt to Mobile and Tablet?"
- In `HomeScreen`, we use `SliverGridDelegateWithMaxCrossAxisExtent`:
  ```dart
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220, // Max width of each card
    childAspectRatio: 0.62,
  )
  ```
- On a mobile phone (screen width ~360-400px), Flutter automatically creates **2 columns**.
- On a tablet or landscape display (screen width ~700-1200px), Flutter automatically creates **3, 4, or 5 columns**.
- On `DetailScreen` and `ProductFormScreen`, we wrap content in `ConstrainedBox(constraints: BoxConstraints(maxWidth: 800))` so contents do not stretch unnaturally wide on tablets.

---

## 11. Top 15 Viva Questions & Direct Answers

### Q1: What is Flutter and why is it called a cross-platform framework?
**Answer**: Flutter is Google's UI toolkit that compiles to native machine code (ARM / x86) from a single Dart codebase. It renders its own widgets using Impeller/Skia rather than relying on native platform wrappers.

### Q2: What is the difference between `StatelessWidget` and `StatefulWidget`?
**Answer**: 
- `StatelessWidget` is immutable and has no internal state that changes after build (e.g. `ProductCard`, `MessageView`).
- `StatefulWidget` has a mutable `State` object that survives across rebuilds and can trigger updates via `setState()` or lifecycle events (`initState`, `dispose`).

### Q3: What is the purpose of `initState()` and `dispose()`?
**Answer**:
- `initState()` is called exactly once when the widget is inserted into the widget tree. We use it to trigger initial data fetching and attach scroll listeners.
- `dispose()` is called when the widget is removed permanently from the tree. We use it to clean up resources like `ScrollController`, `TextEditingController`, and `Timer`.

### Q4: What does `WidgetsFlutterBinding.ensureInitialized()` do?
**Answer**: It ensures that the Flutter engine's binary communication channels with the underlying platform (Android/iOS) are ready before executing asynchronous plugins such as `Hive.initFlutter()`.

### Q5: What is the difference between `context.watch()` and `context.read()`?
**Answer**:
- `context.watch<T>()` subscribes the widget to changes; when `notifyListeners()` is fired, the widget rebuilds.
- `context.read<T>()` retrieves the provider instance once without subscribing to rebuilds. It is suitable for event handlers like `onPressed`.

### Q6: How does `RefreshIndicator` work in Flutter?
**Answer**: `RefreshIndicator` listens to over-scroll pull gestures on scrollable widgets. When the user pulls down, it displays a spinning progress indicator and awaits the completion of an asynchronous callback (`Future<void> Function()`), such as `loadFirstPage()`.

### Q7: Why do we use `cached_network_image` instead of `Image.network`?
**Answer**: `Image.network` re-downloads images every time the widget rebuilds or re-appears. `cached_network_image` stores downloaded images on the local disk cache, displays placeholders while loading, shows error fallbacks if downloading fails, and enables images to display when offline.

### Q8: What is the purpose of `CustomScrollView` and `Slivers`?
**Answer**: Slivers are portions of a scrollable area that allow custom scroll effects. We combine `SliverGrid` and `SliverToBoxAdapter` inside a single `CustomScrollView` to have a scrollable grid and a pagination footer seamlessly share the same scroll controller.

### Q9: What is Dependency Injection and where is it used in this project?
**Answer**: Dependency Injection means passing dependencies from outside rather than creating them hardcoded inside classes. In `main.dart`, we create `RemoteDataSource` and `LocalDataSource`, pass them to `ProductRepository`, and pass `ProductRepository` to `ProductProvider`. This makes code modular, loosely coupled, and easy to unit test.

### Q10: How do you handle errors during network requests?
**Answer**: We wrap network calls in `try-catch` blocks. We inspect the error: if it is a `SocketException` or `TimeoutException`, we show a user-friendly "No internet connection" message. For server errors (like status 500), we display a server error view with a "Try Again" button.

### Q11: What is a `GlobalKey<FormState>` used for?
**Answer**: It uniquely identifies the `Form` widget and allows us to validate all enclosed `TextFormField` widgets at once using `_formKey.currentState!.validate()`.

### Q12: Why do you store deleted API item IDs in Hive?
**Answer**: Since DummyJSON is a read-only mock REST API, it does not permanently delete items on its remote server. If a user deletes an item in the app, storing its ID in Hive's `deleted_ids` ensures that future API refreshes filter out that ID and do not bring the deleted item back.

### Q13: How is Dark Mode persisted across app launches?
**Answer**: In `LocalDataSource`, we store a boolean flag in Hive's `meta_box`. When the app opens, `ThemeProvider` reads this boolean. When the user toggles the theme, the new value is immediately written back to Hive.

### Q14: What is the difference between `POST`, `PUT`, and `DELETE` in REST APIs?
**Answer**:
- `GET`: Reads data without modifying state.
- `POST`: Creates a new resource.
- `PUT`: Updates an existing resource completely or creates it if absent.
- `DELETE`: Removes a resource.

### Q15: Why is `LayoutBuilder` used with `SingleChildScrollView` for empty/error states?
**Answer**: When a list is empty, `RefreshIndicator` only works if the child is scrollable. `LayoutBuilder` gives us the exact available height (`constraints.maxHeight`), allowing us to center the empty message while ensuring the view is scrollable with `AlwaysScrollableScrollPhysics` so pull-to-refresh functions properly.
