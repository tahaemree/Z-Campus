import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isEditing = false;
  String? _currentName;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final data = doc.data();
    if (data != null && data['displayName'] != null) {
      _nameController.text = data['displayName'];
      _currentName = data['displayName'];
    } else if (user!.displayName != null) {
      _nameController.text = user!.displayName!;
      _currentName = user!.displayName!;
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false) || user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'displayName': _nameController.text.trim(),
      });
      await user!.updateDisplayName(_nameController.text.trim());
      setState(() {
        _isEditing = false;
        _currentName = _nameController.text.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      }
    } catch (e) {
      setState(() {
        _error = 'Profil güncellenemedi.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final userData = doc.data();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
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
    if (confirmed != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (userData != null) {
        await FirebaseFirestore.instance
            .collection('olduser')
            .doc(user!.uid)
            .set({
          ...userData,
          'deletedAt': DateTime.now().toIso8601String(),
        });
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .delete();
      await user!.delete();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _error = 'Hesap silinemedi.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          user?.photoURL != null && user!.photoURL!.isNotEmpty
                              ? NetworkImage(user!.photoURL!)
                              : null,
                      child: user?.photoURL == null || user!.photoURL!.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isEditing
                            ? Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Ad Soyad',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'İsim boş olamaz'
                                          : null,
                                ),
                              )
                            : Expanded(
                                child: Text(
                                  _currentName ?? '-',
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                        IconButton(
                          icon: Icon(_isEditing ? Icons.close : Icons.edit),
                          tooltip: _isEditing ? 'İptal' : 'Düzenle',
                          onPressed: () {
                            setState(() {
                              if (_isEditing) {
                                _nameController.text = _currentName ?? '';
                              }
                              _isEditing = !_isEditing;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Kaydet'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextButton(
                      onPressed: _deleteAccount,
                      style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error),
                      child: const Text('Hesabı Sil'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
    );
  }
}
