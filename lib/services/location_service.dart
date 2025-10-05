import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String _baseUrl = "https://countriesnow.space/api/v0.1";

  Future<List<Map<String, String>>> getCountries() async {
    final url = Uri.parse('$_baseUrl/countries');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> countries = data['data'];
        return countries
            .map(
              (country) => {
                'iso2': country['iso2'].toString(),
                'name': country['country'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getStatesOfCountry(
    String countryIso2,
  ) async {
    try {
      final countries = await getCountries();
      final country = countries.firstWhere(
        (c) => c['iso2'] == countryIso2,
        orElse: () => {'name': '', 'iso2': ''},
      );

      if (country['name']!.isEmpty) {
        return [];
      }

      final countryName = country['name']!;
      final url = Uri.parse(
        '$_baseUrl/countries/states/q?country=$countryName',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['error'] == true) {
          return [];
        }

        if (data['data'] != null && data['data']['states'] != null) {
          List<dynamic> states = data['data']['states'];
          return states
              .map(
                (state) => {
                  'iso2':
                      state['state_code']?.toString() ??
                      state['name']?.toString() ??
                      '',
                  'name': state['name'].toString(),
                },
              )
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load states - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getCitiesOfState(
    String countryIso2,
    String stateIso2,
  ) async {
    try {
      final countries = await getCountries();
      final country = countries.firstWhere(
        (c) => c['iso2'] == countryIso2,
        orElse: () => {'name': '', 'iso2': ''},
      );

      if (country['name']!.isEmpty) {
        return [];
      }
      final countryName = country['name']!;

      final states = await getStatesOfCountry(countryIso2);
      final state = states.firstWhere(
        (s) => s['iso2'] == stateIso2,
        orElse: () => {'name': '', 'iso2': ''},
      );

      if (state['name']!.isEmpty) {
        return [];
      }
      final stateName = state['name']!;

      final url = Uri.parse(
        '$_baseUrl/countries/state/cities/q?country=$countryName&state=$stateName',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['error'] == true) {
          return [];
        }

        if (data['data'] != null) {
          List<dynamic> cities = data['data'];
          return cities.map((city) => city.toString()).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load cities - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, double>?> getCityCoordinates(String cityName) async {
    final baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
    final url = Uri.parse(
      '$baseUrl?name=$cityName&count=1&language=en&format=json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0];
          final lat = (location['latitude'] as num).toDouble();
          final long = (location['longitude'] as num).toDouble();
          return {'lat': lat, 'long': long};
        } else {
          return null;
        }
      } else {
        throw Exception(
          'Failed to load coordinates - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
