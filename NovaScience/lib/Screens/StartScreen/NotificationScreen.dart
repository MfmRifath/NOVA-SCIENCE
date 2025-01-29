import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              return ListTile(
                leading: Icon(Icons.notifications, color: Colors.blueAccent),
                title: Text(notification['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notification['body']),
                trailing: notification['isRead']
                    ? Icon(Icons.check, color: Colors.green)
                    : Icon(Icons.circle, color: Colors.red, size: 12),
                onTap: () {
                  _markAsRead(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'isRead': true});
  }
}