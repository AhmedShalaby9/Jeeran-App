import 'package:flutter/foundation.dart';

// ── Message ───────────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ── Session ───────────────────────────────────────────────────────────────────
class ChatSession {
  final String id;
  String title;
  DateTime lastMessageAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    required this.messages,
  });

  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final text = last.text;
    return text.length > 60 ? '${text.substring(0, 60)}…' : text;
  }
}

// ── In-memory session manager ─────────────────────────────────────────────────
class ChatSessionManager extends ChangeNotifier {
  static final ChatSessionManager _instance = ChatSessionManager._internal();
  factory ChatSessionManager() => _instance;
  ChatSessionManager._internal() {
    _seedDemoData();
  }

  final List<ChatSession> _sessions = [];

  List<ChatSession> get sessions =>
      List.unmodifiable(_sessions.reversed.toList());

  void _seedDemoData() {
    final now = DateTime.now();
    _sessions.addAll([
      ChatSession(
        id: 'demo_1',
        title: 'Finding a 2-bedroom apartment',
        lastMessageAt: now.subtract(const Duration(hours: 1, minutes: 23)),
        messages: [
          ChatMessage(
            text: 'Hello! I\'m Jeeran AI, your smart real-estate assistant. '
                'Ask me anything about properties, neighborhoods, or market trends! 🏡',
            isUser: false,
            time: now.subtract(const Duration(hours: 1, minutes: 25)),
          ),
          ChatMessage(
            text: 'I\'m looking for a 2-bedroom apartment near the city center.',
            isUser: true,
            time: now.subtract(const Duration(hours: 1, minutes: 24)),
          ),
          ChatMessage(
            text: 'Great choice! There are several 2-bedroom options near the city center. '
                'Prices typically range from \$1,200–\$2,500/month. '
                'Would you like me to filter by budget or specific amenities?',
            isUser: false,
            time: now.subtract(const Duration(hours: 1, minutes: 23)),
          ),
        ],
      ),
      ChatSession(
        id: 'demo_2',
        title: 'Property investment advice',
        lastMessageAt: now.subtract(const Duration(days: 1, hours: 3)),
        messages: [
          ChatMessage(
            text: 'Hello! I\'m Jeeran AI, your smart real-estate assistant. '
                'Ask me anything about properties, neighborhoods, or market trends! 🏡',
            isUser: false,
            time: now.subtract(const Duration(days: 1, hours: 4)),
          ),
          ChatMessage(
            text: 'What are the best areas for property investment right now?',
            isUser: true,
            time: now.subtract(const Duration(days: 1, hours: 3, minutes: 5)),
          ),
          ChatMessage(
            text: 'For investment, I\'d recommend looking at up-and-coming neighborhoods '
                'with good transport links. Rental yields are currently strong in suburban areas. '
                'Would you like detailed market data?',
            isUser: false,
            time: now.subtract(const Duration(days: 1, hours: 3)),
          ),
        ],
      ),
      ChatSession(
        id: 'demo_3',
        title: 'Neighborhood comparison',
        lastMessageAt: now.subtract(const Duration(days: 3)),
        messages: [
          ChatMessage(
            text: 'Hello! I\'m Jeeran AI, your smart real-estate assistant. '
                'Ask me anything about properties, neighborhoods, or market trends! 🏡',
            isUser: false,
            time: now.subtract(const Duration(days: 3, hours: 1)),
          ),
          ChatMessage(
            text: 'Can you compare the north and south districts?',
            isUser: true,
            time: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    ]);
  }

  ChatSession createNewSession() {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New conversation',
      lastMessageAt: DateTime.now(),
      messages: [
        ChatMessage(
          text: 'Hello! I\'m Jeeran AI, your smart real-estate assistant. '
              'Ask me anything about properties, neighborhoods, or market trends! 🏡',
          isUser: false,
          time: DateTime.now(),
        ),
      ],
    );
    _sessions.add(session);
    notifyListeners();
    return session;
  }

  void addMessageToSession(String sessionId, ChatMessage message) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    session.messages.add(message);
    session.lastMessageAt = message.time;
    // Auto-title from first user chat
    final userMessages = session.messages.where((m) => m.isUser).toList();
    if (userMessages.length == 1 && session.title == 'New conversation') {
      final text = userMessages.first.text;
      session.title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
    }
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }
}
