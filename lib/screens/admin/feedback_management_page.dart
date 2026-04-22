import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/notification_model.dart';
import 'package:campus_online/providers/notifications_provider.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedbackManagementPage extends ConsumerStatefulWidget {
  const FeedbackManagementPage({super.key});

  @override
  ConsumerState<FeedbackManagementPage> createState() =>
      _FeedbackManagementPageState();
}

class _FeedbackManagementPageState
    extends ConsumerState<FeedbackManagementPage>
    with AutomaticKeepAliveClientMixin {
  String? _statusFilter;

  static const _statusOptions = [
    (null, 'Tümü'),
    ('new', 'Yeni'),
    ('in_review', 'İnceleniyor'),
    ('resolved', 'Çözüldü'),
    ('archived', 'Arşiv'),
  ];

  @override
  bool get wantKeepAlive => true;

  Future<void> _updateStatus(
    FeedbackItem item,
    String newStatus,
  ) async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.updateFeedbackStatus(
        feedbackId: item.id,
        status: newStatus,
      );
      ref.invalidate(adminFeedbackListProvider);

      if (!mounted) return;
      AppError.showSuccess(context, 'Durum güncellendi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  Future<void> _deleteFeedback(FeedbackItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri bildirimi sil'),
        content:
            const Text('Bu geri bildirimi silmek istediğinize emin misiniz?'),
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
      final service = ref.read(notificationServiceProvider);
      await service.deleteFeedback(item.id);
      ref.invalidate(adminFeedbackListProvider);

      if (!mounted) return;
      AppError.showSuccess(context, 'Geri bildirim silindi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  void _showFeedbackDetail(FeedbackItem item) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildStatusBadge(theme, item.status, item.statusLabel),
                  const SizedBox(width: 8),
                  _buildCategoryBadge(theme, item.categoryLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.subject,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (item.contactEmail != null)
                _buildInfoRow(
                    theme, Icons.email_outlined, item.contactEmail!),
              _buildInfoRow(
                  theme, Icons.devices_outlined, item.devicePlatform),
              _buildInfoRow(
                theme,
                Icons.access_time_outlined,
                _formatFullDate(item.createdAt),
              ),
              if (item.adminNote != null &&
                  item.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Notu',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.adminNote!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status, String label) {
    final Color bgColor;
    switch (status) {
      case 'new':
        bgColor = theme.colorScheme.primary;
        break;
      case 'in_review':
        bgColor = Colors.orange;
        break;
      case 'resolved':
        bgColor = Colors.green;
        break;
      case 'archived':
        bgColor = theme.colorScheme.outline;
        break;
      default:
        bgColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: bgColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final feedbackAsync = ref.watch(adminFeedbackListProvider(_statusFilter));

    return Column(
      children: [
        // Filtre barı
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: _statusOptions.map((option) {
              final isSelected = _statusFilter == option.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(option.$2),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _statusFilter = option.$1);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminFeedbackListProvider);
            },
            child: feedbackAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Geri bildirim bulunamadı.',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showFeedbackDetail(item),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusBadge(
                                    theme,
                                    item.status,
                                    item.statusLabel,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCategoryBadge(
                                    theme,
                                    item.categoryLabel,
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatShortDate(item.createdAt),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.subject,
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (item.contactEmail != null)
                                    Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  if (item.contactEmail != null)
                                    const SizedBox(width: 4),
                                  if (item.contactEmail != null)
                                    Flexible(
                                      child: Text(
                                        item.contactEmail!,
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteFeedback(item);
                                      } else {
                                        _updateStatus(item, value);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (item.status != 'in_review')
                                        const PopupMenuItem(
                                          value: 'in_review',
                                          child: Text('İnceleniyor yap'),
                                        ),
                                      if (item.status != 'resolved')
                                        const PopupMenuItem(
                                          value: 'resolved',
                                          child: Text(
                                              'Çözüldü olarak işaretle'),
                                        ),
                                      if (item.status != 'archived')
                                        const PopupMenuItem(
                                          value: 'archived',
                                          child: Text('Arşivle'),
                                        ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Sil',
                                          style:
                                              TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Geri bildirimler yüklenemedi: $error'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatShortDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
