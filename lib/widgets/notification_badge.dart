import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser != null) {
        final unreadCount = await _notificationService.getUnreadCount(currentUser.id);
        
        if (mounted) {
          setState(() {
            _unreadCount = unreadCount;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _unreadCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications),
          if (_unreadCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        ).then((_) => _loadUnreadCount());
      },
      tooltip: 'Notifications',
    );
  }
}
