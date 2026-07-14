import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة قاعدة البيانات المحلية عند بدء التشغيل
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;
  
  runApp(const HeabahAccountantApp());
}

/// إدارة السمة (Theme) والوضع الداكن والضوئي
class HeabahAccountantApp extends StatefulWidget {
  const HeabahAccountantApp({super.key});

  @override
  State<HeabahAccountantApp> createState() => _HeabahAccountantAppState();
}

class _HeabahAccountantAppState extends State<HeabahAccountantApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هيبة المحاسب الذكي برو',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00B4D8), // أزرق فاتح رقمي
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00B4D8),
          secondary: Color(0xFF03045E), // أزرق داكن
        ),
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00B4D8),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B4D8),
          secondary: Colors.lightBlueAccent,
        ),
        fontFamily: 'Cairo',
      ),
      home: SplashScreen(onThemeChanged: toggleTheme),
    );
  }
}

// ==========================================
// 1. قاعدة بيانات SQLITE الفرعية والمحلية
// ==========================================
class DatabaseHelper {
  static const _databaseName = "HeabahSmartAccountant.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = p.join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // جدول العمليات المالية (سندات، قيود)
    await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL, -- "له" أو "عليه"
            date TEXT NOT NULL,
            category TEXT NOT NULL
          )
          ''');

    // جدول كروت الأصناف والمخازن
    await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            barcode TEXT,
            quantity REAL NOT NULL,
            price REAL NOT NULL,
            expiry_date TEXT
          )
          ''');

    // جدول المقاسات والتمتير
    await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_name TEXT NOT NULL,
            length REAL NOT NULL,
            width REAL NOT NULL,
            height REAL NOT NULL,
            total_area REAL NOT NULL,
            date TEXT NOT NULL
          )
          ''');
  }

  // عمليات الإدخال والاسترجاع الأساسية
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions() async {
    Database db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
  }

  Future<int> insertItem(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('inventory', row);
  }

  Future<List<Map<String, dynamic>>> queryAllItems() async {
    Database db = await instance.database;
    return await db.query('inventory');
  }

  Future<int> insertMeasurement(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('measurements', row);
  }

  Future<List<Map<String, dynamic>>> queryAllMeasurements() async {
    Database db = await instance.database;
    return await db.query('measurements');
  }
}

// ==========================================
// 2. الشاشة الافتتاحية (Splash Screen)
// ==========================================
class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // الانتقال لشاشة طلب الأذونات بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PermissionsScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03045E), // أزرق داكن
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الدائرة التي تدور وبداخلها الشعار والاسم بشكل دائري
            RotationTransition(
              turns: _controller,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00B4D8), width: 4),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline, // محاكاة لمصباح حرف S الذكي
                      size: 80,
                      color: Color(0xFF00B4D8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'هيبة المحاسب الذكي برو',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Alheabah Smart Accountant Pro',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
            const Spacer(),
            const Text(
              'Developer: Ziad ALBAWAH',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. شاشة طلب الأذونات الصارمة
// ==========================================
class PermissionsScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const PermissionsScreen({super.key, required this.onThemeChanged});

  void _showPermissionDialog(BuildContext context, String title, String message, VoidCallback onDone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.folder, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDone();
            },
            child: const Text('عدم السماح', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8)),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDone();
            },
            child: const Text('سماح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 100, color: Color(0xFF03045E)),
              const SizedBox(height: 30),
              const Text(
                'مرحباً بك في هيبة المحاسب الذكي برو',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),
              const Text(
                'يتطلب التطبيق بعض الأذونات الأساسية لضمان عمل كافة الأنظمة المحلية بدون اتصال بالإنترنت وتأمين بياناتك المالية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  // بدء نافذة إذن جهات الاتصال أولاً
                  _showPermissionDialog(
                    context,
                    'إذن جهات الاتصال',
                    'هل تريد السماح لتطبيق هيبة المحاسب الذكي برو بالوصول إلى جهات الاتصال لتسهيل إضافة العملاء والموردين؟',
                    () {
                      // ثم نافذة إذن الملفات
                      _showPermissionDialog(
                        context,
                        'إذن الملفات والوسائط',
                        'هل تريد السماح لتطبيق هيبة المحاسب الذكي برو بالدخول إلى الصور والوسائط على جهازك لحفظ فواتير وتصدير كشوفات الحساب؟',
                        () {
                          // التوجه لصفحة تسجيل الدخول
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(onThemeChanged: onThemeChanged),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text(
                  'بدء إعداد الأذونات والمتابعة',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. شاشة تسجيل الدخول (Login Screen)
// ==========================================
class LoginScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const LoginScreen({super.key, required this.onThemeChanged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'alheabah@gmail.com');
  final _passwordController = TextEditingController(text: '1234567890');
  bool _obscureText = true;

  void _login() async {
    final prefs = await SharedPreferences.getInstance();
    // جلب بيانات الدخول الحالية أو استخدام الافتراضية
    String savedEmail = prefs.getString('saved_email') ?? 'alheabah@gmail.com';
    String savedPassword = prefs.getString('saved_password') ?? '1234567890';

    if (_emailController.text == savedEmail && _passwordController.text == savedPassword) {
      // إظهار نافذة الترحيب الذكي المخصصة
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('أهلاً بك 👋', textAlign: TextAlign.center),
            content: Text(
              'مرحباً بك، alheabah\nفي عالمك المحاسبي الذكي مع هيبة المحاسب!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(onThemeChanged: widget.onThemeChanged),
                      ),
                    );
                  },
                  child: const Text('دخول لوحة التحكم', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF03045E)),
              const SizedBox(height: 20),
              const Text(
                'تسجيل الدخول الآمن',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
              ),
              const Text('يعمل محلياً بالكامل 100% وبدون اتصال بالإنترنت', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _login,
                  child: const Text(
                    'دخول مباشر آمن',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint, size: 40, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Text('محاكاة البصمة مفعلة تلقائياً', style: TextStyle(color: Colors.blueGrey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. الشاشة الرئيسية ولوحة التحكم (Dashboard)
// ==========================================
class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDarkMode = false;

  void _callDeveloper(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await launchUrl(url)) {}
  }

  void _sendSMS(String phone) async {
    final Uri url = Uri.parse('sms:$phone?body=مرحباً مطور تطبيق هيبة المحاسب الذكي برو');
    if (await launchUrl(url)) {}
  }

  void _openWhatsapp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone?text=طلب مساعدة حول تطبيق هيبة المحاسب الذكي برو');
    if (await launchUrl(url)) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF03045E),
        title: const Text('هيبة المحاسب الذكي برو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
    );
  }
}

