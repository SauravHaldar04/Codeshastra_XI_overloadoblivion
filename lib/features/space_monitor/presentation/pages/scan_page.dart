import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/data/services/scene_analysis_service.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_job.dart';
import 'dart:async'; // For Timer
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final ImagePicker _picker = ImagePicker();
  File? _roomImage;
  File? _inventoryImage;
  bool _isRoomVideo = false;
  bool _isInventoryVideo = false;

  // Scene Analysis API related
  final SceneAnalysisService _analysisService = SceneAnalysisService();
  SceneAnalysisJob? _currentJob;
  Timer? _statusCheckTimer;
  bool _isProcessing = false;

  // Sample data for rooms
  final List<String> _rooms = [
    'Room 101',
    'Room 202',
    'Room 300',
    'Room 15',
    'Living Room',
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
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 2,
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.meeting_room),
                text: 'Room Scan',
              ),
              Tab(
                icon: Icon(Icons.inventory),
                text: 'Inventory Scan',
              ),
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

  Future<void> _pickMedia(bool isRoom, ImageSource source, bool isVideo) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);

      if (file != null) {
        setState(() {
          if (isRoom) {
            _roomImage = File(file.path);
            _isRoomVideo = isVideo;
          } else {
            _inventoryImage = File(file.path);
            _isInventoryVideo = isVideo;
          }
        });
        _showMediaPreviewDialog(isRoom);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  void _showMediaOptions(bool isRoom) {
    final Color color = isRoom
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final String areaType = isRoom ? 'Room' : 'Inventory';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Text(
              'Capture $areaType',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to capture the $areaType',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaOptionButton(
                  context,
                  Icons.camera_alt,
                  'Take Photo',
                  () {
                    Navigator.pop(context);
                    _pickMedia(isRoom, ImageSource.camera, false);
                  },
                  color,
                ),
                _mediaOptionButton(
                  context,
                  Icons.videocam,
                  'Record Video',
                  () {
                    Navigator.pop(context);
                    _pickMedia(isRoom, ImageSource.camera, true);
                  },
                  color,
                ),
                _mediaOptionButton(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    _pickMedia(isRoom, ImageSource.gallery, false);
                  },
                  color,
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _mediaOptionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPreviewDialog(bool isRoom) {
    final File? mediaFile = isRoom ? _roomImage : _inventoryImage;
    final bool isVideo = isRoom ? _isRoomVideo : _isInventoryVideo;
    final String? area = isRoom ? _selectedRoom : _selectedInventoryArea;

    if (mediaFile == null || area == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '${isVideo ? 'Video' : 'Photo'} Preview',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? Container(
                        color: Colors.black,
                        height: 200,
                        width: double.infinity,
                        child: const Center(
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      )
                    : Image.file(
                        mediaFile,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to analyze $area?',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (isRoom) {
                  _roomImage = null;
                } else {
                  _inventoryImage = null;
                }
              });
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Only use Scene Analysis API for room images (not video and not inventory)
              if (isRoom && !isVideo) {
                _startSceneAnalysis(mediaFile, area);
              } else {
                _showScanResultDialog(isRoom);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: isRoom
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            child: const Text(
              'Analyze',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Scene Analysis API methods

  // Start analyzing an image
  Future<void> _startSceneAnalysis(File imageFile, String room) async {
    setState(() {
      _isProcessing = true;
    });

    // Show loading dialog
    _showLoadingDialog('Sending image for analysis...');

    try {
      // Call API to analyze image
      final response = await _analysisService.analyzeImage(
        imageFile: imageFile,
        room: room,
      );

      // Create SceneAnalysisJob from response
      _currentJob = SceneAnalysisJob.fromAnalyzeResponse(response);

      // Close loading dialog
      Navigator.pop(context);

      // If job was created successfully, start polling for status
      if (_currentJob != null && _currentJob!.jobId.isNotEmpty) {
        _startStatusChecking(_currentJob!.jobId, room);
      } else {
        _showErrorDialog('Failed to start analysis job.');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Error starting analysis: $e');

      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Start polling for job status
  void _startStatusChecking(String jobId, String room) {
    // Show processing dialog
    _showProcessingDialog();

    // Set up periodic status check
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final statusResponse = await _analysisService.checkStatus(jobId);
        final job = SceneAnalysisJob.fromStatusResponse(statusResponse, room);

        setState(() {
          _currentJob = job;
        });

        if (job.isComplete) {
          timer.cancel();
          _fetchResults(jobId);
        } else if (job.hasError) {
          timer.cancel();
          Navigator.pop(context); // Close processing dialog
          _showErrorDialog('Analysis failed: ${job.message}');
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        timer.cancel();
        Navigator.pop(context); // Close processing dialog
        _showErrorDialog('Error checking status: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  // Fetch results when job is complete
  Future<void> _fetchResults(String jobId) async {
    try {
      // Get results
      final resultsResponse = await _analysisService.getResults(jobId);

      // Get cloud links
      final linksResponse = await _analysisService.getCloudLinks(jobId);

      // Update current job with results and links
      setState(() {
        _currentJob = _currentJob!
            .copyWithResults(resultsResponse)
            .copyWithCloudLinks(linksResponse);
        _isProcessing = false;
      });

      // Close processing dialog
      Navigator.pop(context);

      // Show results
      _showAnalysisResults();
    } catch (e) {
      // Close processing dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Error fetching results: $e');

      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Display loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Display processing dialog with animated progress
  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Processing your image...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'This may take up to a minute. We\'re analyzing objects, depth, and spatial relationships.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator().animate(onPlay: (controller) {
                controller.repeat();
              }).shimmer(delay: 400.ms, duration: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  // Display error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Display analysis results
  void _showAnalysisResults() {
    if (_currentJob == null || !_currentJob!.hasResults) return;

    final job = _currentJob!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Analysis Results: ${job.room}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save to Firestore',
                onPressed: () => _saveAnalysisToFirestore(job),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Results Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detected ${job.detectionCount} Objects',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Scan ID: ${job.jobId}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Image Gallery
                  if (job.hasCloudLinks &&
                      job.cloudLinks!['images'] != null) ...[
                    const Text(
                      'Scene Images:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Original Image
                          if (job.cloudLinks!['images']['original'] != null)
                            _buildImageCard(
                              'Original',
                              job.cloudLinks!['images']['original']
                                  ['secure_url'],
                            ),

                          // Detection Image
                          if (job.cloudLinks!['images']['detection'] != null)
                            _buildImageCard(
                              'Detection',
                              job.cloudLinks!['images']['detection']
                                  ['secure_url'],
                            ),

                          // Depth Image
                          if (job.cloudLinks!['images']['depth'] != null)
                            _buildImageCard(
                              'Depth Map',
                              job.cloudLinks!['images']['depth']['secure_url'],
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Object Summary
                  const Text(
                    'Objects Detected:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Class summary list
                  ...job.classSummary
                      .map((item) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading:
                                  Icon(_getIconForClass(item['class'] ?? '')),
                              title: Text(
                                _capitalizeFirstLetter(
                                    item['class'] ?? 'Unknown'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item['count']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),

                  const SizedBox(height: 20),

                  // Analysis Summary
                  const Text(
                    'Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(job.summary),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build an image card for the gallery
  Widget _buildImageCard(String title, String imageUrl) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading image',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save analysis results to Firestore
  Future<void> _saveAnalysisToFirestore(SceneAnalysisJob job) async {
    if (!job.hasResults || !job.hasCloudLinks) {
      _showErrorDialog('Cannot save analysis: results or cloud links missing');
      return;
    }

    _showLoadingDialog('Saving analysis to Firestore...');

    try {
      // Create a map to store in Firestore
      final analysisData = {
        'job_id': job.jobId,
        'room': job.room,
        'timestamp': DateTime.now().toIso8601String(),
        'detection_count': job.detectionCount,
        'class_summary': job.classSummary,
        'summary': job.summary,
        'cloud_links': job.cloudLinks,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('scene_analysis_results')
          .add(analysisData);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Error saving analysis: $e');
    }
  }

  // Helper to get icon for object class
  IconData _getIconForClass(String className) {
    switch (className.toLowerCase()) {
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

  // Helper to capitalize first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildRoomScanContent() {
    final bool isAreaSelected = _selectedRoom != null;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildScannerIcon(
              Icons.camera_alt,
              primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Room Scanner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildAreaSelector(
                  'Select Room to Scan',
                  _selectedRoom,
                  _rooms,
                  (value) {
                    setState(() {
                      _selectedRoom = value;
                    });
                  },
                ),
              ),
            ),
            if (!isAreaSelected)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '👆 Please select a room to continue',
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            if (_roomImage != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _isRoomVideo
                          ? Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.videocam,
                                    color: Colors.white, size: 60),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _roomImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isRoomVideo ? Icons.videocam : Icons.image,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRoomVideo
                                      ? 'Video Selected'
                                      : 'Image Selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _roomImage = null;
                                });
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildScanButton(
                    _roomImage != null
                        ? 'Begin Room Scan'
                        : 'Capture & Scan Room',
                    _selectedRoom == null
                        ? null
                        : () {
                            if (_roomImage != null) {
                              _showScanDialog(true);
                            } else {
                              _showMediaOptions(true);
                            }
                          },
                    primaryColor,
                    _roomImage != null ? Icons.play_arrow : Icons.camera_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildInventoryScanContent() {
    final bool isAreaSelected = _selectedInventoryArea != null;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildScannerIcon(
              Icons.qr_code_scanner,
              secondaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Inventory Scanner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildAreaSelector(
                  'Select Inventory Area to Scan',
                  _selectedInventoryArea,
                  _inventoryAreas,
                  (value) {
                    setState(() {
                      _selectedInventoryArea = value;
                    });
                  },
                ),
              ),
            ),
            if (!isAreaSelected)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '👆 Please select an inventory area to continue',
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            if (_inventoryImage != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _isInventoryVideo
                          ? Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.videocam,
                                    color: Colors.white, size: 60),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _inventoryImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isInventoryVideo
                                      ? Icons.videocam
                                      : Icons.image,
                                  color: secondaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isInventoryVideo
                                      ? 'Video Selected'
                                      : 'Image Selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _inventoryImage = null;
                                });
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildScanButton(
                    _inventoryImage != null
                        ? 'Begin Inventory Scan'
                        : 'Capture & Scan Inventory',
                    _selectedInventoryArea == null
                        ? null
                        : () {
                            if (_inventoryImage != null) {
                              _showScanDialog(false);
                            } else {
                              _showMediaOptions(false);
                            }
                          },
                    secondaryColor,
                    _inventoryImage != null
                        ? Icons.play_arrow
                        : Icons.camera_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildScannerIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
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

  Widget _buildScanButton(
      String label, VoidCallback? onPressed, Color color, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _showScanDialog(bool isRoom) {
    final String area = isRoom ? _selectedRoom! : _selectedInventoryArea!;
    final Color color = isRoom
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Scanning ${isRoom ? 'Room' : 'Inventory'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning $area...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please point your camera at the area.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showScanResultDialog(isRoom);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Simulate Scan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanResultDialog(bool isRoom) {
    final String area = isRoom ? _selectedRoom! : _selectedInventoryArea!;
    final Color color = isRoom
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Scan Complete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Successfully scanned $area',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isRoom ? Icons.analytics : Icons.inventory_2,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRoom
                          ? 'Found 12 objects, 2 changes detected'
                          : 'Found 87 items, 5 low stock items',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
