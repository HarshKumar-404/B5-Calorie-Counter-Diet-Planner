import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const CalorieCounterApp());
}

final AppState app = AppState();

class FoodItem {
  final String name;
  final double cal, p, c, f;

  const FoodItem(this.name, this.cal, this.p, this.c, this.f);
}

const List<FoodItem> foodItems = [
  FoodItem('Roti', 110, 3, 22, 1),
  FoodItem('Rice (1 cup)', 205, 4, 45, 0.4),
  FoodItem('Dal (1 cup)', 180, 10, 28, 3),
  FoodItem('Curd (100 g)', 60, 3.5, 4, 3),
  FoodItem('Banana', 105, 1.3, 27, 0.4),
  FoodItem('Apple', 95, 0.5, 25, 0.3),
  FoodItem('Soya chunks (50 g dry)', 173, 26, 17, 0.5),
  FoodItem('Boiled chana (100 g)', 164, 8.9, 27, 2.6),
  FoodItem('Paneer (100 g)', 265, 18, 3.5, 20),
  FoodItem('Idli (2 pieces)', 116, 4, 24, 0.6),
  FoodItem('Dosa (1 medium)', 168, 4, 28, 4),
  FoodItem('Upma (1 cup)', 200, 5, 30, 6),
  FoodItem('Poha (1 cup)', 180, 4, 30, 5),
  FoodItem('Peanuts (30 g)', 170, 7, 5, 14),
  FoodItem('Milk (250 ml)', 150, 8, 12, 8),
  FoodItem('Egg', 72, 6, 0.4, 5),
  FoodItem('Vegetable curry (1 cup)', 120, 3, 15, 5),
  FoodItem('Lady finger curry (1 cup)', 130, 3, 15, 6),
  FoodItem('Potato (100 g)', 87, 2, 20, 0.1),
  FoodItem('Almonds (15 g)', 87, 3.2, 3.2, 7.5),
];

class Entry {
  String id;
  String date;
  String meal;
  String name;
  double qty, cal, protein, carbs, fat;

  Entry({
    required this.id,
    required this.date,
    required this.meal,
    required this.name,
    required this.qty,
    required this.cal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'meal': meal,
        'name': name,
        'qty': qty,
        'cal': cal,
        'p': protein,
        'c': carbs,
        'f': fat,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
        date: '${j['date'] ?? today()}',
        meal: '${j['meal'] ?? 'Lunch'}',
        name: '${j['name'] ?? 'Food'}',
        qty: _num(j['qty'], 1),
        cal: _num(j['cal'], 0),
        protein: _num(j['p'] ?? j['protein'], 0),
        carbs: _num(j['c'] ?? j['carbs'], 0),
        fat: _num(j['f'] ?? j['fat'], 0),
      );
}

class WeightLog {
  String date;
  double kg;

  WeightLog({required this.date, required this.kg});

  Map<String, dynamic> toJson() => {'date': date, 'kg': kg};

