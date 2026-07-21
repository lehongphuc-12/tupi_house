import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/review_provider.dart';
import 'screens/product/optimized_product_list_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==================== SEED DATA (Chạy 1 lần) ====================
  await seedInitialData();
  // ============================================================

  runApp(const MyApp());
}

// Hàm insert data từ JSON lên Firebase (chỉ chạy lần đầu)
Future<void> seedInitialData() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Kiểm tra xem đã có dữ liệu chưa
    final productsSnapshot =
        await firestore.collection('products').limit(1).get();
    if (productsSnapshot.docs.isNotEmpty) {
      print("✅ Dữ liệu đã tồn tại, bỏ qua seed data.");
      return;
    }

    print("🌱 Đang insert dữ liệu lần đầu...");

    // 1. Insert Categories
    final categoriesString =
        await rootBundle.loadString('assets/categories.json');
    final categoriesList = jsonDecode(categoriesString) as List;

    for (var cat in categoriesList) {
      await firestore.collection('categories').doc(cat['id']).set(cat);
    }
    print("✅ Đã insert ${categoriesList.length} categories");

    // 2. Insert Products
    final productsString =
        await rootBundle.loadString('assets/products_for_firestore.json');
    final productsList = jsonDecode(productsString) as List;

    for (var product in productsList) {
      await firestore.collection('products').doc(product['id']).set(product);
    }
    print("✅ Đã insert ${productsList.length} products");

    print("🎉 Seed data hoàn thành thành công!");
  } catch (e) {
    print("❌ Lỗi khi seed data: $e");
    print(
        "💡 Đảm bảo 2 file categories.json và products_for_firestore.json nằm cùng thư mục với project.");
  }
}

/// GlobalKey cho ScaffoldMessenger – dùng để hiển thị thông báo đơn hàng toàn cục
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'Tupi House',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: const OptimizedProductListScreen(),
      ),
    );
  }
}
