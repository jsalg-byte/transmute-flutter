import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  final _query = TextEditingController();
  final Map<String, double> _draft = {};
  DateTime _day = _dateOnly(DateTime.now());
  MealType _type = MealType.breakfast;
  bool _saving = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(nutritionRecordProvider);
    return AppShell(
      title: 'Nutrition',
      child: record.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(nutritionRecordProvider),
            child: const Text('Retry nutrition record'),
          ),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(NutritionRecord record) {
    final meals = record.meals
        .where((meal) => DateUtils.isSameDay(meal.consumedAt, _day))
        .toList();
    final draftFoods = record.foods
        .where((food) => _draft.containsKey(food.id))
        .toList();
    final query = _query.text.trim().toLowerCase();
    final foods = record.foods
        .where(
          (food) => query.isEmpty || food.name.toLowerCase().contains(query),
        )
        .toList();
    final totals = _Totals.fromMeals(meals);
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
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'create') _createFood();
                if (value == 'barcode') _barcode();
                if (value == 'label') _readLabel();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'create', child: Text('Create food')),
                PopupMenuItem(
                  value: 'barcode',
                  child: Text('Scan or enter barcode'),
                ),
                PopupMenuItem(
                  value: 'label',
                  child: Text('Read nutrition label'),
                ),
              ],
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _createFood(),
                icon: const Icon(Icons.add),
                label: const Text('Add food'),
              ),
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
          totals: totals,
          onPrevious: () =>
              setState(() => _day = _day.subtract(const Duration(days: 1))),
          onNext: () =>
              setState(() => _day = _day.add(const Duration(days: 1))),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final catalog = _Catalog(
              query: _query,
              foods: foods,
              onChanged: () => setState(() {}),
              onAdd: _addFood,
            );
            final composer = _MealComposer(
              foods: draftFoods,
              grams: _draft,
              type: _type,
              day: _day,
              saving: _saving,
              onTypeChanged: (type) => setState(() => _type = type),
              onAmountChanged: (food, grams) =>
                  setState(() => _draft[food.id] = grams),
              onRemove: (food) => setState(() => _draft.remove(food.id)),
              onSave: () => _saveMeal(draftFoods),
            );
            return constraints.maxWidth >= 960
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: catalog),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: composer),
                    ],
                  )
                : Column(
                    children: [catalog, const SizedBox(height: 16), composer],
                  );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Food record · ${_displayDate(_day)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (meals.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No food logged on this date. Add foods to the meal composer above.',
              ),
            ),
          )
        else
          ...meals.map(
            (meal) => _MealTile(
              meal: meal,
              onEdit: () => _editMeal(meal),
              onDelete: () => _deleteMeal(meal),
              onPhoto: () => _uploadMealPhoto(meal),
            ),
          ),
      ],
    );
  }

  void _addFood(Food food) {
    setState(() => _draft.putIfAbsent(food.id, () => _defaultGrams(food)));
  }

  Future<void> _saveMeal(List<Food> foods) async {
    if (foods.isEmpty) return;
    try {
      setState(() => _saving = true);
      await ref
          .read(nutritionRepositoryProvider)
          .createMeal(
            _type,
            foods
                .map(
                  (food) =>
                      MealItemInput(foodId: food.id, grams: _draft[food.id]!),
                )
                .toList(),
            consumedAt: _dayAtNow(_day),
          );
      setState(() => _draft.clear());
      ref.invalidate(nutritionRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
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
        _addFood(result.food!);
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
    required this.totals,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime day;
  final _Totals totals;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                tooltip: 'Previous day',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _displayDate(day),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onNext,
                tooltip: 'Next day',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _Macro(
                label: 'Calories',
                value: '${totals.calories.round()} kcal',
              ),
              _Macro(
                label: 'Protein',
                value: '${totals.protein.toStringAsFixed(1)} g',
              ),
              _Macro(
                label: 'Carbs',
                value: '${totals.carbs.toStringAsFixed(1)} g',
              ),
              _Macro(label: 'Fat', value: '${totals.fat.toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label),
    ],
  );
}

class _Catalog extends StatelessWidget {
  const _Catalog({
    required this.query,
    required this.foods,
    required this.onChanged,
    required this.onAdd,
  });
  final TextEditingController query;
  final List<Food> foods;
  final VoidCallback onChanged;
  final ValueChanged<Food> onAdd;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food catalog', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: query,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search foods',
            ),
          ),
          const SizedBox(height: 8),
          if (foods.isEmpty)
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
                child: Text(saving ? 'Saving…' : 'Log meal'),
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
        '${meal.mealType.name} · ${meal.grams.toStringAsFixed(1)} ${meal.servingSizeUnit == null ? 'servings' : servingUnitLabel(meal.servingSizeUnit!)} · ${meal.caloriesKcal.round()} kcal\nP ${meal.proteinG.toStringAsFixed(1)} · C ${meal.carbsG.toStringAsFixed(1)} · F ${meal.fatG.toStringAsFixed(1)}',
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
  factory _Totals.fromMeals(List<NutritionMeal> meals) => _Totals(
    calories: meals.fold(0, (sum, meal) => sum + meal.caloriesKcal),
    protein: meals.fold(0, (sum, meal) => sum + meal.proteinG),
    carbs: meals.fold(0, (sum, meal) => sum + meal.carbsG),
    fat: meals.fold(0, (sum, meal) => sum + meal.fatG),
  );
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
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime _dayAtNow(DateTime day) {
  final now = DateTime.now();
  return DateTime(day.year, day.month, day.day, now.hour, now.minute);
}

String _apiDate(DateTime value) => value.toIso8601String().substring(0, 10);
DateTime? _validDate(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed != null && _apiDate(parsed) == value ? parsed : null;
}

String _displayDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';
void _failure(BuildContext context, AppFailure error) {
  if (context.mounted)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
}
