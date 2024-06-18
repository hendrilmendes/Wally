import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:projectx/api/api.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _weatherData = '';
  String _cityName = '';
  bool _isLoading = true;  // Indica se está carregando

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
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
        _getWeatherData(_cityName);
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

  Future<void> _getWeatherData(String cityName) async {
    try {
      if (kDebugMode) {
        print('Fetching weather data for city: $cityName');
      }
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&units=metric&appid=$apiKeyWearth'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _weatherData = '''
City: $cityName
Description: ${jsonData['weather'][0]['description']}
Temperature: ${jsonData['main']['temp']}°C
Humidity: ${jsonData['main']['humidity']}%
Wind Speed: ${jsonData['wind']['speed']} m/s
          ''';
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _weatherData = 'Error: The requested resource was not found.';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Weather data not found for city: $cityName');
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${AppLocalizations.of(context)!.weather} $_cityName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_weatherData),
              ],
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
