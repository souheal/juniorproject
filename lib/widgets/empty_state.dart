import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionText!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoTicketsEmpty extends StatelessWidget {
  final VoidCallback? onBrowseEvents;

  const NoTicketsEmpty({super.key, this.onBrowseEvents});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'No Tickets Yet',
      subtitle: 'Your purchased tickets will appear here.\nStart exploring events to get your first ticket!',
      actionText: 'Browse Events',
      onAction: onBrowseEvents,
    );
  }
}


class NoEventsEmpty extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoEventsEmpty({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.event_busy_outlined,
      title: 'No Events Found',
      subtitle: 'We couldn\'t find any events matching your criteria.\nTry adjusting your filters or search.',
      actionText: 'Clear Filters',
      onAction: onRefresh,
    );
  }
}

class NoSearchResults extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClear;

  const NoSearchResults({
    super.key,
    required this.searchQuery,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      subtitle: 'We couldn\'t find anything for "$searchQuery".\nTry a different search term.',
      actionText: 'Clear Search',
      onAction: onClear,
    );
  }
}
