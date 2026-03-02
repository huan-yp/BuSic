import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/extensions/context_extensions.dart';
import '../application/download_notifier.dart';
import '../domain/models/download_task.dart';
import 'widgets/download_task_tile.dart';

/// Download management screen showing all download tasks.
class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(downloadNotifierProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: context.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSongs,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final activeTasks = tasks
              .where((t) =>
                  t.status == DownloadStatus.pending ||
                  t.status == DownloadStatus.downloading)
              .toList();
          final completedTasks = tasks
              .where((t) => t.status == DownloadStatus.completed)
              .toList();
          final failedTasks = tasks
              .where((t) => t.status == DownloadStatus.failed)
              .toList();

          return CustomScrollView(
            slivers: [
              // Active downloads section
              if (activeTasks.isNotEmpty) ...[
                _SectionHeader(title: l10n.activeDownloads),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = activeTasks[index];
                      return DownloadTaskTile(
                        task: task,
                        songTitle: task.songTitle ?? 'Song #${task.songId}',
                        onCancel: task.status == DownloadStatus.downloading
                            ? () => ref
                                .read(downloadNotifierProvider.notifier)
                                .cancelDownload(task.id)
                            : null,
                      );
                    },
                    childCount: activeTasks.length,
                  ),
                ),
              ],

              // Failed downloads section
              if (failedTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.downloadFailed,
                  trailing: TextButton(
                    onPressed: () {
                      for (final task in failedTasks) {
                        ref
                            .read(downloadNotifierProvider.notifier)
                            .retryDownload(task.id);
                      }
                    },
                    child: Text(l10n.retryAll),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = failedTasks[index];
                      return DownloadTaskTile(
                        task: task,
                        songTitle: task.songTitle ?? 'Song #${task.songId}',
                        onRetry: () => ref
                            .read(downloadNotifierProvider.notifier)
                            .retryDownload(task.id),
                        onDelete: () => ref
                            .read(downloadNotifierProvider.notifier)
                            .deleteTask(task.id, deleteFile: true),
                      );
                    },
                    childCount: failedTasks.length,
                  ),
                ),
              ],

              // Completed downloads section
              if (completedTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.completedDownloads,
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: Text(l10n.clearCompleted),
                    onPressed: () {
                      ref
                          .read(downloadNotifierProvider.notifier)
                          .clearCompleted();
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = completedTasks[index];
                      return DownloadTaskTile(
                        task: task,
                        songTitle: task.songTitle ?? 'Song #${task.songId}',
                        onDelete: () => ref
                            .read(downloadNotifierProvider.notifier)
                            .deleteTask(task.id, deleteFile: true),
                      );
                    },
                    childCount: completedTasks.length,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Section header for the download list.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
