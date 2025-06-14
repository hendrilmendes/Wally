// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// --- DATA MODELS (Modelos de Dados) ---
class WeatherData {
  final String cityName;
  final int temperature;
  final String description;
  final int weatherCode;
  final int humidity;
  final double windSpeed;
  final List<HourlyForecast> hourlyForecast;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.hourlyForecast,
  });
}

class HourlyForecast {
  final DateTime time;
  final int temperature;
  final int weatherCode;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });
}

// --- API SERVICE (Serviço de busca de dados) ---
class WeatherService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse?format=json';
  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> getWeatherForCurrentLocation() async {
    Position position = await _determinePosition();

    final reverseGeocodingResponse = await http.get(
      Uri.parse('$_nominatimUrl&lat=${position.latitude}&lon=${position.longitude}'),
    );
    if (reverseGeocodingResponse.statusCode != 200) {
      throw Exception('Falha ao obter o nome da cidade');
    }

    final geoJson = jsonDecode(reverseGeocodingResponse.body);
    String cityName = geoJson['address']?['city'] ?? geoJson['address']?['town'] ?? geoJson['address']?['village'] ?? 'Local Desconhecido';

    final weatherResponse = await http.get(
      Uri.parse(
        '$_openMeteoUrl?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true&hourly=temperature_2m,weathercode,relativehumidity_2m&current=windspeed_10m&timezone=auto',
      ),
    );
    if (weatherResponse.statusCode != 200) {
      throw Exception('Falha ao carregar os dados do clima');
    }

    final weatherJson = jsonDecode(weatherResponse.body);
    final currentWeather = weatherJson['current_weather'];
    final hourlyData = weatherJson['hourly'];

    List<HourlyForecast> forecasts = [];
    List<String> times = List<String>.from(hourlyData['time']);
    List<num> temps = List<num>.from(hourlyData['temperature_2m']);
    List<int> codes = List<int>.from(hourlyData['weathercode']);
    List<num> humidities = List<num>.from(hourlyData['relativehumidity_2m']);

    for (int i = 0; i < times.length; i++) {
      DateTime forecastTime = DateTime.parse(times[i]);
      if (forecastTime.isAfter(DateTime.now())) {
        forecasts.add(
          HourlyForecast(
            time: forecastTime,
            temperature: temps[i].toDouble().round(),
            weatherCode: codes[i],
          ),
        );
        if (forecasts.length >= 24) break;
      }
    }

    int currentHourIndex = times.indexWhere((time) {
      final parsedTime = DateTime.parse(time);
      return parsedTime.year == DateTime.now().year &&
          parsedTime.month == DateTime.now().month &&
          parsedTime.day == DateTime.now().day &&
          parsedTime.hour == DateTime.now().hour;
    });
    if (currentHourIndex == -1) currentHourIndex = 0;

    return WeatherData(
      cityName: cityName,
      temperature: (currentWeather['temperature'] as num).toDouble().round(),
      weatherCode: currentWeather['weathercode'] as int,
      description: _getWeatherDescription(currentWeather['weathercode'] as int),
      humidity: humidities[currentHourIndex].toInt(),
      windSpeed: (currentWeather['windspeed'] as num).toDouble(),
      hourlyForecast: forecasts,
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviços de localização desativados.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }
    return await Geolocator.getCurrentPosition();
  }
}

// --- WIDGET DA TELA DE CLIMA (ADAPTÁVEL AO TEMA) ---
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  Future<WeatherData>? _weatherDataFuture;
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fetchWeather();
  }

  void _fetchWeather() {
    setState(() {
      _weatherDataFuture = _weatherService.getWeatherForCurrentLocation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Container(
        // Fundo em gradiente para dar base ao efeito de vidro
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: FutureBuilder<WeatherData>(
          future: _weatherDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text("Erro: ${snapshot.error}", textAlign: TextAlign.center),
                ),
              );
            }
            if (snapshot.hasData) {
              _slideController.forward(from: 0.0);
              return _buildWeatherUI(snapshot.data!);
            }
            return const Center(child: Text("Sem dados."));
          },
        ),
      ),
    );
  }

  Widget _buildWeatherUI(WeatherData data) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeroSection(data),
          _buildDetailsPanel(data),
        ],
      ),
    );
  }

  Widget _buildHeroSection(WeatherData data) {
    final theme = Theme.of(context);
    return Expanded(
      flex: 5,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: WeatherAnimationPainter(_animationController, data.description),
                size: const Size.square(150),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.cityName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${data.temperature}°',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                height: 1.2,
              ),
            ),
            Text(
              data.description,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(WeatherData data) {
    return Expanded(
      flex: 6,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Previsão",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildHourlyChart(data.hourlyForecast),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildInfoTile(WeatherIcons.strong_wind, 'Vento', '${data.windSpeed} km/h')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInfoTile(WeatherIcons.humidity, 'Umidade', '${data.humidity}%')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        Icons.lightbulb_outline_rounded,
                        "Recomendação",
                        _getPreventionRecommendation(data.description),
                        isRecommendation: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {bool isRecommendation = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isRecommendation ? 16 : 22,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(List<HourlyForecast> forecasts) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    final spots = forecasts.asMap().entries.map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.temperature.toDouble()),
        ).toList();
    final minTemp = forecasts.map((e) => e.temperature).reduce(min);
    final maxTemp = forecasts.map((e) => e.temperature).reduce(max);

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < forecasts.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('HH:mm').format(forecasts[index].time),
                        style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.7)),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: (minTemp - 3).toDouble(),
          maxY: (maxTemp + 3).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.4), primaryColor.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASSE DE ANIMAÇÃO PERSONALIZADA ---
