class NotifItem {
  final String title;
  final String body;
  final String type;
  final String timeAgo;
  bool isRead;

  NotifItem({
    required this.title,
    required this.body,
    required this.type,
    required this.timeAgo,
    required this.isRead,
  });
}
