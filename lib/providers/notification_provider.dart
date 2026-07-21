import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  StreamSubscription<List<AppNotification>>? _subscription;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  bool _seeded = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  void startListening(String userId) {
    if (_userId == userId && _subscription != null) return;

    stopListening();
    _userId = userId;
    _isLoading = true;
    _seeded = false;
    _errorMessage = null;
    notifyListeners();

    NotificationService.bindUser(userId);

    _subscription =
        NotificationService.listenNotifications(userId).listen((list) {
      final previousIds = _notifications.map((n) => n.id).toSet();

      // First snapshot: seed seen IDs so we don't spam alerts for history.
      if (!_seeded) {
        NotificationService.seedSeenIds(list.map((n) => n.id));
        _seeded = true;
      } else {
        for (final n in list) {
          if (!previousIds.contains(n.id) && !n.isRead) {
            NotificationService.handleIncomingNotification(n);
          }
        }
      }

      _notifications = list;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Không thể tải thông báo.';
      _isLoading = false;
      notifyListeners();
      debugPrint('Notification stream error: $e');
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _userId = null;
    _seeded = false;
    _isLoading = false;
    _errorMessage = null;
    NotificationService.unbindUser();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    try {
      await NotificationService.markAsRead(id);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await NotificationService.markAllAsRead(userId);
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await NotificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
