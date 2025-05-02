import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _weekdayHoursController = TextEditingController();
  final _weekendHoursController = TextEditingController();
  final _menuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _announcementController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isEditing = false;
  String? _editingVenueId;
  final bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _weekdayHoursController.dispose();
    _weekendHoursController.dispose();
    _menuController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _addVenue() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final venue = VenueModel(
        id: _editingVenueId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        latitude: _latitudeController.text.isEmpty
            ? null
            : double.parse(_latitudeController.text),
        longitude: _longitudeController.text.isEmpty
            ? null
            : double.parse(_longitudeController.text),
        weekdayHours: _weekdayHoursController.text,
        weekendHours: _weekendHoursController.text,
        menu: _menuController.text.isEmpty ? null : _menuController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        announcement: _announcementController.text.isEmpty
            ? null
            : _announcementController.text,
        imageUrl:
            _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        amenities: [],
        visitCount: 0,
      );

      if (_isEditing && _editingVenueId != null) {
        await _firestoreService.updateVenue(venue);
        ref.invalidate(venueByIdProvider(_editingVenueId!));
        clearVenuesCache(ref);
      } else {
        await _firestoreService.addVenue(venue);
        clearVenuesCache(ref);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Mekan güncellendi' : 'Mekan eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteVenue(String venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mekanı Sil'),
        content: const Text('Bu mekanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteVenue(venueId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mekan silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _editVenue(VenueModel venue) {
    setState(() {
      _editingVenueId = venue.id;
      _nameController.text = venue.name;
      _locationController.text = venue.location ?? '';
      _latitudeController.text = venue.latitude?.toString() ?? '';
      _longitudeController.text = venue.longitude?.toString() ?? '';
      _weekdayHoursController.text = venue.weekdayHours;
      _weekendHoursController.text = venue.weekendHours;
      _menuController.text = venue.menu ?? '';
      _descriptionController.text = venue.description ?? '';
      _announcementController.text = venue.announcement ?? '';
      _imageUrlController.text = venue.imageUrl ?? '';
      _isEditing = true;
    });
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _locationController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _weekdayHoursController.clear();
      _weekendHoursController.clear();
      _menuController.clear();
      _descriptionController.clear();
      _announcementController.clear();
      _imageUrlController.clear();
      _isEditing = false;
      _editingVenueId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildVenueForm(),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Mekan Listesi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            _buildVenuesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getVenuesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final venues = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return VenueModel.fromJson(data, doc.id);
        }).toList();

        if (venues.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('Henüz mekan eklenmemiş'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(
                  venue.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(venue.location ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editVenue(venue);
                        // Scroll to top to show the form
                        Scrollable.ensureVisible(
                          _formKey.currentContext!,
                          duration: const Duration(milliseconds: 500),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _deleteVenue(venue.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVenueForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit_note : Icons.add_business,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Mekan Düzenle' : 'Yeni Mekan Ekle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Mekan Adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen mekan adını girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Konum (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Enlem (Opsiyonel)',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: 41.0082',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          double lat = double.parse(value);
                          if (lat < -90 || lat > 90) {
                            return 'Enlem -90 ile 90 arasında olmalıdır';
                          }
                        } catch (e) {
                          return 'Geçerli bir sayı girin';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Boylam (Opsiyonel)',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: 28.9784',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          double lon = double.parse(value);
                          if (lon < -180 || lon > 180) {
                            return 'Boylam -180 ile 180 arasında olmalıdır';
                          }
                        } catch (e) {
                          return 'Geçerli bir sayı girin';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weekdayHoursController,
              decoration: const InputDecoration(
                labelText: 'Hafta İçi Çalışma Saatleri',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen hafta içi çalışma saatlerini girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weekendHoursController,
              decoration: const InputDecoration(
                labelText: 'Hafta Sonu Çalışma Saatleri (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _menuController,
              decoration: const InputDecoration(
                labelText: 'Menü (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _announcementController,
              decoration: const InputDecoration(
                labelText: 'Duyuru (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Resim URL (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addVenue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? 'Güncelle' : 'Ekle'),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('İptal'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
