import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.payload,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> payload;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      type: (data['type'] as String?) ?? 'general',
      title: (data['title'] as String?) ?? 'Update',
      body: (data['body'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
      payload: (data['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
