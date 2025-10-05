import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String iconType;
  final double size;

  const WeatherIcon({super.key, required this.iconType, this.size = 50});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (iconType) {
      case 'sunny':
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case 'partly_cloudy':
        iconData = Icons.wb_cloudy;
        iconColor = const Color(0xFF87CEEB);
        break;
      case 'cloudy':
        iconData = Icons.cloud;
        iconColor = const Color(0xFF708090);
        break;
      case 'overcast':
        iconData = Icons.cloud_circle;
        iconColor = const Color(0xFF696969);
        break;
      case 'light_rain':
        iconData = Icons.grain;
        iconColor = const Color(0xFF4A90E2);
        break;
      case 'rain':
        iconData = Icons.cloud_queue;
        iconColor = const Color(0xFF4A90E2);
        break;
      case 'showers':
        iconData = Icons.shower;
        iconColor = const Color(0xFF4169E1);
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on;
        iconColor = const Color(0xFF8B008B);
        break;
      case 'clear':
        iconData = Icons.wb_sunny_outlined;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.cloud_queue;
        iconColor = const Color(0xFF4A90E2);
    }

    return Icon(iconData, size: size, color: iconColor);
  }
}

class WeatherData {
  final String temperature;
  final String probability;
  final String description;
  final String iconType;
  final String city;
  final String state;
  final String country;
  final String date;

  WeatherData({
    required this.temperature,
    required this.probability,
    required this.description,
    required this.iconType,
    required this.city,
    required this.state,
    required this.country,
    required this.date,
  });
}
