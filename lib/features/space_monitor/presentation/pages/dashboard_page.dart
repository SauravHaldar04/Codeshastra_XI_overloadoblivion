import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/stat_card.dart';
import '../widgets/area_list_tile.dart';
import '../../domain/entities/scene_analysis_result.dart';
import '../cubits/scene_analysis_cubit.dart';
import 'package:codeshastraxi_overload_oblivion/init_dependencies.dart';
import 'image_view_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide FieldValue;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    // Directly fetch data from Firestore
    _fetchRoomData();
  }

  Future<void> _fetchRoomData() async {
    try {
      print('Fetching scene analysis results...');
      final sceneAnalysisSnapshot = await FirebaseFirestore.instance
          .collection('scene_analysis_results')
          .orderBy('timestamp', descending: true)
          .get();

      print(
          'Found ${sceneAnalysisSnapshot.docs.length} scene analysis documents');
      if (sceneAnalysisSnapshot.docs.isEmpty) {
        print('No scene analysis results found in the collection');
        setState(() {
          _roomData = {};
          _allRooms = [];
        });
        return;
      }

      final roomData = <String, SceneAnalysisResult>{};
      final allRooms = <String>{}; // Using a Set to avoid duplicates

      for (var doc in sceneAnalysisSnapshot.docs) {
        final data = doc.data();

        // Get room name from the data
        final roomName = data['room'] as String? ?? 'Unknown Room';
        print('Processing analysis for room: $roomName');

        // Add to all rooms
        allRooms.add(roomName);

        // Only save the latest analysis per room
        if (!roomData.containsKey(roomName)) {
          try {
            print('Processing data for room: $roomName');
            final result = SceneAnalysisResult.fromMap(data);
            roomData[roomName] = result;
            print('Successfully processed data for room: $roomName');
          } catch (e) {
            print('Error processing data for room $roomName: $e');
            print('Data causing the error: $data');
          }
        }
      }

      print(
          'Setting state with ${roomData.length} room data entries and ${allRooms.length} rooms');
      setState(() {
        _roomData = roomData;
        _allRooms = allRooms.toList(); // Convert Set to List
      });

      print('Data fetching complete. Rooms: $_allRooms');
    } catch (e) {
      print('Error fetching room data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Map<String, SceneAnalysisResult> _roomData = {};
  List<String> _allRooms = [];

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
    if (_roomData.isEmpty && _allRooms.isEmpty) {
      // We have no rooms or data yet - show loading
      return const Center(child: CircularProgressIndicator());
    }

    if (_allRooms.isEmpty) {
      // We have checked for rooms but found none
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No rooms found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddAreaDialog(true),
              child: const Text('Add Room'),
            ),
          ],
        ),
      );
    }

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
                _buildRoomStats(_roomData, _calculateTotalObjects()),
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
                if (index == _allRooms.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildAddAreaButton(
                        'Add Room', () => _showAddAreaDialog(true)),
                  );
                }

                final roomName = _allRooms[index];
                final roomAnalysis = _roomData[roomName];

                // If we have analysis data for this room
                if (roomAnalysis != null) {
                  return AreaListTile(
                    title: roomName,
                    subtitle: 'Last scan: ${roomAnalysis.formattedDate}',
                    leading: const Icon(Icons.meeting_room, size: 28),
                    trailing: '${roomAnalysis.detectionCount} objects',
                    onTap: () {
                      _showRoomDetailDialog(context, roomAnalysis);
                    },
                  );
                } else {
                  // If we don't have analysis data yet
                  return AreaListTile(
                    title: roomName,
                    subtitle: 'No scan data available',
                    leading: const Icon(Icons.meeting_room, size: 28),
                    trailing: 'Not scanned',
                    onTap: () {
                      // Navigate to scanning page for this room
                    },
                  );
                }
              },
              childCount: _allRooms.length + 1, // +1 for the Add button
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  int _calculateTotalObjects() {
    return _roomData.values.fold(0, (sum, item) => sum + item.detectionCount);
  }

  void _showRoomDetailDialog(
      BuildContext context, SceneAnalysisResult analysis) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.meeting_room,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      analysis.room,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                'Last Scan: ${analysis.formattedDate}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Total Objects: ${analysis.detectionCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Objects Found:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              // Show the list of objects
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: analysis.classSummary.length,
                  itemBuilder: (context, index) {
                    final objectCount = analysis.classSummary[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _getIconForObject(objectCount.objectClass),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        _capitalizeFirstLetter(objectCount.objectClass),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        'x${objectCount.count}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Show all images in a gallery view
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ImageViewPage(
                            imageUrl: analysis.images.detection.secureUrl,
                            title: '${analysis.room} - Detection',
                            galleryImages: _getValidImageItems(analysis),
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('View All Images'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Debug button to see image URLs
              TextButton.icon(
                onPressed: () {
                  _showDebugInfo(context, analysis);
                },
                icon: const Icon(Icons.bug_report, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                label: const Text('Debug Info', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl,
      {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewPage(
          imageUrl: imageUrl,
          title: title ?? 'Detection Image',
        ),
      ),
    );
  }

  IconData _getIconForObject(String objectClass) {
    switch (objectClass.toLowerCase()) {
      case 'chair':
        return Icons.chair;
      case 'table':
      case 'dining table':
        return Icons.table_restaurant;
      case 'sofa':
      case 'couch':
        return Icons.weekend;
      case 'bed':
        return Icons.bed;
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      case 'tv':
      case 'television':
        return Icons.tv;
      case 'book':
        return Icons.book;
      case 'cup':
      case 'glass':
        return Icons.local_drink;
      case 'bottle':
        return Icons.liquor;
      case 'remote':
        return Icons.cast;
      case 'clock':
        return Icons.access_time;
      case 'vase':
        return Icons.local_florist;
      case 'sports ball':
      case 'ball':
        return Icons.sports_basketball;
      case 'backpack':
        return Icons.backpack;
      default:
        return Icons.category;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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

  Widget _buildRoomStats(
      Map<String, SceneAnalysisResult> roomData, int totalObjects) {
    int totalRooms = roomData.length;

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
          icon: Icons.settings_input_component,
          title: 'Total Objects',
          value: totalObjects.toString(),
          color: Colors.amber,
        ),
        StatCard(
          icon: Icons.security,
          title: 'Secured Rooms',
          value: '${totalRooms > 0 ? totalRooms - 1 : 0}',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.analytics,
          title: 'Analyses',
          value: '${roomData.values.length}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInventoryStats() {
    int totalAreas = _inventoryAreas.length;
    int totalItems =
        _inventoryAreas.fold(0, (sum, area) => sum + (area['items'] as int));
    double avgStockLevel = _inventoryAreas.isEmpty
        ? 0.0
        : _inventoryAreas.fold<double>(
                0.0,
                (sum, area) =>
                    sum +
                    double.parse(
                        (area['stockLevel'] as String).replaceAll('%', ''))) /
            _inventoryAreas.length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatCard(
          icon: Icons.inventory_2,
          title: 'Total Areas',
          value: totalAreas.toString(),
          color: Colors.teal,
        ),
        StatCard(
          icon: Icons.category,
          title: 'Total Items',
          value: totalItems.toString(),
          color: Colors.pink,
        ),
        StatCard(
          icon: Icons.swap_vert,
          title: 'Avg Stock',
          value: '${avgStockLevel.toStringAsFixed(0)}%',
          color: Colors.deepPurple,
        ),
        StatCard(
          icon: Icons.warning,
          title: 'Alerts',
          value: '1',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAddAreaButton(String text, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.add,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  void _showAddAreaDialog(bool isRoom) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add ${isRoom ? 'Room' : 'Inventory Area'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter ${isRoom ? 'room' : 'area'} name',
                  border: const OutlineInputBorder(),
                ),
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    if (isRoom) {
                      // Add room logic here
                      _createRoom(nameController.text);
                    } else {
                      // Add inventory area logic here
                      _inventoryAreas.add({
                        'name': nameController.text,
                        'items': 0,
                        'stockLevel': '0%'
                      });
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createRoom(String roomName) async {
    try {
      print('Creating room data for: $roomName');

      // Create a sample scene analysis document directly in scene_analysis_results
      final sampleSceneAnalysis = {
        'class_summary': [
          {'class': 'chair', 'count': 2},
          {'class': 'desk', 'count': 1},
          {'class': 'computer', 'count': 1},
        ],
        'cloud_links': {
          'data': {
            'graph_data': {
              'format': 'json',
              'public_id': 'scene_analysis/sample-id/graph_data.json',
              'secure_url':
                  'https://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/graph_data.json',
              'url':
                  'http://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/graph_data.json',
            },
            'results': {
              'format': 'json',
              'public_id': 'scene_analysis/sample-id/results.json',
              'secure_url':
                  'https://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/results.json',
              'url':
                  'http://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/results.json',
            },
            'summary': {
              'format': 'json',
              'public_id': 'scene_analysis/sample-id/summary.json',
              'secure_url':
                  'https://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/summary.json',
              'url':
                  'http://res.cloudinary.com/sample/raw/upload/v1/scene_analysis/sample-id/summary.json',
            }
          }
        },
        'images': {
          'depth': {
            'format': 'jpg',
            'public_id': 'scene_analysis/sample-id/depth',
            'secure_url':
                'https://via.placeholder.com/800x600?text=Depth+Image',
            'url': 'http://via.placeholder.com/800x600?text=Depth+Image',
          },
          'detection': {
            'format': 'jpg',
            'public_id': 'scene_analysis/sample-id/detection',
            'secure_url':
                'https://via.placeholder.com/800x600?text=Detection+Image',
            'url': 'http://via.placeholder.com/800x600?text=Detection+Image',
          },
          'original': {
            'format': 'jpg',
            'public_id': 'scene_analysis/sample-id/original',
            'secure_url':
                'https://via.placeholder.com/800x600?text=Original+Image',
            'url': 'http://via.placeholder.com/800x600?text=Original+Image',
          },
          'segmentation': {
            'format': 'jpg',
            'public_id': 'scene_analysis/sample-id/segmentation',
            'secure_url':
                'https://via.placeholder.com/800x600?text=Segmentation+Image',
            'url': 'http://via.placeholder.com/800x600?text=Segmentation+Image',
          }
        },
        'job_id': 'sample-id-${DateTime.now().millisecondsSinceEpoch}',
        'room': roomName,
        'timestamp': DateTime.now().toIso8601String(),
        'detection_count': 4,
        'summary':
            'This room contains 4 objects: 2 chairs, 1 desk, and 1 computer.',
      };

      await FirebaseFirestore.instance
          .collection('scene_analysis_results')
          .add(sampleSceneAnalysis);

      print(
          'Successfully created sample scene analysis data for room: $roomName');

      // Refresh the data to show the new room
      _fetchRoomData();
    } catch (e) {
      print('Error creating room data: $e');
    }
  }

  List<ImageItem> _getValidImageItems(SceneAnalysisResult analysis) {
    final List<ImageItem> images = [];

    // Print all image URLs for debugging
    print('Detection Image URL: ${analysis.images.detection.secureUrl}');
    print('Segmentation Image URL: ${analysis.images.segmentation.secureUrl}');
    print('Depth Image URL: ${analysis.images.depth.secureUrl}');
    print('Original Image URL: ${analysis.images.original.secureUrl}');

    // Only add images with valid URLs (not empty)
    if (analysis.images.detection.secureUrl.isNotEmpty) {
      images.add(ImageItem(
          analysis.images.detection.secureUrl, '${analysis.room} - Detection'));
    }

    if (analysis.images.segmentation.secureUrl.isNotEmpty) {
      images.add(ImageItem(analysis.images.segmentation.secureUrl,
          '${analysis.room} - Segmentation'));
    }

    if (analysis.images.depth.secureUrl.isNotEmpty) {
      images.add(ImageItem(
          analysis.images.depth.secureUrl, '${analysis.room} - Depth'));
    }

    if (analysis.images.original.secureUrl.isNotEmpty) {
      images.add(ImageItem(
          analysis.images.original.secureUrl, '${analysis.room} - Original'));
    }

    // If no valid images, add a placeholder
    if (images.isEmpty) {
      images.add(ImageItem(
          'https://via.placeholder.com/800x600?text=No+Image+Available',
          '${analysis.room} - No Images Available'));
    }

    return images;
  }

  void _showDebugInfo(BuildContext context, SceneAnalysisResult analysis) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debug Info - Image URLs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Room: ${analysis.room}'),
              Text('Job ID: ${analysis.jobId}'),
              const SizedBox(height: 16),
              const Text('Image URLs:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDebugItem(
                          'Detection (url)', analysis.images.detection.url),
                      _buildDebugItem('Detection (secure_url)',
                          analysis.images.detection.secureUrl),
                      _buildDebugItem('Segmentation (url)',
                          analysis.images.segmentation.url),
                      _buildDebugItem('Segmentation (secure_url)',
                          analysis.images.segmentation.secureUrl),
                      _buildDebugItem('Depth (url)', analysis.images.depth.url),
                      _buildDebugItem('Depth (secure_url)',
                          analysis.images.depth.secureUrl),
                      _buildDebugItem(
                          'Original (url)', analysis.images.original.url),
                      _buildDebugItem('Original (secure_url)',
                          analysis.images.original.secureUrl),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugItem(String label, String url) {
    bool isValid = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(isValid ? 'Valid URL' : 'Empty URL'),
            ],
          ),
          if (isValid)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                url,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
