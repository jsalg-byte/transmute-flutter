import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_shell.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _day = _dateOnly(DateTime.now());
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = _apiDate(_day);
    final recordAsync = ref.watch(nutritionRecordProvider);
    final diaryAsync = ref.watch(nutritionDiaryDayProvider(dateStr));

    return AppShell(
      title: 'Nutrition',
      child: recordAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () {
              ref.invalidate(nutritionRecordProvider);
              ref.invalidate(nutritionDiaryDayProvider(dateStr));
            },
            child: const Text('Retry nutrition record'),
          ),
        ),
        data: (record) => diaryAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: ElevatedButton(
              onPressed: () => ref.invalidate(nutritionDiaryDayProvider(dateStr)),
              child: const Text('Retry diary'),
            ),
          ),
          data: (diary) => _content(record, diary),
        ),
      ),
    );
  }

  Widget _content(NutritionRecord record, NutritionDiaryDay diary) {
    final meals = record.meals
        .where((meal) => DateUtils.isSameDay(meal.consumedAt.toLocal(), _day))
        .toList();

    // Recently logged unique foods
    final recentFoods = <Food>[];
    final seenIds = <String>{};
    for (final m in record.meals) {
      if (!seenIds.contains(m.foodId)) {
        seenIds.add(m.foodId);
        final food = record.foods.where((f) => f.id == m.foodId).firstOrNull;
        if (food != null) recentFoods.add(food);
      }
      if (recentFoods.length >= 6) break;
    }

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nutrition',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            IconButton(
              tooltip: 'Set daily target',
              icon: const Icon(Icons.tune),
              onPressed: () => _openTargetDialog(diary.target),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'recipes') context.push('/recipes');
                if (value == 'barcode') _barcode();
                if (value == 'label') _readLabel();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'recipes',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 20),
                      SizedBox(width: 8),
                      Text('Discover recipes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'barcode',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 20),
                      SizedBox(width: 8),
                      Text('Scan or enter barcode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'label',
                  child: Row(
                    children: [
                      Icon(Icons.document_scanner, size: 20),
                      SizedBox(width: 8),
                      Text('Read nutrition label'),
                    ],
                  ),
                ),
              ],
              tooltip: 'Nutrition tools',
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Build a food record once, log the serving you actually ate, and keep the day’s macros visible.',
        ),
        const SizedBox(height: 16),
        _DayHeader(
          day: _day,
          diary: diary,
          meals: meals,
          onPrevious: () =>
              setState(() => _day = _day.subtract(const Duration(days: 1))),
          onNext: () =>
              setState(() => _day = _day.add(const Duration(days: 1))),
          onSetTarget: () => _openTargetDialog(diary.target),
          onAddMeal: () => _openMealDialog(record),
        ),
        const SizedBox(height: 16),
        TransmutePanel(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/recipes'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.soup_kitchen_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Curated Recipes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'High-protein alchemical meals with verified macros & preparation guides.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (recentFoods.isNotEmpty) ...[
          Text(
            'Recently Logged',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentFoods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final food = recentFoods[index];
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text('${food.name} (${food.caloriesKcal} cal)'),
                  onPressed: _saving
                      ? null
                      : () => _quickAddFood(record, food),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Food record · ${_displayDate(_day)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (meals.isEmpty)
          const TransmutePanel(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.no_meals_outlined,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'No food logged on this date.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap Add Meal or use the sections below to track your meals.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ...MealType.values.map((type) {
          final group = meals.where((meal) => meal.mealType == type).toList();
          final groupCals = group.fold<double>(0, (sum, m) => sum + m.caloriesKcal).round();

          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TransmutePanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_mealIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mealLabel(type),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (group.isNotEmpty)
                        Text(
                          '$groupCals kcal',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add to ${_mealLabel(type)}',
                        onPressed: _saving ? null : () => _openMealDialog(record, type),
                      ),
                    ],
                  ),
                  if (group.isNotEmpty) ...[
                    const Divider(height: 16),
                    ...group.map(
                      (meal) => _MealTile(
                        meal: meal,
                        onEdit: () => _editMeal(meal),
                        onDelete: () => _deleteMeal(meal),
                        onPhoto: () => _uploadMealPhoto(meal),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 38),
                        ),
                        onPressed: _saving ? null : () => _openMealDialog(record, type),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Add ${_mealLabel(type)}'),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _quickAddFood(NutritionRecord record, Food food) async {
    try {
      setState(() => _saving = true);
      final grams = _defaultGrams(food);
      await ref.read(nutritionRepositoryProvider).createMeal(
        MealType.snack,
        [MealItemInput(foodId: food.id, grams: grams)],
        consumedAt: _dayAtNow(_day),
      );
      ref.invalidate(nutritionRecordProvider);
      final dateStr = _apiDate(_day);
      ref.invalidate(nutritionDiaryDayProvider(dateStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged ${food.name}.')),
        );
      }
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openTargetDialog(DailyNutritionTarget? current) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _DailyTargetDialog(currentTarget: current),
    );
    if (updated == true) {
      final dateStr = _apiDate(_day);
      ref.invalidate(dailyNutritionTargetProvider(null));
      ref.invalidate(dailyNutritionTargetProvider(dateStr));
      ref.invalidate(nutritionDiaryDayProvider(dateStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily target updated.')),
        );
      }
    }
  }

  Future<void> _openMealDialog(NutritionRecord record, [MealType? type]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MealLogDialog(record: record, day: _day, initialType: type),
    );
    if (saved == true) {
      ref.invalidate(nutritionRecordProvider);
      final dateStr = _apiDate(_day);
      ref.invalidate(nutritionDiaryDayProvider(dateStr));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal logged.')));
      }
    }
  }

  Future<void> _createFood([Food? seed]) async {
    final food = await showDialog<Food>(
      context: context,
      builder: (_) => _FoodDialog(seed: seed),
    );
    if (food == null) return;
    try {
      setState(() => _saving = true);
      await ref.read(nutritionRepositoryProvider).createFood(food);
      ref.invalidate(nutritionRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _barcode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _BarcodeDialog(),
    );
    if (code == null) return;
    try {
      setState(() => _saving = true);
      final result = await ref
          .read(nutritionRepositoryProvider)
          .lookupBarcode(code);
      if (!result.found || result.food == null) {
        _failure(
          context,
          const AppFailure(
            'barcode_not_found',
            'No food was found for that barcode. Create it manually.',
          ),
        );
      } else if (result.food!.id != 'draft') {
        final record = await ref.refresh(nutritionRecordProvider.future);
        await _openMealDialog(record);
      } else {
        await _createFood(result.food);
      }
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _readLabel() async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 2200,
      );
      if (selected == null) return;
      final result = await ref
          .read(nutritionRepositoryProvider)
          .parseNutritionLabel(await selected.readAsBytes());
      if (result.food == null) {
        _failure(
          context,
          const AppFailure(
            'label_unreadable',
            'No readable nutrition values were found. Try a clearer label.',
          ),
        );
        return;
      }
      if (mounted && result.confidence != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.source == 'ai' ? 'AI' : 'OCR'} read the label at ${(result.confidence! * 100).round()}% confidence. Review before saving.',
            ),
          ),
        );
      }
      await _createFood(result.food);
    } on AppFailure catch (error) {
      _failure(context, error);
    } catch (_) {
      _failure(
        context,
        const AppFailure(
          'label_parse_failed',
          'Unable to read the selected nutrition label.',
        ),
      );
    }
  }

  Future<void> _uploadMealPhoto(NutritionMeal meal) async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2400,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      setState(() => _saving = true);
      await ref
          .read(nutritionRepositoryProvider)
          .uploadMealPhoto(
            meal.id,
            ProgressPhotoUpload(
              fileName: selected.name,
              mimeType: selected.mimeType ?? 'image/jpeg',
              bytes: bytes,
              capturedAt: meal.consumedAt,
            ),
          );
      ref.invalidate(nutritionRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } catch (_) {
      _failure(
        context,
        const AppFailure(
          'meal_photo_upload_failed',
          'Unable to read or upload the selected meal photo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editMeal(NutritionMeal meal) async {
    final edit =
        await showDialog<({MealType type, double grams, DateTime consumedAt})>(
          context: context,
          builder: (_) => _MealEditDialog(meal: meal),
        );
    if (edit == null) return;
    try {
      setState(() => _saving = true);
      await ref
          .read(nutritionRepositoryProvider)
          .updateMeal(
            meal.id,
            type: edit.type,
            grams: edit.grams,
            consumedAt: edit.consumedAt,
          );
      ref.invalidate(nutritionRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMeal(NutritionMeal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove logged food?'),
        content: Text(
          'Remove ${meal.foodName} from ${_displayDate(meal.consumedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      setState(() => _saving = true);
      await ref.read(nutritionRepositoryProvider).deleteMeal(meal.id);
      ref.invalidate(nutritionRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.diary,
    required this.meals,
    required this.onPrevious,
    required this.onNext,
    required this.onSetTarget,
    required this.onAddMeal,
  });

  final DateTime day;
  final NutritionDiaryDay diary;
  final List<NutritionMeal> meals;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSetTarget;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = diary.target;

    // Dynamically roll up from actual logged meals to guarantee state consistency
    final consumed = meals.fold<int>(
      0,
      (sum, m) => sum + m.caloriesKcal.round(),
    );
    final remaining = target != null ? (target.caloriesTarget - consumed) : null;

    final consumedProtein = meals.fold<double>(
      0.0,
      (sum, m) => sum + m.proteinG,
    );
    final consumedCarbs = meals.fold<double>(
      0.0,
      (sum, m) => sum + m.carbsG,
    );
    final consumedFat = meals.fold<double>(
      0.0,
      (sum, m) => sum + m.fatG,
    );

    final double progress;
    if (target != null && target.caloriesTarget > 0) {
      progress = (consumed / target.caloriesTarget).clamp(0.0, 1.0);
    } else {
      progress = 0.0;
    }

    return TransmutePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
            // Date navigation row
            Row(
              children: [
                IconButton(
                  onPressed: onPrevious,
                  tooltip: 'Previous day',
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: DesignMotion.duration(
                      context,
                      DesignMotion.instant,
                    ),
                    switchInCurve: DesignMotion.curve,
                    switchOutCurve: DesignMotion.curve,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      _displayDate(day),
                      key: ValueKey(_dateOnly(day)),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  tooltip: 'Next day',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top calorie summary: circular gauge left, numbers right
            Row(
              children: [
                // Circular calorie progress gauge
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: target != null ? progress : 0.0,
                          strokeWidth: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            target != null && consumed > target.caloriesTarget
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (remaining != null) ...[
                            Text(
                              '${remaining.abs()}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: remaining < 0 ? theme.colorScheme.error : null,
                              ),
                            ),
                            Text(
                              remaining < 0 ? 'Over' : 'Remaining',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: remaining < 0
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '$consumed',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Consumed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Target, Food, and Remaining numeric stack
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatRow(
                        label: 'Goal',
                        value: target != null
                            ? '${target.caloriesTarget} kcal'
                            : 'Not set',
                        actionLabel: target == null ? 'Set' : 'Edit',
                        onAction: onSetTarget,
                      ),
                      const SizedBox(height: 6),
                      _StatRow(
                        label: 'Food',
                        value: '$consumed kcal',
                      ),
                      const SizedBox(height: 6),
                      _StatRow(
                        label: 'Remaining',
                        value: remaining != null
                            ? '${remaining < 0 ? "-" : ""}${remaining.abs()} kcal'
                            : '—',
                        valueColor: remaining != null && remaining < 0
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Macro progress bars
            _MacroBar(
              label: 'Protein',
              consumed: consumedProtein,
              target: target?.proteinGTarget,
              unit: 'g',
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 8),
            _MacroBar(
              label: 'Carbs',
              consumed: consumedCarbs,
              target: target?.carbsGTarget,
              unit: 'g',
              color: Colors.amberAccent.shade700,
            ),
            const SizedBox(height: 8),
            _MacroBar(
              label: 'Fat',
              consumed: consumedFat,
              target: target?.fatGTarget,
              unit: 'g',
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),

            // Full-width Add Meal action button at bottom of header card
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddMeal,
                icon: const Icon(Icons.add),
                label: const Text('Add Meal'),
              ),
            ),
          ],
        ),
      );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double consumed;
  final double? target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTarget = target != null && target! > 0;
    final progress = hasTarget ? (consumed / target!).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium,
            ),
            Text(
              hasTarget
                  ? '${consumed.toStringAsFixed(1)} / ${target!.toStringAsFixed(0)} $unit'
                  : '${consumed.toStringAsFixed(1)} $unit',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hasTarget ? progress : 0.0,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DailyTargetDialog extends ConsumerStatefulWidget {
  const _DailyTargetDialog({this.currentTarget});

  final DailyNutritionTarget? currentTarget;

  @override
  ConsumerState<_DailyTargetDialog> createState() => _DailyTargetDialogState();
}

class _DailyTargetDialogState extends ConsumerState<_DailyTargetDialog> {
  late final TextEditingController _calories = TextEditingController(
    text: widget.currentTarget != null ? '${widget.currentTarget!.caloriesTarget}' : '',
  );
  late final TextEditingController _protein = TextEditingController(
    text: widget.currentTarget != null && widget.currentTarget!.proteinGTarget > 0
        ? '${widget.currentTarget!.proteinGTarget.round()}'
        : '',
  );
  late final TextEditingController _carbs = TextEditingController(
    text: widget.currentTarget != null && widget.currentTarget!.carbsGTarget > 0
        ? '${widget.currentTarget!.carbsGTarget.round()}'
        : '',
  );
  late final TextEditingController _fat = TextEditingController(
    text: widget.currentTarget != null && widget.currentTarget!.fatGTarget > 0
        ? '${widget.currentTarget!.fatGTarget.round()}'
        : '',
  );

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Nutrition Target'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set your daily caloric and macronutrient targets. Remaining calories in the meal diary reflect food consumed against this target.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories Target (kcal) *',
                  hintText: 'e.g. 2200',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _protein,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Protein Target (g)',
                  hintText: 'e.g. 160',
                  prefixIcon: Icon(Icons.fitness_center_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _carbs,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates Target (g)',
                  hintText: 'e.g. 250',
                  prefixIcon: Icon(Icons.bakery_dining_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fat,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fat Target (g)',
                  hintText: 'e.g. 70',
                  prefixIcon: Icon(Icons.local_drink_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Target'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final cals = int.tryParse(_calories.text.trim());
    if (cals == null || cals <= 0 || cals > 15000) {
      setState(() => _error = 'Please enter a valid calorie target between 1 and 15,000.');
      return;
    }

    final p = double.tryParse(_protein.text.trim()) ?? 0.0;
    final c = double.tryParse(_carbs.text.trim()) ?? 0.0;
    final f = double.tryParse(_fat.text.trim()) ?? 0.0;

    try {
      setState(() {
        _saving = true;
        _error = null;
      });

      await ref.read(nutritionRepositoryProvider).saveDailyTarget(
        caloriesTarget: cals,
        proteinGTarget: p,
        carbsGTarget: c,
        fatGTarget: f,
      );

      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (error) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Failed to save daily target.';
      });
    }
  }
}


class _MealLogDialog extends ConsumerStatefulWidget {
  const _MealLogDialog({
    required this.record,
    required this.day,
    this.initialType,
  });
  final NutritionRecord record;
  final DateTime day;
  final MealType? initialType;

  @override
  ConsumerState<_MealLogDialog> createState() => _MealLogDialogState();
}

class _MealLogDialogState extends ConsumerState<_MealLogDialog> {
  late final TextEditingController _query = TextEditingController();
  late List<Food> _foods = [...widget.record.foods];
  final Map<String, double> _draft = {};
  late MealType _type = widget.initialType ?? MealType.breakfast;
  bool _saving = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terms = _query.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    final foods =
        _foods.where((food) {
          final name = food.name.toLowerCase();
          return terms.isNotEmpty && terms.every(name.contains);
        }).toList()..sort((a, b) {
          final query = _query.text.trim().toLowerCase();
          final aStarts = a.name.toLowerCase().startsWith(query);
          final bStarts = b.name.toLowerCase().startsWith(query);
          return (bStarts ? 1 : 0).compareTo(aStarts ? 1 : 0);
        });
    final draftFoods = _foods
        .where((food) => _draft.containsKey(food.id))
        .toList();

    return AlertDialog(
      title: const Text('Log meal'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Logging for ${_displayDate(widget.day)}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<MealType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Meal type',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                items: MealType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_mealLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search saved foods',
                  hintText: 'Try “chicken rice” or part of a name',
                ),
              ),
              const SizedBox(height: 8),
              if (terms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Search to find foods to add to this meal.'),
                )
              else
                _Catalog(
                  query: _query,
                  foods: foods,
                  onChanged: () => setState(() {}),
                  onAdd: (food) => setState(
                    () =>
                        _draft.putIfAbsent(food.id, () => _defaultGrams(food)),
                  ),
                  hideUntilSearch: true,
                  showSearch: false,
                ),
              if (draftFoods.isNotEmpty) ...[
                const Divider(height: 24),
                _MealComposer(
                  foods: draftFoods,
                  grams: _draft,
                  type: _type,
                  day: widget.day,
                  saving: _saving,
                  onTypeChanged: (type) => setState(() => _type = type),
                  onAmountChanged: (food, grams) =>
                      setState(() => _draft[food.id] = grams),
                  onRemove: (food) => setState(() => _draft.remove(food.id)),
                  onSave: _save,
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _addNewFood,
                      icon: const Icon(Icons.add),
                      label: const Text('Add NEW food'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _photoAnalyze,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Photo meal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _photoAnalyze() async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2400,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();

      if (!mounted) return;
      // Show loading indicator dialog with cancellation
      final analysis = await showDialog<FoodPhotoAnalysis?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _FoodPhotoLoadingDialog(
          bytes: bytes,
          analyze: () => ref.read(nutritionRepositoryProvider).analyzeFoodPhoto(bytes),
        ),
      );

      if (analysis == null || !mounted) return;
      if (analysis.candidates.isEmpty) {
        _failure(
          context,
          const AppFailure(
            'no_food_candidates',
            'No recognizable foods were found in this photo. Search or add the food manually.',
          ),
        );
        return;
      }

      // Open Candidate Review Dialog
      final reviewed = await showDialog<FoodCandidateReviewResult>(
        context: context,
        builder: (_) => FoodCandidateReviewDialog(
          analysis: analysis,
          imageBytes: bytes,
          initialMealType: _type,
          day: widget.day,
        ),
      );

      if (reviewed == null || !mounted) return;

      // On confirm, create the food and meal
      setState(() => _saving = true);
      final createdFood = await ref.read(nutritionRepositoryProvider).createFood(reviewed.food);
      await ref.read(nutritionRepositoryProvider).createMeal(
        reviewed.mealType,
        [MealItemInput(foodId: createdFood.id, grams: reviewed.portionGrams)],
        consumedAt: _dayAtNow(widget.day),
      );

      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (error) {
      _failure(context, error);
    } catch (_) {
      _failure(
        context,
        const AppFailure(
          'food_photo_failed',
          'Unable to analyze the food photo. Try a clearer angle or enter manually.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addNewFood() async {
    final food = await showDialog<Food>(
      context: context,
      builder: (_) => const _FoodDialog(),
    );
    if (food == null || !mounted) return;
    try {
      setState(() => _saving = true);
      await ref.read(nutritionRepositoryProvider).createFood(food);
      final updated = await ref.refresh(nutritionRecordProvider.future);
      if (mounted) setState(() => _foods = [...updated.foods]);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_draft.isEmpty) return;
    try {
      setState(() => _saving = true);
      await ref
          .read(nutritionRepositoryProvider)
          .createMeal(
            _type,
            _draft.entries
                .map(
                  (entry) =>
                      MealItemInput(foodId: entry.key, grams: entry.value),
                )
                .toList(),
            consumedAt: _dayAtNow(widget.day),
          );
      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({
    required this.query,
    required this.foods,
    required this.onChanged,
    required this.onAdd,
    this.hideUntilSearch = false,
    this.showSearch = true,
  });
  final TextEditingController query;
  final List<Food> foods;
  final VoidCallback onChanged;
  final ValueChanged<Food> onAdd;
  final bool hideUntilSearch;
  final bool showSearch;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food catalog', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (showSearch)
            TextField(
              controller: query,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search foods',
              ),
            ),
          const SizedBox(height: 8),
          if (hideUntilSearch && query.text.trim().isEmpty)
            const SizedBox.shrink()
          else if (foods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No foods match. Create a food to add it.'),
            )
          else
            ...foods.map(
              (food) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(food.name),
                subtitle: Text(
                  '${food.servingLabel} · ${food.caloriesKcal.round()} kcal · P ${food.proteinG} C ${food.carbsG} F ${food.fatG}',
                ),
                trailing: TextButton(
                  onPressed: () => onAdd(food),
                  child: const Text('Add'),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MealComposer extends StatelessWidget {
  const _MealComposer({
    required this.foods,
    required this.grams,
    required this.type,
    required this.day,
    required this.saving,
    required this.onTypeChanged,
    required this.onAmountChanged,
    required this.onRemove,
    required this.onSave,
  });
  final List<Food> foods;
  final Map<String, double> grams;
  final MealType type;
  final DateTime day;
  final bool saving;
  final ValueChanged<MealType> onTypeChanged;
  final void Function(Food, double) onAmountChanged;
  final ValueChanged<Food> onRemove;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    final totals = _Totals.fromDraft(foods, grams);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal composer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Logging for ${_displayDate(day)}'),
            const SizedBox(height: 8),
            DropdownButtonFormField<MealType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Meal type'),
              items: MealType.values
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onTypeChanged(value);
              },
            ),
            const SizedBox(height: 8),
            if (foods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Add a food from the catalog. Amounts use each food’s saved serving unit.',
                ),
              )
            else ...[
              ...foods.map(
                (food) => _DraftFood(
                  food: food,
                  grams: grams[food.id]!,
                  onChanged: (value) => onAmountChanged(food, value),
                  onRemove: () => onRemove(food),
                ),
              ),
              const Divider(),
              Text(
                '${totals.calories.round()} kcal · P ${totals.protein.toStringAsFixed(1)} · C ${totals.carbs.toStringAsFixed(1)} · F ${totals.fat.toStringAsFixed(1)}',
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                child: Semantics(
                  liveRegion: saving,
                  label: saving ? 'Saving meal' : 'Log meal',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: saving ? 0 : 1,
                        child: const Text('Log meal'),
                      ),
                      if (saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DraftFood extends StatefulWidget {
  const _DraftFood({
    required this.food,
    required this.grams,
    required this.onChanged,
    required this.onRemove,
  });
  final Food food;
  final double grams;
  final ValueChanged<double> onChanged;
  final VoidCallback onRemove;
  @override
  State<_DraftFood> createState() => _DraftFoodState();
}

class _DraftFoodState extends State<_DraftFood> {
  late final TextEditingController _grams = TextEditingController(
    text: widget.grams.toStringAsFixed(widget.grams % 1 == 0 ? 0 : 1),
  );
  @override
  void didUpdateWidget(covariant _DraftFood oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grams != widget.grams &&
        double.tryParse(_grams.text) != widget.grams)
      _grams.text = widget.grams.toString();
  }

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(widget.food.name)),
      SizedBox(
        width: 112,
        child: TextField(
          controller: _grams,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: servingUnitLabel(
              widget.food.servingSizeUnit ?? ServingUnit.g,
            ),
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null && parsed > 0 && parsed <= 5000)
              widget.onChanged(parsed);
          },
        ),
      ),
      IconButton(
        onPressed: widget.onRemove,
        tooltip: 'Remove ${widget.food.name}',
        icon: const Icon(Icons.close),
      ),
    ],
  );
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
    required this.onPhoto,
  });
  final NutritionMeal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPhoto;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: meal.localImageBytes != null
          ? Image.memory(
              meal.localImageBytes!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            )
          : meal.imageUrl != null
          ? Image.network(
              meal.imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported_outlined),
            )
          : const Icon(Icons.restaurant_outlined),
      title: Text(meal.foodName),
      subtitle: Text(
        '${meal.mealType.name} · ${meal.grams.toStringAsFixed(1)} ${meal.servingSizeUnit == null ? 'servings' : servingUnitLabel(meal.servingSizeUnit!)} · ${meal.caloriesKcal.round()} cals\nP ${meal.proteinG.toStringAsFixed(1)} · C ${meal.carbsG.toStringAsFixed(1)} · F ${meal.fatG.toStringAsFixed(1)}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'photo') onPhoto();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'photo', child: Text('Add or replace photo')),
          PopupMenuItem(value: 'delete', child: Text('Remove')),
        ],
      ),
    ),
  );
}

class _FoodDialog extends StatefulWidget {
  const _FoodDialog({this.seed});
  final Food? seed;
  @override
  State<_FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<_FoodDialog> {
  late final name = TextEditingController(text: widget.seed?.name ?? '');
  late final barcode = TextEditingController(
    text: widget.seed?.barcodeUpc ?? '',
  );
  late final serving = TextEditingController(
    text: '${widget.seed?.servingSizeValue ?? 100}',
  );
  late final calories = TextEditingController(
    text: widget.seed == null ? '' : '${widget.seed!.caloriesKcal}',
  );
  late final protein = TextEditingController(
    text: '${widget.seed?.proteinG ?? 0}',
  );
  late final carbs = TextEditingController(text: '${widget.seed?.carbsG ?? 0}');
  late final fat = TextEditingController(text: '${widget.seed?.fatG ?? 0}');
  late ServingUnit unit = widget.seed?.servingSizeUnit ?? ServingUnit.g;
  String? error;
  @override
  void dispose() {
    for (final controller in [
      name,
      barcode,
      serving,
      calories,
      protein,
      carbs,
      fat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create food'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Food name'),
          ),
          TextField(
            controller: barcode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Barcode (optional)'),
          ),
          TextField(
            controller: serving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Serving size value'),
          ),
          DropdownButtonFormField<ServingUnit>(
            initialValue: unit,
            items: ServingUnit.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(servingUnitLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => unit = value!),
            decoration: const InputDecoration(labelText: 'Serving unit'),
          ),
          TextField(
            controller: calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories per serving',
            ),
          ),
          TextField(
            controller: protein,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Protein g per serving',
            ),
          ),
          TextField(
            controller: carbs,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Carbs g per serving'),
          ),
          TextField(
            controller: fat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fat g per serving'),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _submit, child: const Text('Create')),
    ],
  );
  void _submit() {
    final servingValue = double.tryParse(serving.text);
    final kcal = double.tryParse(calories.text);
    final p = double.tryParse(protein.text);
    final c = double.tryParse(carbs.text);
    final f = double.tryParse(fat.text);
    final validBarcode =
        barcode.text.trim().isEmpty ||
        RegExp(r'^\d{8,14}$').hasMatch(barcode.text.trim());
    if (name.text.trim().length < 2 ||
        servingValue == null ||
        servingValue <= 0 ||
        kcal == null ||
        kcal < 0 ||
        p == null ||
        p < 0 ||
        c == null ||
        c < 0 ||
        f == null ||
        f < 0 ||
        !validBarcode) {
      setState(
        () => error =
            'Enter a name, non-negative macros, a positive serving, and an 8–14 digit barcode if supplied.',
      );
      return;
    }
    Navigator.pop(
      context,
      Food(
        id: 'draft',
        name: name.text.trim(),
        barcodeUpc: barcode.text.trim().isEmpty ? null : barcode.text.trim(),
        caloriesKcal: kcal,
        proteinG: p,
        carbsG: c,
        fatG: f,
        servingSizeValue: servingValue,
        servingSizeUnit: unit,
      ),
    );
  }
}

class _MealEditDialog extends StatefulWidget {
  const _MealEditDialog({required this.meal});
  final NutritionMeal meal;
  @override
  State<_MealEditDialog> createState() => _MealEditDialogState();
}

class _BarcodeDialog extends StatefulWidget {
  const _BarcodeDialog();
  @override
  State<_BarcodeDialog> createState() => _BarcodeDialogState();
}

class _BarcodeDialogState extends State<_BarcodeDialog> {
  final code = TextEditingController();
  String? error;
  bool _handledScan = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(normalized)) {
      setState(() => error = 'Enter or scan an 8–14 digit barcode.');
      return;
    }
    Navigator.pop(context, normalized);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Scan or enter barcode'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 220,
            width: 320,
            child: MobileScanner(
              onDetect: (capture) {
                if (_handledScan) return;
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty || barcodes.first.rawValue == null) return;
                _handledScan = true;
                _submit(barcodes.first.rawValue!);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If camera access is unavailable, enter the numeric code.',
          ),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Barcode'),
            onSubmitted: _submit,
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => _submit(code.text),
        child: const Text('Look up'),
      ),
    ],
  );
}

