import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/admin_models.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/screens/events/event_location_picker_screen.dart';
import 'package:campus_online/services/admin_service.dart';
import 'package:campus_online/services/media_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class VenueManagementPage extends ConsumerStatefulWidget {
  final AsyncValue<List<VenueModel>> venuesAsync;
  final UserAccessProfile access;

  const VenueManagementPage({
    super.key,
    required this.venuesAsync,
    required this.access,
  });

  @override
  ConsumerState<VenueManagementPage> createState() =>
      _VenueManagementPageState();
}

class _VenueManagementPageState extends ConsumerState<VenueManagementPage>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final MediaUploadService _mediaUploadService = MediaUploadService();

  final _venueFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _weekdayHoursController = TextEditingController();
  final _weekendHoursController = TextEditingController();
  final _menuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _announcementController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _venueSearchController = TextEditingController();

  bool _isEditingVenue = false;
  bool _showVenueForm = false;
  String? _editingVenueId;
  bool _isSavingVenue = false;
  bool _isUploadingVenueImage = false;
  String _venueSearchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _weekdayHoursController.dispose();
    _weekendHoursController.dispose();
    _menuController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _imageUrlController.dispose();
    _venueSearchController.dispose();
    super.dispose();
  }

  // ── Yardımcı metotlar ─────────────────────────────────────

  bool _matchesVenue(VenueModel venue, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    final bucket = [
      venue.name,
      venue.category ?? '',
      venue.location ?? '',
      venue.description ?? '',
    ].join(' ').toLowerCase();

    return bucket.contains(cleanQuery);
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

  // ── Aksiyonlar ────────────────────────────────────────────

  Future<void> _openVenueMapPicker() async {
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

  void _populateVenueForm(VenueModel venue) {
    setState(() {
      _showVenueForm = true;
      _isEditingVenue = true;
      _editingVenueId = venue.id;
      _nameController.text = venue.name;
      _categoryController.text = venue.category ?? '';
      _locationController.text = venue.location ?? '';
      _latitudeController.text = venue.latitude?.toStringAsFixed(6) ?? '';
      _longitudeController.text = venue.longitude?.toStringAsFixed(6) ?? '';
      _weekdayHoursController.text = venue.hours;
      _weekendHoursController.text = venue.weekendHours;
      _menuController.text = venue.menu ?? '';
      _descriptionController.text = venue.description ?? '';
      _announcementController.text = venue.announcement ?? '';
      _imageUrlController.text = venue.imageUrl ?? '';
    });
  }

  void _clearVenueForm() {
    setState(() {
      _isEditingVenue = false;
      _editingVenueId = null;
      _showVenueForm = false;
      _nameController.clear();
      _categoryController.clear();
      _locationController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _weekdayHoursController.clear();
      _weekendHoursController.clear();
      _menuController.clear();
      _descriptionController.clear();
      _announcementController.clear();
      _imageUrlController.clear();
    });
  }

  Future<void> _saveVenue() async {
    if (!_venueFormKey.currentState!.validate()) return;

    final hasLatitude = _latitudeController.text.trim().isNotEmpty;
    final hasLongitude = _longitudeController.text.trim().isNotEmpty;
    if (hasLatitude != hasLongitude) {
      AppError.showError(
        context,
        'Koordinat kullanacaksanız enlem ve boylamı birlikte girin.',
      );
      return;
    }

    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    if (hasLatitude && (latitude == null || longitude == null)) {
      AppError.showError(context, 'Koordinat değerleri geçersiz.');
      return;
    }

    setState(() {
      _isSavingVenue = true;
    });

    try {
      final venueData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'hours': _weekdayHoursController.text.trim(),
        'weekend_hours': _weekendHoursController.text.trim(),
        'menu': _menuController.text.trim().isEmpty
            ? null
            : _menuController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'announcement': _announcementController.text.trim().isEmpty
            ? null
            : _announcementController.text.trim(),
        'image_url': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
      };

      if (_isEditingVenue && _editingVenueId != null) {
        await _adminService.updateVenue(_editingVenueId!, venueData);
        ref.invalidate(venueByIdProvider(_editingVenueId!));
      } else {
        await _adminService.addVenue(venueData);
      }

      clearVenuesCache(ref);
      ref.invalidate(venuesProvider);

      if (!mounted) return;
      AppError.showSuccess(
        context,
        _isEditingVenue ? 'Mekan güncellendi.' : 'Mekan eklendi.',
      );
      _clearVenueForm();
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingVenue = false;
        });
      }
    }
  }

  Future<void> _deleteVenue(String venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mekanı sil'),
        content: const Text('Bu mekanı silmek istediğinize emin misiniz?'),
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
      await _adminService.deleteVenue(venueId);
      clearVenuesCache(ref);
      ref.invalidate(venuesProvider);

      if (!mounted) return;
      AppError.showSuccess(context, 'Mekan silindi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  // ── Görsel Yükleme ────────────────────────────────────────

  Future<void> _pickAndUploadVenueImage(ImageSource source) async {
    if (_isUploadingVenueImage) return;

    setState(() {
      _isUploadingVenueImage = true;
    });

    try {
      final imageUrl = await _mediaUploadService.pickAndUploadImage(
        entityType: MediaEntityType.venue,
        source: source,
      );

      if (!mounted || imageUrl == null) return;
      setState(() {
        _imageUrlController.text = imageUrl;
      });
      AppError.showSuccess(context, 'Mekan görseli yüklendi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVenueImage = false;
        });
      }
    }
  }

  Future<void> _pickVenueImageFromGallery() {
    return _pickAndUploadVenueImage(ImageSource.gallery);
  }

  Future<void> _pickVenueImageFromCamera() {
    return _pickAndUploadVenueImage(ImageSource.camera);
  }

  void _clearVenueImage() {
    setState(_imageUrlController.clear);
  }

  // ── Widget'lar ────────────────────────────────────────────

  Widget _buildVenueImageUploadSection(ThemeData theme) {
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
                    _isUploadingVenueImage ? null : _pickVenueImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isUploadingVenueImage ? null : _pickVenueImageFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Kamera'),
              ),
            ),
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Görseli temizle',
                onPressed: _isUploadingVenueImage ? null : _clearVenueImage,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          imageUrl.isEmpty
              ? 'Galeri veya kamera ile mekan görseli ekleyin.'
              : 'Görsel seçildi. Kaydettiğinizde mekana atanır.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueFormCard() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _venueFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_isEditingVenue ? Icons.edit : Icons.add_business),
                  const SizedBox(width: 8),
                  Text(
                    _isEditingVenue ? 'Mekan Düzenle' : 'Yeni Mekan Ekle',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Mekan Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mekan adı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enlem',
                        hintText: 'Örn: 41.0082',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateLatitude,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Boylam',
                        hintText: 'Örn: 28.9784',
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
                    onPressed: _openVenueMapPicker,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Haritadan Seç'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Konumu koordinatla girin veya haritadan seçin. Tarif al özelliği bu koordinatları kullanır.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weekdayHoursController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Hafta içi saatleri',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Çalışma saatleri zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weekendHoursController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Hafta sonu saatleri',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _menuController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Menü (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _announcementController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Duyuru (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _buildVenueImageUploadSection(theme),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSavingVenue ? null : _saveVenue,
                      icon: _isSavingVenue
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEditingVenue ? Icons.save : Icons.add),
                      label: Text(
                        _isEditingVenue ? 'Güncelle' : 'Mekanı Kaydet',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _clearVenueForm,
                    icon: const Icon(Icons.close),
                    label: const Text('İptal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canCreateOrDeleteVenues = widget.access.isAdmin;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _venueSearchController,
                  decoration: InputDecoration(
                    labelText: 'Mekan ara',
                    hintText: 'Ad, kategori, konum...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _venueSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                _venueSearchController.clear();
                                _venueSearchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _venueSearchQuery = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (canCreateOrDeleteVenues)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showVenueForm = !_showVenueForm;
                              if (!_showVenueForm) {
                                _clearVenueForm();
                              }
                            });
                          },
                          icon: Icon(
                            _showVenueForm ? Icons.expand_less : Icons.add,
                          ),
                          label: Text(
                            _showVenueForm ? 'Formu Gizle' : 'Yeni Mekan Ekle',
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Size atanan mekanları düzenleyebilirsiniz.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if ((canCreateOrDeleteVenues && _showVenueForm) || _isEditingVenue) ...[
          const SizedBox(height: 12),
          _buildVenueFormCard(),
        ],
        const SizedBox(height: 12),
        Text(
          'Mekan Listesi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        widget.venuesAsync.when(
          data: (venues) {
            final manageableVenueIds = widget.access.editableVenueIds;
            final visibleVenues = widget.access.isAdmin
                ? venues
                : venues
                    .where((venue) => manageableVenueIds.contains(venue.id))
                    .toList();

            final filtered = visibleVenues
                .where((venue) => _matchesVenue(venue, _venueSearchQuery))
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

            if (filtered.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.access.isAdmin
                        ? 'Mekan bulunamadı.'
                        : 'Size atanmış mekan bulunamadı.',
                  ),
                ),
              );
            }

            return Column(
              children: filtered.map(
                (venue) {
                  final canEditVenue = widget.access.isAdmin ||
                      manageableVenueIds.contains(venue.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(venue.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((venue.category ?? '').isNotEmpty)
                            Text('Kategori: ${venue.category}'),
                          if ((venue.location ?? '').isNotEmpty)
                            Text('Konum: ${venue.location}'),
                        ],
                      ),
                      trailing: canEditVenue || widget.access.isAdmin
                          ? Wrap(
                              spacing: 4,
                              children: [
                                if (canEditVenue)
                                  IconButton(
                                    tooltip: 'Düzenle',
                                    onPressed: () => _populateVenueForm(venue),
                                    icon: const Icon(Icons.edit),
                                  ),
                                if (widget.access.isAdmin)
                                  IconButton(
                                    tooltip: 'Sil',
                                    onPressed: () => _deleteVenue(venue.id),
                                    icon: const Icon(Icons.delete),
                                  ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Mekanlar yüklenemedi: $error'),
            ),
          ),
        ),
      ],
    );
  }
}
