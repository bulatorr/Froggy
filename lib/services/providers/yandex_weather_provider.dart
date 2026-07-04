import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/weather.dart';
import '../weather_provider.dart';
import 'open_meteo_provider.dart' show WeatherException;
import 'yandex_types.dart';

class YandexWeatherProvider implements WeatherProvider {
  YandexWeatherProvider({
    http.Client? client,
    this.baseUrl,
    this.apiKey = _defaultApiKey,
    this.lang = 'en',
  }) : _client = client ?? http.Client();

  static const _yandexDirectUrl =
      'https://api.weather.yandex.ru/mobile/graphql/query';
  static const _defaultApiKey =
      '5b4b5a44-055f-4884-960e-af9e12301e46';

  final String? baseUrl;
  final http.Client _client;
  final String apiKey;
  final String lang;

  static const String _query = '''
query getWeatherByPoint(\$lat: Float!, \$lon: Float!, \$lang: Language!) {
  weatherByPoint(request: {lat: \$lat, lon: \$lon}, language: \$lang) {
    now {
      condition
      temperature(unit: CELSIUS)
    }
    location {
      timezone {
        offset
      }
    }
    forecast {
      days(limit: 1) {
        sunrise
        sunset
        summary {
          day {
            maxTemperature(unit: CELSIUS)
          }
          night {
            minTemperature(unit: CELSIUS)
          }
        }
      }
    }
  }
  l10n: localization(language: \$lang) {
    key
    val
  }
}
''';

  @override
  Future<WeatherData> fetch(double lat, double lon) async {
    debugPrint('[Yandex] fetch lat=$lat lon=$lon lang=$lang');

    final body = jsonEncode({
      'operationName': 'getWeatherByPoint',
      'variables': {
        'lat': lat,
        'lon': lon,
        'lang': lang,
      },
      'query': _query,
    });

    final uri = Uri.parse(baseUrl ?? _yandexDirectUrl);
    debugPrint('[Yandex] POST $uri');

    try {
      final resp = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'X-Yandex-API-Key': apiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[Yandex] HTTP ${resp.statusCode} (${resp.body.length} bytes)');

      if (resp.statusCode != 200) {
        throw WeatherException(
            'Yandex Weather returned HTTP ${resp.statusCode}');
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final response = YandexResponse.fromJson(decoded);
      if (response == null) {
        debugPrint('[Yandex] parse failed');
        throw const WeatherException('Failed to parse Yandex response');
      }

      final wp = response.weatherByPoint;
      if (wp == null) {
        throw const WeatherException('No weather data in Yandex response');
      }

      final now = wp.now;
      if (now == null || now.condition.isEmpty) {
        throw const WeatherException('No current weather in Yandex response');
      }

      final today = wp.dayForecast?.days.isNotEmpty == true
          ? wp.dayForecast!.days.first
          : null;

      final tz = wp.location?.timezone;

      final condition = yandexConditionToWeatherCondition(now.condition);

      String? description;
      if (response.l10n != null) {
        description = response.l10n!.description(now.condition);
      }

      final dayPart = today?.summary?.day;
      final nightPart = today?.summary?.night;

      return WeatherData(
        condition: condition,
        weatherCode: 0,
        temperatureC: now.temperature.toDouble(),
        tempMaxC: dayPart != null ? dayPart.maxTemperature.toDouble() : null,
        tempMinC: nightPart != null ? nightPart.minTemperature.toDouble() : null,
        sunrise: _parseDate(today?.sunrise),
        sunset: _parseDate(today?.sunset),
        utcOffsetSeconds: tz?.offset,
        fetchedAt: DateTime.now(),
        customDescription: description,
      );
    } catch (e) {
      debugPrint('[Yandex] ERROR: $e');
      rethrow;
    }
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  }

  @override
  void dispose() => _client.close();
}
