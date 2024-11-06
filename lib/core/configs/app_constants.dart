class AppConstants {
  // App Information
  static const String appName = 'Smart Gate';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.example.com';
  static const int apiTimeout = 30000; // milliseconds

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int normalAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;

  // Error Messages
  static const String defaultErrorMessage = 'Something went wrong';
  static const String networkErrorMessage = 'Network connection error';
  static const String unauthorizedMessage = 'Unauthorized access';

  // Contact Information
  static const String adminEmail = 'admin@cleanstore.com';
}
