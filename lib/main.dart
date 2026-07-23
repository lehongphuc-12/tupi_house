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
import 'providers/notification_provider.dart';
import 'providers/voucher_provider.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'utils/error_logger.dart';
import 'package:flutter/services.dart';

/// GlobalKey cho ScaffoldMessenger – thông báo đơn hàng toàn cục
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve file logging on IO targets while remaining web-compatible.
  FlutterError.onError = (details) {
    appendErrorLog(
      '======================================================\n'
      '${DateTime.now()}: EXCEPTION: ${details.exception}\n'
      'STACK TRACE:\n${details.stack}\n'
      '======================================================\n\n',
    );
    FlutterError.presentError(details);
  };
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==================== SEED DATA (Chạy 1 lần) ====================
  await seedInitialData();
  // ============================================================

  await NotificationService.initialize(
    scaffoldMessengerKey: scaffoldMessengerKey,
  );

  runApp(const MyApp());
}

// Hàm insert data từ JSON lên Firebase (chỉ chạy lần đầu)
Future<void> seedInitialData() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Seed vouchers if TUPINEW doesn't exist (always checked)
    final vouchersSnapshot = await firestore.collection('vouchers').where('code', isEqualTo: 'TUPINEW').limit(1).get();
    if (vouchersSnapshot.docs.isEmpty) {
      print("🌱 Đang seed vouchers...");
      final testVouchers = [
        {
          'id': 'VOUCHER_10K',
          'code': 'TUPI10K',
          'description': 'Giảm ngay 10.000₫ cho đơn hàng từ 50.000₫',
          'type': 'fixed',
          'discountValue': 10000,
          'minOrderValue': 50000,
          'maxDiscountAmount': 10000,
          'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          'isActive': true,
          'usageLimit': 100,
          'usedCount': 0,
        },
        {
          'id': 'VOUCHER_PERCENT',
          'code': 'TUPINEW',
          'description': 'Giảm 20% cho đơn hàng bất kỳ, tối đa 50.000₫',
          'type': 'percent',
          'discountValue': 20,
          'minOrderValue': 0,
          'maxDiscountAmount': 50000,
          'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          'isActive': true,
          'usageLimit': 50,
          'usedCount': 0,
        }
      ];
      for (var v in testVouchers) {
        await firestore.collection('vouchers').doc(v['id'] as String).set(v);
      }
      print("✅ Đã seed ${testVouchers.length} vouchers");
    }

    // Configure test products for Low Stock Alert (Scenario 9) & Flash Sale (Scenario 10)
    final productsQuery = await firestore.collection('products').limit(2).get();
    if (productsQuery.docs.length >= 2) {
      final doc1 = productsQuery.docs[0];
      final doc2 = productsQuery.docs[1];

      // Product 1: Set stock to 3 (Low stock < 5)
      await doc1.reference.update({
        'stock': 3,
      });

      // Product 2: Set Flash Sale
      await doc2.reference.update({
        'price': 50000,
        'isFlashSale': true,
        'flashSalePrice': 15000,
        'flashSaleStartTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
        'flashSaleEndTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
      });
    }

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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
      ],
      child: MaterialApp(
        title: 'Tupi House',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scaffoldMessengerKey: scaffoldMessengerKey,
        // Start with SplashScreen - flow will be: Splash -> Welcome -> Onboarding -> Login -> Main
        home: const SplashScreen(),
      ),
    );
  }
}

/// Restores session and starts/stops notification listening with auth state.
class _AuthBootstrap extends StatefulWidget {
  final Widget child;

  const _AuthBootstrap({required this.child});

  @override
  State<_AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends State<_AuthBootstrap> {
  String? _boundUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.tryAutoLogin();
      if (!mounted) return;
      _syncNotifications(auth);
    });
  }

  void _syncNotifications(AuthProvider auth) {
    final notif = context.read<NotificationProvider>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      if (_boundUserId != null) {
        notif.stopListening();
        _boundUserId = null;
      }
      return;
    }

    if (_boundUserId != userId) {
      notif.startListening(userId);
      _boundUserId = userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Keep notification stream in sync when login/logout changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncNotifications(auth);
    });
    return widget.child;
  }
}
