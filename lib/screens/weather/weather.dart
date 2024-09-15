import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  String _weatherData = '';
  String _cityName = '';
  String _weatherDescription = '';
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _weatherData = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _weatherData = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _weatherData = 'Location permission denied forever';
          _isLoading = false;
        });
        return;
      }

      _getLocation();
    } catch (e) {
      setState(() {
        _weatherData = 'Error: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      _getCityNameFromLocation(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _weatherData = 'Error: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
  }

  Future<void> _getCityNameFromLocation(
      double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (kDebugMode) {
          print('Geolocation JSON: $jsonData');
        }
        String cityName;
        if (jsonData['address']['city'] != null) {
          cityName = jsonData['address']['city'];
        } else if (jsonData['address']['town'] != null) {
          cityName = jsonData['address']['town'];
        } else if (jsonData['address']['village'] != null) {
          cityName = jsonData['address']['village'];
        } else {
          cityName = 'Unknown';
        }

        cityName = cityName.trim();
        if (kDebugMode) {
          print('City name before fetching weather data: $cityName');
        }

        setState(() {
          _cityName = cityName;
        });
        _getWeatherData(latitude, longitude);
      } else {
        setState(() {
          _weatherData = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Error getting city name: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() {
        _weatherData = 'Error: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error getting city name from location: $e');
      }
    }
  }

  Future<void> _getWeatherData(double latitude, double longitude) async {
    try {
      String apiUrl =
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&timezone=auto';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData != null && jsonData['current_weather'] != null) {
          final weatherData = jsonData['current_weather'];
          final temperature = (weatherData['temperature'] ?? 0).toInt();
          final weatherCode = weatherData['weathercode'] ?? 0;
          final weatherDescription = _getWeatherDescription(weatherCode);
          setState(() {
            _weatherData = '$temperature°C';
            _weatherDescription = weatherDescription;
            _isLoading = false;
          });
          _controller.forward();
        } else {
          setState(() {
            _weatherData = 'Error: No weather data found';
            _isLoading = false;
          });
          if (kDebugMode) {
            print('Error: No weather data found in the response');
          }
        }
      } else {
        setState(() {
          _weatherData = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Error fetching weather data: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is HttpException) {
        setState(() {
          _weatherData = 'Error: ${e.message}';
        });
      } else {
        setState(() {
          _weatherData = 'Error: $e';
        });
      }
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error getting weather data: $e');
      }
    }
  }

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
    if (weatherDescription.contains('Chuva') ||
        weatherDescription.contains('Chuvisco')) {
      return 'Está chovendo! Perfeito para assistir a um filme com pipoca ou fazer uma sopa quentinha. Não se esqueça do guarda-chuva!';
    } else if (weatherDescription.contains('Céu limpo')) {
      return 'O céu está limpo e o sol está brilhando! Use protetor solar e aproveite um sorvete ou um picnic no parque.';
    } else if (weatherDescription.contains('Nublado') ||
        weatherDescription.contains('Nevoeiro')) {
      return 'Está nublado. Que tal um café quentinho e um bom livro? Fique de olho, o tempo pode mudar a qualquer momento.';
    } else if (weatherDescription.contains('Neve')) {
      return 'Neve! Hora de um chocolate quente e construir um boneco de neve. Não se esqueça do casaco!';
    } else if (weatherDescription.contains('Trovoada')) {
      return 'Trovoada à vista! Melhor ficar em casa e jogar um jogo de tabuleiro. Evite áreas abertas e árvores.';
    } else {
      return 'Talvez seja um bom momento para inventar uma nova receita na cozinha!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.weather),
        backgroundColor: _getGradientColor(_weatherDescription).colors.first,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _getGradientColor(_weatherDescription),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FadeTransition(
                opacity: _animation,
                child: Icon(
                  _getWeatherIcon(_weatherDescription),
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              Text(
                '${AppLocalizations.of(context)!.weatherTo} $_cityName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _weatherData,
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                ),
              ),
              Text(
                _weatherDescription,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (!_isLoading)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getPreventionRecommendation(_weatherDescription),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientColor(String weatherDescription) {
    switch (weatherDescription) {
      case 'Céu limpo':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.lightBlueAccent],
        );
      case 'Chuva':
      case 'Chuvisco':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey, Colors.blueGrey],
        );
      case 'Neve':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey, Colors.white],
        );
      case 'Trovoada':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.grey],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey, Colors.white],
        );
    }
  }
}

IconData _getWeatherIcon(String weatherDescription) {
  if (weatherDescription.contains('Céu limpo')) {
    return WeatherIcons.day_sunny;
  } else if (weatherDescription.contains('Chuva') ||
      weatherDescription.contains('Chuvisco')) {
    return WeatherIcons.rain;
  } else if (weatherDescription.contains('Nublado') ||
      weatherDescription.contains('Nevoeiro')) {
    return WeatherIcons.cloud;
  } else if (weatherDescription.contains('Neve')) {
    return WeatherIcons.snow;
  } else if (weatherDescription.contains('Trovoada')) {
    return WeatherIcons.thunderstorm;
  } else {
    return WeatherIcons.cloudy;
  }
}
