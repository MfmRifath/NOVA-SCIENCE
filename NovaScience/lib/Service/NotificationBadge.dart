// NotificationBadge.dart
import 'package:flutter/material.dart';

import 'NotificationService.dart';


class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color badgeColor;
  final Color textColor;
  final double size;
  final double padding;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.size = 20.0,
    this.padding = 4.0,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadNotificationCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        // No badge needed if count is zero and showZero is false
        if (count == 0 && !showZero) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 1.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  minWidth: size,
                  minHeight: size,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Usage example:
// NotificationBadge(
//   child: IconButton(
//     icon: Icon(Icons.notifications),
//     onPressed: () {
//       // Show notifications panel
//     },
//   ),
// )