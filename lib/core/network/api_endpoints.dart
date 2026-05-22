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
  static String projectById(int id) => '/projects/$id';

  // Properties
  static const String properties = '/properties';
  static String propertyById(int id) => '/properties/$id';
  static String propertyApprove(int id) => '/properties/$id/approve';
  static String propertyReject(int id) => '/properties/$id/reject';
  static const String featuredProperties = '/properties/featured';
  static const String searchProperties = '/properties/search';
  static String similarProperties(int id) => '/properties/$id/similar';
  static const String myProperties = '/properties/my';

  // News
  static const String news = '/news';
  static String newsById(int id) => '/news/$id';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteById(int id) => '/favorites/$id';

  // Subscription
  static const String packages = '/packages';
  static const String subscriptions = '/subscriptions';
  static const String mySubscription = '/subscriptions/my';
  static const String upgradeSubscription = '/subscriptions/upgrade';
  static const String cancelSubscription = '/subscriptions/cancel';
  static const String subscriptionHistory = '/subscriptions/history';
  static String subscriptionCheckPayment(int id) => '/subscriptions/$id/check-payment';

  // Seller Request
  static const String sellerRequests = '/seller-requests';
  static String sellerRequestById(int id) => '/seller-requests/$id';
  static String sellerRequestApprove(int id) => '/seller-requests/$id/approve';
  static String sellerRequestReject(int id) => '/seller-requests/$id/reject';

  // Upload
  static const String uploadSingle = '/upload/single';

  // AI Chat
  static const String chatSessions = '/chat/sessions';
  static String chatSessionById(int id) => '/chat/sessions/$id';
  static String chatMessages(int sessionId) => '/chat/sessions/$sessionId/messages';

  // FCM Tokens
  static const String fcmTokens = '/fcm-tokens';
  static String fcmToken(String deviceId) => '/fcm-tokens/$deviceId';

  // AI Ads
  static const String aiAdsGenerate = '/ai-ads/generate';
  static const String aiAdsAdminGenerate = '/ai-ads/admin/generate';
  static const String aiAds = '/ai-ads';
  static String aiAdById(int id) => '/ai-ads/$id';
  static String aiAdTrials(int id) => '/ai-ads/$id/trials';
  static String aiAdCheckPayment(int id) => '/ai-ads/$id/check-payment';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(int receiptId) => '/notifications/$receiptId/read';
  static const String notificationsReadAll = '/notifications/read-all';
}
