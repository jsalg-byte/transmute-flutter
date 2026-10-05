import 'dart:convert';
import 'package:flutter/services.dart';

import '../domain/models.dart';

/// Ingested OpenGym catalog holding 1,324 exercise definitions with
/// normalized taxonomy, execution instructions, and CDN demonstration media.
abstract final class OpenGymCatalog {
  static List<Exercise>? _cached;

  /// Loads all 1,324 OpenGym exercises from the bundled asset.
  static Future<List<Exercise>> loadAll() async {
    if (_cached != null) return _cached!;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/transmute/opengym_exercises.json',
      );
      final list = json.decode(jsonStr) as List<dynamic>;
      _cached = list
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return _cached!;
    } catch (_) {
      return const [];
    }
  }

  /// Searches exercises matching [query] with optional [bodyPart] and [equipment] filters.
  static Future<List<Exercise>> search({
    String query = '',
    String? bodyPart,
    String? equipment,
    String? muscleGroup,
    int limit = 50,
  }) async {
    final all = await loadAll();
    final q = query.trim().toLowerCase();
    final bp = bodyPart?.trim().toLowerCase();
    final eq = equipment?.trim().toLowerCase();
    final mg = muscleGroup?.trim().toLowerCase();

    return all.where((e) {
      if (bp != null && bp.isNotEmpty && e.bodyPart?.toLowerCase() != bp) {
        return false;
      }
      if (eq != null && eq.isNotEmpty && e.equipment?.toLowerCase() != eq) {
        return false;
      }
      if (mg != null && mg.isNotEmpty && e.muscleGroup?.toLowerCase() != mg) {
        return false;
      }
      if (q.isNotEmpty) {
        final nameMatch = e.name.toLowerCase().contains(q);
        final targetMatch = e.targetMuscle?.toLowerCase().contains(q) ?? false;
        final eqMatch = e.equipment?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !targetMatch && !eqMatch) return false;
      }
      return true;
    }).take(limit).toList();
  }

  /// Distinct body parts in the OpenGym catalog.
  static const bodyParts = [
    'back',
    'cardio',
    'chest',
    'lower arms',
    'lower legs',
    'neck',
    'shoulders',
    'upper arms',
    'upper legs',
    'waist',
  ];

  /// Distinct equipment types in the OpenGym catalog.
  static const equipmentTypes = [
    'barbell',
    'dumbbell',
    'cable',
    'body weight',
    'band',
    'kettlebell',
    'leverage machine',
    'smith machine',
    'olympic barbell',
    'ez barbell',
    'trap bar',
    'assisted',
    'medicine ball',
    'stability ball',
    'roller',
    'weighted',
  ];
}
