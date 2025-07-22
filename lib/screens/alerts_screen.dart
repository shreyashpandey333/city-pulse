import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import '../components/event_card.dart';
import '../components/alert_banner.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final filters = ref.watch(eventFiltersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context, ref),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => RefreshIndicator(
          onRefresh: () async {
            ref.read(eventsProvider.notifier).refreshEvents();
          },
          child: events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No alerts found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading alerts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(eventsProvider.notifier).refreshEvents();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Severity filters
            Text(
              'Severity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['High', 'Medium', 'Low'].map((severity) {
                final isSelected = ref.read(eventFiltersProvider).selectedSeverities.contains(severity);
                return FilterChip(
                  label: Text(severity),
                  selected: isSelected,
                  onSelected: (selected) {
                    final currentFilters = ref.read(eventFiltersProvider);
                    final newSeverities = List<String>.from(currentFilters.selectedSeverities);
                    if (selected) {
                      newSeverities.add(severity);
                    } else {
                      newSeverities.remove(severity);
                    }
                    ref.read(eventFiltersProvider.notifier).updateSeverities(newSeverities);
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Category filters
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Traffic', 'Emergency', 'Weather', 'Infrastructure', 'Utilities'].map((category) {
                final isSelected = ref.read(eventFiltersProvider).selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    final currentFilters = ref.read(eventFiltersProvider);
                    final newCategories = List<String>.from(currentFilters.selectedCategories);
                    if (selected) {
                      newCategories.add(category);
                    } else {
                      newCategories.remove(category);
                    }
                    ref.read(eventFiltersProvider.notifier).updateCategories(newCategories);
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(eventFiltersProvider.notifier).clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, dynamic event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Event details
              Text(
                event.eventType,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Additional details
              _buildDetailRow('Location', event.location.address),
              _buildDetailRow('Severity', event.severity),
              _buildDetailRow('Category', event.category),
              _buildDetailRow('Reported By', event.reportedBy),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
