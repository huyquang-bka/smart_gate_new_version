class AppConstants {
  // App Information
  static const String appName = 'Smart Gate';
  static const String appVersion = '1.3.0';
  static const String userGithub = 'huyquang-bka';
  static const String repoName = 'smart_gate_new_version';
  static const String adminEmail = 'admin@atin.com.vn';

  // Company Information
  static const String companyName = 'ATIN';
  static const String companyWebsite = 'https://atin.com.vn';
  static const String copyright = '© 2024 ATIN. All rights reserved.';

  //default list cargo type code
  static const List<String> defaultCargoTypeCode = [
    'AK', // Over Dimension
    'BB', // Break Bulk
    'BN', // Bundle
    'DG', // Dangerous
    'DR', // Reefer & DG
    'ED', // Dangerous Empty
    'FR', // Fragile
    'GP', // General
    'MT', // Empty
    'RF', // Reefer
    'DO', // DG & Over Dimension
  ];

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // MQTT Topics
  // static const String mqttBroker = '27.72.98.49';
  static const String mqttBroker = '172.34.64.10';
  static const String mqttTopicEvent = "Event/Container";
  static const String mqttTopicCargoType = "Event/CargoType";
  static const String mqttTopicCheckSeal = "Event/CheckSeal";
  static const int mqttPort = 1883;
  static const String mqttUsername = 'admin';
  static const String mqttPassword = 'admin';

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

  //Image additional
  static const int maxAdditionalImages = 6;
}
