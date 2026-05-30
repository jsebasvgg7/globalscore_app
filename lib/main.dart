import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlobalScore',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int puntos = 0; // como useState(0) en React

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚽ GlobalScore',
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            SizedBox(height: 16),
            Text(
              'Puntos: $puntos',
              style: TextStyle(color: Colors.amber, fontSize: 24),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  puntos += 5; // como setPuntos(puntos + 5)
                });
              },
              child: Text('Predije bien (+5 pts)'),
            ),
          ],
        ),
      ),
    );
  }
}