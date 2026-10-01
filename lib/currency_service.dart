import 'dart:convert';

import 'package:http/http.dart' as http;

class Rates {
  final Map<String, double> rates; // units of each currency per 1 USD
  final String updated;
  Rates(this.rates, this.updated);
}

Future<Rates> fetchRates() async {
  final res = await http.get(
    Uri.https('open.er-api.com', '/v6/latest/USD'),
  );
  if (res.statusCode != 200) {
    throw Exception('Request failed (${res.statusCode})');
  }
  final json = jsonDecode(res.body);
  if (json['result'] != 'success') throw Exception('API error');
  final raw = json['rates'] as Map<String, dynamic>;
  return Rates(
    raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    (json['time_last_update_utc'] ?? '').toString(),
  );
}

String fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$whole.${parts[1]}';
}

const currencyNames = {
  'USD': 'US Dollar',
  'EUR': 'Euro',
  'GBP': 'British Pound',
  'ETB': 'Ethiopian Birr',
  'JPY': 'Japanese Yen',
  'CNY': 'Chinese Yuan',
  'INR': 'Indian Rupee',
  'CAD': 'Canadian Dollar',
  'AUD': 'Australian Dollar',
  'CHF': 'Swiss Franc',
  'AED': 'UAE Dirham',
  'SAR': 'Saudi Riyal',
  'KES': 'Kenyan Shilling',
  'NGN': 'Nigerian Naira',
  'ZAR': 'South African Rand',
  'EGP': 'Egyptian Pound',
  'TRY': 'Turkish Lira',
};
