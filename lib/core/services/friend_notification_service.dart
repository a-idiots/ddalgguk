import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:ddalgguk/core/services/notification_service.dart';
import 'package:ddalgguk/core/services/notification_config.dart';

/// Service for handling friend-related notifications
/// Works without Cloud Functions (client-side only)
class FriendNotificationService {
  factory FriendNotificationService() => _instance;

  FriendNotificationService._internal();

  static final FriendNotificationService _instance =
      FriendNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<QuerySnapshot>? _friendRequestListener;
  Stream<QuerySnapshot>? _friendsListener;

  // Track initial load to avoid notifications for existing data
  bool _isInitialFriendRequestLoad = true;
  bool _isInitialFriendsLoad = true;

  /// Start listening for friend requests and friends
  Future<void> startListening() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ No user logged in, cannot start friend notifications');
      return;
    }

    debugPrint('🔔 Starting friend notification listeners for user: $userId');

    // Listen for new friend requests
    _friendRequestListener = _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    _friendRequestListener!.listen((snapshot) {
      // Skip initial load - only notify for real-time changes
      if (_isInitialFriendRequestLoad) {
        _isInitialFriendRequestLoad = false;
        debugPrint('📬 Initial friend requests loaded: ${snapshot.docs.length}');
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // New friend request received
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            _handleNewFriendRequest(data);
          }
        }
      }
    });

    // Listen for new friends (accepted requests)
    _friendsListener = _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots();

    _friendsListener!.listen((snapshot) {
      // Skip initial load - only notify for real-time changes
      if (_isInitialFriendsLoad) {
        _isInitialFriendsLoad = false;
        debugPrint('👥 Initial friends loaded: ${snapshot.docs.length}');
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // New friend added
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            _handleFriendAdded(data);
          }
        }
      }
    });

    // Check for old friend requests
    await _checkOldFriendRequests();

    debugPrint('✅ Friend notification listeners started');
  }

  /// Stop listening
  void stopListening() {
    _friendRequestListener = null;
    _friendsListener = null;
    // Reset flags for next session
    _isInitialFriendRequestLoad = true;
    _isInitialFriendsLoad = true;
    debugPrint('🔕 Friend notification listeners stopped');
  }

  /// Handle new friend request
  Future<void> _handleNewFriendRequest(Map<String, dynamic> data) async {
    final fromUserName = data['fromUserName'] as String? ?? '누군가';

    debugPrint('🔔 New friend request from: $fromUserName');

    // Show local notification
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '새로운 친구 신청이 도착했어요!',
      body: '$fromUserName님이 친구 신청을 보냈습니다.',
      type: NotificationType.socialAlarm,
    );
  }

  /// Handle friend added (request accepted)
  Future<void> _handleFriendAdded(Map<String, dynamic> data) async {
    final friendName = data['name'] as String? ?? '누군가';

    debugPrint('🔔 New friend added: $friendName');

    // Show local notification
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '친구 신청이 수락되었어요!',
      body: '$friendName님과 친구가 되었습니다.',
      type: NotificationType.socialAlarm,
    );
  }

  /// Check for friend requests older than 3 days
  Future<void> _checkOldFriendRequests() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    try {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friendRequests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: Timestamp.fromDate(threeDaysAgo))
          .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('📬 Found ${snapshot.docs.length} old friend requests');

        // Show reminder notification
        await _notificationService.showNotification(
          id: 9999, // Fixed ID for reminder
          title: '친구 신청을 확인해보세요!',
          body: '3일이 지난 친구 신청이 있습니다. 우체통을 확인해보세요!',
          type: NotificationType.socialAlarm,
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking old friend requests: $e');
    }
  }

  /// Check old friend requests on demand
  Future<void> checkOldRequests() async {
    await _checkOldFriendRequests();
  }
}