class _MealEditDialogState extends State<_MealEditDialog> {
  late final grams = TextEditingController(text: widget.meal.grams.toString());
  late final date = TextEditingController(
    text: _apiDate(widget.meal.consumedAt),
  );
  MealType type = MealType.breakfast;
  String? error;
  @override
  void initState() {
    super.initState();
    type = widget.meal.mealType;
  }

  @override
  void dispose() {
    grams.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Edit ${widget.meal.foodName}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<MealType>(
          initialValue: type,
          items: MealType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => type = value!),
          decoration: const InputDecoration(labelText: 'Meal type'),
        ),
        TextField(
          controller: grams,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.meal.servingSizeUnit == null
                ? 'Amount'
                : servingUnitLabel(widget.meal.servingSizeUnit!),
          ),
        ),
        TextField(
          controller: date,
          decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _submit, child: const Text('Save')),
    ],
  );
  void _submit() {
    final amount = double.tryParse(grams.text);
    final consumedAt = _validDate(date.text);
    if (amount == null || amount <= 0 || amount > 5000 || consumedAt == null) {
      setState(
        () => error = 'Enter an amount from 0–5,000 and a YYYY-MM-DD date.',
      );
      return;
    }
    Navigator.pop(context, (
      type: type,
      grams: amount,
      consumedAt: _dayAtNow(consumedAt),
    ));
  }
}

