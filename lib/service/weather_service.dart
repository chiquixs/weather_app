import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'f54bed5d43fcbdc04493c8f29304242d';

  Future<Map<String, dynamic>> getWeather(String city) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}'); // ✅ tambah ini
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'city': data['name'],
        'temp': data['main']['temp'],
        'weather': data['weather'][0]['main'],
        'description': data['weather'][0]['description'],
        'feelsLike': data['main']['feels_like'],
      };
    } else {
      throw Exception('Kota tidak ditemukan');
    }
  }
}
