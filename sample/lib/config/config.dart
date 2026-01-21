class AppConfig {
  static const String appName = 'ラーメンマップ';
  static const String appVersion = '1.0.0';
  
  // API設定
  static const String apiBaseUrl = 'https://api.example.com';
  
  // マップ設定
  static const double defaultLatitude = 35.6812;
  static const double defaultLongitude = 139.7671;
  static const double defaultZoom = 15.0;
  
  // UI設定
  static const int feedLoadLimit = 10;
  static const int videoLoadLimit = 20;
}

class ThemeConfig {
  static const String primaryColor = '#FF0000';
  static const String accentColor = '#FFA500';
  static const String backgroundColor = '#FFFFFF';
}

class FeatureFlags {
  static const bool enableMaps = true;
  static const bool enableVideos = true;
  static const bool enableShop = true;
  static const bool enableNotifications = false;
}
