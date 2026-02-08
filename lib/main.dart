import 'package:flutter/material.dart';
import 'package:flutter_studio/pages/home_page.dart';
import 'package:sonner_toast/sonner_toast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      builder: (context, child) {
        return Stack(
          children: [
            child!,
            SonnerOverlay(
              key: Sonner.overlayKey,
              config: const SonnerConfig(
                width: 250,
                alignment: Alignment.bottomRight, 
                expandedSpacing: 10.0,
                collapsedOffset: 13.0,
                maxVisibleToasts: 4,
              ),
            ),
          ],
        );
      },
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF414A4C),
          secondary: Color(0xFF3B444B),
          surface: Color(0xFF232B2B),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        /*fontFamily: "NeoFolia",*/
        scaffoldBackgroundColor: const Color(0xFF232B2B),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), 
            elevation: 0, 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              // fontFamily: "NeoFolia",
              fontWeight: FontWeight.bold,
            ),
            foregroundColor: Colors.white, 
            backgroundColor: Colors.transparent, 
            side: const BorderSide(
              color: Colors.white,
              width: 1.5,
            ), 
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, 
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white, 
            side: const BorderSide(
              color: Colors.white,
              width: 1.5,
            ), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
       
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white, 
          unselectedLabelColor:
              Colors.white70, 
          indicator: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.yellow, width: 2)),
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            // fontFamily: "NeoFolia",
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            // fontFamily: "NeoFolia",
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF232B2B),
          elevation: 4,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const HomePage(),
    );
  }
}
