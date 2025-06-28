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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.vibrantBlue.withOpacity(0.3),
              AppColors.vibrantPurple.withOpacity(0.3),
              AppColors.vibrantPink.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20,),
            Text(
          'Nutrient Tracking',
          style: AppStyles.pageTitle.copyWith(
            color: AppColors.vibrantPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
            // Add Nutrition Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddNutrition(),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text('Add Nutrition', style: AppStyles.primaryStyle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantPurple.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ),

            // Daily Summary Card
            _buildDailySummaryCard(),

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
                            color: AppColors.vibrantPurple.withOpacity(0.5),
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.vibrantBlue.withOpacity(0.8),
                AppColors.vibrantPurple.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Summary',
                style: AppStyles.textStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Calories', '${totals['calories']?.toInt() ?? 0}'),
                  _buildSummaryItem('Protein', '${totals['protein']?.toStringAsFixed(1) ?? 0}g'),
                  _buildSummaryItem('Carbs', '${totals['carbs']?.toStringAsFixed(1) ?? 0}g'),
                  _buildSummaryItem('Fat', '${totals['fat']?.toStringAsFixed(1) ?? 0}g'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppStyles.textStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(NutritionEntry nutrition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.9),
            AppColors.vibrantPink.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.2),
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
                    Icon(
                      nutrition.isFromApi ? Icons.search : Icons.edit,
                      color: AppColors.vibrantPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nutrition.name,
                        style: AppStyles.textStyle.copyWith(
                          color: AppColors.lineerStart,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showNutritionDetails(nutrition),
                      icon: Icon(
                        Icons.info_outline,
                        color: AppColors.vibrantBlue,
                      ),
                      tooltip: 'Show Details',
                    ),
                    IconButton(
                      onPressed: () => _deleteNutrition(nutrition),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.vibrantPink,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Amount
                Text(
                  '${nutrition.gram}g',
                  style: AppStyles.textStyle.copyWith(
                    color: AppColors.vibrantPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                // Nutrition Info (if available)
                if (nutrition.isFromApi && nutrition.calories != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientChip('Cal', '${nutrition.calories?.toInt() ?? 0}'),
                      _buildNutrientChip('P', '${nutrition.protein?.toStringAsFixed(1) ?? 0}g'),
                      _buildNutrientChip('C', '${nutrition.carbs?.toStringAsFixed(1) ?? 0}g'),
                      _buildNutrientChip('F', '${nutrition.fat?.toStringAsFixed(1) ?? 0}g'),
                    ],
                  ),
                ],

                // Time
                const SizedBox(height: 8),
                Text(
                  _formatTime(nutrition.dateAdded),
                  style: TextStyle(
                    color: AppColors.lineerEnd,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.vibrantPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.vibrantPurple,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.lineerEnd,
              fontSize: 10,
            ),
          ),
        ],
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
      MaterialPageRoute(
        builder: (context) => const AddNutritionPage(),
      ),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          'Delete Nutrition',
          style: AppStyles.textStyle.copyWith(
            color: AppColors.vibrantPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${nutrition.name}"?',
          style: AppStyles.textStyle.copyWith(color: AppColors.lineerStart),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.lineerEnd)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.vibrantPink)),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          'Edit Amount',
          style: AppStyles.textStyle.copyWith(
            color: AppColors.vibrantPurple,
            fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppStyles.textStyle.copyWith(color: AppColors.lineerStart),
              decoration: InputDecoration(
                labelText: 'Amount (g)',
                labelStyle: TextStyle(color: AppColors.lineerStart),
                filled: true,
                fillColor: AppColors.primaryColor.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.vibrantPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.vibrantPurple, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.lineerEnd, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.lineerEnd)),
          ),
          TextButton(
            onPressed: () async {
              final newGram = double.tryParse(controller.text);
              if (newGram != null && newGram > 0) {
                try {
                  await _nutritionService.updateNutritionGram(nutrition.id, newGram);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Amount updated successfully!'),
                        backgroundColor: AppColors.vibrantPurple,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update amount: $e'),
                        backgroundColor: AppColors.vibrantPink,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Update', style: TextStyle(color: AppColors.vibrantPurple)),
          ),
        ],
      ),
    );
  }

  void _showNutritionDetails(NutritionEntry nutrition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          nutrition.name,
          style: AppStyles.textStyle.copyWith(
            color: AppColors.vibrantPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '${nutrition.gram}g'),
            if (nutrition.isFromApi) ...[
              const SizedBox(height: 8),
              Text(
                'Nutrition Information:',
                style: AppStyles.textStyle.copyWith(
                  color: AppColors.lineerStart,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (nutrition.calories != null)
                _buildDetailRow('Calories', '${nutrition.calories!.toInt()}'),
              if (nutrition.protein != null)
                _buildDetailRow('Protein', '${nutrition.protein!.toStringAsFixed(1)}g'),
              if (nutrition.carbs != null)
                _buildDetailRow('Carbohydrates', '${nutrition.carbs!.toStringAsFixed(1)}g'),
              if (nutrition.fat != null)
                _buildDetailRow('Fat', '${nutrition.fat!.toStringAsFixed(1)}g'),
              if (nutrition.fiber != null)
                _buildDetailRow('Fiber', '${nutrition.fiber!.toStringAsFixed(1)}g'),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Manual entry - no nutrition data',
                style: TextStyle(
                  color: AppColors.lineerEnd,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow('Added', _formatTime(nutrition.dateAdded)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.vibrantPurple)),
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
            style: AppStyles.textStyle.copyWith(color: AppColors.lineerStart),
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