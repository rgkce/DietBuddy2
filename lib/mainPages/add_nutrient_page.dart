import 'package:flutter/material.dart';
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/services/fatsecret_service.dart';

class AddNutritionPage extends StatefulWidget {
  const AddNutritionPage({super.key});

  @override
  State<AddNutritionPage> createState() => _AddNutritionPageState();
}

class _AddNutritionPageState extends State<AddNutritionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final FatSecretService _fatSecretService = FatSecretService();

  bool _isSaving = false;
  bool _isSearching = false;
  bool _isDetailLoading = false;
  List<Food> _searchResults = [];
  Food? _selectedFood;
  FoodDetails? _selectedFoodDetails;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double formWidth = screenWidth < 450 ? screenWidth * 0.9 : 400;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.vibrantPurple,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Add Nutrition',
            style: AppStyles.pageTitle.copyWith(
              color: AppColors.vibrantPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
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
              ),
            ),

            // Form Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Form(
                  key: _formKey,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: formWidth,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.vibrantBlue.withValues(alpha: 0.75),
                          AppColors.vibrantPink.withValues(alpha: 0.75),
                          AppColors.vibrantPurple.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildSearchForm()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Column(
      children: [
        // Search Field
        TextFormField(
          controller: _searchController,
          style: AppStyles.textStyle.copyWith(color: AppColors.lineerStart),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: AppColors.lineerStart),
            suffixIcon:
                _isSearching
                    ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.lineerStart,
                        ),
                      ),
                    )
                    : IconButton(
                      icon: Icon(Icons.clear, color: AppColors.lineerStart),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                          _selectedFood = null;
                          _selectedFoodDetails = null;
                        });
                      },
                    ),
            labelText: 'Search Food',
            hintText: 'e.g. Apple, Pizza, Chicken',
            hintStyle: TextStyle(color: AppColors.lineerEnd),
            labelStyle: TextStyle(color: AppColors.lineerStart),
            filled: true,
            fillColor: AppColors.primaryColor.withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lineerStart),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.vibrantPurple,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lineerEnd, width: 1.5),
            ),
          ),
          onFieldSubmitted: (value) => _searchFoods(),
        ),

        const SizedBox(height: 10),

        // Search Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _searchFoods,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Search'),
          ),
        ),

        const SizedBox(height: 20),

        // Search Results
        if (_searchResults.isNotEmpty) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final food = _searchResults[index];
                return ListTile(
                  title: Text(
                    food.name,
                    style: TextStyle(
                      color: AppColors.lineerStart,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    food.description,
                    style: TextStyle(color: AppColors.lineerEnd, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.vibrantPurple,
                  ),
                  onTap: () => _selectFood(food),
                  selected: _selectedFood?.id == food.id,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Selected Food Details
        if (_isDetailLoading) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ] else if (_selectedFoodDetails != null) ...[
          _buildSelectedFoodCard(),
          const SizedBox(height: 20),
        ],

        // Amount Field (only if food is selected)
        if (_selectedFood != null) ...[
          _buildTextField(
            _gramController,
            'Amount (g)',
            'e.g. 150',
            isNumber: true,
            icon: Icon(Icons.scale, color: AppColors.lineerStart),
          ),
          const SizedBox(height: 20),
        ],

        // Save Button (only if food is selected and amount is entered)
        if (_selectedFood != null) ...[
          ElevatedButton(
            onPressed:
                (_isSaving || _selectedFoodDetails == null)
                    ? null
                    : _saveFoodEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantPurple.withValues(alpha: 0.65),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child:
                _isSaving
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Text('Save', style: AppStyles.primaryStyle),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedFoodCard() {
    if (_selectedFoodDetails == null) return Container();

    final details = _selectedFoodDetails!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vibrantPurple, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            details.name,
            style: AppStyles.textStyle.copyWith(
              color: AppColors.lineerStart,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Per ${details.servingDescription}:',
            style: TextStyle(color: AppColors.lineerEnd, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutrientInfo('Calories', '${details.calories.toInt()}'),
              _buildNutrientInfo(
                'Protein',
                '${details.protein.toStringAsFixed(1)}g',
              ),
              _buildNutrientInfo(
                'Carbs',
                '${details.carbs.toStringAsFixed(1)}g',
              ),
              _buildNutrientInfo('Fat', '${details.fat.toStringAsFixed(1)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppStyles.textStyle.copyWith(
            color: AppColors.vibrantPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: AppColors.lineerEnd, fontSize: 10)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
    Icon? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      style: AppStyles.textStyle.copyWith(color: AppColors.lineerStart),
      decoration: InputDecoration(
        prefixIcon: icon,
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.lineerEnd),
        labelStyle: TextStyle(color: AppColors.lineerStart),
        filled: true,
        fillColor: AppColors.primaryColor.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lineerStart),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.vibrantPurple, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lineerEnd, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isNumber && double.tryParse(value) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }

  // Search foods using FatSecret API
  void _searchFoods() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await _fatSecretService.searchFoods(
        _searchController.text.trim(),
      );
      setState(() {
        _searchResults = results;
        _selectedFood = null;
        _selectedFoodDetails = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppColors.vibrantPink,
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Select a food from search results
  void _selectFood(Food food) async {
    setState(() {
      _selectedFood = food;
      _isDetailLoading = true;
      _selectedFoodDetails = null;
    });

    try {
      final details = await _fatSecretService.getFoodDetails(food.id);
      if (mounted) {
        setState(() {
          _selectedFoodDetails = details;
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDetailLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get food details: $e'),
            backgroundColor: AppColors.vibrantPink,
          ),
        );
      }
    }
  }

  // Save food entry from API search
  void _saveFoodEntry() async {
    if (_formKey.currentState!.validate() &&
        _gramController.text.isNotEmpty &&
        _selectedFoodDetails != null) {
      setState(() => _isSaving = true);

      try {
        final amount = double.parse(_gramController.text);
        final details = _selectedFoodDetails!;

        // Calculate nutrition based on entered amount
        // Use metric_serving_amount from API as base for calculations
        final multiplier = amount / details.metricServingAmount;

        // Return the data to be processed by NutritionPage
        Navigator.pop(context, {
          'name': details.name,
          'gram': amount,
          'calories': details.calories * multiplier,
          'protein': details.protein * multiplier,
          'carbs': details.carbs * multiplier,
          'fat': details.fat * multiplier,
          'fiber': details.fiber * multiplier,
          'isFromApi': true,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save nutrition: $e'),
              backgroundColor: AppColors.vibrantPink,
            ),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramController.dispose();
    super.dispose();
  }
}
