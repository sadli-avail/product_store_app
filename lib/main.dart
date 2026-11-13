import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/datasource/local_datasource.dart';
import 'data/datasource/remote_datasource.dart';
import 'data/repository/product_repository.dart';
import 'presentation/screens/splash_screen.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';

/// Entry point of the application
Future<void> main() async {
  // Ensure Flutter engine bindings are initialized before calling native plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  final localDataSource = LocalDataSource();
  await localDataSource.init();

  // Dependency Injection: Construct repositories and remote sources
  final remoteDataSource = RemoteDataSource();
  final productRepository = ProductRepository(remoteDataSource, localDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(localDataSource),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productRepository),
        ),
      ],
      child: const ProductStoreApp(),
    ),
  );
}

/// Root application widget
class ProductStoreApp extends StatelessWidget {
  const ProductStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return MaterialApp(
      title: 'Product Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
