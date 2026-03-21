import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const SportShieldApp());
}

// Change this to your IP address when testing on real device
// For emulator use: http://10.0.2.2:5000
// For web use: http://127.0.0.1:5000
const String API_BASE = 'http://127.0.0.1:5000';

class SportShieldApp extends StatelessWidget {
  const SportShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportShield AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.shield,
                size: 60,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SportShield AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Digital Asset Protection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ScanScreen(),
    const ViolationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_outlined),
            selectedIcon: Icon(Icons.warning),
            label: 'Violations',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD SCREEN
// ============================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _assets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final statusRes = await http.get(
        Uri.parse('$API_BASE/api/v1/status'),
      );
      final assetsRes = await http.get(
        Uri.parse('$API_BASE/api/v1/assets'),
      );

      if (statusRes.statusCode == 200) {
        setState(() {
          _stats = json.decode(statusRes.body);
          _assets = json.decode(assetsRes.body)['assets'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text(
              'SportShield AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          title: 'Assets',
                          value: '${_stats['total_assets'] ?? 0}',
                          icon: Icons.photo_library,
                          color: const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          title: 'Violations',
                          value: '${_stats['total_violations'] ?? 0}',
                          icon: Icons.warning,
                          color: const Color(0xFFE11D48),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.circle,
                                  color: Color(0xFF10B981), size: 12),
                              SizedBox(width: 8),
                              Text(
                                'System Operational',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Detection methods: ${(_stats['detection_methods'] as List?)?.join(', ') ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Protected assets
                    const Text(
                      'Protected Assets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_assets.isEmpty)
                      const Center(
                        child: Text(
                          'No assets registered yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF4F46E5),
                                child: Text(
                                  asset['name'][0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                asset['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Registered: ${asset['uploaded_at']?.toString().substring(0, 10) ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCAN SCREEN
// ============================================================
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _scanning = false;
  Map<String, dynamic>? _results;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _results = null;
      });
    }
  }

  Future<void> _scanImage() async {
    if (_selectedImage == null) return;

    setState(() => _scanning = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_BASE/api/v1/scan'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = json.decode(body);

      setState(() {
        _results = data;
        _scanning = false;
      });
    } catch (e) {
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF4F46E5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF5F3FF),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: Color(0xFF4F46E5),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to select suspect image',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'JPG, PNG supported',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _selectedImage == null || _scanning
                    ? null
                    : _scanImage,
                icon: _scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt),
                label: Text(_scanning ? 'Scanning...' : 'Scan Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_results != null) ...[
              Row(
                children: [
                  const Text(
                    'Scan Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (_results!['violations_found'] ?? 0) > 0
                          ? const Color(0xFFFFF1F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_results!['violations_found'] ?? 0} violations',
                      style: TextStyle(
                        color: (_results!['violations_found'] ?? 0) > 0
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (_results!['results'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final result = _results!['results'][index];
                  final score =
                      result['scores']['final_score'] as double? ?? 0.0;
                  final isViolation = result['is_violation'] as bool? ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isViolation
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFF0FDF4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result['asset_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Score: ${score.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'Risk: ${result['risk_level'] ?? 'LOW'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isViolation
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isViolation
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isViolation ? 'ALERT' : 'SAFE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VIOLATIONS SCREEN
// ============================================================
class ViolationsScreen extends StatefulWidget {
  const ViolationsScreen({super.key});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  List<dynamic> _violations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadViolations();
  }

  Future<void> _loadViolations() async {
    try {
      final res = await http.get(
        Uri.parse('$API_BASE/api/v1/violations?limit=20'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _violations = json.decode(res.body)['violations'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _getRiskColor(double similarity) {
    if (similarity >= 90) return const Color(0xFFE11D48);
    if (similarity >= 70) return const Color(0xFFF97316);
    if (similarity >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getRiskLabel(double similarity) {
    if (similarity >= 90) return 'CRITICAL';
    if (similarity >= 70) return 'HIGH';
    if (similarity >= 50) return 'MEDIUM';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Violations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadViolations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _violations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 64, color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text(
                        'No violations detected!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadViolations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _violations.length,
                    itemBuilder: (context, index) {
                      final v = _violations[index];
                      final similarity =
                          (v['similarity'] as num?)?.toDouble() ?? 0.0;
                      final riskColor = _getRiskColor(similarity);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    v['asset_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: riskColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: riskColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _getRiskLabel(similarity),
                                      style: TextStyle(
                                        color: riskColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: similarity / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(riskColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Similarity: ${similarity.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (v['detected_at'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Detected: ${v['detected_at'].toString().substring(0, 16)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (v['found_url'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  v['found_url'].toString().length > 50
                                      ? '${v['found_url'].toString().substring(0, 50)}...'
                                      : v['found_url'].toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}