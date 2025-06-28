import 'package:flutter/material.dart';
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';

class UpdateNutritionPage extends StatefulWidget {
  final String name;
  final double currentGram;
  final double currentCalorie;

  const UpdateNutritionPage({
    super.key,
    required this.name,
    required this.currentGram,
    required this.currentCalorie,
  });

  @override
  State<UpdateNutritionPage> createState() => _UpdateNutritionPageState();
}

class _UpdateNutritionPageState extends State<UpdateNutritionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gramController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gramController.text = widget.currentGram.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    // Responsive font sizes and paddings
    final titleFontSize = width * 0.07; // yaklaşık 24 için genişliğe göre
    final subtitleFontSize = width * 0.045; // yaklaşık 16 için
    final buttonHeight = height * 0.07 > 50 ? 50.0 : height * 0.07;
    final inputFontSize = width * 0.045;
    final paddingAll = width * 0.05;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: AppColors.vibrantPurple,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Update Nutrient",
            style: AppStyles.pageTitle.copyWith(
              color: AppColors.vibrantPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
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
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(paddingAll),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: EdgeInsets.all(paddingAll),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.vibrantBlue.withOpacity(0.75),
                          AppColors.vibrantPink.withOpacity(0.75),
                          AppColors.vibrantPurple.withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.name,
                          style: AppStyles.pageTitle.copyWith(
                            fontSize: titleFontSize,
                            color: AppColors.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: height * 0.02),
                        Text(
                          "Current: ${widget.currentGram.toStringAsFixed(0)}g • ${widget.currentCalorie.toStringAsFixed(0)} kcal",
                          style: AppStyles.primaryStyle.copyWith(
                            fontSize: subtitleFontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: height * 0.03),
                        _buildGramField(inputFontSize),
                        SizedBox(height: height * 0.03),
                        _isLoading
                            ? _buildLoadingButton(buttonHeight)
                            : _buildSaveButton(buttonHeight),
                      ],
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

  Widget _buildGramField(double fontSize) {
    return TextFormField(
      controller: _gramController,
      keyboardType: TextInputType.number,
      style: AppStyles.textStyle.copyWith(
        fontSize: fontSize,
        color: AppColors.lineerStart,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.scale, color: AppColors.lineerStart),
        labelText: 'Amount (g)',
        hintText: 'Enter gram amount',
        hintStyle: TextStyle(
          color: AppColors.lineerEnd,
          fontSize: fontSize * 0.9,
        ),
        labelStyle: TextStyle(color: AppColors.lineerStart, fontSize: fontSize),
        filled: true,
        fillColor: AppColors.primaryColor.withOpacity(0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lineerStart, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lineerEnd, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter amount';
        if (double.tryParse(value) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  Widget _buildSaveButton(double height) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          setState(() {
            _isLoading = true;
          });

          await Future.delayed(const Duration(seconds: 1));

          final double newGram = double.parse(_gramController.text);
          final double newCalorie =
              (widget.currentCalorie / widget.currentGram) * newGram;

          setState(() {
            _isLoading = false;
          });

          Navigator.pop(context, {
            'updatedGram': newGram,
            'updatedCalorie': newCalorie,
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vibrantPurple.withOpacity(0.65),
        foregroundColor: AppColors.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: Size(double.infinity, height),
      ),
      child: Text(
        'Save',
        style: AppStyles.primaryStyle.copyWith(fontSize: height * 0.4),
      ),
    );
  }

  Widget _buildLoadingButton(double height) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vibrantPurple.withOpacity(0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: Size(double.infinity, height),
      ),
      child: SizedBox(
        height: height * 0.5,
        width: height * 0.5,
        child: const CircularProgressIndicator(
          color: AppColors.primaryColor,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}