class _Totals {
  const _Totals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  factory _Totals.fromDraft(List<Food> foods, Map<String, double> grams) {
    double total(String Function(Food) field) => foods.fold(0, (sum, food) {
      final serving = food.servingSizeValue ?? 100;
      return sum + double.parse(field(food)) * (grams[food.id]! / serving);
    });
    return _Totals(
      calories: total((food) => '${food.caloriesKcal}'),
      protein: total((food) => '${food.proteinG}'),
      carbs: total((food) => '${food.carbsG}'),
      fat: total((food) => '${food.fatG}'),
    );
  }
}

double _defaultGrams(Food food) => food.servingSizeValue ?? 100;
DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _dayAtNow(DateTime day) {
  final now = DateTime.now();
  return DateTime(day.year, day.month, day.day, now.hour, now.minute);
}

String _apiDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime? _validDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final parsed = DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  return _apiDate(parsed) == value ? parsed : null;
}

String _displayDate(DateTime value) =>
    '${value.toLocal().month}/${value.toLocal().day}/${value.toLocal().year}';

String _mealLabel(MealType type) => switch (type) {
  MealType.breakfast => 'Breakfast',
  MealType.lunch => 'Lunch',
  MealType.dinner => 'Dinner',
  MealType.snack => 'Snack',
  MealType.uncategorized => 'Uncategorized',
};

