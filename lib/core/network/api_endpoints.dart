class ApiEndpoints {
  // App Settings
  static const String appSettings = '/settings';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String completeProfile = '/auth/profile';
  static const String me = '/auth/me';

  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Banners
  static const String banners = '/banners';

  // Projects
  static const String projects = '/projects';

  // Properties
  static const String properties = '/properties';
  static String propertyById(int id) => '/properties/$id';
  static const String featuredProperties = '/properties/featured';
  static const String searchProperties = '/properties/search';
  static String similarProperties(int id) => '/properties/$id/similar';
  static const String myProperties = '/properties/my';

  // News
  static const String news = '/news';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteById(int id) => '/favorites/$id';

  // Subscription
  static const String packages = '/packages';
  static const String subscriptions = '/subscriptions';
  static const String mySubscription = '/subscriptions/my';

  // Seller Request
  static const String sellerRequests = '/seller-requests';

  // Upload
  static const String uploadSingle = '/upload/single';

  // AI Chat
  static const String chatSessions = '/chat/sessions';
  static String chatSessionById(int id) => '/chat/sessions/$id';
  static String chatMessages(int sessionId) => '/chat/sessions/$sessionId/messages';
}
