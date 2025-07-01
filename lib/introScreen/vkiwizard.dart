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
  DateTime? birthDate;

  void goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                birthDate: birthDate,
                onBirthDateChanged: (val) {
                  setState(() {
                    birthDate = val;
                    if (birthDate != null) {
                      final now = DateTime.now();
                      int age = now.year - birthDate!.year;
                      if (now.month < birthDate!.month ||
                          (now.month == birthDate!.month &&
                              now.day < birthDate!.day)) {
                        age--;
                      }
                      _ageController.text = age.toString();
                    }
                  });
                },
                selectedGender: gender,
                onGenderChanged: (val) => setState(() => gender = val),
                onNext: () {
                  final h = double.tryParse(_heightController.text);
                  final w = double.tryParse(_weightController.text);
                  if (h != null && w != null) {
                    setState(() {
                      vki = w / ((h / 100) * (h / 100));
                    });
                    goToPage(3);
                  }
                },
                onBack: () => goToPage(1),
              ),
              ResultPage(
                vki: vki ?? 0,
                plan: "Diyet planınızı düzenli uygulayın",
                onBack: () => goToPage(2),
                onSave: () => _saveToFirestore(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToFirestore(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pop();
        throw Exception("Kullanıcı oturumu açık değil.");
      }

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
      if (birthDate == null) {
        Navigator.of(context).pop();
        throw Exception("Doğum tarihi seçimi yapılmalıdır.");
      }
      if (age == null || age <= 0) {
        Navigator.of(context).pop();
        throw Exception("Yaş hesaplanamadı.");
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

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'height': height,
          'weight': weight,
          'initialWeight': weight,
          'targetWeight': targetWeight,
          'age': age,
          'birthDate': birthDate,
          'gender': gender!,
          'vki': currentVki,
          'category': _getBmiCategory(currentVki),
          'plan': "Diyet planınızı düzenli uygulayın",
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDocRef.update({
          'name': _nameController.text.trim(),
          'height': height,
          'weight': weight,
          'targetWeight': targetWeight,
          'age': age,
          'birthDate': birthDate,
          'gender': gender!,
          'vki': currentVki,
          'category': _getBmiCategory(currentVki),
          'plan': "Diyet planınızı düzenli uygulayın",
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verileriniz başarıyla kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationPage()),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veri kaydedilirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Firebase kayıt hatası: $e");
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
          // Gradient button instead of ElevatedButton
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
            decoration: _inputDecoration("Height (cm)"),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Weight (kg)"),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: targetWeightController,
            keyboardType: TextInputType.number,
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

class AgeGenderPage extends StatelessWidget {
  final TextEditingController ageController;
  final DateTime? birthDate;
  final Function(DateTime) onBirthDateChanged;
  final String? selectedGender;
  final Function(String) onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AgeGenderPage({
    super.key,
    required this.ageController,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.selectedGender,
    required this.onGenderChanged,
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
            "Select your birth date and gender",
            style: AppStyles.titleStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.vibrantPurple,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                onBirthDateChanged(selectedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.textfield,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    birthDate == null
                        ? "Select birth date"
                        : "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}",
                    style: AppStyles.text,
                  ),
                  const Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: ageController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Calculated age",
              filled: true,
              fillColor: AppColors.textfield,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              hintText: "Select Gender",
              filled: true,
              fillColor: AppColors.textfield,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (value) {
              if (value != null) onGenderChanged(value);
            },
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
                child: _buildGradientButton(label: 'Next', onPressed: onNext),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final double vki;
  final String plan;
  final VoidCallback onBack;
  final VoidCallback onSave; // Yeni eklenen parametre

  const ResultPage({
    super.key,
    required this.vki,
    required this.plan,
    required this.onBack,
    required this.onSave, // Yeni eklenen parametre
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
            "Your Result",
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
                    color: AppColors.vibrantPink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Category: $bmiCategory",
                  style: AppStyles.subtitleStyle.copyWith(
                    fontSize: 20,
                    color: AppColors.vibrantPink.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Recommended Plan:",
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 22,
                    color: AppColors.vibrantPink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  plan,
                  style: AppStyles.text.copyWith(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.vibrantPink.withOpacity(0.7),
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
                  onPressed: onSave, // Ana sınıftaki fonksiyonu çağır
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
