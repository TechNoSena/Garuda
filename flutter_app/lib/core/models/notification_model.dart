class PushNotification {
  final String notificationId;
  final String title;
  final String body;
  final String type;
  final String priority;
  final String? shipmentId;
  final bool read;
  final String timestamp;

  PushNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.shipmentId,
    required this.read,
    required this.timestamp,
  });

  factory PushNotification.fromJson(Map<String, dynamic> json) => PushNotification(
    notificationId: json['notification_id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    type: json['type'] ?? '',
    priority: json['priority'] ?? '',
    shipmentId: json['shipment_id'],
    read: json['read'] ?? false,
    timestamp: json['timestamp'] ?? '',
  );
}

class ChatBridgeData {
  final String bridgeId;
  final String shipmentId;
  final String maskedPhoneNumber;
  final int sessionExpiresInMins;
  final String message;

  ChatBridgeData({
    required this.bridgeId,
    required this.shipmentId,
    required this.maskedPhoneNumber,
    required this.sessionExpiresInMins,
    required this.message,
  });

  factory ChatBridgeData.fromJson(Map<String, dynamic> json) => ChatBridgeData(
    bridgeId: json['bridge_id'] ?? '',
    shipmentId: json['shipment_id'] ?? '',
    maskedPhoneNumber: json['masked_phone_number'] ?? '',
    sessionExpiresInMins: json['session_expires_in_mins'] ?? 60,
    message: json['message'] ?? '',
  );
}
