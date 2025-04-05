import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_changes_list.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildStatsGrid(context),
          const SizedBox(height: 20),
          const RecentChangesList(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Space Monitoring Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time space analysis and change detection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatCard(
          icon: Icons.warning,
          title: 'Active Alerts',
          value: '3',
          color: Colors.red,
        ),
        StatCard(
          icon: Icons.check_circle,
          title: 'Stable Areas',
          value: '12',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.timer,
          title: 'Avg. Response',
          value: '2m',
          color: Colors.blue,
        ),
        StatCard(
          icon: Icons.area_chart,
          title: 'Coverage',
          value: '85%',
          color: Colors.orange,
        ),
      ],
    );
  }
}
