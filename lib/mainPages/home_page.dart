import 'dart:math' as math;
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/services/firebase/firebase_weight_service.dart'; // Service'i import edin
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double startWeight = 0;
  double currentWeight = 0;
  double goalWeight = 0;
  int age = 0;
  int height = 0;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        700 / 3,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadWeightData() async {
    setState(() {
      _isLoading = true;
    });

    final weightData = await FirebaseWeightService.loadWeightData();
    
    if (weightData != null) {
      setState(() {
        startWeight = weightData.startWeight;
        currentWeight = weightData.currentWeight;
        goalWeight = weightData.goalWeight;
        height = weightData.height;
        age = weightData.age;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Hata durumunda kullanıcıya bilgi verilebilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veriler yüklenirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCurrentWeight(double newWeight) async {
    // Optimistic update - UI'ı hemen güncelle
    setState(() {
      currentWeight = newWeight;
    });

    final success = await FirebaseWeightService.updateCurrentWeight(newWeight);
    
    if (!success) {
      // Eğer güncelleme başarısız olursa, eski değeri geri yükle
      await _loadWeightData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kilo güncellenirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kilo başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.vibrantBlue.withOpacity(0.3),
                AppColors.vibrantPurple.withOpacity(0.3),
                AppColors.vibrantPink.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildWeightInfo(),
                        const SizedBox(height: 20),
                        _buildChart(context),
                        const SizedBox(height: 30),
                        _buildUpdateBMIButton(context),
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Start Weight: $startWeight kg", style: AppStyles.text.copyWith(fontSize: 20)),
        Text("Goal Weight: $goalWeight kg", style: AppStyles.text.copyWith(fontSize: 20)),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final List<FlSpot> weightSpots = [
      FlSpot(0, startWeight),
      FlSpot(1, currentWeight),
      FlSpot(2, goalWeight),
    ];

    final allWeights = [startWeight, currentWeight, goalWeight];
    final minY = math.max(0, allWeights.reduce(math.min) - 5);
    final maxY = allWeights.reduce(math.max) + 5;

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.button.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.lineerStart, size: 26),
              const SizedBox(width: 8),
              Text(
                "Weight Chart",
                style: AppStyles.titleStyle.copyWith(fontSize: 25, color: AppColors.lineerStart),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 700,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 2.0,
                    minY: minY.toDouble(),
                    maxY: maxY.toDouble(),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            switch (value.toInt()) {
                              case 0:
                                return Text("Start", style: AppStyles.titleStyle.copyWith(color: AppColors.lineerEnd));
                              case 1:
                                return Text("Current", style: AppStyles.titleStyle.copyWith(color: AppColors.lineerEnd));
                              case 2:
                                return Text("Goal", style: AppStyles.titleStyle.copyWith(color: AppColors.lineerEnd));
                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weightSpots,
                        isCurved: true,
                        color: AppColors.chartColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.chartColor.withOpacity(0.2),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.chartColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.black.withOpacity(0.7),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} kg',
                              const TextStyle(color: Colors.white, fontSize: 14),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBMIButton(BuildContext context) {
    double bmi = currentWeight / ((height / 100) * (height / 100));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.button.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Age: $age", style: AppStyles.subtitleButtonStyle.copyWith(fontSize: 20)),
                Text("Height: $height cm", style: AppStyles.subtitleButtonStyle.copyWith(fontSize: 20)),
                Text("Weight: $currentWeight kg", style: AppStyles.subtitleButtonStyle.copyWith(fontSize: 20)),
                Text("BMI: ${bmi.toStringAsFixed(1)}", style: AppStyles.subtitleButtonStyle.copyWith(fontSize: 20)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.lineerEnd, size: 30),
            onPressed: () => _showUpdateDialog(context),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final weightController = TextEditingController(text: currentWeight.toString());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AlertDialog(
              backgroundColor: AppColors.primaryColor.withOpacity(0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text("Update Weight", style: AppStyles.titleStyle.copyWith(color: AppColors.lineerStart, fontSize: 25)),
              content: TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: AppStyles.text.copyWith(color: AppColors.lineerStart)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newWeight = double.tryParse(weightController.text);
                    if (newWeight != null && newWeight > 0) {
                      _updateCurrentWeight(newWeight);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen geçerli bir kilo değeri girin'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.button),
                  child: Text("Update", style: AppStyles.text.copyWith(color: AppColors.lineerStart)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}