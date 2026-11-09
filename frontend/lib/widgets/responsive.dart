import 'package:flutter/material.dart';

class Responsive {
  /// Lebar minimum layar yang dianggap desktop
  static const double desktop = 900;

  /// Lebar maksimum isi halaman di desktop
  static const double maxContent = 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}