import 'dart:convert';
import 'package:flutter/services.dart';

import '../domain/models.dart';

/// Ingested OpenGym catalog holding 1,324 exercise definitions with
/// normalized taxonomy, execution instructions, and CDN demonstration media.
abstract final class OpenGymCatalog {
  static List<Exercise>? _cached;
  static Map<String, Exercise>? _exactMap;
  static Map<String, Exercise>? _stemMap;

  static String _clean(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
  }

  static String _stem(String s) {
    final words = _clean(s).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final stemmed = words.map((w) {
      if (w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
      if (w.endsWith('es') && !w.endsWith('ses')) {
        return w.substring(0, w.length - 2);
      }
      if (w.endsWith('s') && !w.endsWith('ss')) {
        return w.substring(0, w.length - 1);
      }
      return w;
    });
    return stemmed.join(' ');
  }

  static void _buildIndexes(List<Exercise> exercises) {
    _exactMap = {};
    _stemMap = {};
    for (final ex in exercises) {
      final c = _clean(ex.name);
      final s = _stem(c);
      _exactMap![c] = ex;
      _stemMap![s] = ex;
    }
  }

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
      _buildIndexes(_cached!);
      return _cached!;
    } catch (_) {
      return const [];
    }
  }

  /// Synchronously attempts to find the best OpenGym match for [name].
  /// Returns null if catalog is not yet loaded or no candidate matches.
  static Exercise? findMatchSync(String name) {
    if (_cached == null || _exactMap == null) return null;
    final c = _clean(name);
    if (c.isEmpty) return null;
    if (_exactMap!.containsKey(c)) return _exactMap![c];

    final s = _stem(c);
    if (_stemMap!.containsKey(s)) return _stemMap![s];

    // Token overlap matching
    final tokens = s.split(RegExp(r'\s+')).toSet();
    const noise = {
      'practice',
      'existing',
      'routine',
      'supported',
      'modified',
      'one',
      'per',
      'side',
      'arm',
    };
    final coreTokens = tokens.difference(noise);
    if (coreTokens.isEmpty) return null;

    Exercise? bestMatch;
    var bestScore = 0;
    for (final ex in _cached!) {
      final ec = _clean(ex.name);
      final es = _stem(ec);
      final exTokens = es.split(RegExp(r'\s+')).toSet();
      final overlap = coreTokens.intersection(exTokens).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        bestMatch = ex;
      }
    }
    if (bestScore > 0) return bestMatch;
    return null;
  }

  /// Asynchronously finds the best OpenGym match for [name].
  static Future<Exercise?> findMatch(String name) async {
    await loadAll();
    return findMatchSync(name);
  }

  /// Enriches an [exercise] with OpenGym demonstration media and execution cues
  /// if they are missing on the original record.
  static Exercise enrich(Exercise exercise) {
    final match = findMatchSync(exercise.name);
    if (match == null) return exercise;

    return Exercise(
      id: exercise.id,
      name: exercise.name,
      category: exercise.category,
      muscleGroup: exercise.muscleGroup ?? match.muscleGroup,
      bodyPart: exercise.bodyPart ?? match.bodyPart,
      equipment: exercise.equipment ?? match.equipment,
      targetMuscle: exercise.targetMuscle ?? match.targetMuscle,
      primaryMuscles: exercise.primaryMuscles.isNotEmpty
          ? exercise.primaryMuscles
          : match.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles.isNotEmpty
          ? exercise.secondaryMuscles
          : match.secondaryMuscles,
      instructions: exercise.instructions.isNotEmpty
          ? exercise.instructions
          : match.instructions,
      imageUrl: exercise.imageUrl ?? match.imageUrl,
      gifUrl: exercise.gifUrl ?? match.gifUrl,
      demoUrl: exercise.demoUrl ?? match.demoUrl,
      demoSourceName: exercise.demoSourceName ?? match.demoSourceName ?? 'OpenGym',
    );
  }

  /// Merges server exercises with OpenGym exercises, ensuring all server
  /// exercises are enriched with OpenGym media/cues and deduplicated.
  static List<Exercise> mergeWithServerExercises({
    required List<Exercise> serverExercises,
    required List<Exercise> openGymExercises,
  }) {
    final seen = <String>{};
    final merged = <Exercise>[];

    // First, enrich and include all server exercises
    for (final s in serverExercises) {
      final enriched = enrich(s);
      final key = _clean(s.name);
      if (seen.add(key)) {
        merged.add(enriched);
      }
    }

    // Then, include all OpenGym exercises that haven't been added yet
    for (final og in openGymExercises) {
      final key = _clean(og.name);
      if (seen.add(key)) {
        merged.add(og);
      }
    }

    return merged;
  }

  /// Searches exercises matching [query] with optional [bodyPart] and [equipment] filters.
  static Future<List<Exercise>> search({
    String query = '',
    String? bodyPart,
    String? equipment,
    String? muscleGroup,
    List<Exercise>? baseExercises,
    int limit = 1500,
  }) async {
    final openGym = await loadAll();
    final all = baseExercises != null && baseExercises.isNotEmpty
        ? mergeWithServerExercises(
            serverExercises: baseExercises,
            openGymExercises: openGym,
          )
        : openGym;
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
