import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/commons/event_date_formatter.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/screens/events/event_location_picker_screen.dart';
import 'package:campus_online/services/media_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EventManagementScreen extends ConsumerStatefulWidget {
  const EventManagementScreen({super.key});

  @override
  ConsumerState<EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends ConsumerState<EventManagementScreen> {
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime? _startAt;
  DateTime? _endAt;
  bool _isPublished = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _editingEventId;
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double? _parseCoordinate(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final latitude = _parseCoordinate(value);
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'Geçerli enlem girin';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final longitude = _parseCoordinate(value);
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'Geçerli boylam girin';
    }
    return null;
  }

  Future<void> _openMapPicker() async {
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);

    final selected = await Navigator.of(context).push<EventLocationSelection>(
      MaterialPageRoute(
        builder: (_) => EventLocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
          initialLocationLabel: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        ),
      ),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _latitudeController.text = selected.latitude.toStringAsFixed(6);
      _longitudeController.text = selected.longitude.toStringAsFixed(6);
      if (_locationController.text.trim().isEmpty &&
          (selected.locationLabel ?? '').trim().isNotEmpty) {
        _locationController.text = selected.locationLabel!.trim();
      }
    });

    AppError.showSuccess(context, 'Konum seçildi.');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year} $hh:$min';
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final initialDate = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickAndUploadEventImage(ImageSource source) async {
    if (_isUploadingImage) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _mediaUploadService.pickAndUploadImage(
        entityType: MediaEntityType.event,
        source: source,
      );

      if (!mounted || imageUrl == null) return;
      setState(() {
        _imageUrlController.text = imageUrl;
      });
      AppError.showSuccess(context, 'Etkinlik görseli yüklendi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _pickEventImageFromGallery() {
    return _pickAndUploadEventImage(ImageSource.gallery);
  }

  Future<void> _pickEventImageFromCamera() {
    return _pickAndUploadEventImage(ImageSource.camera);
  }

  void _clearEventImage() {
    setState(_imageUrlController.clear);
  }

  Widget _buildImageUploadSection(ThemeData theme) {
    final imageUrl = _imageUrlController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 36),
                ),
              ),
            ),
          ),
        if (imageUrl.isNotEmpty) const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isUploadingImage ? null : _pickEventImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _pickEventImageFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Kamera'),
              ),
            ),
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Görseli temizle',
                onPressed: _isUploadingImage ? null : _clearEventImage,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          imageUrl.isEmpty
              ? 'Galeri veya kamera ile görsel ekleyin.'
              : 'Görsel seçildi. Kaydettiğinizde etkinliğe atanır.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _setEditingEvent(EventModel event) {
    setState(() {
      _editingEventId = event.id;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _latitudeController.text = event.latitude?.toStringAsFixed(6) ?? '';
      _longitudeController.text = event.longitude?.toStringAsFixed(6) ?? '';
      _imageUrlController.text = event.imageUrl ?? '';
      _startAt = event.startAt.toLocal();
      _endAt = event.endAt.toLocal();
      _isPublished = event.isPublished;
    });
  }

  void _clearForm() {
    setState(() {
      _editingEventId = null;
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _imageUrlController.clear();
      _startAt = null;
      _endAt = null;
      _isPublished = true;
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startAt == null || _endAt == null) {
      AppError.showError(context, 'Başlangıç ve bitiş tarihi seçin.');
      return;
    }

    if (_endAt!.isBefore(_startAt!)) {
      AppError.showError(context, 'Bitiş tarihi başlangıçtan once olamaz.');
      return;
    }

    final hasLatitude = _latitudeController.text.trim().isNotEmpty;
    final hasLongitude = _longitudeController.text.trim().isNotEmpty;
    if (hasLatitude != hasLongitude) {
      AppError.showError(
        context,
        'Koordinat kullanacaksaniz enlem ve boylami birlikte girin.',
      );
      return;
    }

    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    if (hasLatitude && (latitude == null || longitude == null)) {
      AppError.showError(context, 'Koordinat degerleri geçersiz.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final eventService = ref.read(eventServiceProvider);

    try {
      await eventService.saveEvent(
        eventId: _editingEventId,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        latitude: latitude,
        longitude: longitude,
        imageUrl: _imageUrlController.text,
        startAt: _startAt!,
        endAt: _endAt!,
        isPublished: _isPublished,
      );

      invalidateEvents(ref);
      ref.invalidate(manageableEventsProvider(_searchQuery));

      if (!mounted) return;
      AppError.showSuccess(
        context,
        _editingEventId == null ? 'Etkinlik eklendi.' : 'Etkinlik güncellendi.',
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği sil'),
        content: const Text('Bu etkinliği silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(eventServiceProvider).deleteEvent(eventId);
      invalidateEvents(ref);
      ref.invalidate(manageableEventsProvider(_searchQuery));
      if (!mounted) return;
      AppError.showSuccess(context, 'Etkinlik silindi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(manageableEventsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(title: const Text('Etkinlik Yönetimi')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _editingEventId == null
                                    ? Icons.event_available
                                    : Icons.edit_calendar,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editingEventId == null
                                    ? 'Yeni Etkinlik'
                                    : 'Etkinlik Düzenle',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Baslik',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Baslik zorunludur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Konum adı / adres',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Enlem',
                                    hintText: 'Orn: 41.0082',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: _validateLatitude,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Boylam',
                                    hintText: 'Orn: 28.9784',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: _validateLongitude,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openMapPicker,
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Haritadan Sec'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Konumu koordinatla girin veya haritadan seçin. Tarif Al bu koordinatlari kullanir.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildImageUploadSection(theme),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Açıklama',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final selected = await _pickDateTime(
                                      _startAt,
                                    );
                                    if (selected == null) return;
                                    setState(() {
                                      _startAt = selected;
                                      _endAt ??= selected.add(
                                        const Duration(hours: 2),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.schedule),
                                  label: Text(
                                    _startAt == null
                                        ? 'Başlangıç sec'
                                        : _formatDateTime(_startAt!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final selected = await _pickDateTime(
                                      _endAt,
                                    );
                                    if (selected == null) return;
                                    setState(() {
                                      _endAt = selected;
                                    });
                                  },
                                  icon: const Icon(Icons.event),
                                  label: Text(
                                    _endAt == null
                                        ? 'Bitiş sec'
                                        : _formatDateTime(_endAt!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: _isPublished,
                            title: const Text('Yayinda'),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _isPublished = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSaving ? null : _saveEvent,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _editingEventId == null
                                              ? Icons.add
                                              : Icons.save,
                                        ),
                                  label: Text(
                                    _editingEventId == null
                                        ? 'Etkinliği Kaydet'
                                        : 'Güncelle',
                                  ),
                                ),
                              ),
                              if (_editingEventId != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _clearForm,
                                    icon: const Icon(Icons.close),
                                    label: const Text('İptal'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Etkinlik ara',
                    hintText: 'Baslik, konum veya açıklama',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Mevcut Etkinlikler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Etkinlik bulunamadı.'),
                        ),
                      );
                    }

                    return Column(
                      children: events
                          .map(
                            (event) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(event.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      formatEventDateRange(
                                        event.startAt,
                                        event.endAt,
                                      ),
                                    ),
                                    if (event.location != null &&
                                        event.location!.isNotEmpty)
                                      Text(event.location!),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Chip(
                                          label: Text(
                                            event.isPublished
                                                ? 'Yayinda'
                                                : 'Taslak',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Düzenle',
                                      onPressed: () => _setEditingEvent(event),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      tooltip: 'Sil',
                                      onPressed: () => _deleteEvent(event.id),
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Etkinlikler yüklenemedi: $error'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
