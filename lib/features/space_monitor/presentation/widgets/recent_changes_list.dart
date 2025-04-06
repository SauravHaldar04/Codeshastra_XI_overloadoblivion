import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecentChangesList extends StatelessWidget {
  const RecentChangesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Recent Changes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getChangeColor(index).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getChangeIcon(index),
                      color: _getChangeColor(index)),
                ),
                title: Text(
                  'Change Detected in Area ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${DateTime.now().subtract(Duration(minutes: index * 15))}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms);
          },
        ),
      ],
    );
  }

  Color _getChangeColor(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple
    ];
    return colors[index % colors.length];
  }

  IconData _getChangeIcon(int index) {
    final icons = [
      Icons.warning,
      Icons.add_circle,
      Icons.remove_circle,
      Icons.move_up,
      Icons.move_down,
    ];
    return icons[index % icons.length];
  }
}
