import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:projectx/api/api.dart';

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
        _getLocationKey(latitude, longitude);
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

  Future<void> _getLocationKey(double latitude, double longitude) async {
    try {
      String apiUrl =
          'https://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=$apiKeyWearth&q=$latitude,$longitude';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData != null && jsonData['Key'] != null) {
          String locationKey = jsonData['Key'];
          _getWeatherData(locationKey);
        } else {
          setState(() {
            _weatherData = 'Error: No location key found';
            _isLoading = false;
          });
          if (kDebugMode) {
            print('Error: No location key found in the response');
          }
        }
      } else {
        setState(() {
          _weatherData = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Error getting location key: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() {
        _weatherData = 'Error: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error getting location key: $e');
      }
    }
  }

  Future<void> _getWeatherData(String locationKey) async {
    try {
      String apiUrl =
          'https://dataservice.accuweather.com/currentconditions/v1/$locationKey?apikey=$apiKeyWearth';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData != null && jsonData.isNotEmpty) {
          final weatherData = jsonData[0];
          setState(() {
            _weatherData = '''
${AppLocalizations.of(context)!.description}: ${weatherData['WeatherText'] ?? 'N/A'}
${AppLocalizations.of(context)!.temperature}: ${weatherData['Temperature']['Metric']['Value'] ?? 'N/A'}°C
${AppLocalizations.of(context)!.humidity}: ${weatherData['RelativeHumidity'] ?? 'N/A'}%
${AppLocalizations.of(context)!.windSpeed}: ${weatherData['Wind']?['Speed']?['Metric']?['Value'] ?? 'N/A'} m/s
            ''';
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
      } else if (response.statusCode == 404) {
        setState(() {
          _weatherData = 'Error: The requested resource was not found.';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Weather data not found for location key: $locationKey');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.weather),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FadeTransition(
              opacity: _animation,
              child: const Icon(
                Icons.cloud,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)!.weatherTo} $_cityName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _weatherData,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
