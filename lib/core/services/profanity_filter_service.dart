import 'package:flutter/services.dart';

class ProfanityFilterService {
  ProfanityFilterService._();
  static final ProfanityFilterService instance = ProfanityFilterService._();

  static final RegExp _stripPattern = RegExp(r'[\s\p{P}]', unicode: true);

  List<String>? _words;

  Future<List<String>> _loadWords() async {
    if (_words != null) {
      return _words!;
    }
    final content = await rootBundle.loadString('assets/data/fword_list.txt');
    _words = content
        .split('\n')
        .map((w) => _normalize(w))
        .where((w) => w.isNotEmpty)
        .toList();
    return _words!;
  }

  String _normalize(String input) {
    return input.replaceAll(_stripPattern, '').toLowerCase();
  }

  Future<bool> containsProfanity(String input) async {
    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return false;
    }
    final words = await _loadWords();
    for (final word in words) {
      if (normalized.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