  factory WeightLog.fromJson(Map<String, dynamic> j) => WeightLog(
        date: '${j['date'] ?? today()}',
        kg: _num(j['kg'], 0),
      );
}

double _num(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

String today() => DateTime.now().toIso8601String().substring(0, 10);

String dateLabel(String date) {
  try {
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return date;
  }
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  String name = '';
  String gender = 'Male';
  String goal = 'Build muscle';
  String activity = 'Moderate';

  int age = 19;
  double height = 165;
  double weight = 65;
  double target = 2200;
  double water = 0;
  bool profileSaved = false;

  List<Entry> entries = [];
  List<WeightLog> weights = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    name = '';
    gender = 'Male';
    goal = 'Build muscle';
    activity = 'Moderate';
    age = 19;
    height = 165;
    weight = 65;
    target = 2200;
    water = 0;
    profileSaved = false;
    entries = [];
    weights = [];

    try {
      final profileString = _prefs!.getString('profile');

      if (profileString != null) {
        final p = jsonDecode(profileString) as Map<String, dynamic>;
        name = '${p['name'] ?? ''}';
        age = (p['age'] as num?)?.toInt() ?? age;
        gender = '${p['gender'] ?? gender}';
        height = _num(p['height'], height);
        weight = _num(p['weight'], weight);
        goal = '${p['goal'] ?? goal}';
        activity = '${p['activity'] ?? activity}';
        profileSaved = name.trim().isNotEmpty;
      }
    } catch (_) {}

    target = _prefs!.getDouble('target') ?? target;

    try {
      final raw = _prefs!.getString('entries');
      if (raw != null) {
        entries = (jsonDecode(raw) as List)
            .map((e) => Entry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    try {
      final rawWater = _prefs!.get('water');
      if (rawWater is double) {
        water = rawWater;
      } else if (rawWater is int) {
        water = rawWater.toDouble();
      } else if (rawWater is String) {
        water = double.tryParse(rawWater) ?? 0;
      }
    } catch (_) {}

    try {
      final raw = _prefs!.getString('weights');
      if (raw != null) {
        weights = (jsonDecode(raw) as List)
            .map((e) => WeightLog.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> save() async {
    _prefs ??= await SharedPreferences.getInstance();

    await _prefs!.setString(
      'profile',
      jsonEncode({
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'goal': goal,
        'activity': activity,
      }),
    );

    await _prefs!.setDouble('target', target);
    await _prefs!.setString(
      'entries',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    await _prefs!.setDouble('water', water);
    await _prefs!.setString(
      'weights',
      jsonEncode(weights.map((e) => e.toJson()).toList()),
    );

    notifyListeners();
  }

  double get caloriesToday => entries
      .where((e) => e.date == today())
      .fold(0.0, (sum, e) => sum + e.cal);

  double get proteinToday => entries
      .where((e) => e.date == today())
      .fold(0.0, (sum, e) => sum + e.protein);

  double get carbsToday => entries
      .where((e) => e.date == today())
      .fold(0.0, (sum, e) => sum + e.carbs);

  double get fatToday => entries
      .where((e) => e.date == today())
      .fold(0.0, (sum, e) => sum + e.fat);

  List<Entry> get todayEntries =>
      entries.where((e) => e.date == today()).toList();

  double get bmi {
    if (height <= 0) return 0;
    final m = height / 100;
    return weight / (m * m);
  }

  double get bmr {
    if (gender == 'Female') {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
    return 10 * weight + 6.25 * height - 5 * age + 5;
  }

  double get calculatedTarget {
    double factor;

    switch (activity) {
      case 'Light':
        factor = 1.375;
        break;
      case 'Moderate':
        factor = 1.55;
        break;
      case 'High':
        factor = 1.725;
        break;
      default:
        factor = 1.2;
    }

    double result = bmr * factor;
    if (goal == 'Lose fat') result -= 250;
    if (goal == 'Build muscle') result += 200;
    return result.clamp(1200, 5000).toDouble();
  }

  Future<void> addEntry(Entry entry) async {
    entries.add(entry);
    await save();
  }

  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> addWater([double amount = 250]) async {
    water += amount;
    await save();
  }

  Future<void> resetWater() async {
    water = 0;
    await save();
  }

  Future<void> saveProfile({
    required String newName,
    required int newAge,
    required String newGender,
    required double newHeight,
    required double newWeight,
    required String newGoal,
    required String newActivity,
  }) async {
    name = newName.trim();
    age = newAge;
    gender = newGender;
    height = newHeight;
    weight = newWeight;
    goal = newGoal;
    activity = newActivity;
    profileSaved = name.isNotEmpty;
    target = calculatedTarget;

    if (weights.isEmpty ||
        weights.last.date != today() ||
        weights.last.kg != weight) {
      weights.add(WeightLog(date: today(), kg: weight));
    }

    await save();
  }

  Future<void> addWeight(double kg) async {
    weight = kg;
    weights.add(WeightLog(date: today(), kg: kg));
    await save();
  }
}

const Color primaryColor = Color(0xFF276749);
const Color backgroundColor = Color(0xFFF5F8F5);

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5ECE5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool showWelcome = true;
  int index = 0;

  void continueToApp() {
    setState(() {
      showWelcome = false;
      index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        if (showWelcome) {
          return WelcomeScreen(onContinue: continueToApp);
        }

        final pages = <Widget>[
          const HomeScreen(),
          const FoodScreen(),
          const DietPlanScreen(),
          const ProgressScreen(),
          ProfileScreen(key: ValueKey('${app.name}-${app.profileSaved}')),
        ];

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: index, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Food',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Diet Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE4F3E8),
              Color(0xFFF7FAF7),
              Color(0xFFEAF3EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.20),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'WELCOME TO',
                      style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Calorie Counter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183B28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your simple personal health and nutrition companion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: Color(0xFF617267),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const _WelcomeFeature(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Track your nutrition',
                      subtitle: 'Record calories and daily macros.',
                    ),
                    const SizedBox(height: 12),
                    const _WelcomeFeature(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Plan your meals',
                      subtitle: 'Explore practical vegetarian meal ideas.',
                    ),
                    const SizedBox(height: 12),
                    const _WelcomeFeature(
                      icon: Icons.show_chart_rounded,
                      title: 'Monitor your progress',
                      subtitle: 'Keep track of weight and daily habits.',
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your journey to healthier habits starts here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WelcomeFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0EAE1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget pageTitle(String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

Widget sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  );
}

Widget infoCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(18),
}) {
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: padding, child: child),
  );
}

Widget metric(String label, String value, {String? unit}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      if (unit != null)
        Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}

// FIX: accept num, so both int-like and double values are supported.
String number(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

Widget progressBar(double value, double maximum, Color color) {
  final double fraction =
      maximum <= 0 ? 0.0 : (value / maximum).clamp(0.0, 1.0).toDouble();

  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LinearProgressIndicator(
      value: fraction,
      minHeight: 8,
      backgroundColor: const Color(0xFFE8EDE8),
      color: color,
    ),
  );
}

// ============================================================
// HOME / DASHBOARD
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double remaining =
        (app.target - app.caloriesToday).clamp(0, 100000).toDouble();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        pageTitle(
          'Hello${app.name.trim().isEmpty ? '' : ', ${app.name}'} 👋',
          'Here is your nutrition summary for today.',
        ),
        if (!app.profileSaved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: infoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_add_alt_1,
                      color: primaryColor, size: 30),
                  const SizedBox(height: 10),
                  const Text(
                    'Complete your profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add your personal details to calculate your daily calorie target.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Open the Profile tab to get started.'),
                        ),
                      );
                    },
                    child: const Text('Get started in Profile'),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S CALORIES",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      number(app.caloriesToday),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 7, left: 6),
                      child: Text('kcal eaten'),
                    ),
                    const Spacer(),
                    Text(
                      '${number(app.target)} kcal goal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                progressBar(app.caloriesToday, app.target, primaryColor),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining'),
                    Text(
                      '${number(remaining)} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Macronutrients'),
                _MacroRow(
                  label: 'Protein',
                  amount: app.proteinToday,
                  color: const Color(0xFF3677C8),
                  goal: 100,
                ),
                const SizedBox(height: 14),
                _MacroRow(
                  label: 'Carbs',
                  amount: app.carbsToday,
                  color: const Color(0xFFE1A23B),
                  goal: 250,
                ),
                const SizedBox(height: 14),
                _MacroRow(
                  label: 'Fat',
                  amount: app.fatToday,
                  color: const Color(0xFF9B70C9),
                  goal: 65,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Water intake',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Text('${number(app.water)} / 2000 ml'),
                  ],
                ),
                const SizedBox(height: 12),
                progressBar(app.water, 2000, Colors.blue),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => app.addWater(250),
                      icon: const Icon(Icons.water_drop_outlined),
                      label: const Text('+250 ml'),
                    ),
                    OutlinedButton(
                      onPressed: () => app.addWater(500),
                      child: const Text('+500 ml'),
                    ),
                    TextButton(
                      onPressed: () => app.resetWater(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle("Today's meals"),
                if (app.todayEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No food recorded yet. Open Food to add your first meal.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  ...app.todayEntries.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE6F3E9),
                        child: Icon(Icons.restaurant, color: primaryColor),
                      ),
                      title: Text(e.name),
                      subtitle: Text(
                        '${e.meal} • ${number(e.qty)} serving(s)',
                      ),
                      trailing: Text('${number(e.cal)} kcal'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double amount;
  final double goal;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.amount,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${number(amount)} g / ${number(goal)} g',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 7),
        progressBar(amount, goal, color),
      ],
    );
  }
}

// ============================================================
// FOOD LOG
// ============================================================

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  String meal = 'Breakfast';
  String search = '';

