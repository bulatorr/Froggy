import '../../models/weather.dart';

class YandexL10n {
  final Map<String, String> values;

  YandexL10n(this.values);

  String? description(String key) => values[key];

  static YandexL10n fromJson(List<dynamic> list) {
    final map = <String, String>{};
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final k = item['key'] as String?;
        final v = item['val'] as String?;
        if (k != null && v != null) map[k] = v;
      }
    }
    return YandexL10n(map);
  }
}

WeatherCondition yandexConditionToWeatherCondition(String condition) {
  switch (condition) {
    case 'CLEAR':
      return WeatherCondition.sunny;
    case 'PARTLY_CLOUDY':
    case 'CLOUDY':
    case 'OVERCAST':
      return WeatherCondition.cloudy;
    case 'DRIZZLE':
    case 'LIGHT_RAIN':
    case 'RAIN':
    case 'HEAVY_RAIN':
    case 'SHOWERS':
    case 'HAIL':
    case 'THUNDERSTORM':
    case 'THUNDERSTORM_WITH_RAIN':
    case 'THUNDERSTORM_WITH_HAIL':
      return WeatherCondition.rainy;
    case 'SLEET':
    case 'LIGHT_SNOW':
    case 'SNOW':
    case 'SNOWFALL':
      return WeatherCondition.snowy;
    default:
      return WeatherCondition.cloudy;
  }
}

class YandexNow {
  final int temperature;
  final String condition;

  YandexNow({required this.temperature, required this.condition});

  static YandexNow? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexNow(
      temperature: (json['temperature'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? '',
    );
  }
}

class YandexTimezone {
  final int offset;

  YandexTimezone({required this.offset});

  static YandexTimezone? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexTimezone(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}

class YandexLocation {
  final YandexTimezone? timezone;

  YandexLocation({this.timezone});

  static YandexLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexLocation(
      timezone: YandexTimezone.fromJson(json['timezone'] as Map<String, dynamic>?),
    );
  }
}

class YandexDaypart {
  final int maxTemperature;
  final int minTemperature;

  YandexDaypart({required this.maxTemperature, required this.minTemperature});

  static YandexDaypart? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexDaypart(
      maxTemperature: (json['maxTemperature'] as num?)?.toInt() ?? 0,
      minTemperature: (json['minTemperature'] as num?)?.toInt() ?? 0,
    );
  }
}

class YandexSummary {
  final YandexDaypart? day;
  final YandexDaypart? night;

  YandexSummary({this.day, this.night});

  static YandexSummary? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexSummary(
      day: YandexDaypart.fromJson(json['day'] as Map<String, dynamic>?),
      night: YandexDaypart.fromJson(json['night'] as Map<String, dynamic>?),
    );
  }
}

class YandexForecastDay {
  final String? sunrise;
  final String? sunset;
  final YandexSummary? summary;

  YandexForecastDay({
    this.sunrise,
    this.sunset,
    this.summary,
  });

  static YandexForecastDay fromJson(Map<String, dynamic> json) {
    return YandexForecastDay(
      sunrise: json['sunrise'] as String?,
      sunset: json['sunset'] as String?,
      summary: YandexSummary.fromJson(json['summary'] as Map<String, dynamic>?),
    );
  }
}

class YandexDayForecast {
  final List<YandexForecastDay> days;

  YandexDayForecast({required this.days});

  static YandexDayForecast fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List<dynamic>? ?? [];
    return YandexDayForecast(
      days: daysList
          .map((d) => YandexForecastDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class YandexWeatherByPoint {
  final YandexLocation? location;
  final YandexNow? now;
  final YandexDayForecast? dayForecast;

  YandexWeatherByPoint({this.location, this.now, this.dayForecast});

  static YandexWeatherByPoint? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return YandexWeatherByPoint(
      location: YandexLocation.fromJson(
          json['location'] as Map<String, dynamic>?),
      now: YandexNow.fromJson(json['now'] as Map<String, dynamic>?),
      dayForecast: json['forecast'] != null
          ? YandexDayForecast.fromJson(
              json['forecast'] as Map<String, dynamic>)
          : null,
    );
  }
}

class YandexResponse {
  final YandexWeatherByPoint? weatherByPoint;
  final YandexL10n? l10n;

  YandexResponse({this.weatherByPoint, this.l10n});

  static YandexResponse? fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return YandexResponse(
      weatherByPoint: YandexWeatherByPoint.fromJson(
          data['weatherByPoint'] as Map<String, dynamic>?),
      l10n: data['l10n'] != null
          ? YandexL10n.fromJson(data['l10n'] as List<dynamic>)
          : null,
    );
  }
}
