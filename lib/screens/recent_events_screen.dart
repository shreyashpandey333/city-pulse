import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import '../themes/app_theme.dart';
import '../components/event_card.dart';

class RecentEventsScreen extends ConsumerWidget {
  const RecentEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Events'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: eventsAsync.when(
        data: (events) => ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              showAnimation: event.severity.toLowerCase() == 'high',
              onTap: () => _showEventDetails(context, event),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Error loading events'),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, dynamic event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            event.eventType,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Location: ${event.location.address}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Reported By: ${event.reportedBy}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Time: ${event.timestamp}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
