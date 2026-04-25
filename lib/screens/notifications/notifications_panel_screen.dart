import 'dart:async';

import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/notification_model.dart';
import 'package:campus_online/providers/notifications_provider.dart';
import 'package:campus_online/widgets/venue_list_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsPanelScreen extends ConsumerStatefulWidget {
  const NotificationsPanelScreen({
    super.key,
    this.initialNotificationId,
  });

  final String? initialNotificationId;

  @override
  ConsumerState<NotificationsPanelScreen> createState() =>
      _NotificationsPanelScreenState();
}

class _NotificationsPanelScreenState
    extends ConsumerState<NotificationsPanelScreen> {
  bool _initialNotificationOpened = false;

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsFeedProvider.notifier).refresh();

      if (!context.mounted) return;
      AppError.showSuccess(context, 'Bildirimler yenilendi.');
    } catch (e) {
      if (!context.mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsFeedProvider.notifier).markAllAsRead();
      if (!context.mounted) return;
      AppError.showSuccess(
          context, 'Tüm bildirimler okundu olarak işaretlendi.');
    } catch (e) {
      if (!context.mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  Future<bool> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) async {
    try {
      unawaited(
        ref
            .read(notificationsFeedProvider.notifier)
            .deleteNotification(item.id)
            .catchError((Object error) {
          if (!context.mounted) return;
          AppError.showError(context, AppError.getUserFriendlyMessage(error));
        }),
      );

      if (!context.mounted) return true;
      AppError.showSuccess(context, 'Bildirim silindi.');
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
      return false;
    }
  }

  Future<void> _openTarget(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) async {
    if (!item.isRead) {
      unawaited(
        ref
            .read(notificationsFeedProvider.notifier)
            .markAsRead(item.id)
            .catchError((Object error) {
          if (!context.mounted) return;
          AppError.showError(context, AppError.getUserFriendlyMessage(error));
        }),
      );
    }

    if (!context.mounted) return;

    if (item.type == 'event' && item.targetId != null) {
      Navigator.pushNamed(context, '/event_details', arguments: item.targetId);
      return;
    }

    if (item.type == 'venue' && item.targetId != null) {
      Navigator.pushNamed(context, '/venue_details', arguments: item.targetId);
      return;
    }

    _showNotificationDetail(context, item);
  }

  void _showNotificationDetail(BuildContext context, NotificationModel item) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.7,
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForType(item.type),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDateTime(item.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'venue':
        return Icons.store;
      case 'feedback':
        return Icons.feedback;
      case 'admin_broadcast':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  void _maybeOpenInitialNotification(List<NotificationModel> items) {
    if (_initialNotificationOpened) return;

    final notificationId = widget.initialNotificationId?.trim();
    if (notificationId == null || notificationId.isEmpty) return;

    NotificationModel? target;
    for (final item in items) {
      if (item.id == notificationId) {
        target = item;
        break;
      }
    }

    if (target == null) return;
    _initialNotificationOpened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openTarget(context, ref, target!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsFeedProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => _markAllRead(context, ref),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tümünü Oku'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => _refresh(context, ref),
        child: notificationsAsync.when(
          data: (items) {
            _maybeOpenInitialNotification(items);
            if (items.isEmpty) {
              return const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  VenueEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Henüz bildirimin yok',
                    subtitle: 'Yeni bildirimler ve duyurular burada görünecek.',
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return _deleteNotification(context, ref, item);
                        },
                        child: _NotificationCard(
                          item: item,
                          onTap: () => _openTarget(context, ref, item),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              VenueErrorState(
                error: error,
                title: 'Bildirimler yüklenemedi',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'venue':
        return Icons.store;
      case 'feedback':
        return Icons.feedback_outlined;
      case 'admin_broadcast':
        return Icons.campaign;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: item.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: item.isRead
                ? theme.colorScheme.outline.withValues(alpha: 0.08)
                : theme.colorScheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    size: 20,
                    color: item.isRead
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!item.isRead)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatRelativeTime(item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();

  if (local.isAfter(now)) {
    final futureDiff = local.difference(now);
    if (futureDiff.inMinutes < 60) {
      final minutes = futureDiff.inMinutes.clamp(1, 59);
      return '$minutes dk sonra';
    }
    if (futureDiff.inHours < 24) {
      return '${futureDiff.inHours} saat sonra';
    }
    if (futureDiff.inDays < 7) {
      return '${futureDiff.inDays} gün sonra';
    }

    return '${_twoDigits(local.day)}.${_twoDigits(local.month)}';
  }

  final pastDiff = now.difference(local);
  if (pastDiff.inMinutes < 1) return 'Az önce';
  if (pastDiff.inMinutes < 60) return '${pastDiff.inMinutes} dk önce';
  if (pastDiff.inHours < 24) return '${pastDiff.inHours} saat önce';
  if (pastDiff.inDays < 7) return '${pastDiff.inDays} gün önce';

  return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year}';
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
