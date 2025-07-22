import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../themes/app_theme.dart';
import '../services/alert_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final isDarkMode = ref.watch(themeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              _buildUserProfileSection(context, user),
              const SizedBox(height: 24),
              
              // Notification Settings
              _buildNotificationSettings(context, ref, user),
              const SizedBox(height: 24),
              
              // App Settings
              _buildAppSettings(context, ref, isDarkMode),
              const SizedBox(height: 24),
              
              // About Section
              _buildAboutSection(context),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(userProvider.notifier).loadUser(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
backgroundColor: AppTheme.primaryPurple,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit profile
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Reports Submitted',
                    user.reportsSubmitted.toString(),
                    Icons.report,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Reputation',
                    user.reputation.toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
Icon(icon, color: AppTheme.primaryPurple),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts for events in your area'),
              value: user.preferences.notificationEnabled,
              onChanged: (value) {
                final newPreferences = user.preferences.copyWith(
                  notificationEnabled: value,
                );
                ref.read(userProvider.notifier).updateUserPreferences(newPreferences);
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Alert Radius'),
              subtitle: Text('${user.preferences.alertRadius.toInt()} km'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showRadiusDialog(context, ref, user),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Alert Categories'),
              subtitle: Text('${user.preferences.categories.length} categories selected'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showCategoriesDialog(context, ref, user),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.notifications_active, color: AppTheme.primaryPurple),
              title: const Text('Test Notification'),
              subtitle: const Text('Send a test push notification'),
              trailing: const Icon(Icons.send),
              onTap: () async {
                await AlertService().sendTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).setTheme(value);
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement language selection
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Clear Cache'),
              subtitle: const Text('Free up storage space'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showClearCacheDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show privacy policy
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show terms of service
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show help screen
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRadiusDialog(BuildContext context, WidgetRef ref, dynamic user) {
    double currentRadius = user.preferences.alertRadius;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Alert Radius'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Receive alerts within ${currentRadius.toInt()} km'),
              const SizedBox(height: 16),
              Slider(
                value: currentRadius,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${currentRadius.toInt()} km',
                onChanged: (value) {
                  setState(() {
                    currentRadius = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPreferences = user.preferences.copyWith(
                  alertRadius: currentRadius,
                );
                ref.read(userProvider.notifier).updateUserPreferences(newPreferences);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final allCategories = ['Traffic', 'Emergency', 'Weather', 'Infrastructure', 'Utilities'];
    List<String> selectedCategories = List.from(user.preferences.categories);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Alert Categories'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: allCategories.map((category) {
              return CheckboxListTile(
                title: Text(category),
                value: selectedCategories.contains(category),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedCategories.add(category);
                    } else {
                      selectedCategories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPreferences = user.preferences.copyWith(
                  categories: selectedCategories,
                );
                ref.read(userProvider.notifier).updateUserPreferences(newPreferences);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
