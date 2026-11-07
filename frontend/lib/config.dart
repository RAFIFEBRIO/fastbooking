import 'package:flutter/foundation.dart';

class AppConfig {
  // Chrome memakai localhost, emulator Android memakai 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String mejaImage(String file) => 'assets/images/meja/$file';
  static String menuImage(String file) => 'assets/images/menu/$file';
  static String paketImage(String file) => 'assets/images/paket/$file';

  // Kategori Paket ada di folder paket, selain itu di folder menu
  static String menuItemImage(String category, String file) =>
      category == 'Paket' ? paketImage(file) : menuImage(file);
}