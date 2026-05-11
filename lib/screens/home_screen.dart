import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/weather_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController cityController = TextEditingController();
  final WeatherService weatherService = WeatherService();

  String city = '';
  String temperature = '';
  String weather = '';
  String description = '';

  Future<void> searchWeather() async {
    try {
      final data = await weatherService.getWeather(cityController.text);
      setState(() {
        city = data['city'];
        temperature = data['temp'].toString();
        weather = data['weather'];
        description = data['description'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kota tidak ditemukan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('Weather App', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Halo, ${user?.email ?? 'User'}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Search bar
            TextField(
              controller: cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: searchWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cari Cuaca',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),

            // Animasi + info cuaca
            if (city.isNotEmpty) ...[
              WeatherAnimation(weatherType: weather),
              const SizedBox(height: 20),
              Text(city,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$temperature°C',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 50)),
              Text(weather,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24)),
              Text(description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Widget Animasi ───────────────────────────────────────────────

class WeatherAnimation extends StatefulWidget {
  final String weatherType;
  const WeatherAnimation({super.key, required this.weatherType});

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.weatherType.toLowerCase();

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (type.contains('rain') || type.contains('drizzle')) {
            return CustomPaint(painter: RainPainter(_controller.value));
          } else if (type.contains('thunder') || type.contains('storm')) {
            return CustomPaint(painter: ThunderPainter(_controller.value));
          } else if (type.contains('cloud')) {
            return CustomPaint(painter: CloudPainter(_controller.value));
          } else if (type.contains('mist') ||
              type.contains('fog') ||
              type.contains('haze') ||
              type.contains('smoke')) {
            return CustomPaint(painter: MistPainter(_controller.value));
          } else {
            // Clear / sunny
            return CustomPaint(painter: SunPainter(_controller.value));
          }
        },
      ),
    );
  }
}

// ─── Sun Painter ─────────────────────────────────────────────────

class SunPainter extends CustomPainter {
  final double progress;
  SunPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = Colors.amber;

    // Sinar berputar
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (progress * 2 * pi);
      final x1 = cx + 38 * cos(angle);
      final y1 = cy + 38 * sin(angle);
      final x2 = cx + 55 * cos(angle);
      final y2 = cy + 55 * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // Bola matahari
    canvas.drawCircle(Offset(cx, cy), 30, paint);
  }

  @override
  bool shouldRepaint(SunPainter old) => old.progress != progress;
}

// ─── Rain Painter ─────────────────────────────────────────────────

class RainPainter extends CustomPainter {
  final double progress;
  final List<_Drop> drops;

  RainPainter(this.progress)
      : drops = List.generate(
            20,
            (i) => _Drop(
                  x: (i * 37.3) % 1.0,
                  offset: (i * 0.17) % 1.0,
                ));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final y = ((progress + drop.offset) % 1.0) * size.height;
      final x = drop.x * size.width;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), paint);
    }
  }

  @override
  bool shouldRepaint(RainPainter old) => old.progress != progress;
}

class _Drop {
  final double x;
  final double offset;
  _Drop({required this.x, required this.offset});
}

// ─── Thunder Painter ──────────────────────────────────────────────

class ThunderPainter extends CustomPainter {
  final double progress;
  ThunderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Hujan
    RainPainter(progress).paint(canvas, size);

    // Kilat (muncul tiap 0.6 progress)
    if (progress > 0.6) {
      final paint = Paint()
        ..color = Colors.yellowAccent.withOpacity((progress - 0.6) * 2.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final cx = size.width / 2;
      final path = Path()
        ..moveTo(cx, 20)
        ..lineTo(cx - 12, 70)
        ..lineTo(cx + 4, 70)
        ..lineTo(cx - 8, 130);

      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.yellowAccent.withOpacity((progress - 0.6) * 2.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(ThunderPainter old) => old.progress != progress;
}

// ─── Cloud Painter ────────────────────────────────────────────────

class CloudPainter extends CustomPainter {
  final double progress;
  CloudPainter(this.progress);

  void _drawCloud(Canvas canvas, Offset center, double scale, Color color) {
    final paint = Paint()..color = color;
    final r = 22.0 * scale;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center.translate(-r * 0.8, r * 0.3), r * 0.8, paint);
    canvas.drawCircle(center.translate(r * 0.8, r * 0.3), r * 0.8, paint);
    canvas.drawCircle(center.translate(0, r * 0.6), r * 1.1, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final offset = sin(progress * 2 * pi) * 10;

    _drawCloud(canvas, Offset(size.width * 0.35 + offset, 60), 1.0,
        Colors.white60);
    _drawCloud(canvas, Offset(size.width * 0.65 - offset * 0.5, 90), 0.75,
        Colors.white38);
  }

  @override
  bool shouldRepaint(CloudPainter old) => old.progress != progress;
}

// ─── Mist Painter ────────────────────────────────────────────────

class MistPainter extends CustomPainter {
  final double progress;
  MistPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final lines = [0.3, 0.5, 0.7];
    for (int i = 0; i < lines.length; i++) {
      final y = lines[i] * size.height;
      final shift = sin((progress + i * 0.3) * 2 * pi) * 15;
      paint.color = Colors.white.withOpacity(0.25 + i * 0.1);
      canvas.drawLine(
        Offset(20 + shift, y),
        Offset(size.width - 20 + shift, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MistPainter old) => old.progress != progress;
}