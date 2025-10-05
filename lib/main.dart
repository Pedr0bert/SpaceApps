import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tob/services/date_text_formatter.dart';
import 'models/weather_data.dart';
import 'services/location_service.dart';
import 'widgets/weather_icon.dart';

void main() {
  runApp(const WeatherForecastApp());
}

class WeatherForecastApp extends StatelessWidget {
  const WeatherForecastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WeatherForecastScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  final TextEditingController _dateController = TextEditingController();
  WeatherData? _weatherData;

  final LocationService _locationService = LocationService();

  List<Map<String, String>> _countries = [];
  List<Map<String, String>> _states = [];
  List<String> _cities = [];

  Map<String, String>? _selectedCountry;
  Map<String, String>? _selectedState;
  String? _selectedCity;

  bool _isLoadingCountries = true;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _locationService.getCountries();
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
      });
      _showErrorSnackBar('Erro ao carregar países.');
    }
  }

  Future<void> _loadStates(String countryIso2) async {
    setState(() {
      _isLoadingStates = true;
      _states = [];
      _cities = [];
      _selectedState = null;
      _selectedCity = null;
    });
    try {
      final states = await _locationService.getStatesOfCountry(countryIso2);
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStates = false;
      });
      _showErrorSnackBar('Erro ao carregar estados.');
    }
  }

  Future<void> _loadCities(String countryIso2, String stateIso2) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final cities = await _locationService.getCitiesOfState(
        countryIso2,
        stateIso2,
      );
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      _showErrorSnackBar('Erro ao carregar cidades.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        elevation: 4.0,
        action: SnackBarAction(
          label: 'FECHAR',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3D9FF), Color(0xFF87CEEB)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 80,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Weather\nForecast",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        size: 50,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildDropdown<Map<String, String>>(
                  hint: "País",
                  value: _selectedCountry,
                  items: _countries,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCountry = value;
                    });
                    _loadStates(value['iso2']!);
                  },
                  isLoading: _isLoadingCountries,
                  itemBuilder: (item) =>
                      DropdownMenuItem(value: item, child: Text(item['name']!)),
                ),
                const SizedBox(height: 15),
                _buildDropdown<Map<String, String>>(
                  hint: "Estado",
                  value: _selectedState,
                  items: _states,
                  onChanged: _selectedCountry == null
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedState = value;
                          });
                          _loadCities(
                            _selectedCountry!['iso2']!,
                            value['iso2']!,
                          );
                        },
                  isLoading: _isLoadingStates,
                  itemBuilder: (item) =>
                      DropdownMenuItem(value: item, child: Text(item['name']!)),
                ),
                const SizedBox(height: 15),
                _buildDropdown<String>(
                  hint: "Cidade",
                  value: _selectedCity,
                  items: _cities,
                  onChanged: _selectedState == null
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                  isLoading: _isLoadingCities,
                  itemBuilder: (item) =>
                      DropdownMenuItem(value: item, child: Text(item)),
                ),
                const SizedBox(height: 15),
                _buildDateField("Data (Opcional)", _dateController),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCity == null) {
                      _showErrorSnackBar(
                        'Por favor, selecione País, Estado e Cidade.',
                      );
                      return;
                    }

                    String dateToUse;
                    final now = DateTime.now();

                    if (_dateController.text.isNotEmpty) {
                      if (!RegExp(
                        r'^\d{2}/\d{2}/\d{4}$',
                      ).hasMatch(_dateController.text)) {
                        _showErrorSnackBar(
                          'Formato de data inválido. Use DD/MM/AAAA.',
                        );
                        return;
                      }

                      try {
                        final parts = _dateController.text.split('/');
                        final day = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final year = int.parse(parts[2]);
                        final date = DateTime(year, month, day);

                        if (date.day != day ||
                            date.month != month ||
                            date.year != year) {
                          throw const FormatException(
                            'Data não existe no calendário.',
                          );
                        }
                        dateToUse = _dateController.text;
                      } catch (e) {
                        _showErrorSnackBar(
                          'Data inválida. Verifique dia, mês e ano.',
                        );
                        return;
                      }
                    } else {
                      dateToUse =
                          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
                    }
                    setState(() {
                      _weatherData = WeatherData.getMockData(
                        _selectedCity!,
                        _selectedState!['name']!,
                        _selectedCountry!['name']!,
                        dateToUse,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Check Forecast",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weatherData?.temperature ?? '--°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _weatherData != null
                            ? "${_weatherData!.city}, ${_weatherData!.state}"
                            : 'Insira uma localização',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      if (_weatherData?.date.isNotEmpty ?? false)
                        Text(
                          _weatherData!.date,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF95A5A6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0x4D87CEEB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: WeatherIcon(
                            iconType: _weatherData?.iconType ?? 'sunny',
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Probability ${_weatherData?.probability ?? '--%'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _weatherData?.description ??
                                  'Aguardando dados...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
    required bool isLoading,
    required DropdownMenuItem<T> Function(T) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onChanged != null
              ? [
                  const Color.fromRGBO(255, 255, 255, 0.95),
                  const Color.fromRGBO(255, 255, 255, 0.85),
                ]
              : [const Color(0x99EEEEEE), const Color(0x66E0E0E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onChanged != null
              ? const Color(0x4D4A90E2)
              : const Color(0x4D9E9E9E),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x264A90E2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color.fromRGBO(255, 255, 255, 0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map(itemBuilder).toList(),
        onChanged: isLoading ? null : onChanged,
        isExpanded: true,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                ),
              )
            : Icon(
                Icons.keyboard_arrow_down_rounded,
                color: onChanged != null
                    ? const Color(0xFF4A90E2)
                    : Colors.grey.shade500,
                size: 28,
              ),
        iconSize: 28,
        elevation: 8,
        dropdownColor: Colors.white,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          prefixIcon: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        onChanged != null
                            ? const Color(0xFF4A90E2)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    _getIconForHint(hint),
                    color: onChanged != null
                        ? const Color(0xFF4A90E2)
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
          hintText: hint,
          hintStyle: TextStyle(
            color: onChanged != null
                ? const Color(0xFF7F8C8D)
                : Colors.grey.shade500,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: TextStyle(
          fontSize: 16,
          color: onChanged != null
              ? const Color(0xFF2C3E50)
              : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIconForHint(String hint) {
    switch (hint.toLowerCase()) {
      case 'país':
        return Icons.public_rounded;
      case 'estado':
        return Icons.location_on_rounded;
      case 'cidade':
        return Icons.location_city_rounded;
      default:
        return Icons.arrow_drop_down_rounded;
    }
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(255, 255, 255, 0.95),
            Color.fromRGBO(255, 255, 255, 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4D4A90E2), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x264A90E2),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.8),
            blurRadius: 8,
            offset: Offset(-2, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF4A90E2),
              size: 22,
            ),
          ),
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF7F8C8D),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          DateTextFormatter(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }
}
