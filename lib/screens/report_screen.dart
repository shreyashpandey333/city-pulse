import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../themes/app_theme.dart';
import '../services/gemini_service.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Traffic';
  String _selectedSeverity = 'Medium';
  XFile? _selectedImage;
  bool _isSubmitting = false;
  Map<String, dynamic>? _aiAnalysis;

  final List<String> _categories = [
    'Traffic',
    'Emergency',
    'Weather',
    'Infrastructure',
    'Utilities',
  ];

  final List<String> _severities = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Report a City Event',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help keep your community informed by reporting events.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Image Upload
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // AI Analysis Results
              if (_aiAnalysis != null) _buildAIAnalysisSection(),

              // Category Selection
              _buildCategorySelection(),
              const SizedBox(height: 16),

              // Severity Selection
              _buildSeveritySelection(),
              const SizedBox(height: 16),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Brief description of the event',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide more details about the event',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location Info
              _buildLocationInfo(),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child:
                      _isSubmitting
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Submitting...'),
                            ],
                          )
                          : const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Photo/Video',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add visual evidence to help authorities respond faster.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Image Preview Not Available'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _aiAnalysis = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[50],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Take Photo'),
                      SizedBox(height: 4),
                      Text(
                        'Capture image using camera',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection() {
    return Card(
      color: AppTheme.successGreen.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: AppTheme.successGreen),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${_aiAnalysis!['category']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Confidence: ${(_aiAnalysis!['confidence'] * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _aiAnalysis!['description'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = _aiAnalysis!['category'];
                  _titleController.text = _aiAnalysis!['category'];
                  _descriptionController.text = _aiAnalysis!['description'];
                });
              },
              child: const Text('Use AI Suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeveritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _severities.map((severity) {
                final isSelected = _selectedSeverity == severity;
                return FilterChip(
                  label: Text(severity),
                  selected: isSelected,
                  selectedColor: AppTheme.getSeverityColor(
                    severity,
                  ).withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSeverity = severity;
                      });
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Your current location will be included with this report to help authorities respond faster.'),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getCurrentLocationText(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Getting location...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }
                return Text(
                  snapshot.data ?? 'Bengaluru, Karnataka, India',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getCurrentLocationText() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      return 'Bengaluru, Karnataka, India';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Simulate AI analysis
        _analyzeImageWithAI(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _analyzeImageWithAI(String imagePath) async {
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final analysis = await geminiService.analyzeImageWithGemini(imagePath);
      setState(() {
        _aiAnalysis = analysis;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing image: $e')));
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🚀 Starting report submission...');
      
      // Get current location
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      print('📍 Location obtained: ${position.latitude}, ${position.longitude}');
      
      String? imageUrl;
      
      // Upload image to Firebase Storage if an image is selected
      if (_selectedImage != null) {
        print('📸 Uploading image to Firebase Storage...');
        try {
          imageUrl = await StorageService.uploadReportImage(File(_selectedImage!.path));
          print('✅ Image uploaded successfully: $imageUrl');
        } catch (imageError) {
          print('❌ Error uploading image: $imageError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: Image upload failed. Report will be submitted without image.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue without image
          imageUrl = null;
        }
      }

      // Submit report to Firestore
      final reportId = await ref.read(userReportsProvider.notifier).submitReport(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        severity: _selectedSeverity,
        latitude: position.latitude,
        longitude: position.longitude,
        imageUrl: imageUrl, // Use the uploaded Firebase Storage URL
      );

      print('✅ Report submitted successfully with ID: $reportId');
      
      // Refresh user data to update reports count
      ref.read(userProvider.notifier).refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'Traffic';
          _selectedSeverity = 'Medium';
          _selectedImage = null;
          _aiAnalysis = null;
        });
      }
    } catch (e) {
      print('❌ Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('How to Report'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Take a photo or video of the event'),
                SizedBox(height: 8),
                Text('2. Select the appropriate category'),
                SizedBox(height: 8),
                Text('3. Choose the severity level'),
                SizedBox(height: 8),
                Text('4. Provide a clear title and description'),
                SizedBox(height: 8),
                Text('5. Submit your report'),
                SizedBox(height: 16),
                Text('Your report helps keep the community safe and informed!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
