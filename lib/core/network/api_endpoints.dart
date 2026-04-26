class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Cities
  static const String cities = '/cities';

  // Projects
  static const String projects = '/projects';

  // Properties
  static const String properties = '/properties';
  static String propertyById(int id) => '/properties/$id';
  static const String featuredProperties = '/properties/featured';
  static const String searchProperties = '/properties/search';
}
