import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/stat_card.dart';
import '../widgets/area_list_tile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data for rooms
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Room 101', 'expensiveItems': 5, 'lastScan': '2 hours ago'},
    {'name': 'Room 202', 'expensiveItems': 3, 'lastScan': '1 day ago'},
    {
      'name': 'Conference Room A',
      'expensiveItems': 7,
      'lastScan': '3 hours ago'
    },
  ];

  // Sample data for inventory
  final List<Map<String, dynamic>> _inventoryAreas = [
    {'name': 'Grocery Aisle', 'items': 125, 'stockLevel': '85%'},
    {'name': 'Electronics Section', 'items': 78, 'stockLevel': '62%'},
    {'name': 'Clothing Department', 'items': 210, 'stockLevel': '91%'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Rooms', icon: Icon(Icons.meeting_room)),
              Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomsContent(),
              _buildInventoryContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                    'Rooms Management', 'Monitor and manage room spaces'),
                const SizedBox(height: 20),
                _buildRoomStats(),
                const SizedBox(height: 20),
                Text(
                  'Monitored Rooms',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _rooms.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildAddAreaButton(
                        'Add Room', () => _showAddAreaDialog(true)),
                  );
                }
                final room = _rooms[index];
                return AreaListTile(
                  title: room['name'],
                  subtitle: 'Last scan: ${room['lastScan']}',
                  leading: const Icon(Icons.meeting_room, size: 28),
                  trailing: '${room['expensiveItems']} items',
                  onTap: () {
                    // Navigate to room detail
                  },
                );
              },
              childCount: _rooms.length + 1, // +1 for the Add button
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInventoryContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                    'Inventory Management', 'Track and manage inventory areas'),
                const SizedBox(height: 20),
                _buildInventoryStats(),
                const SizedBox(height: 20),
                Text(
                  'Inventory Areas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _inventoryAreas.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildAddAreaButton(
                        'Add Inventory Area', () => _showAddAreaDialog(false)),
                  );
                }
                final area = _inventoryAreas[index];
                return AreaListTile(
                  title: area['name'],
                  subtitle: '${area['items']} unique items',
                  leading: const Icon(Icons.inventory, size: 28),
                  trailing: 'Stock: ${area['stockLevel']}',
                  onTap: () {
                    // Navigate to inventory area detail
                  },
                );
              },
              childCount: _inventoryAreas.length + 1, // +1 for the Add button
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStats() {
    int totalRooms = _rooms.length;
    int totalExpensiveItems =
        _rooms.fold(0, (sum, room) => sum + (room['expensiveItems'] as int));

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatCard(
          icon: Icons.meeting_room,
          title: 'Total Rooms',
          value: totalRooms.toString(),
          color: Colors.blue,
        ),
        StatCard(
          icon: Icons.diamond,
          title: 'Valuable Items',
          value: totalExpensiveItems.toString(),
          color: Colors.amber,
        ),
        StatCard(
          icon: Icons.security,
          title: 'Secured Rooms',
          value: '${totalRooms - 1}',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.warning,
          title: 'Alerts',
          value: '2',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildInventoryStats() {
    int totalAreas = _inventoryAreas.length;
    int totalItems =
        _inventoryAreas.fold(0, (sum, area) => sum + (area['items'] as int));
    double avgStockLevel = _inventoryAreas.fold(
            0.0,
            (sum, area) =>
                sum +
                double.parse(
                    (area['stockLevel'] as String).replaceAll('%', ''))) /
        totalAreas;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatCard(
          icon: Icons.category,
          title: 'Total Areas',
          value: totalAreas.toString(),
          color: Colors.purple,
        ),
        StatCard(
          icon: Icons.inventory_2,
          title: 'Total Items',
          value: totalItems.toString(),
          color: Colors.teal,
        ),
        StatCard(
          icon: Icons.show_chart,
          title: 'Avg Stock',
          value: '${avgStockLevel.toStringAsFixed(0)}%',
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.trending_down,
          title: 'Low Stock',
          value: '3',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAddAreaButton(String label, VoidCallback onPressed) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  void _showAddAreaDialog(bool isRoom) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${isRoom ? 'Room' : 'Inventory Area'}'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter ${isRoom ? 'room' : 'area'} name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  if (isRoom) {
                    _rooms.add({
                      'name': nameController.text,
                      'expensiveItems': 0,
                      'lastScan': 'Not scanned yet',
                    });
                  } else {
                    _inventoryAreas.add({
                      'name': nameController.text,
                      'items': 0,
                      'stockLevel': '0%',
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
