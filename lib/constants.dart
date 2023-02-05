import 'package:flutter/material.dart';

bool IS_PREMIUM = false;
String ALBUM_NAME = "TheseDays";
bool IS_TEST = false;

// ON OFF button
Color btnOn = Colors.white;
Color btnNg = Colors.grey;
Color btnNl = Colors.white;

ThemeData myTheme = myDarkTheme;

/// e.g.
/// - myTheme.backgroundColor
/// - myTheme.cardColor
/// - myTheme.textTheme.bodyMedium (size 14)
/// - myTheme.textTheme.titleMedium (size 16)
ThemeData myDarkTheme = ThemeData.dark().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  backgroundColor: Color(0xFF000000),
  scaffoldBackgroundColor: Color(0xFF000000),
  canvasColor: Color(0xFF333333),
  cardColor: Color(0xFF333333),
  primaryColor: Color(0xFF333333),
  primaryColorDark: Color(0xFF333333),
  dividerColor: Color(0xFF555555),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Color(0xFFffffff))),
  ),
);

// Swipe to cancel. From left to right.
class MyPageTransitionsTheme extends PageTransitionsTheme {
  const MyPageTransitionsTheme();
  static const PageTransitionsBuilder builder = CupertinoPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return builder.buildTransitions<T>(route, context, animation, secondaryAnimation, child);
  }
}
