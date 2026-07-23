import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';

/// Top-level background FCM handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// In-app notification center + FCM push + local notifications.
class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tupi_house_orders',
    'Thông báo đơn hàng',
    description: 'Cập nhật trạng thái đơn hàng Tupi House',
    importance: Importance.high,
  );

  static GlobalKey<ScaffoldMessengerState>? messengerKey;
  static bool _initialized = false;
  static String? _currentUserId;
  static final Set<String> _seenNotificationIds = {};

  static String statusLabel(String status) {
    const labels = {
      'pending': 'Chờ xác nhận ⏳',
      'confirmed': 'Đã xác nhận ✅',
      'shipping': 'Đang giao hàng 🚚',
      'delivered': 'Đã giao thành công 🎉',
      'cancelled': 'Đã hủy đơn ❌',
    };
    return labels[status] ?? status;
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.celebration_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static String shortOrderId(String orderId) {
    if (orderId.length >= 6) {
      return orderId.substring(0, 6).toUpperCase();
    }
    return orderId.toUpperCase();
  }

  /// Initialize FCM + local notifications. Call once after Firebase.initializeApp.
  static Future<void> initialize({
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) async {
    if (_initialized) return;
    messengerKey = scaffoldMessengerKey;

    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final isFCMSupported = kIsWeb || isMobile;

    // Local notifications (mobile only)
    if (isMobile) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _local.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();

      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // FCM permissions & handlers
    if (isFCMSupported) {
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // iOS: show alert even in foreground
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          _handleMessageOpened(initial);
        }
      } catch (e) {
        debugPrint('Failed to initialize Firebase Messaging: $e');
      }
    }

    _initialized = true;
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    // Navigation can be wired later via a global navigator key if needed.
    debugPrint('Local notification tapped: ${response.payload}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Tupi House';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    await showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );

    _showInAppSnackBar(title: title, body: body);
  }

  static void _handleMessageOpened(RemoteMessage message) {
    debugPrint('FCM opened: ${message.data}');
  }

  /// Save / refresh FCM token for the logged-in user.
  static Future<void> bindUser(String userId) async {
    _currentUserId = userId;
    _seenNotificationIds.clear();

    final isFCMSupported = kIsWeb || (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS));
    if (!isFCMSupported) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(userId, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        if (_currentUserId != null) {
          _saveToken(_currentUserId!, newToken);
        }
      });
    } catch (e) {
      debugPrint('FCM token bind error: $e');
    }
  }

  static Future<void> _saveToken(String userId, String token) async {
    final userRef = _db.collection('users').doc(userId);
    await userRef.set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove current device token on logout.
  static Future<void> unbindUser() async {
    final userId = _currentUserId;
    _currentUserId = null;
    _seenNotificationIds.clear();

    final isFCMSupported = kIsWeb || (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS));
    if (userId == null || !isFCMSupported) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));

        final doc = await _db.collection('users').doc(userId).get();
        if (doc.data()?['fcmToken'] == token) {
          await _db.collection('users').doc(userId).set({
            'fcmToken': FieldValue.delete(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('FCM unbind error: $e');
    }
  }

  // ───────────────────── Firestore notifications ─────────────────────

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  static Stream<List<AppNotification>> listenNotifications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Create a notification document for a user (in-app + triggers Cloud Function FCM).
  static Future<String> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
    String? orderId,
    Map<String, dynamic>? data,
  }) async {
    final doc = _col.doc();
    await doc.set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': data ?? {},
    });
    return doc.id;
  }

  static Future<void> notifyOrderCreated({
    required String userId,
    required String orderId,
  }) async {
    final shortId = shortOrderId(orderId);
    await createNotification(
      userId: userId,
      title: 'Đặt hàng thành công 🌷',
      body: 'Đơn #$shortId đã được tạo và đang chờ xác nhận.',
      type: 'order_created',
      orderId: orderId,
      data: {'status': 'pending'},
    );
  }

  static Future<void> notifyOrderStatusChanged({
    required String userId,
    required String orderId,
    required String newStatus,
  }) async {
    final shortId = shortOrderId(orderId);
    final label = statusLabel(newStatus);
    final isCancelled = newStatus == 'cancelled';

    await createNotification(
      userId: userId,
      title: isCancelled ? 'Đơn hàng đã hủy' : 'Cập nhật đơn hàng',
      body: 'Đơn #$shortId: $label',
      type: isCancelled ? 'order_cancelled' : 'order_status',
      orderId: orderId,
      data: {'status': newStatus},
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    // Single-field query avoids requiring a composite index.
    final snapshot = await _col.where('userId', isEqualTo: userId).get();
    final unread = snapshot.docs.where((d) => d.data()['isRead'] != true);
    if (unread.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> deleteNotification(String notificationId) async {
    await _col.doc(notificationId).delete();
  }

  /// Show OS local notification (when app is open / process alive).
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Local notifications plugin is mobile-oriented; skip desktop/web.
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Called when a new Firestore notification arrives while listening.
  static Future<void> handleIncomingNotification(
    AppNotification notification, {
    bool showLocal = true,
    bool showSnackBar = true,
  }) async {
    if (_seenNotificationIds.contains(notification.id)) return;
    _seenNotificationIds.add(notification.id);

    // Skip initial snapshot flood: only alert for very recent items
    final age = DateTime.now().difference(notification.createdAt);
    if (age > const Duration(seconds: 30)) return;

    if (showLocal) {
      await showLocalNotification(
        title: notification.title,
        body: notification.body,
        payload: jsonEncode({
          'notificationId': notification.id,
          'orderId': notification.orderId,
          'type': notification.type,
        }),
      );
    }

    if (showSnackBar) {
      _showInAppSnackBar(
        title: notification.title,
        body: notification.body,
        status: notification.data['status']?.toString(),
      );
    }
  }

  static void _showInAppSnackBar({
    required String title,
    required String body,
    String? status,
  }) {
    messengerKey?.currentState?.hideCurrentSnackBar();
    messengerKey?.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white70,
          onPressed: () {
            messengerKey?.currentState?.hideCurrentSnackBar();
          },
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                status != null ? statusIcon(status) : Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seed seen IDs so the first snapshot does not spam local alerts.
  static void seedSeenIds(Iterable<String> ids) {
    _seenNotificationIds.addAll(ids);
  }
}
