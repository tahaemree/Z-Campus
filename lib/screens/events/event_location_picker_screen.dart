import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventLocationSelection {
  final double latitude;
  final double longitude;
  final String? locationLabel;

  const EventLocationSelection({
    required this.latitude,
    required this.longitude,
    this.locationLabel,
  });
}

class EventLocationPickerScreen extends StatefulWidget {
  const EventLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationLabel,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationLabel;

  @override
  State<EventLocationPickerScreen> createState() =>
      _EventLocationPickerScreenState();
}

class _EventLocationPickerScreenState extends State<EventLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(41.0082, 28.9784);

  final MapController _mapController = MapController();
  late final TextEditingController _locationLabelController;

  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _locationLabelController = TextEditingController(
      text: widget.initialLocationLabel ?? '',
    );

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _locationLabelController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter => _selectedPoint ?? _defaultCenter;

  void _centerOnSelection() {
    final target = _selectedPoint;
    if (target == null) return;

    _mapController.move(target, 16);
  }

  void _confirmSelection() {
    final selected = _selectedPoint;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen harita üzerinden bir konum seçin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanLabel = _locationLabelController.text.trim();

    Navigator.of(context).pop(
      EventLocationSelection(
        latitude: selected.latitude,
        longitude: selected.longitude,
        locationLabel: cleanLabel.isEmpty ? null : cleanLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritadan Konum Seç'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Konum seçmek için haritaya dokunun. Daha sonra isterseniz bir mekan/etkinlik adı da girebilirsiniz.',
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _selectedPoint == null ? 12 : 16,
                    onTap: (_, point) {
                      setState(() {
                        _selectedPoint = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'campus_online',
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.location_pin,
                              size: 44,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (_selectedPoint != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Seçili koordinat: '
                      '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                      '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Henüz bir koordinat seçilmedi.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Konum adı / adres (opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          _selectedPoint == null ? null : _centerOnSelection,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Seçime Git'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.check),
                        label: const Text('Konumu Kullan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
