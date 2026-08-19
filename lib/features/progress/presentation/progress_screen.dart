import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  DateTime _month = _monthStart(DateTime.now());
  DateTime _selected = DateTime.now();
  bool _timeline = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(progressRecordProvider);
    return AppShell(
      title: 'Progress',
      child: record.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(progressRecordProvider),
            child: const Text('Retry progress record'),
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(ProgressRecord record) {
    final photosByDay = <String, List<ProgressPhoto>>{};
    for (final photo in record.photos) {
      photosByDay.putIfAbsent(_dayKey(photo.capturedAt), () => []).add(photo);
    }
    final sessionsByDay = <String, List<ProgressSession>>{};
    for (final session in record.sessions) {
      sessionsByDay
          .putIfAbsent(_dayKey(session.startedAt), () => [])
          .add(session);
    }
    final selectedKey = _dayKey(_selected);
    final selectedPhotos = photosByDay[selectedKey] ?? const [];
    final selectedSessions = sessionsByDay[selectedKey] ?? const [];
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Progress',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _saving ? null : _addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_saving ? 'Uploading…' : 'Add photo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Index visual check-ins by day, alongside the completed training evidence that belongs to them.',
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Calendar'),
              icon: Icon(Icons.calendar_month),
            ),
            ButtonSegment(
              value: true,
              label: Text('Timeline'),
              icon: Icon(Icons.view_list),
            ),
          ],
          selected: {_timeline},
          onSelectionChanged: (value) =>
              setState(() => _timeline = value.single),
        ),
        const SizedBox(height: 16),
        if (_timeline)
          _Timeline(
            photosByDay: photosByDay,
            sessionsByDay: sessionsByDay,
            onPhotoTap: _showPhoto,
            onEdit: _editPhotoDate,
            onDelete: _deletePhoto,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final calendar = _Calendar(
                month: _month,
                selected: _selected,
                photoDays: photosByDay.keys.toSet(),
                sessionDays: sessionsByDay.keys.toSet(),
                onPrevious: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                onSelect: (date) => setState(() => _selected = date),
              );
              final detail = _DayDetail(
                day: _selected,
                photos: selectedPhotos,
                sessions: selectedSessions,
                onPhotoTap: _showPhoto,
                onEdit: _editPhotoDate,
                onDelete: _deletePhoto,
              );
              return constraints.maxWidth >= 820
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: calendar),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: detail),
                      ],
                    )
                  : Column(
                      children: [calendar, const SizedBox(height: 16), detail],
                    );
            },
          ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    final date = TextEditingController(text: _apiDate(_selected));
    final note = TextEditingController();
    final details = await showDialog<({DateTime date, String? note})>(
      context: context,
      builder: (dialog) {
        String? error;
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            title: const Text('Add progress photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: 'Photo date (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: note,
                  maxLength: 400,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final capturedAt = _validDate(date.text);
                  if (capturedAt == null) {
                    setState(
                      () => error = 'Enter the photo date as YYYY-MM-DD.',
                    );
                    return;
                  }
                  Navigator.pop(dialog, (
                    date: capturedAt,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  ));
                },
                child: const Text('Choose photo'),
              ),
            ],
          ),
        );
      },
    );
    date.dispose();
    note.dispose();
    if (details == null) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (bytes.lengthInBytes > 20 * 1024 * 1024) {
        throw const AppFailure(
          'progress_photo_too_large',
          'Choose an image smaller than 20 MB.',
        );
      }
      setState(() => _saving = true);
      await ref
          .read(progressRepositoryProvider)
          .create(
            ProgressPhotoUpload(
              fileName: selected.name,
              mimeType: selected.mimeType ?? 'image/jpeg',
              bytes: bytes,
              capturedAt: details.date,
              note: details.note,
            ),
          );
      if (mounted) setState(() => _selected = details.date);
      ref.invalidate(progressRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } catch (_) {
      _failure(
        context,
        const AppFailure(
          'progress_upload_failed',
          'Unable to read or upload the selected progress photo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editPhotoDate(ProgressPhoto photo) async {
    final date = TextEditingController(text: _apiDate(photo.capturedAt));
    final updated = await showDialog<DateTime>(
      context: context,
      builder: (dialog) {
        String? error;
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            title: const Text('Change photo date'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: 'Photo date (YYYY-MM-DD)',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsed = _validDate(date.text);
                  if (parsed == null) {
                    setState(
                      () => error = 'Enter the photo date as YYYY-MM-DD.',
                    );
                  } else {
                    Navigator.pop(dialog, parsed);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    date.dispose();
    if (updated == null) return;
    try {
      setState(() => _saving = true);
      await ref
          .read(progressRepositoryProvider)
          .updateCapturedAt(photo.id, updated);
      if (mounted) setState(() => _selected = updated);
      ref.invalidate(progressRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove progress photo?'),
        content: const Text(
          'This removes the photo from your private progress record.',
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
      await ref.read(progressRepositoryProvider).delete(photo.id);
      ref.invalidate(progressRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPhoto(ProgressPhoto photo) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text('Progress photo · ${_date(photo.capturedAt)}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: _PhotoImage(photo: photo, fit: BoxFit.contain),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.selected,
    required this.photoDays,
    required this.sessionDays,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });
  final DateTime month;
  final DateTime selected;
  final Set<String> photoDays;
  final Set<String> sessionDays;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final cells = <Widget>[];
    for (var blank = 0; blank < first.weekday % 7; blank++) {
      cells.add(const SizedBox.shrink());
    }
    final days = DateTime(month.year, month.month + 1, 0).day;
    for (var day = 1; day <= days; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = _dayKey(date);
      final hasPhoto = photoDays.contains(key);
      final hasSession = sessionDays.contains(key);
      cells.add(
        Semantics(
          button: true,
          label:
              '${_date(date)}${hasPhoto ? ', progress photo' : ''}${hasSession ? ', training session' : ''}',
          child: InkWell(
            onTap: () => onSelect(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: DateUtils.isSameDay(selected, date)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 3,
                      children: [
                        if (hasPhoto) const Icon(Icons.photo, size: 14),
                        if (hasSession)
                          const Icon(Icons.fitness_center, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPrevious,
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(month.month)} ${month.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (final day in [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                ])
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 330,
              child: GridView.count(
                crossAxisCount: 7,
                childAspectRatio: 0.92,
                physics: const NeverScrollableScrollPhysics(),
                children: cells,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({
    required this.day,
    required this.photos,
    required this.sessions,
    required this.onPhotoTap,
    required this.onEdit,
    required this.onDelete,
  });
  final DateTime day;
  final List<ProgressPhoto> photos;
  final List<ProgressSession> sessions;
  final ValueChanged<ProgressPhoto> onPhotoTap;
  final ValueChanged<ProgressPhoto> onEdit;
  final ValueChanged<ProgressPhoto> onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_date(day), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (photos.isEmpty && sessions.isEmpty)
            const Text('No work or progress photo recorded on this date.'),
          if (photos.isNotEmpty) ...[
            const Text(
              'Progress photos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...photos.map(
              (photo) => _PhotoTile(
                photo: photo,
                onTap: () => onPhotoTap(photo),
                onEdit: () => onEdit(photo),
                onDelete: () => onDelete(photo),
              ),
            ),
          ],
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Training record',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...sessions.map(
              (session) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center),
                title: Text(
                  '${session.planName ?? 'Workout'}${session.planDayName == null ? '' : ' · ${session.planDayName}'}',
                ),
                subtitle: Text(session.status.name),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.photosByDay,
    required this.sessionsByDay,
    required this.onPhotoTap,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, List<ProgressPhoto>> photosByDay;
  final Map<String, List<ProgressSession>> sessionsByDay;
  final ValueChanged<ProgressPhoto> onPhotoTap;
  final ValueChanged<ProgressPhoto> onEdit;
  final ValueChanged<ProgressPhoto> onDelete;

  @override
  Widget build(BuildContext context) {
    final days = {...photosByDay.keys, ...sessionsByDay.keys}.toList()
      ..sort((a, b) => b.compareTo(a));
    if (days.isEmpty)
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No progress records yet. Add a photo to start a visual check-in.',
          ),
        ),
      );
    return Column(
      children: days
          .map(
            (key) => _DayDetail(
              day: DateTime.parse(key),
              photos: photosByDay[key] ?? const [],
              sessions: sessionsByDay[key] ?? const [],
              onPhotoTap: onPhotoTap,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          )
          .toList(),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final ProgressPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 92,
            height: 92,
            child: _PhotoImage(photo: photo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            photo.note?.isNotEmpty == true ? photo.note! : 'Progress photo',
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Change date')),
            PopupMenuItem(value: 'delete', child: Text('Remove')),
          ],
        ),
      ],
    ),
  );
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.photo, required this.fit});
  final ProgressPhoto photo;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (photo.localBytes != null)
      return Image.memory(
        photo.localBytes!,
        fit: fit,
        errorBuilder: (_, __, ___) => _unavailable(),
      );
    if (photo.imageUrl != null)
      return Image.network(
        photo.imageUrl!,
        fit: fit,
        errorBuilder: (_, __, ___) => _unavailable(),
      );
    return _unavailable();
  }

  Widget _unavailable() => const ColoredBox(
    color: Color(0xffDED4C6),
    child: Center(child: Icon(Icons.image_not_supported_outlined)),
  );
}

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);
String _dayKey(DateTime value) => _apiDate(value);
String _apiDate(DateTime value) => value.toIso8601String().substring(0, 10);
String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
DateTime? _validDate(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed != null && _apiDate(parsed) == value ? parsed : null;
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
void _failure(BuildContext context, AppFailure error) {
  if (context.mounted)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
}
