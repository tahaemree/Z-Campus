import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/admin_models.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/access_provider.dart';
import 'package:campus_online/services/access_control_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsManagementPage extends ConsumerStatefulWidget {
  final AsyncValue<List<VenueModel>> venuesAsync;

  const PermissionsManagementPage({
    super.key,
    required this.venuesAsync,
  });

  @override
  ConsumerState<PermissionsManagementPage> createState() =>
      _PermissionsManagementPageState();
}

class _PermissionsManagementPageState
    extends ConsumerState<PermissionsManagementPage>
    with AutomaticKeepAliveClientMixin {
  final AccessControlService _accessControlService = AccessControlService();

  final _newAccountDisplayNameController = TextEditingController();
  final _newAccountEmailController = TextEditingController();
  final _newAccountPasswordController = TextEditingController();
  final _newAccountVenueSearchController = TextEditingController();
  final _userSearchController = TextEditingController();
  final _selectedUserVenueSearchController = TextEditingController();

  String _userSearchQuery = '';
  String _newAccountVenueSearchQuery = '';
  String _selectedUserVenueSearchQuery = '';

  bool _isCreatingAccount = false;
  Set<StaffRole> _newAccountRoles = <StaffRole>{};
  Set<String> _newAccountVenueIds = <String>{};

  String? _selectedUserId;
  String? _selectedUserLabel;
  String? _loadedPermissionUserId;
  bool _isSavingPermissions = false;
  Set<StaffRole> _selectedUserRoles = <StaffRole>{};
  Set<String> _selectedUserVenueIds = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _newAccountDisplayNameController.dispose();
    _newAccountEmailController.dispose();
    _newAccountPasswordController.dispose();
    _newAccountVenueSearchController.dispose();
    _userSearchController.dispose();
    _selectedUserVenueSearchController.dispose();
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
    ].join(' ').toLowerCase();
    return bucket.contains(cleanQuery);
  }

  List<VenueModel> _filterVenuesForPermissions(
    List<VenueModel> venues,
    String query,
  ) {
    return venues.where((venue) => _matchesVenue(venue, query)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ── Hesap Oluşturma ────────────────────────────────────────

  Future<void> _createStaffAccount() async {
    final displayName = _newAccountDisplayNameController.text.trim();
    final email = _newAccountEmailController.text.trim();
    final password = _newAccountPasswordController.text;

    if (displayName.isEmpty) {
      AppError.showError(context, 'Ad Soyad zorunludur.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      AppError.showError(context, 'Geçerli bir e-posta girin.');
      return;
    }

    if (password.length < 6) {
      AppError.showError(context, 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _isCreatingAccount = true;
    });

    try {
      await _accessControlService.createStaffAccount(
        email: email,
        password: password,
        displayName: displayName,
        roles: _newAccountRoles,
        editableVenueIds: _newAccountVenueIds,
      );

      ref.invalidate(adminUserSearchProvider(_userSearchQuery));

      if (!mounted) return;
      AppError.showSuccess(context, 'Personel hesabı oluşturuldu.');

      setState(() {
        _newAccountDisplayNameController.clear();
        _newAccountEmailController.clear();
        _newAccountPasswordController.clear();
        _newAccountRoles = <StaffRole>{};
        _newAccountVenueIds = <String>{};
        _newAccountVenueSearchController.clear();
        _newAccountVenueSearchQuery = '';
      });
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  // ── Yetki Yönetimi ─────────────────────────────────────────

  void _selectUser(AdminUserProfile user) {
    setState(() {
      _selectedUserId = user.id;
      _selectedUserLabel = '${user.displayName} (${user.email})';
      _loadedPermissionUserId = null;
      _selectedUserRoles = <StaffRole>{};
      _selectedUserVenueIds = <String>{};
      _selectedUserVenueSearchController.clear();
      _selectedUserVenueSearchQuery = '';
    });
  }

  void _hydratePermissionDraftIfNeeded(
    String userId,
    UserPermissionBundle bundle,
  ) {
    if (_loadedPermissionUserId == userId) return;
    _loadedPermissionUserId = userId;
    _selectedUserRoles = Set<StaffRole>.from(bundle.roles);
    _selectedUserVenueIds = Set<String>.from(bundle.editableVenueIds);
  }

  Future<void> _saveSelectedUserPermissions() async {
    if (_selectedUserId == null) {
      AppError.showError(context, 'Lütfen bir kullanıcı seçin.');
      return;
    }

    setState(() {
      _isSavingPermissions = true;
    });

    try {
      await _accessControlService.updateUserPermissions(
        userId: _selectedUserId!,
        roles: _selectedUserRoles,
        editableVenueIds: _selectedUserVenueIds,
      );

      ref.invalidate(userPermissionBundleProvider(_selectedUserId!));
      ref.invalidate(currentUserAccessProvider);

      if (!mounted) return;
      AppError.showSuccess(context, 'Yetkiler kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPermissions = false;
        });
      }
    }
  }

  // ── Widget'lar ────────────────────────────────────────────

  Widget _buildCreateAccountCard(List<VenueModel> venues) {
    final filteredVenues = _filterVenuesForPermissions(
      venues,
      _newAccountVenueSearchQuery,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Personel Hesabı Oluştur',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newAccountDisplayNameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newAccountEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newAccountPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Geçici şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: StaffRole.values
                  .map(
                    (role) => FilterChip(
                      label: Text(staffRoleLabel(role)),
                      selected: _newAccountRoles.contains(role),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _newAccountRoles.add(role);
                          } else {
                            _newAccountRoles.remove(role);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newAccountVenueSearchController,
              decoration: const InputDecoration(
                labelText: 'Mekan yetkisi ara',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _newAccountVenueSearchQuery = value.trim();
                });
              },
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: filteredVenues.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Mekan bulunamadı.'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        final venue = filteredVenues[index];
                        final selected =
                            _newAccountVenueIds.contains(venue.id);

                        return CheckboxListTile(
                          value: selected,
                          title: Text(venue.name),
                          subtitle: venue.category != null
                              ? Text(venue.category!)
                              : null,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _newAccountVenueIds.add(venue.id);
                              } else {
                                _newAccountVenueIds.remove(venue.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isCreatingAccount ? null : _createStaffAccount,
              icon: _isCreatingAccount
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: const Text('Hesap Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersPermissionCard(List<VenueModel> venues) {
    final usersAsync = ref.watch(adminUserSearchProvider(_userSearchQuery));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kullanıcı Yetki Yönetimi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userSearchController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı ara',
                hintText: 'Ad veya e-posta',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _userSearchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _userSearchController.clear();
                            _userSearchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _userSearchQuery = value.trim();
                });
              },
            ),
            const SizedBox(height: 12),
            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Kullanıcı bulunamadı.'),
                    ),
                  );
                }

                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final selected = user.id == _selectedUserId;

                      return Card(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.35)
                            : null,
                        child: ListTile(
                          onTap: () => _selectUser(user),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          trailing: selected
                              ? const Icon(Icons.check_circle)
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Kullanıcılar yüklenemedi: $error'),
                ),
              ),
            ),
            if (_selectedUserId != null) ...[
              const SizedBox(height: 16),
              Text(
                'Seçili kullanıcı: $_selectedUserLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ref.watch(userPermissionBundleProvider(_selectedUserId!)).when(
                    data: (bundle) {
                      _hydratePermissionDraftIfNeeded(
                          _selectedUserId!, bundle);

                      final filteredVenues = _filterVenuesForPermissions(
                        venues,
                        _selectedUserVenueSearchQuery,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: StaffRole.values
                                .map(
                                  (role) => FilterChip(
                                    label: Text(staffRoleLabel(role)),
                                    selected:
                                        _selectedUserRoles.contains(role),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedUserRoles.add(role);
                                        } else {
                                          _selectedUserRoles.remove(role);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _selectedUserVenueSearchController,
                            decoration: const InputDecoration(
                              labelText: 'Mekan yetkisi ara',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserVenueSearchQuery = value.trim();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            constraints:
                                const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: filteredVenues.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Mekan bulunamadı.'),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredVenues.length,
                                    itemBuilder: (context, index) {
                                      final venue = filteredVenues[index];
                                      final selected =
                                          _selectedUserVenueIds
                                              .contains(venue.id);

                                      return CheckboxListTile(
                                        value: selected,
                                        title: Text(venue.name),
                                        subtitle: venue.category != null
                                            ? Text(venue.category!)
                                            : null,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedUserVenueIds.add(
                                                venue.id,
                                              );
                                            } else {
                                              _selectedUserVenueIds.remove(
                                                venue.id,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isSavingPermissions
                                ? null
                                : _saveSelectedUserPermissions,
                            icon: _isSavingPermissions
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Yetkileri Kaydet'),
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Yetkiler yüklenemedi: $error'),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.venuesAsync.when(
      data: (venues) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCreateAccountCard(venues),
            const SizedBox(height: 12),
            _buildUsersPermissionCard(venues),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Mekanlar yuklenmeden yetki ekranı açılamaz: $error'),
      ),
    );
  }
}
