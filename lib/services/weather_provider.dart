import '../models/weather.dart';

abstract class WeatherProvider {
  Future<WeatherData> fetch(double lat, double lon);
  void dispose();
}
