import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:campus_online/models/venue_model.dart';
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
  final _weekdayHoursController = TextEditingController();
  final _weekendHoursController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'cafeteria';
  bool _isEditing = false;
  String? _editingVenueId;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _weekdayHoursController.dispose();
    _weekendHoursController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _addVenue() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final now = DateTime.now();
      final venue = VenueModel(
        id: _editingVenueId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        location: _locationController.text,
        category: _selectedCategory,
        weekdayHours: _weekdayHoursController.text,
        weekendHours: _weekendHoursController.text,
        description: _descriptionController.text,
        imageUrl:
            _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        amenities: [],
        visitCount: 0,
      );

      if (_isEditing && _editingVenueId != null) {
        await _firestoreService.updateVenue(venue);
      } else {
        await _firestoreService.addVenue(venue);
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
      _isEditing = true;
      _editingVenueId = venue.id;
      _nameController.text = venue.name;
      _locationController.text = venue.location;
      _selectedCategory = venue.category;
      _weekdayHoursController.text = venue.weekdayHours;
      _weekendHoursController.text = venue.weekendHours;
      _descriptionController.text = venue.description;
      _imageUrlController.text = venue.imageUrl ?? '';
    });

    DefaultTabController.of(context).animateTo(1);
  }

  void _clearForm() {
    setState(() {
      _isEditing = false;
      _editingVenueId = null;
      _nameController.clear();
      _locationController.clear();
      _weekdayHoursController.clear();
      _weekendHoursController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _selectedCategory = 'cafeteria';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Paneli'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mekanlar'),
              Tab(text: 'Yeni Mekan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVenuesList(),
            _buildVenueForm(),
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
          return const Center(
            child: Text('Henüz mekan eklenmemiş'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(venue.name),
                subtitle: Text(venue.category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editVenue(venue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                labelText: 'Konum',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen konumu girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cafeteria', child: Text('Yemekhane')),
                DropdownMenuItem(value: 'library', child: Text('Kütüphane')),
                DropdownMenuItem(value: 'mosque', child: Text('Cami')),
                DropdownMenuItem(value: 'cafe', child: Text('Kafe')),
                DropdownMenuItem(value: 'gym', child: Text('Spor Salonu')),
                DropdownMenuItem(value: 'kafeterya', child: Text('Kafeterya')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen kategori seçin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weekdayHoursController,
              decoration: const InputDecoration(
                labelText: 'Hafta İçi Çalışma Saatleri',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen çalışma saatlerini girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weekendHoursController,
              decoration: const InputDecoration(
                labelText: 'Hafta Sonu Çalışma Saatleri',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
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
                  child: ElevatedButton(
                    onPressed: _addVenue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isEditing ? 'Güncelle' : 'Ekle'),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('İptal'),
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
