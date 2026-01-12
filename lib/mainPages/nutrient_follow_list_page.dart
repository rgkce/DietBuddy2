import 'package:flutter/material.dart';
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/services/nutrition_service.dart';
import 'package:dietbuddy/mainPages/add_nutrient_page.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final NutritionService _nutritionService = NutritionService();

  int _goalCalories = 2000; // varsayılan değer

  @override
  void initState() {
    super.initState();
    _loadGoalCalories();
  }

  Future<void> _loadGoalCalories() async {
    try {
      final goal = await _nutritionService.getDailyGoalCalories();
      if (mounted) {
        setState(() {
          _goalCalories = goal;
        });
      }
    } catch (e) {
      // Hata varsa varsayılan kalori değerini ayarla ve hata logla
      debugPrint("Goal calorie loading error: $e");
      if (mounted) {
        setState(() {
          _goalCalories = 2000;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.vibrantBlue.withValues(alpha: 0.3),
              AppColors.vibrantPurple.withValues(alpha: 0.3),
              AppColors.vibrantPink.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 50),
            Text(
              'Nutrient Tracking',
              style: AppStyles.pageTitle.copyWith(
                color: AppColors.vibrantPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            // Add Nutrition Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddNutrition(),
                  icon: Icon(Icons.add, color: AppColors.primaryColor),
                  label: Text('Add Nutrition', style: AppStyles.primaryStyle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantPurple.withValues(
                      alpha: 0.8,
                    ),
                    foregroundColor: AppColors.primaryColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            // Daily Summary Card
            _buildDailySummaryCard(),
            SizedBox(height: 30),
            // Nutrition List
            Expanded(
              child: StreamBuilder<List<NutritionEntry>>(
                stream: _nutritionService.getTodayNutrition(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.vibrantPurple,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: AppColors.vibrantPurple),
                      ),
                    );
                  }

                  final nutritionList = snapshot.data ?? [];

                  if (nutritionList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.vibrantPurple.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No nutrition entries yet',
                            style: AppStyles.textStyle.copyWith(
                              color: AppColors.vibrantPurple,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Add Nutrition" to get started',
                            style: TextStyle(
                              color: AppColors.lineerEnd,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nutritionList.length,
                    itemBuilder: (context, index) {
                      final nutrition = nutritionList[index];
                      return _buildNutritionCard(nutrition);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    return StreamBuilder<List<NutritionEntry>>(
      stream: _nutritionService.getTodayNutrition(),
      builder: (context, snapshot) {
        final nutritionList = snapshot.data ?? [];
        final totals = _nutritionService.calculateDailyTotals(nutritionList);

        final int currentCalories = totals['calories']?.toInt() ?? 0;
        double progress = currentCalories / _goalCalories;
        if (progress > 1.0) progress = 1.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Today\'s Summary',
                  style: AppStyles.textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 18,
                  backgroundColor: AppColors.shadowColor.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.5
                        ? AppColors.lineerEnd
                        : (progress < 0.8
                            ? AppColors.vibrantPink
                            : AppColors.errorColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$currentCalories / $_goalCalories kcal',
                style: AppStyles.textStyle.copyWith(fontSize: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionCard(NutritionEntry nutrition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.9),
            AppColors.vibrantPink.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditGramDialog(nutrition),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nutrition.name,
                        style: AppStyles.textStyle.copyWith(
                          color: AppColors.lineerStart,
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showNutritionDetails(nutrition),
                      icon: Icon(
                        Icons.info_outline,
                        color: AppColors.lineerEnd,
                      ),
                      tooltip: 'Show Details',
                    ),
                    IconButton(
                      onPressed: () => _deleteNutrition(nutrition),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.errorColor,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Gram ve Kalori Bilgisi
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${nutrition.gram}g',
                      style: AppStyles.textStyle.copyWith(
                        color: AppColors.vibrantPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text('-'),
                    SizedBox(width: 20),
                    if (nutrition.calories != null)
                      Text(
                        '${nutrition.calories!.toInt()} kcal',
                        style: AppStyles.textStyle.copyWith(
                          color: AppColors.vibrantPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),
                // Zaman bilgisi
                Text(
                  _formatTime(nutrition.dateAdded),
                  style: TextStyle(color: AppColors.lineerEnd, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _navigateToAddNutrition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNutritionPage()),
    );

    if (result != null) {
      _saveNutritionEntry(result);
    }
  }

  void _saveNutritionEntry(Map<String, dynamic> data) async {
    try {
      final entry = NutritionEntry(
        id: '', // Firestore will generate this
        name: data['name'],
        gram: data['gram'],
        calories: data['calories'],
        protein: data['protein'],
        carbs: data['carbs'],
        fat: data['fat'],
        fiber: data['fiber'],
        isFromApi: data['isFromApi'] ?? false,
        dateAdded: DateTime.now(),
        userId: '', // NutritionService will handle this
      );

      await _nutritionService.addNutrition(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['name']} added successfully!'),
            backgroundColor: AppColors.vibrantPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add nutrition: $e'),
            backgroundColor: AppColors.vibrantPink,
          ),
        );
      }
    }
  }

  void _deleteNutrition(NutritionEntry nutrition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primaryColor,
            title: Text(
              'Delete Nutrition',
              style: AppStyles.textStyle.copyWith(
                color: AppColors.vibrantPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${nutrition.name}"?',
              style: AppStyles.textStyle.copyWith(
                color: AppColors.lineerStart,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.lineerEnd, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.errorColor, fontSize: 18),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _nutritionService.deleteNutrition(nutrition.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${nutrition.name} deleted successfully!'),
              backgroundColor: AppColors.vibrantPurple,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete nutrition: $e'),
              backgroundColor: AppColors.vibrantPink,
            ),
          );
        }
      }
    }
  }

  void _showEditGramDialog(NutritionEntry nutrition) {
    final controller = TextEditingController(text: nutrition.gram.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primaryColor,
            title: Text(
              'Edit Amount',
              style: AppStyles.textStyle.copyWith(
                color: AppColors.vibrantPurple,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nutrition.name,
                  style: AppStyles.textStyle.copyWith(
                    color: AppColors.lineerStart,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppStyles.textStyle.copyWith(
                    color: AppColors.lineerStart,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (g)',
                    labelStyle: TextStyle(color: AppColors.lineerStart),
                    filled: true,
                    fillColor: AppColors.primaryColor.withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.vibrantPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.vibrantPurple,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.lineerEnd,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.lineerEnd, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final newGram = double.tryParse(controller.text);
                  if (newGram != null && newGram > 0) {
                    try {
                      await _nutritionService.updateNutritionGram(
                        nutrition.id,
                        newGram,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Amount updated successfully!'),
                          backgroundColor: AppColors.vibrantPurple,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update amount: $e'),
                          backgroundColor: AppColors.vibrantPink,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Update',
                  style: TextStyle(
                    color: AppColors.vibrantPurple,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showNutritionDetails(NutritionEntry nutrition) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              nutrition.name,
              style: AppStyles.textStyle.copyWith(
                color: AppColors.vibrantPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Amount', '${nutrition.gram}g'),
                  const SizedBox(height: 12),
                  Text(
                    'Nutrition Information:',
                    style: AppStyles.textStyle.copyWith(
                      color: AppColors.lineerStart,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Calories',
                    '${nutrition.calories?.toInt() ?? '-'}',
                  ),
                  _buildDetailRow(
                    'Protein',
                    '${nutrition.protein?.toStringAsFixed(1) ?? '-'}g',
                  ),
                  _buildDetailRow(
                    'Carbs',
                    '${nutrition.carbs?.toStringAsFixed(1) ?? '-'}g',
                  ),
                  _buildDetailRow(
                    'Fat',
                    '${nutrition.fat?.toStringAsFixed(1) ?? '-'}g',
                  ),
                  _buildDetailRow(
                    'Fiber',
                    '${nutrition.fiber?.toStringAsFixed(1) ?? '-'}g',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Added', _formatTime(nutrition.dateAdded)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: AppColors.vibrantPurple),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.textStyle.copyWith(
              color: AppColors.lineerStart,
              fontSize: 18,
            ),
          ),
          Text(
            value,
            style: AppStyles.textStyle.copyWith(
              color: AppColors.vibrantPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
