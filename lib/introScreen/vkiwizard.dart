import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:dietbuddy/mainPages/main_navigation_page.dart'; // NavBar'lı ana sayfa
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VKIWizard extends StatefulWidget {
  const VKIWizard({super.key});

  @override
  _VKIWizardState createState() => _VKIWizardState();
}

class _VKIWizardState extends State<VKIWizard> {
  final PageController _pageController = PageController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? gender;
  double? vki;
  int? dailyCalories;

  void goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Günlük kalori hesaplama fonksiyonu
  int calculateDailyCalories(
    double weight,
    double height,
    int age,
    String gender,
  ) {
    double bmr;

    // Harris-Benedict formülü kullanarak Bazal Metabolizma Hızı (BMR) hesaplama
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Aktivite seviyesi çarpanı (sedanter yaşam tarzı varsayımı)
    double activityMultiplier = 1.2;

    // Günlük kalori ihtiyacı
    double dailyCalorieNeeds = bmr * activityMultiplier;

    return dailyCalorieNeeds.round();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.vibrantBlue.withOpacity(0.5),
                AppColors.vibrantPurple.withOpacity(0.5),
                AppColors.vibrantPink.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              NamePage(
                nameController: _nameController,
                onNext: () => goToPage(1),
              ),
              HeightWeightPage(
                heightController: _heightController,
                weightController: _weightController,
                targetWeightController: _targetWeightController,
                onNext: () => goToPage(2),
                onBack: () => goToPage(0),
              ),
              AgeGenderPage(
                ageController: _ageController,
                selectedGender: gender,
                onGenderChanged: (val) => setState(() => gender = val),
                onNext: () {
                  final h = double.tryParse(_heightController.text);
                  final w = double.tryParse(_weightController.text);
                  final age = int.tryParse(_ageController.text);

                  if (h != null && w != null && age != null && gender != null) {
                    setState(() {
                      vki = w / ((h / 100) * (h / 100));
                      dailyCalories = calculateDailyCalories(
                        w,
                        h,
                        age,
                        gender!,
                      );
                    });
                    goToPage(3);
                  }
                },
                onBack: () => goToPage(1),
              ),
              ResultPage(
                vki: vki ?? 0,
                dailyCalories: dailyCalories ?? 0,
                plan:
                    "Diyet planınızı düzenli uygulayın, günlük ${dailyCalories ?? 0} kalori alınız",
                onBack: () => goToPage(2),
                onSave: () => _saveToFirestore(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Firebase kaydetme fonksiyonunu ana sınıfın içine taşıdık
  Future<void> _saveToFirestore(BuildContext context) async {
    try {
      // Loading dialog'u göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pop(); // Loading dialog'u kapat
        throw Exception("Kullanıcı oturumu açık değil.");
      }

      // Veri doğrulaması
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      final targetWeight = double.tryParse(_targetWeightController.text);
      final age = int.tryParse(_ageController.text);

      if (height == null || height <= 0) {
        Navigator.of(context).pop();
        throw Exception("Geçerli bir boy değeri giriniz.");
      }
      if (weight == null || weight <= 0) {
        Navigator.of(context).pop();
        throw Exception("Geçerli bir kilo değeri giriniz.");
      }
      if (targetWeight == null || targetWeight <= 0) {
        Navigator.of(context).pop();
        throw Exception("Geçerli bir hedef kilo değeri giriniz.");
      }
      if (age == null || age <= 0) {
        Navigator.of(context).pop();
        throw Exception("Geçerli bir yaş değeri giriniz.");
      }
      if (_nameController.text.trim().isEmpty) {
        Navigator.of(context).pop();
        throw Exception("İsim alanı boş olamaz.");
      }
      if (gender == null || gender!.isEmpty) {
        Navigator.of(context).pop();
        throw Exception("Cinsiyet seçimi yapılmalıdır.");
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users_vki_data')
          .doc(user.uid);

      final docSnapshot = await userDocRef.get();
      final currentVki = vki ?? (weight / ((height / 100) * (height / 100)));
      final currentDailyCalories =
          dailyCalories ?? calculateDailyCalories(weight, height, age, gender!);

      if (!docSnapshot.exists) {
        // İlk kayıt – initialWeight eklenir
        await userDocRef.set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'height': height,
          'weight': weight,
          'initialWeight': weight, // sadece ilk seferde eklenir
          'targetWeight': targetWeight,
          'age': age,
          'gender': gender!,
          'vki': currentVki,
          'dailyCalories': currentDailyCalories,
          'category': _getBmiCategory(currentVki),
          'plan':
              "Diyet planınızı düzenli uygulayın, günlük $currentDailyCalories kalori alınız",
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Daha önce kayıt varsa – initialWeight korunur, güncellenmez
        await userDocRef.update({
          'name': _nameController.text.trim(),
          'height': height,
          'weight': weight,
          'targetWeight': targetWeight,
          'age': age,
          'gender': gender!,
          'vki': currentVki,
          'dailyCalories': currentDailyCalories,
          'category': _getBmiCategory(currentVki),
          'plan':
              "Diyet planınızı düzenli uygulayın, günlük $currentDailyCalories kalori alınız",
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.of(context).pop(); // Loading dialog'u kapat

      // Başarılı kayıt mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verileriniz başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );

      // Ana sayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationPage()),
      );
    } catch (e) {
      // Hata durumunda loading dialog'u kapat
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veri kaydedilirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Firebase kayıt hatası: $e"); // Debug için
    }
  }

  String _getBmiCategory(double vki) {
    if (vki < 18.5) return "Underweight";
    if (vki < 25) return "Normal";
    if (vki < 30) return "Overweight";
    return "Obese";
  }
}

class NamePage extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onNext;

  const NamePage({
    super.key,
    required this.nameController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/db_logo.png', height: 160),
          const SizedBox(height: 40),
          Text(
            "What is your name?",
            style: AppStyles.titleStyle.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.vibrantPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              if (nameController.text.trim().isNotEmpty) {
                onNext();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen isminizi giriniz")),
                );
              }
            },
            decoration: InputDecoration(
              hintText: "Enter your full name",
              filled: true,
              fillColor: AppColors.textfield,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildGradientButton(
            label: 'Next',
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (nameController.text.trim().isNotEmpty) {
                onNext();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen isminizi giriniz")),
                );
              }
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class HeightWeightPage extends StatelessWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetWeightController;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const HeightWeightPage({
    super.key,
    required this.heightController,
    required this.weightController,
    required this.targetWeightController,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/images/db_logo.png', height: 160),
          const SizedBox(height: 40),
          Text(
            "Enter your height and weight",
            style: AppStyles.titleStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.vibrantPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: _inputDecoration("Height (cm)"),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: _inputDecoration("Weight (kg)"),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: targetWeightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              final height = double.tryParse(heightController.text);
              final weight = double.tryParse(weightController.text);
              final targetWeight = double.tryParse(targetWeightController.text);

              if (height == null || height <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Geçerli bir boy değeri giriniz"),
                  ),
                );
              } else if (weight == null || weight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Geçerli bir kilo değeri giriniz"),
                  ),
                );
              } else if (targetWeight == null || targetWeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Geçerli bir hedef kilo değeri giriniz"),
                  ),
                );
              } else {
                onNext();
              }
            },
            decoration: _inputDecoration("Target Weight (kg)"),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.vibrantPurple),
                    ),
                    child: Center(
                      child: Text(
                        "Back",
                        style: AppStyles.titleStyle.copyWith(
                          fontSize: 18,
                          color: AppColors.vibrantPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientButton(
                  label: 'Next',
                  onPressed: () {
                    final height = double.tryParse(heightController.text);
                    final weight = double.tryParse(weightController.text);
                    final targetWeight = double.tryParse(
                      targetWeightController.text,
                    );

                    if (height == null || height <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Geçerli bir boy değeri giriniz"),
                        ),
                      );
                    } else if (weight == null || weight <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Geçerli bir kilo değeri giriniz"),
                        ),
                      );
                    } else if (targetWeight == null || targetWeight <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Geçerli bir hedef kilo değeri giriniz",
                          ),
                        ),
                      );
                    } else {
                      onNext();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.textfield,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class AgeGenderPage extends StatefulWidget {
  final TextEditingController ageController;
  final String? selectedGender;
  final Function(String) onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AgeGenderPage({
    super.key,
    required this.ageController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AgeGenderPage> createState() => _AgeGenderPageState();
}

class _AgeGenderPageState extends State<AgeGenderPage> {
  DateTime? selectedBirthDate;

  void _pickBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
        final calculatedAge =
            now.year -
            picked.year -
            ((now.month < picked.month ||
                    (now.month == picked.month && now.day < picked.day))
                ? 1
                : 0);
        widget.ageController.text = calculatedAge.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/images/db_logo.png', height: 160),
          const SizedBox(height: 40),
          Text(
            "Enter your birth date and gender",
            style: AppStyles.titleStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.vibrantPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _pickBirthDate(context),
            child: AbsorbPointer(
              child: TextField(
                controller: widget.ageController,
                decoration: _inputDecoration(
                  selectedBirthDate == null
                      ? "Select Birth Date"
                      : "Age: ${widget.ageController.text}",
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: widget.selectedGender,
            decoration: _inputDecoration("Select Gender"),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.onGenderChanged(value);
              }
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.vibrantPurple),
                    ),
                    child: Center(
                      child: Text(
                        "Back",
                        style: AppStyles.titleStyle.copyWith(
                          fontSize: 18,
                          color: AppColors.vibrantPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientButton(
                  label: 'Next',
                  onPressed: () {
                    final age = int.tryParse(widget.ageController.text);

                    if (selectedBirthDate == null || age == null || age <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Lütfen geçerli bir doğum tarihi seçiniz",
                          ),
                        ),
                      );
                    } else if (widget.selectedGender == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen cinsiyetinizi seçiniz"),
                        ),
                      );
                    } else {
                      widget.onNext();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.textfield,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final double vki;
  final int dailyCalories;
  final String plan;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const ResultPage({
    super.key,
    required this.vki,
    required this.dailyCalories,
    required this.plan,
    required this.onBack,
    required this.onSave,
  });

  String getBmiCategory(double vki) {
    if (vki < 18.5) return "Underweight";
    if (vki < 25) return "Normal";
    if (vki < 30) return "Overweight";
    return "Obese";
  }

  @override
  Widget build(BuildContext context) {
    final bmiCategory = getBmiCategory(vki);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/images/db_logo.png', height: 160),
          const SizedBox(height: 30),
          Text(
            "Your Plan",
            style: AppStyles.pageTitle.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.vibrantPurple,
            ),
          ),
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.textfield.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "BMI: ${vki.toStringAsFixed(1)}",
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vibrantPurple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Category: $bmiCategory",
                  style: AppStyles.subtitleStyle.copyWith(
                    fontSize: 20,
                    color: AppColors.vibrantPurple.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Daily Calories: $dailyCalories kcal",
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vibrantPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Recommended Plan:",
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 22,
                    color: AppColors.vibrantPurple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "$plan, günlük $dailyCalories kalori alınız",
                  style: AppStyles.text.copyWith(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.vibrantPurple.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.vibrantPurple),
                    ),
                    child: Center(
                      child: Text(
                        "Back",
                        style: AppStyles.titleStyle.copyWith(
                          fontSize: 18,
                          color: AppColors.vibrantPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientButton(
                  label: 'Save & Continue',
                  onPressed: onSave,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

Widget _buildGradientButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.vibrantBlue.withOpacity(0.4),
            AppColors.vibrantPurple.withOpacity(0.4),
            AppColors.vibrantPink.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppStyles.titleStyle.copyWith(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    ),
  );
}
