import 'dart:convert';
import 'package:http/http.dart' as http;



class HolidaysService {
  static const baseUrl = 'https://date.nager.at/api/v3/PublicHolidays';

  Future<Set<DateTime>> getHolidays(int year, {String countryCode = 'PK'}) async {
    final url = Uri.parse('$baseUrl/$year/$countryCode');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      // Fail gracefully - booking should still work even if the API is down.
      return {};
    }

    final List data = jsonDecode(res.body);
    return data.map((h) {
      final date = DateTime.parse(h['date']);
      return DateTime(date.year, date.month, date.day); // strip time
    }).toSet();
  }

  bool isHoliday(DateTime day, Set<DateTime> holidays) {
    final normalized = DateTime(day.year, day.month, day.day); // strip time
    return holidays.contains(normalized);
  }
}