class WeatherAnimationPainter extends CustomPainter {
  final Animation<double> animation;
  final String weatherDescription;
  WeatherAnimationPainter(this.animation, this.weatherDescription) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (weatherDescription.contains('Céu limpo')) {
      _drawSun(canvas, size, center);
    } else if (weatherDescription.contains('Chuva') || weatherDescription.contains('Chuvisco')) {
      _drawCloud(canvas, size, center, isRaining: true);
    } else {
      _drawCloud(canvas, size, center);
    }
  }

  void _drawSun(Canvas canvas, Size size, Offset center) {
    final paint = Paint()..color = Colors.yellow.shade700;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation.value * 2 * pi);
    canvas.translate(-center.dx, -center.dy);
    for (int i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * pi / 4);
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.35, -size.height * 0.02, size.width * 0.25, size.height * 0.04),
        paint..color = Colors.yellow.withOpacity(0.8),
      );
      canvas.restore();
    }
    canvas.drawCircle(center, size.width * 0.3, paint..color = Colors.yellow.shade700);
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, Size size, Offset center, {bool isRaining = false}) {
    final paint = Paint()..color = Colors.grey.shade300;
    final path = Path()
      ..moveTo(size.width * 0.2, center.dy + size.height * 0.1)
      ..cubicTo(size.width * 0.1, center.dy + size.height * 0.1, size.width * 0.1, center.dy - size.height * 0.2, size.width * 0.4, center.dy - size.height * 0.1)
      ..cubicTo(size.width * 0.5, center.dy - size.height * 0.3, size.width * 0.8, center.dy - size.height * 0.2, size.width * 0.8, center.dy)
      ..cubicTo(size.width, center.dy, size.width, center.dy + size.height * 0.1, size.width * 0.8, center.dy + size.height * 0.1)
      ..close();
    canvas.drawPath(path, paint..color = Colors.white.withOpacity(0.8));
    if (isRaining) {
      final rainPaint = Paint()
        ..color = Colors.blue.shade200
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 6; i++) {
        final progress = (animation.value + (i * 0.15)) % 1.0;
        final startX = size.width * 0.3 + (i * size.width * 0.1);
        final startY = center.dy + size.height * 0.15;
        final currentY = startY + progress * size.height * 0.25;
        canvas.drawLine(Offset(startX, currentY - 8), Offset(startX, currentY), rainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- FUNÇÕES DE APOIO ---
String _getWeatherDescription(int weatherCode) {
  switch (weatherCode) {
    case 0:
      return 'Céu limpo';
    case 1:
    case 2:
    case 3:
      return 'Parcialmente nublado';
    case 45:
    case 48:
      return 'Nevoeiro';
    case 51:
    case 53:
    case 55:
      return 'Chuvisco';
    case 61:
    case 63:
    case 65:
      return 'Chuva';
    case 71:
    case 73:
    case 75:
      return 'Neve';
    case 95:
      return 'Trovoada';
    default:
      return 'Desconhecido';
  }
}

String _getPreventionRecommendation(String weatherDescription) {
  if (weatherDescription.contains('Chuva') || weatherDescription.contains('Chuvisco')) {
    return 'Leve um guarda-chuva! Perfeito para uma maratona de séries.';
  }
  if (weatherDescription.contains('Céu limpo')) {
    return 'Dia de sol! Não esqueça o protetor solar e se hidrate.';
  }
  if (weatherDescription.contains('Nublado') || weatherDescription.contains('Nevoeiro')) {
    return 'Tempo nublado. Um bom livro e uma bebida quente são uma ótima pedida.';
  }
  if (weatherDescription.contains('Neve')) {
    return 'Neve à vista! Se agasalhe bem e aproveite um chocolate quente.';
  }
  if (weatherDescription.contains('Trovoada')) {
    return 'Trovoadas! Fique em um lugar seguro e evite áreas abertas.';
  }
  return 'Verifique o tempo e se prepare para qualquer mudança!';
}
