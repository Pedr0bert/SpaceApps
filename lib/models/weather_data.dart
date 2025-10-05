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

  static WeatherData getMockData(
    String city,
    String state,
    String country,
    String date,
  ) {
    final Map<String, Map<String, String>> mockWeatherData = {
      'são paulo': {
        'temperature': '23°C',
        'probability': '75%',
        'description': 'Heavy rain',
        'iconType': 'rain',
      },
      'rio de janeiro': {
        'temperature': '28°C',
        'probability': '30%',
        'description': 'Partly cloudy',
        'iconType': 'partly_cloudy',
      },
      'brasília': {
        'temperature': '26°C',
        'probability': '10%',
        'description': 'Sunny',
        'iconType': 'sunny',
      },
      'salvador': {
        'temperature': '30°C',
        'probability': '45%',
        'description': 'Light rain',
        'iconType': 'light_rain',
      },
      'fortaleza': {
        'temperature': '32°C',
        'probability': '20%',
        'description': 'Clear sky',
        'iconType': 'clear',
      },
      'belo horizonte': {
        'temperature': '24°C',
        'probability': '60%',
        'description': 'Moderate rain',
        'iconType': 'rain',
      },
      'manaus': {
        'temperature': '31°C',
        'probability': '80%',
        'description': 'Thunderstorm',
        'iconType': 'thunderstorm',
      },
      'curitiba': {
        'temperature': '19°C',
        'probability': '55%',
        'description': 'Cloudy',
        'iconType': 'cloudy',
      },
      'porto alegre': {
        'temperature': '21°C',
        'probability': '40%',
        'description': 'Overcast',
        'iconType': 'overcast',
      },
      'recife': {
        'temperature': '29°C',
        'probability': '65%',
        'description': 'Scattered showers',
        'iconType': 'showers',
      },
    };

    final cityKey = city.toLowerCase().trim();
    final weatherInfo =
        mockWeatherData[cityKey] ??
        {
          'temperature': '25°C',
          'probability': '60%',
          'description': 'Moderate rain',
          'iconType': 'rain',
        };

    return WeatherData(
      temperature: weatherInfo['temperature']!,
      probability: weatherInfo['probability']!,
      description: weatherInfo['description']!,
      iconType: weatherInfo['iconType']!,
      city: city,
      state: state,
      country: country,
      date: date,
    );
  }
}
