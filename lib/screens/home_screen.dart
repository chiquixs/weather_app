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
  String feelsLike = '';
  bool isLoading = false;

  Future<void> searchWeather() async {
    if (cityController.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final data = await weatherService.getWeather(cityController.text);
      setState(() {
        city = data['city'];
        temperature = data['temp'].toString();
        weather = data['weather'];
        description = data['description'];
        feelsLike = data['feelsLike'].toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kota tidak ditemukan')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Background gradient berdasarkan cuaca
  List<Color> _bgColors() {
    final w = weather.toLowerCase();
    if (w.contains('rain') || w.contains('drizzle')) {
      return [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)];
    } else if (w.contains('thunder') || w.contains('storm')) {
      return [const Color(0xFF0d0d0d), const Color(0xFF1a1a2e), const Color(0xFF2d1b69)];
    } else if (w.contains('cloud')) {
      return [const Color(0xFF2C3E50), const Color(0xFF3D5A73), const Color(0xFF4A6FA5)];
    } else if (w.contains('clear')) {
      return [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f4c75)];
    } else {
      return [const Color(0xFF1E3A5F), const Color(0xFF16213e), const Color(0xFF0f3460)];
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
  body: Stack(
    children: [
      // ✅ gradient memenuhi seluruh layar termasuk area putih
      SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _bgColors(),
            ),
          ),
        ),
      ),
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UrWeather',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  _glassButton(
                    icon: Icons.logout_rounded,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Search Bar ───────────────────────────
              _GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Cari kota...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => searchWeather(),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white54),
                      )
                    else
                      GestureDetector(
                        onTap: searchWeather,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Cari',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Weather Card ─────────────────────────
              if (city.isNotEmpty) ...[
                _GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Animasi
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: WeatherAnimation(weatherType: weather),
                      ),
                      const SizedBox(height: 16),

                      // Nama kota
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          Text(city,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Suhu besar
                      Text('$temperature°',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontWeight: FontWeight.w200,
                              height: 1)),
                      const SizedBox(height: 4),

                      // Deskripsi
                      Text(
                        description.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 24),

                      // ── Feels Like ───────────────────
                      _GlassCard(
                        color: Colors.white.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.thermostat_rounded,
                                  color: Colors.orangeAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Terasa Seperti',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12)),
                                Text('$feelsLike°C',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ] else ...[
                // ── Empty state ──────────────────────
                _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('Cari kota untuk melihat cuaca',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],

              // ✅ biar background penuh ke bawah
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ],
          ),
        ),
      ),
    ],
    ),
  );
}

  Widget _glassButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

// ── Glass Card Widget ─────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const _GlassCard({required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Weather Animation (sama seperti sebelumnya) ───────────────────

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (type.contains('rain') || type.contains('drizzle')) {
          return CustomPaint(painter: RainPainter(_controller.value));
        } else if (type.contains('thunder') || type.contains('storm')) {
          return CustomPaint(painter: ThunderPainter(_controller.value));
        } else if (type.contains('cloud')) {
          return CustomPaint(painter: CloudPainter(_controller.value));
        } else if (type.contains('mist') || type.contains('fog') || type.contains('haze')) {
          return CustomPaint(painter: MistPainter(_controller.value));
        } else {
          return CustomPaint(painter: SunPainter(_controller.value));
        }
      },
    );
  }
}

class SunPainter extends CustomPainter {
  final double progress;
  SunPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (progress * 2 * pi);
      canvas.drawLine(
        Offset(cx + 38 * cos(angle), cy + 38 * sin(angle)),
        Offset(cx + 55 * cos(angle), cy + 55 * sin(angle)),
        rayPaint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), 30, Paint()..color = Colors.amber);
  }
  @override
  bool shouldRepaint(SunPainter old) => old.progress != progress;
}

class RainPainter extends CustomPainter {
  final double progress;
  RainPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 20; i++) {
      final x = (i * 37.3) % size.width;
      final y = ((progress + (i * 0.17)) % 1.0) * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), paint);
    }
  }
  @override
  bool shouldRepaint(RainPainter old) => old.progress != progress;
}

class ThunderPainter extends CustomPainter {
  final double progress;
  ThunderPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    RainPainter(progress).paint(canvas, size);
    if (progress > 0.6) {
      final opacity = (progress - 0.6) * 2.5;
      final path = Path()
        ..moveTo(size.width / 2, 10)
        ..lineTo(size.width / 2 - 12, 60)
        ..lineTo(size.width / 2 + 4, 60)
        ..lineTo(size.width / 2 - 8, 120);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.yellowAccent.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }
  @override
  bool shouldRepaint(ThunderPainter old) => old.progress != progress;
}

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
    _drawCloud(canvas, Offset(size.width * 0.35 + offset, 60), 1.0, Colors.white60);
    _drawCloud(canvas, Offset(size.width * 0.65 - offset * 0.5, 90), 0.75, Colors.white38);
  }
  @override
  bool shouldRepaint(CloudPainter old) => old.progress != progress;
}

class MistPainter extends CustomPainter {
  final double progress;
  MistPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 8..strokeCap = StrokeCap.round;
    final lines = [0.3, 0.5, 0.7];
    for (int i = 0; i < lines.length; i++) {
      final y = lines[i] * size.height;
      final shift = sin((progress + i * 0.3) * 2 * pi) * 15;
      paint.color = Colors.white.withOpacity(0.25 + i * 0.1);
      canvas.drawLine(Offset(20 + shift, y), Offset(size.width - 20 + shift, y), paint);
    }
  }
  @override
  bool shouldRepaint(MistPainter old) => old.progress != progress;
}