IconData _mealIcon(MealType type) => switch (type) {
  MealType.breakfast => Icons.free_breakfast_outlined,
  MealType.lunch => Icons.lunch_dining_outlined,
  MealType.dinner => Icons.dinner_dining_outlined,
  MealType.snack => Icons.restaurant_outlined,
  MealType.uncategorized => Icons.category_outlined,
};
void _failure(BuildContext context, AppFailure error) {
  if (context.mounted)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
}

class FoodCandidateReviewResult {
  const FoodCandidateReviewResult({
    required this.food,
    required this.portionGrams,
    required this.mealType,
  });

  final Food food;
  final double portionGrams;
  final MealType mealType;
}

class _FoodPhotoLoadingDialog extends StatefulWidget {
  const _FoodPhotoLoadingDialog({
    required this.bytes,
    required this.analyze,
  });

  final List<int> bytes;
  final Future<FoodPhotoAnalysis> Function() analyze;

  @override
  State<_FoodPhotoLoadingDialog> createState() => _FoodPhotoLoadingDialogState();
}

class _FoodPhotoLoadingDialogState extends State<_FoodPhotoLoadingDialog> {
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final result = await widget.analyze();
      if (!_cancelled && mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (!_cancelled && mounted) {
        Navigator.of(context).pop(null);
        if (e is AppFailure) {
          _failure(context, e);
        } else {
          _failure(
            context,
            const AppFailure(
              'photo_analysis_failed',
              'Failed to analyze food photo. Please try again or add manually.',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Analyzing Food Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(widget.bytes),
              height: 160,
              width: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                width: 220,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant_outlined, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Identifying foods and portion estimates...'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cancelled = true;
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class FoodCandidateReviewDialog extends StatefulWidget {
  const FoodCandidateReviewDialog({
    super.key,
    required this.analysis,
    required this.imageBytes,
    required this.initialMealType,
    required this.day,
  });

  final FoodPhotoAnalysis analysis;
  final List<int> imageBytes;
  final MealType initialMealType;
  final DateTime day;

  @override
  State<FoodCandidateReviewDialog> createState() => _FoodCandidateReviewDialogState();
}

class _FoodCandidateReviewDialogState extends State<FoodCandidateReviewDialog> {
  late int _selectedIndex = 0;
  late final TextEditingController _nameController;
  late final TextEditingController _portionController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late MealType _mealType;
  late ServingUnit _servingUnit;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
    final candidate = widget.analysis.candidates.first;
    final portion = widget.analysis.suggestedPortionGrams ??
        candidate.estimatedPortionGrams ??
        candidate.servingSizeValue ??
        100;

    _nameController = TextEditingController(text: candidate.name);
    _portionController = TextEditingController(text: portion.toStringAsFixed(0));
    _caloriesController = TextEditingController(text: candidate.caloriesKcal.toStringAsFixed(0));
    _proteinController = TextEditingController(text: candidate.proteinG.toStringAsFixed(1));
    _carbsController = TextEditingController(text: candidate.carbsG.toStringAsFixed(1));
    _fatController = TextEditingController(text: candidate.fatG.toStringAsFixed(1));
    _servingUnit = candidate.servingSizeUnit ?? ServingUnit.g;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _selectCandidate(int index) {
    if (index == _selectedIndex) return;
    final candidate = widget.analysis.candidates[index];
    final portion = candidate.estimatedPortionGrams ??
        widget.analysis.suggestedPortionGrams ??
        candidate.servingSizeValue ??
        100;

    setState(() {
      _selectedIndex = index;
      _nameController.text = candidate.name;
      _portionController.text = portion.toStringAsFixed(0);
      _caloriesController.text = candidate.caloriesKcal.toStringAsFixed(0);
      _proteinController.text = candidate.proteinG.toStringAsFixed(1);
      _carbsController.text = candidate.carbsG.toStringAsFixed(1);
      _fatController.text = candidate.fatG.toStringAsFixed(1);
      _servingUnit = candidate.servingSizeUnit ?? ServingUnit.g;
      _error = null;
    });
  }

  void _recalculateForPortion(String value) {
    final newPortion = double.tryParse(value);
    if (newPortion == null || newPortion <= 0) return;

    final candidate = widget.analysis.candidates[_selectedIndex];
    final basePortion = candidate.estimatedPortionGrams ??
        candidate.servingSizeValue ??
        100;

    if (basePortion > 0) {
      final ratio = newPortion / basePortion;
      setState(() {
        _caloriesController.text = (candidate.caloriesKcal * ratio).toStringAsFixed(0);
        _proteinController.text = (candidate.proteinG * ratio).toStringAsFixed(1);
        _carbsController.text = (candidate.carbsG * ratio).toStringAsFixed(1);
        _fatController.text = (candidate.fatG * ratio).toStringAsFixed(1);
      });
    }
  }

  void _confirm() {
    final name = _nameController.text.trim();
    final portion = double.tryParse(_portionController.text);
    final cals = double.tryParse(_caloriesController.text);
    final p = double.tryParse(_proteinController.text);
    final c = double.tryParse(_carbsController.text);
    final f = double.tryParse(_fatController.text);

    if (name.length < 2) {
      setState(() => _error = 'Enter a valid food name (at least 2 letters).');
      return;
    }
    if (portion == null || portion <= 0 || portion > 5000) {
      setState(() => _error = 'Enter a valid portion amount (1 - 5,000).');
      return;
    }
    if (cals == null || cals < 0 || p == null || p < 0 || c == null || c < 0 || f == null || f < 0) {
      setState(() => _error = 'Enter valid non-negative nutrition numbers.');
      return;
    }

    final food = Food(
      id: 'draft',
      name: name,
      caloriesKcal: cals,
      proteinG: p,
      carbsG: c,
      fatG: f,
      servingSizeValue: portion,
      servingSizeUnit: _servingUnit,
    );

    Navigator.of(context).pop(
      FoodCandidateReviewResult(
        food: food,
        portionGrams: portion,
        mealType: _mealType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = widget.analysis.candidates;

    return AlertDialog(
      title: const Text('Review Food & Portion'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo preview + source banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(widget.imageBytes),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.restaurant_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logging for ${_displayDate(widget.day)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          avatar: const Icon(Icons.auto_awesome, size: 14),
                          label: Text(
                            widget.analysis.source == 'simulation'
                                ? 'Simulation Candidate'
                                : 'AI Recognition',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify suggestions before confirming. You have full edit control.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meal category dropdown
              DropdownButtonFormField<MealType>(
                initialValue: _mealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Category',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                items: MealType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_mealLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _mealType = val);
                },
              ),
              const SizedBox(height: 16),

              // Food Candidate selector if multiple candidates
              if (candidates.length > 1) ...[
                Text(
                  'Suggested candidates:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(candidates.length, (index) {
                    final cand = candidates[index];
                    final isSelected = index == _selectedIndex;
                    final confText = cand.confidence != null
                        ? ' (${(cand.confidence! * 100).round()}%)'
                        : '';
                    return ChoiceChip(
                      label: Text('${cand.name}$confText'),
                      selected: isSelected,
                      onSelected: (_) => _selectCandidate(index),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Editable Food Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Editable Portion Amount & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _portionController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Portion Amount',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      onChanged: _recalculateForPortion,
                    ),
                  ),
                  const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<ServingUnit>(
                        initialValue: _servingUnit,
                        isExpanded: true,
                        isDense: true,
                        items: ServingUnit.values
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(servingUnitLabel(u)),
                              ),
                            )
                            .toList(),
                        onChanged: (u) {
                          if (u != null) setState(() => _servingUnit = u);
                        },
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Macronutrients header
              Text(
                'Nutritional Values (for this portion):',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Discard'),
        ),
        ElevatedButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check),
          label: const Text('Confirm as Meal'),
        ),
      ],
    );
  }
}
