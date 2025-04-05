import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedRoom;
  String? _selectedInventoryArea;

  // Sample data for rooms
  final List<String> _rooms = [
    'Room 101',
    'Room 202',
    'Conference Room A',
  ];

  // Sample data for inventory
  final List<String> _inventoryAreas = [
    'Grocery Aisle',
    'Electronics Section',
    'Clothing Department',
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
              Tab(text: 'Room Scan', icon: Icon(Icons.meeting_room)),
              Tab(text: 'Inventory Scan', icon: Icon(Icons.inventory)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomScanContent(),
              _buildInventoryScanContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomScanContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildScannerIcon(
              Icons.camera_alt,
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Room Scanner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detect changes in room arrangement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 30),
            _buildAreaSelector(
              'Select Room to Scan',
              _selectedRoom,
              _rooms,
              (value) {
                setState(() {
                  _selectedRoom = value;
                });
              },
            ),
            const SizedBox(height: 30),
            _buildScanButton(
              'Begin Room Scan',
              _selectedRoom == null
                  ? null
                  : () {
                      _showScanDialog(true);
                    },
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInventoryScanContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildScannerIcon(
              Icons.qr_code_scanner,
              Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'Inventory Scanner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track stock levels and inventory changes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 30),
            _buildAreaSelector(
              'Select Inventory Area to Scan',
              _selectedInventoryArea,
              _inventoryAreas,
              (value) {
                setState(() {
                  _selectedInventoryArea = value;
                });
              },
            ),
            const SizedBox(height: 30),
            _buildScanButton(
              'Begin Inventory Scan',
              _selectedInventoryArea == null
                  ? null
                  : () {
                      _showScanDialog(false);
                    },
              Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildScannerIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 80,
        color: color,
      ),
    );
  }

  Widget _buildAreaSelector(
    String label,
    String? selectedValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: const Text('Select an area to scan'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(String label, VoidCallback? onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showScanDialog(bool isRoom) {
    final String area = isRoom ? _selectedRoom! : _selectedInventoryArea!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Scanning ${isRoom ? 'Room' : 'Inventory'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Scanning $area...'),
            const SizedBox(height: 8),
            const Text('Please point your camera at the area.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showScanResultDialog(isRoom);
            },
            child: const Text('Simulate Scan'),
          ),
        ],
      ),
    );
  }

  void _showScanResultDialog(bool isRoom) {
    final String area = isRoom ? _selectedRoom! : _selectedInventoryArea!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Successfully scanned $area'),
            const SizedBox(height: 8),
            Text(
              isRoom
                  ? 'Found 12 objects, 2 changes detected'
                  : 'Found 87 items, 5 low stock items',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to results page
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}
