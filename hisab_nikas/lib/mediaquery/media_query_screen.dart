import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  // স্ক্রিনের মোট Width এবং Height
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  // Aspect Ratio (প্রস্থ এবং উচ্চতার অনুপাত)
  double get aspectRatio => MediaQuery.of(context).size.aspectRatio;

  // Screen Orientation
  Orientation get orientation => MediaQuery.of(context).orientation;

  // স্ক্রিন ওরিয়েন্টেশন (Portrait / Landscape)
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  // Device Type
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  // Responsive Padding
  double get horizontalPadding => isMobile ? 12 : isTablet ? 20 : 24;

  // Responsive Font Size
  double get titleFontSize => isMobile ? 22 : isTablet ? 28 : 32;
}