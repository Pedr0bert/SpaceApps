import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherProbabilityData {
  final double precip;
  final double temperature;
  final double wind;
  final String message;
  final double veryColdProbability;
  final double veryHotProbability;
  final double veryWetProbability;
  final double veryWindyProbability;
  final String qualityMessage;

  WeatherProbabilityData({
    required this.precip,
    required this.temperature,
    required this.wind,
    required this.message,
    required this.veryColdProbability,
    required this.veryHotProbability,
    required this.veryWetProbability,
    required this.veryWindyProbability,
    required this.qualityMessage,
  });

  factory WeatherProbabilityData.fromJson(Map<String, dynamic> json) {
    try {
      return WeatherProbabilityData(
        precip: (json['averages']?['precip'] as num? ?? 0.0).toDouble(),
        temperature: (json['averages']?['temperature'] as num? ?? 0.0)
            .toDouble(),
        wind: (json['averages']?['wind'] as num? ?? 0.0).toDouble(),
        message: json['message'] as String,
        veryColdProbability:
            (json['probabilities']?['very_cold'] as num? ?? 0.0).toDouble(),
        veryHotProbability: (json['probabilities']?['very_hot'] as num? ?? 0.0)
            .toDouble(),
        veryWetProbability: (json['probabilities']?['very_wet'] as num? ?? 0.0)
            .toDouble(),
        veryWindyProbability:
            (json['probabilities']?['very_windy'] as num? ?? 0.0).toDouble(),
        qualityMessage: json['quality_message'] as String,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class WeatherService {
  final String _baseUrl = 'https://weather-api-8p82.onrender.com';

  Future<WeatherProbabilityData> getWeatherProbability({
    required double latitude,
    required double longitude,
    required String date,
  }) async {
    final url = Uri.parse('$_baseUrl/weather_probability');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'date': date,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        return WeatherProbabilityData.fromJson(json.decode(responseBody));
      } else {
        throw Exception(
          'Failed to load weather probability: ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