  final quantityController = TextEditingController(text: '1');
  final customNameController = TextEditingController();
  final customCalController = TextEditingController();
  final customProteinController = TextEditingController();
  final customCarbsController = TextEditingController();
  final customFatController = TextEditingController();

  @override
  void dispose() {
    quantityController.dispose();
    customNameController.dispose();
    customCalController.dispose();
    customProteinController.dispose();
    customCarbsController.dispose();
    customFatController.dispose();
    super.dispose();
  }

  Future<void> addFood(FoodItem food) async {
    final qty = double.tryParse(quantityController.text.trim()) ?? 1;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero.')),
      );
      return;
    }

    await app.addEntry(
      Entry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: today(),
        meal: meal,
        name: food.name,
        qty: qty,
        cal: food.cal * qty,
        protein: food.p * qty,
        carbs: food.c * qty,
        fat: food.f * qty,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} added to $meal.')),
    );
  }

  Future<void> addCustomFood() async {
    final name = customNameController.text.trim();
    final cal = double.tryParse(customCalController.text) ?? 0;
    final p = double.tryParse(customProteinController.text) ?? 0;
    final c = double.tryParse(customCarbsController.text) ?? 0;
    final f = double.tryParse(customFatController.text) ?? 0;
    final qty = double.tryParse(quantityController.text) ?? 1;

    if (name.isEmpty || cal < 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid food name and quantity.'),
        ),
      );
      return;
    }

    await app.addEntry(
      Entry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: today(),
        meal: meal,
        name: name,
        qty: qty,
        cal: cal * qty,
        protein: p * qty,
        carbs: c * qty,
        fat: f * qty,
      ),
    );

    customNameController.clear();
    customCalController.clear();
    customProteinController.clear();
    customCarbsController.clear();
    customFatController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added to $meal.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foods = foodItems
        .where((f) => f.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        pageTitle('Food tracker', 'Record your meals and nutrition.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Add food'),
                DropdownButtonFormField<String>(
                  initialValue: meal,
                  decoration: const InputDecoration(labelText: 'Meal'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Breakfast',
                      child: Text('Breakfast'),
                    ),
                    DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => meal = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity / servings',
                    hintText: '1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search food',
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: sectionTitle('Food database'),
        ),
        ...foods.map(
          (food) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Card(
              child: ListTile(
                title: Text(food.name),
                subtitle: Text(
                  '${number(food.cal)} kcal • P ${number(food.p)} g • '
                  'C ${number(food.c)} g • F ${number(food.f)} g per serving',
                ),
                trailing: IconButton(
                  tooltip: 'Add food',
                  onPressed: () => addFood(food),
                  icon: const Icon(Icons.add_circle, color: primaryColor),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Add custom food'),
                const Text(
                  'Enter nutrition values for one serving.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customNameController,
                  decoration: const InputDecoration(labelText: 'Food name'),
                ),
                const SizedBox(height: 10),
                _numberField(customCalController, 'Calories (kcal)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        customProteinController,
                        'Protein (g)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(customCarbsController, 'Carbs (g)'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(customFatController, 'Fat (g)'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: addCustomFood,
                    icon: const Icon(Icons.add),
                    label: const Text('Add custom food'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Logged today'),
                if (app.todayEntries.isEmpty)
                  const Text('Your food log is empty.')
                else
                  ...app.todayEntries.reversed.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.name),
                      subtitle: Text(
                        '${e.meal} • ${number(e.qty)} serving(s)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${number(e.cal)} kcal'),
                          IconButton(
                            tooltip: 'Delete entry',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => app.deleteEntry(e.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}

// ============================================================
// VEGETARIAN DIET PLAN
// ============================================================

class DietPlanScreen extends StatelessWidget {
  const DietPlanScreen({super.key});

  Future<void> addMeal(
    BuildContext context,
    String meal,
    FoodItem food,
  ) async {
    await app.addEntry(
      Entry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: today(),
        meal: meal,
        name: food.name,
        qty: 1,
        cal: food.cal,
        protein: food.p,
        carbs: food.c,
        fat: food.f,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} added to today’s log.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = <String, List<FoodItem>>{
      'Breakfast': [
        foodItems[9],
        foodItems[4],
        foodItems[5],
        foodItems[11],
      ],
      'Lunch': [
        foodItems[0],
        foodItems[1],
        foodItems[2],
        foodItems[17],
        foodItems[3],
      ],
      'Evening snack': [
        foodItems[4],
        foodItems[7],
        foodItems[13],
        foodItems[19],
      ],
      'Dinner': [
        foodItems[0],
        foodItems[2],
        foodItems[16],
        foodItems[3],
        foodItems[6],
      ],
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        pageTitle('Diet plan', 'Simple vegetarian meal ideas.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Row(
              children: [
                const Icon(Icons.eco, color: primaryColor, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Build balanced meals',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Daily calorie goal: ${number(app.target)} kcal',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final group in plans.entries)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: infoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(group.key),
                  ...group.value.map(
                    (food) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text(
                        '${number(food.cal)} kcal • ${number(food.p)} g protein',
                      ),
                      trailing: IconButton(
                        tooltip: 'Add to today',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => addMeal(context, group.key, food),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Meal values are estimates. Adjust portions to your appetite, '
            'activity, and individual nutritional needs.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROGRESS, WEIGHT HISTORY, BMI AND CALORIE HISTORY
// ============================================================

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Future<void> addWeightDialog(BuildContext context) async {
    final controller = TextEditingController(text: app.weight.toString());

    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight in kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final kg = double.tryParse(controller.text.trim());
              if (kg != null && kg > 0 && kg < 500) {
                Navigator.pop(context, kg);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null) await app.addWeight(value);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, double>{};

    for (final entry in app.entries) {
      grouped[entry.date] = (grouped[entry.date] ?? 0) + entry.cal;
    }

    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedWeights = [...app.weights]
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        pageTitle('Your progress', 'See your nutrition and weight history.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Body measurements'),
                Row(
                  children: [
                    Expanded(
                      child: metric(
                        'Current weight',
                        number(app.weight),
                        unit: 'kg',
                      ),
                    ),
                    Expanded(
                      child: metric(
                        'Height',
                        number(app.height),
                        unit: 'cm',
                      ),
                    ),
                    Expanded(
                      child: metric('BMI', app.bmi.toStringAsFixed(1)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  app.bmi == 0
                      ? 'Enter your height and weight in Profile.'
                      : app.bmi < 18.5
                          ? 'BMI category: Underweight'
                          : app.bmi < 25
                              ? 'BMI category: Normal range'
                              : app.bmi < 30
                                  ? 'BMI category: Overweight'
                                  : 'BMI category: Obesity range',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => addWeightDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Record weight'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Weight history'),
                if (sortedWeights.isEmpty)
                  const Text('No weight records yet.')
                else
                  ...sortedWeights.map(
                    (w) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE6F3E9),
                        child: Icon(
                          Icons.monitor_weight_outlined,
                          color: primaryColor,
                        ),
                      ),
                      title: Text('${w.kg.toStringAsFixed(1)} kg'),
                      subtitle: Text(dateLabel(w.date)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Daily calorie history'),
                if (dates.isEmpty)
                  const Text('Add food to begin tracking your history.')
                else
                  ...dates.map(
                    (date) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(dateLabel(date))),
                              Text(
                                '${number(grouped[date]!)} kcal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          progressBar(
                            grouped[date]!,
                            app.target,
                            primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController ageController;
  late final TextEditingController heightController;
  late final TextEditingController weightController;

  String gender = app.gender;
  String goal = app.goal;
  String activity = app.activity;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: app.name);
    ageController = TextEditingController(text: app.age.toString());
    heightController = TextEditingController(text: app.height.toString());
    weightController = TextEditingController(text: app.weight.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final newName = nameController.text.trim();
    final newAge = int.tryParse(ageController.text.trim());
    final newHeight = double.tryParse(heightController.text.trim());
    final newWeight = double.tryParse(weightController.text.trim());

    if (newName.isEmpty ||
        newAge == null ||
        newAge < 1 ||
        newAge > 120 ||
        newHeight == null ||
        newHeight <= 0 ||
        newWeight == null ||
        newWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid name, age, height and weight.'),
        ),
      );
      return;
    }

    await app.saveProfile(
      newName: newName,
      newAge: newAge,
      newGender: gender,
      newHeight: newHeight,
      newWeight: newWeight,
      newGoal: goal,
      newActivity: activity,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        pageTitle('Your profile', 'Personalise your nutrition target.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFE0F0E3),
                    child: const Icon(
                      Icons.person,
                      size: 42,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    app.profileSaved ? app.name : 'Create your profile',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => gender = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: goal,
                  decoration: const InputDecoration(labelText: 'Your goal'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Build muscle',
                      child: Text('Build muscle'),
                    ),
                    DropdownMenuItem(
                      value: 'Lose fat',
                      child: Text('Lose fat'),
                    ),
                    DropdownMenuItem(
                      value: 'Maintain weight',
                      child: Text('Maintain weight'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => goal = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  decoration: const InputDecoration(
                    labelText: 'Activity level',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sedentary',
                      child: Text('Sedentary'),
                    ),
                    DropdownMenuItem(
                      value: 'Light',
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: 'Moderate',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(
                      value: 'High',
                      child: Text('High'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => activity = v);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Your daily target'),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 36,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${number(app.target)} kcal/day',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is an estimate based on the details you entered. '
                  'Actual energy needs vary from person to person.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}