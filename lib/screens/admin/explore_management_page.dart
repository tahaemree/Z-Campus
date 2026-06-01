import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/models/explore_models.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/providers/explore_provider.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExploreManagementPage extends ConsumerStatefulWidget {
  const ExploreManagementPage({super.key});

  @override
  ConsumerState<ExploreManagementPage> createState() =>
      _ExploreManagementPageState();
}

class _ExploreManagementPageState extends ConsumerState<ExploreManagementPage>
    with AutomaticKeepAliveClientMixin {
  final _settingsFormKey = GlobalKey<FormState>();
  final _contributionFormKey = GlobalKey<FormState>();
  final _contributionsTitleController = TextEditingController();
  final _recentViewsTitleController = TextEditingController();
  final _contributionsLimitController = TextEditingController();
  final _recentViewsLimitController = TextEditingController();
  final _labelController = TextEditingController();
  final _displayOrderController = TextEditingController(text: '0');

  bool _settingsInitialized = false;
  bool _showContributions = true;
  bool _showRecentViews = true;
  bool _isSavingSettings = false;
  bool _isSavingContribution = false;
  bool _isContributionActive = true;
  String _itemType = 'venue';
  String? _selectedTargetId;
  String? _editingContributionId;
  DateTime? _startsAt;
  DateTime? _endsAt;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _contributionsTitleController.dispose();
    _recentViewsTitleController.dispose();
    _contributionsLimitController.dispose();
    _recentViewsLimitController.dispose();
    _labelController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  void _populateSettings(ExploreSettings settings) {
    _settingsInitialized = true;
    _showContributions = settings.showContributions;
    _showRecentViews = settings.showRecentViews;
    _contributionsTitleController.text = settings.contributionsTitle;
    _recentViewsTitleController.text = settings.recentViewsTitle;
    _contributionsLimitController.text = settings.contributionsLimit.toString();
    _recentViewsLimitController.text = settings.recentViewsLimit.toString();
  }

  int _parseLimit(TextEditingController controller, int fallback) {
    final parsed = int.tryParse(controller.text.trim()) ?? fallback;
    return parsed.clamp(1, 50).toInt();
  }

  int _parseDisplayOrder() {
    return int.tryParse(_displayOrderController.text.trim()) ?? 0;
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

  Future<void> _saveSettings() async {
    if (!_settingsFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingSettings = true;
    });

    try {
      final settings = ExploreSettings(
        showContributions: _showContributions,
        showRecentViews: _showRecentViews,
        contributionsTitle: _contributionsTitleController.text.trim(),
        recentViewsTitle: _recentViewsTitleController.text.trim(),
        contributionsLimit: _parseLimit(
          _contributionsLimitController,
          ExploreSettings.defaults.contributionsLimit,
        ),
        recentViewsLimit: _parseLimit(
          _recentViewsLimitController,
          ExploreSettings.defaults.recentViewsLimit,
        ),
      );

      await ref.read(exploreServiceProvider).saveSettings(settings);
      invalidateExplore(ref);

      if (!mounted) return;
      AppError.showSuccess(context, 'Keşfet ayarları kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  Future<void> _saveContribution() async {
    if (!_contributionFormKey.currentState!.validate()) return;

    if (_selectedTargetId == null) {
      AppError.showError(context, 'Bir mekan veya etkinlik seçin.');
      return;
    }

    if (_startsAt != null &&
        _endsAt != null &&
        _endsAt!.isBefore(_startsAt!)) {
      AppError.showError(
        context,
        'Bitiş tarihi başlangıç tarihinden önce olamaz.',
      );
      return;
    }

    setState(() {
      _isSavingContribution = true;
    });

    try {
      await ref.read(exploreServiceProvider).saveContribution(
            id: _editingContributionId,
            itemType: _itemType,
            targetId: _selectedTargetId!,
            label: _labelController.text,
            displayOrder: _parseDisplayOrder(),
            isActive: _isContributionActive,
            startsAt: _startsAt,
            endsAt: _endsAt,
          );

      invalidateExplore(ref);
      _clearContributionForm();

      if (!mounted) return;
      AppError.showSuccess(context, 'Keşfet içeriği kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingContribution = false;
        });
      }
    }
  }

  Future<void> _deleteContribution(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keşfet içeriğini kaldır'),
        content:
            const Text('Bu öğeyi Keşfet menüsünden kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(exploreServiceProvider).deleteContribution(id);
      invalidateExplore(ref);

      if (!mounted) return;
      AppError.showSuccess(context, 'Keşfet içeriği kaldırıldı.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  void _editContribution(ExploreContribution item) {
    setState(() {
      _editingContributionId = item.id;
      _itemType = item.itemType;
      _selectedTargetId = item.venue?.id ?? item.event?.id;
      _labelController.text = item.label ?? '';
      _displayOrderController.text = item.displayOrder.toString();
      _isContributionActive = item.isActive;
      _startsAt = item.startsAt?.toLocal();
      _endsAt = item.endsAt?.toLocal();
    });
  }

  void _clearContributionForm() {
    setState(() {
      _editingContributionId = null;
      _itemType = 'venue';
      _selectedTargetId = null;
      _labelController.clear();
      _displayOrderController.text = '0';
      _isContributionActive = true;
      _startsAt = null;
      _endsAt = null;
    });
  }

  List<DropdownMenuItem<String>> _venueItems(List<VenueModel> venues) {
    final sorted = List<VenueModel>.from(venues)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return [
      for (final venue in sorted)
        DropdownMenuItem(
          value: venue.id,
          child: Text(venue.name, overflow: TextOverflow.ellipsis),
        ),
    ];
  }

  List<DropdownMenuItem<String>> _eventItems(List<EventModel> events) {
    final sorted = List<EventModel>.from(events)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return [
      for (final event in sorted)
        DropdownMenuItem(
          value: event.id,
          child: Text(event.title, overflow: TextOverflow.ellipsis),
        ),
    ];
  }

  Widget _buildSchedulePicker({
    required String label,
    required DateTime? value,
    required IconData icon,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null ? 'Süresiz' : _formatDateTime(value),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Tarih seç',
            onPressed: () async {
              final selected = await _pickDateTime(value);
              if (!mounted || selected == null) return;
              setState(() => onChanged(selected));
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Temizle',
              onPressed: () => setState(() => onChanged(null)),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ExploreSettings settings) {
    if (!_settingsInitialized) {
      _populateSettings(settings);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _settingsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Keşfet Ayarları',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Katkıda bulunanları göster'),
                value: _showContributions,
                onChanged: (value) {
                  setState(() {
                    _showContributions = value;
                  });
                },
              ),
              TextFormField(
                controller: _contributionsTitleController,
                decoration: const InputDecoration(
                  labelText: 'Katkı bölümü başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Başlık zorunlu'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contributionsLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Katkı limiti',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 1 || parsed > 50) {
                    return '1-50 arasında değer girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Son göz atılan yerleri göster'),
                value: _showRecentViews,
                onChanged: (value) {
                  setState(() {
                    _showRecentViews = value;
                  });
                },
              ),
              TextFormField(
                controller: _recentViewsTitleController,
                decoration: const InputDecoration(
                  labelText: 'Son göz atılanlar başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Başlık zorunlu'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recentViewsLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Son göz atılanlar limiti',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 1 || parsed > 50) {
                    return '1-50 arasında değer girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isSavingSettings ? null : _saveSettings,
                icon: _isSavingSettings
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Ayarları Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributionForm(
    List<VenueModel> venues,
    List<EventModel> events,
  ) {
    final targetItems = _itemType == 'venue'
        ? _venueItems(venues)
        : _eventItems(events.where((event) => event.isPublished).toList());
    final hasSelectedTarget =
        targetItems.any((item) => item.value == _selectedTargetId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _contributionFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_editingContributionId == null
                      ? Icons.add_circle_outline
                      : Icons.edit_outlined),
                  const SizedBox(width: 8),
                  Text(
                    _editingContributionId == null
                        ? 'Keşfet İçeriği Ekle'
                        : 'Keşfet İçeriği Düzenle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'venue',
                    label: Text('Mekan'),
                    icon: Icon(Icons.store_mall_directory_outlined),
                  ),
                  ButtonSegment(
                    value: 'event',
                    label: Text('Etkinlik'),
                    icon: Icon(Icons.event_outlined),
                  ),
                ],
                selected: {_itemType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _itemType = selection.first;
                    _selectedTargetId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  '$_itemType-${_selectedTargetId ?? 'none'}-${targetItems.length}',
                ),
                initialValue: hasSelectedTarget ? _selectedTargetId : null,
                isExpanded: true,
                items: targetItems,
                decoration: InputDecoration(
                  labelText:
                      _itemType == 'venue' ? 'Mekan seç' : 'Etkinlik seç',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Öğe seçin' : null,
                onChanged: (value) {
                  setState(() {
                    _selectedTargetId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Etiket (opsiyonel)',
                  hintText: 'Örn: Katkıda Bulunan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sıra',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _buildSchedulePicker(
                label: 'Gösterim başlangıcı',
                value: _startsAt,
                icon: Icons.play_circle_outline,
                onChanged: (value) => _startsAt = value,
              ),
              const SizedBox(height: 12),
              _buildSchedulePicker(
                label: 'Gösterim bitişi',
                value: _endsAt,
                icon: Icons.stop_circle_outlined,
                onChanged: (value) => _endsAt = value,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _isContributionActive,
                onChanged: (value) {
                  setState(() {
                    _isContributionActive = value;
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isSavingContribution ? null : _saveContribution,
                      icon: _isSavingContribution
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Kaydet'),
                    ),
                  ),
                  if (_editingContributionId != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _clearContributionForm,
                      icon: const Icon(Icons.close),
                      label: const Text('İptal'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributionList(List<ExploreContribution> items) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Henüz Keşfet içeriği eklenmedi.'),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  item.isVenue
                      ? Icons.store_mall_directory_outlined
                      : Icons.event_outlined,
                ),
              ),
              title: Text(item.title),
              subtitle: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(label: Text(item.isVenue ? 'Mekan' : 'Etkinlik')),
                  Chip(label: Text('Sıra: ${item.displayOrder}')),
                  Chip(label: Text(item.isActive ? 'Aktif' : 'Pasif')),
                  if (item.startsAt != null)
                    Chip(
                      label:
                          Text('Başlangıç: ${_formatDateTime(item.startsAt!)}'),
                    ),
                  if (item.endsAt != null)
                    Chip(
                      label: Text('Bitiş: ${_formatDateTime(item.endsAt!)}'),
                    ),
                  if ((item.label ?? '').trim().isNotEmpty)
                    Chip(label: Text(item.label!.trim())),
                ],
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Düzenle',
                    onPressed: () => _editContribution(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Kaldır',
                    onPressed: () => _deleteContribution(item.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final settingsAsync = ref.watch(exploreSettingsProvider);
    final contributionsAsync = ref.watch(adminExploreContributionsProvider);
    final venuesAsync = ref.watch(venuesProvider);
    final eventsAsync = ref.watch(manageableEventsProvider(''));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        settingsAsync.when(
          data: _buildSettingsCard,
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Keşfet ayarları yüklenemedi: $error'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        venuesAsync.when(
          data: (venues) => eventsAsync.when(
            data: (events) => _buildContributionForm(venues, events),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Etkinlikler yüklenemedi: $error'),
              ),
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Mekanlar yüklenemedi: $error'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Keşfet İçerikleri',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        contributionsAsync.when(
          data: _buildContributionList,
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Keşfet içerikleri yüklenemedi: $error'),
            ),
          ),
        ),
      ],
    );
  }
}
