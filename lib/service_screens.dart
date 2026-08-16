import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'main.dart';
import 'data/database/database_helper.dart';
import 'data/models/lap_session_model.dart';
import 'data/models/service_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'map_safety_screens.dart';

class ServiceScreens extends StatefulWidget {
  final String mode;
  const ServiceScreens({super.key, required this.mode});

  @override
  State<ServiceScreens> createState() => _ServiceScreensState();
}

class _ServiceScreensState extends State<ServiceScreens>
    with SingleTickerProviderStateMixin {
  // ══════════ Lap Counter Variables ══════════
  int count = 0;
  bool isWaiting = false;
  LapSessionModel? activeSession;
  List<LapSessionModel> history = [];
  bool isLoading = true;
String ritualCategory = 'tawaf';   // طواف أو سعي
String selectedRitualType = '';    // نوع الطواف أو السعي

  // Get max laps based on ritual type
int get maxLaps {
  if (selectedRitualType.isEmpty) return 7;  // default
  return selectedRitualType.startsWith('sai') ? 7 : 7;
}
  // ══════════ Services Variables ══════════
  List<ServiceModel> allServices = [];
  List<ServiceModel> filteredServices = [];
  String selectedServiceType = 'all';
  TextEditingController searchController = TextEditingController();

  // ══════════ Animation Controller ══════════
AnimationController? _pulseCtrl; // شلنا late وأضفنا علامة الاستفهان
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1200),
);
_pulseCtrl?.repeat(reverse: true); // تشغيل الأنيميشن بأمان

    if (widget.mode == "counter") {
      _loadActiveSession();
      _loadHistory();
    } else if (widget.mode == "services") {
      _loadServices();
    }
  }
List<Map<String, String>> saiTypes = [
  {
    'key': 'sai_umrah',
    'ar': 'سعي العمرة',
    'en': 'Umrah Sa\'i',
    'ur': 'عمرہ سعی',
    'id': 'Sa\'i Umrah'
  },
  {
    'key': 'sai_hajj',
    'ar': 'سعي الحج',
    'en': 'Hajj Sa\'i',
    'ur': 'حج سعی',
    'id': 'Sa\'i Haji'
  },
  {
    'key': 'sai_nafl',
    'ar': 'سعي تطوع',
    'en': 'Voluntary Sa\'i',
    'ur': 'نفل سعی',
    'id': 'Sa\'i Sunnah'
  },
];
List<Map<String, String>> tawafTypes = [
  {
    'key': 'tawaf_qudum',
    'ar': 'طواف قدوم',
    'en': 'Arrival Tawaf',
    'ur': 'طواف قدوم',
    'id': 'Tawaf Qudum'
  },
  {
    'key': 'tawaf_ifada',
    'ar': 'طواف إفاضة',
    'en': 'Ifadah Tawaf',
    'ur': 'طواف افاضہ',
    'id': 'Tawaf Ifadah'
  },
  {
    'key': 'tawaf_wada',
    'ar': 'طواف وداع',
    'en': 'Farewell Tawaf',
    'ur': 'طواف وداع',
    'id': 'Tawaf Wada'
  },
  {
    'key': 'tawaf_umrah',
    'ar': 'طواف العمرة',
    'en': 'Umrah Tawaf',
    'ur': 'طواف عمرہ',
    'id': 'Tawaf Umrah'
  },
  {
    'key': 'tawaf_nafl',
    'ar': 'طواف تطوع',
    'en': 'Voluntary Tawaf',
    'ur': 'نفل طواف',
    'id': 'Tawaf Sunnah'
  },
];
  @override
  void dispose() {
_pulseCtrl?.dispose();  
    super.dispose();
  }

  String _getTranslatedLabel(SmartHajjAppState state, String type) {
    Map<String, Map<String, String>> labels = {
      'all': {'ar': 'الكل', 'en': 'All', 'ur': 'سب', 'id': 'Semua'},
      'hospital': {'ar': 'مستشفيات', 'en': 'Hospitals', 'ur': 'اسپتال', 'id': 'Rumah Sakit'},
      'water': {'ar': 'مياه زمزم', 'en': 'Zamzam', 'ur': 'زمزم', 'id': 'Air Zamzam'},
      'lost_found': {'ar': 'المفقودات', 'en': 'Lost & Found', 'ur': 'گمشدہ', 'id': 'Barang Hilang'},
      'transport': {'ar': 'النقل', 'en': 'Transport', 'ur': 'نقل وحمل', 'id': 'Transportasi'},
      'toilet': {'ar': 'دورات المياه', 'en': 'Toilets', 'ur': 'بیت الخلا', 'id': 'Toilet'},
    };
    return labels[type]?[state.locale.languageCode] ?? labels[type]?['en'] ?? type;
  }


 Future<void> _loadActiveSession() async {
    final session = await DatabaseHelper.instance.getActiveLapSession();
    setState(() {
      if (session != null) {
        activeSession = session;
        count = session.currentLap; // سيأخذ القيمة المخزنة فعلياً
        selectedRitualType = session.ritualType;
      } else {
        count = 0; // إذا لا توجد جلسة، العداد صفر حتماً
      }
      isLoading = false;
    });
}
  Future<void> _loadHistory() async {
    final loadedHistory = await DatabaseHelper.instance.getLapHistory();
    setState(() => history = loadedHistory);
  }

 Future<void> _startNewSession() async {
  // التأكد من تصفير العداد قبل البدء
  setState(() {
    count = 0; 
  });

  final newSession = LapSessionModel(
    ritualType: selectedRitualType,
    currentLap: 0,
    startTime: DateTime.now(),
  );

  final id = await DatabaseHelper.instance.insertLapSession(newSession);

  setState(() {
    activeSession = LapSessionModel(
      id: id,
      ritualType: selectedRitualType,
      currentLap: 0,
      startTime: DateTime.now(),
    );
  });
}

 Future<void> _handleIncrement() async {
  // إذا كان العداد مكتمل أو بانتظار عملية، لا تفعل شيئاً
  if (isWaiting || count >= maxLaps || activeSession == null) return;

  setState(() => isWaiting = true);
  HapticFeedback.mediumImpact();

  // محاكاة الانتظار لضمان دقة الدورة
  await Future.delayed(const Duration(seconds: 1)); 
  
  if (!mounted) return;

  final newCount = count + 1; // الزيادة هنا
  
  final updatedSession = LapSessionModel(
    id: activeSession!.id,
    ritualType: activeSession!.ritualType,
    currentLap: newCount,
    startTime: activeSession!.startTime,
    endTime: newCount == maxLaps ? DateTime.now() : null,
    isComplete: newCount == maxLaps,
  );

  await DatabaseHelper.instance.updateLapSession(updatedSession);

  setState(() {
    count = newCount;
    activeSession = updatedSession;
    isWaiting = false;
  });

  if (newCount == maxLaps) {
    HapticFeedback.heavyImpact();
    _showCompletionDialog();
    _loadHistory();
  }
}
 Future<void> _resetCounter() async {
    if (activeSession != null && activeSession!.id != null) {
      await DatabaseHelper.instance.deleteLapSession(activeSession!.id!);
    }
    setState(() {
      activeSession = null;
      count = 0;
      selectedRitualType = ''; // تصفير النوع المختار ليعود العداد 0/0
    });
    _loadHistory(); 
  }

  void _showCompletionDialog() {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF40916C).withOpacity(0.2),
                    const Color(0xFF40916C).withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(Icons.celebration_rounded,
                  size: 50, color: Color(0xFF40916C)),
            ),
            const SizedBox(height: 20),
            Text(
              state.locale.languageCode == 'ar' ? 'مبروك!' : 'Congratulations!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2818),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.locale.languageCode == 'ar'
                  ? 'لقد أكملت ${selectedRitualType == 'tawaf' ? 'الطواف' : 'السعي'} بنجاح'
                  : 'You completed ${selectedRitualType == 'tawaf' ? 'Tawaf' : 'Sa\'i'} successfully',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            if (activeSession != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF40916C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      state.locale.languageCode == 'ar' ? 'الوقت المستغرق' : 'Duration',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(activeSession!.durationInSeconds),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40916C),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  activeSession = null;
                  count = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2818),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                state.locale.languageCode == 'ar' ? 'حسناً' : 'OK',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
String _getRitualCategoryLabel(SmartHajjAppState state) {
  if (ritualCategory == 'tawaf') {
    return state.locale.languageCode == 'ar' ? 'طواف' : 'Tawaf';
  } else {
    return state.locale.languageCode == 'ar' ? 'سعي' : 'Sa\'i';
  }
}

String _getRitualTypeLabel(SmartHajjAppState state) {
  final items = ritualCategory == 'tawaf' ? tawafTypes : saiTypes;
  final item = items.firstWhere(
    (i) => i['key'] == selectedRitualType,
    orElse: () => {'ar': '', 'en': '', 'ur': '', 'id': ''},
  );
  return item[state.locale.languageCode] ?? '';
}

  Future<void> _loadServices() async {
    setState(() => isLoading = true);
    final services = await DatabaseHelper.instance.getAllServices();
    setState(() {
      allServices = services;
      filteredServices = services;
      isLoading = false;
    });
  }

  void _filterServices(String type) {
    setState(() {
      selectedServiceType = type;
      if (type == 'all') {
        filteredServices = allServices;
      } else {
        filteredServices = allServices.where((s) => s.serviceType == type).toList();
      }
    });
  }

  void _searchServices(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredServices = selectedServiceType == 'all'
            ? allServices
            : allServices.where((s) => s.serviceType == selectedServiceType).toList();
      });
      return;
    }

    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    setState(() {
      filteredServices = allServices.where((service) {
        final name = service.getName(state.locale.languageCode).toLowerCase();
        final description = service.getDescription(state.locale.languageCode).toLowerCase();
        return name.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<String> _calculateDistance(double destLat, double destLng) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destLat,
        destLng,
      );
      if (distance < 1000) {
        return '${distance.round()} m';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)} km';
      }
    } catch (e) {
      return '~ 2 km';
    }
  }


String _getSelectedName(SmartHajjAppState state) {
  if (selectedRitualType.isEmpty) return "";
  final allItems = [...tawafTypes, ...saiTypes];
  final selectedItem = allItems.firstWhere(
    (item) => item['key'] == selectedRitualType,
    orElse: () => {'ar': ''},
  );
  return selectedItem[state.locale.languageCode] ?? "";
}
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        body: widget.mode == "counter"
            ? _buildCounterScreen(state, isRTL)
            : _buildServicesScreen(state, isRTL),
      ),
    );
  }

  Widget _buildCounterScreen(SmartHajjAppState state, bool isRTL) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D2818)));
    }

    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Icon(
                      Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20, ),
                      ),
                    ),
            
                  Expanded(
                    child: Text(
                      state.translate('counter'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showHistoryDialog(state),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: const Color(0xFFC9A84C).withOpacity(0.15),
                        border: Border.all(
                          color: const Color(0xFFC9A84C).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),


 // Ritual Type Selection - الخيارات الرئيسية
// Ritual Type Selection
if (activeSession == null) ...[
  Row(
    children: [
      Expanded(
        child: _ritualTypeCard(
          state,
          'tawaf',
          state.locale.languageCode == 'ar' ? 'طواف' : 'Tawaf',
          Icons.autorenew_rounded,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _ritualTypeCard(
          state,
          'sai',
          state.locale.languageCode == 'ar' ? 'سعي' : 'Sa\'i',
          Icons.directions_walk_rounded,
        ),
      ),
    ],
  ),
  const SizedBox(height: 24),
],

            // Counter Display
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: count / maxLaps,
                            bgColor: const Color(0xFFE0E8E4),
                            fgColor: count == maxLaps
                                ? const Color(0xFF40916C)
                                : const Color(0xFFC9A84C),
                          ),
                        ),
                      ),
                      // Count Text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getSelectedName(state),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeSession == null ? "0" : "$count",
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: count == maxLaps
                                  ? const Color(0xFF40916C)
                                  : const Color(0xFF0D2818),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
  activeSession == null 
      ? "0 / 0" 
      : (state.locale.languageCode == 'ar'
          ? 'من $maxLaps أشواط'
          : state.locale.languageCode == 'ur'
              ? '$maxLaps چکروں میں سے'
              : state.locale.languageCode == 'id'
                  ? 'dari $maxLaps putaran'
                  : 'of $maxLaps rounds'),

                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ], // قوس إغلاق الأطفال في Stack
                  ), // قوس إغلاق Stack
                ), // قوس إغلاق SizedBox

                const SizedBox(height: 24),

                // Lap Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(maxLaps, (i) {
                    final done = i < count;
                    final current = i == count - 1 && count < maxLaps;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: current ? 36 : 32,
                      height: current ? 36 : 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: done
                            ? const LinearGradient(
                            colors: [Color(0xFFC9A84C), Color(0xFFE8C96D)])
                            : null,
                        color: done ? null : const Color(0xFFE0E8E4),
                        border: Border.all(
                          color: current
                              ? const Color(0xFFC9A84C)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: current
                            ? [
                          BoxShadow(
                            color: const Color(0xFFC9A84C).withOpacity(0.4),
                            blurRadius: 12,
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: done
                                ? const Color(0xFF3D2800)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

// Tap Button
                if (count < maxLaps)
                  GestureDetector(
                    onTap: () async {
                      if (activeSession == null) {
                        await _startNewSession();
                      }
                      _handleIncrement();
                    },
                    child: AnimatedBuilder(
                      animation: _pulseCtrl ?? AlwaysStoppedAnimation(0.0),
                      builder: (_, __) => Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isWaiting
                              ? LinearGradient(
                                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: isWaiting
                                  ? Colors.grey.withOpacity(0.3)
                                  : const Color(0xFF0D2818).withOpacity(
                                      0.2 + 0.15 * (_pulseCtrl?.value ?? 0.0)),
                              blurRadius: 20 + 15 * (_pulseCtrl?.value ?? 0.0),
                              spreadRadius: 3 * (_pulseCtrl?.value ?? 0.0),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isWaiting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.touch_app_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.locale.languageCode == 'ar'
                                          ? 'اضغط للعدّ'
                                          : state.locale.languageCode == 'ur'
                                              ? 'گننے کے لیے دبائیں'
                                              : state.locale.languageCode == 'id'
                                                  ? 'Ketuk untuk Menghitung'
                                                  : 'Tap to Count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Reset Button
                if (count > 0)
                  TextButton.icon(
                    onPressed: isWaiting ? null : () => _showResetDialog(state),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isWaiting ? Colors.grey : Colors.red.shade700,
                    ),
                    label: Text(
                      state.translate('reset'),
                      style: TextStyle(
                        color: isWaiting ? Colors.grey : Colors.red.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

 Widget _ritualTypeCard(
  SmartHajjAppState state,
  String type,
  String label,
  IconData icon,
) {
  final isSelected = ritualCategory == type;

  return GestureDetector(
    onTap: () {
      setState(() => ritualCategory = type);
      HapticFeedback.selectionClick();
      _showRitualTypeBottomSheet(state, type);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        // أبيض بالكامل، ويصبح أخضر غامق فقط عند الاختيار
        color: isSelected ? const Color(0xFF0D2818) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF0D2818),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF0D2818),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
  // Bottom Sheet
void _showRitualTypeBottomSheet(SmartHajjAppState state, String category) {
  final items = category == 'tawaf' ? tawafTypes : saiTypes;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // لجعل الحواف دائرية
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA), // خلفية فاتحة جداً للـ sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          ...items.map((item) {
            final isSelected = selectedRitualType == item['key'];
            return GestureDetector(
              onTap: () {
                setState(() => selectedRitualType = item['key']!);
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white, // أبيض صريح
                  borderRadius: BorderRadius.circular(15),
                  // ظل مودرن لإعطاء عمق
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D2818) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      item[state.locale.languageCode]!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: const Color(0xFF0D2818),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}
  void _showResetDialog(SmartHajjAppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.translate('reset'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          state.locale.languageCode == 'ar'
              ? 'هل تريد إعادة العداد من الصفر؟'
              : 'Are you sure you want to reset the counter?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetCounter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(state.translate('reset')),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(SmartHajjAppState state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2818).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF0D2818),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
  state.locale.languageCode == 'ar'
      ? 'سجل الجلسات'
      : state.locale.languageCode == 'ur'
          ? 'سیشن کی تاریخ'
          : state.locale.languageCode == 'id'
              ? 'Riwayat Sesi'
              : 'Session History', // English default
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0D2818),
  ),
),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2818).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        Icons.check_circle_rounded,
                        history.length.toString(),
                        state.locale.languageCode == 'ar' ? 'مكتمل' : 
                       state.locale.languageCode == 'ur' ? 'مکمل' : 
                       state.locale.languageCode == 'id' ? 'Selesai' : 'Completed',
                        const Color(0xFF40916C),
                      ),
                      
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _statItem(
                        Icons.access_time_rounded,
                        _formatDuration(
                          (history.map((s) => s.durationInSeconds).reduce((a, b) => a + b) /
                              history.length)
                              .round(),
                        ),
state.locale.languageCode == 'ar' ? 'متوسط' : 
state.locale.languageCode == 'ur' ? 'اوسط' : 
state.locale.languageCode == 'id' ? 'Rata-rata' : 'Average',
                        const Color(0xFFC9A84C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: history.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 15),
                      Text(
                        state.locale.languageCode == 'ar' ? 'لا يوجد سجل بعد' : 
                        state.locale.languageCode == 'ur' ? 'ابھی تک کوئی تاریخ نہیں ہے' : 
                        state.locale.languageCode == 'id' ? 'Belum ada riwayat' : 'No history yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final session = history[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: session.ritualType == 'tawaf'
                                  ? const Color(0xFF0D2818).withOpacity(0.1)
                                  : const Color(0xFF40916C).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              session.ritualType == 'tawaf'
                                  ? Icons.autorenew_rounded
                                  : Icons.directions_walk_rounded,
                              color: session.ritualType == 'tawaf'
                                  ? const Color(0xFF0D2818)
                                  : const Color(0xFF40916C),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.ritualType == 'tawaf'
                                      ? (state.locale.languageCode == 'ar'
                                      ? 'طواف'
                                      : 'Tawaf')
                                      : (state.locale.languageCode == 'ar'
                                      ? 'سعي'
                                      : 'Sa\'i'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(session.startTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF40916C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '7/7 ✓',
                                  style: TextStyle(
                                    color: Color(0xFF40916C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formatDuration(session.durationInSeconds),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  🏥 SERVICES UI - تصميم احترافي جديد
  // ═════════════════════════════════════════════════════════════
  Widget _buildServicesScreen(SmartHajjAppState state, bool isRTL) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D2818)),
      );
    }

    return Column(
      children: [
        // ── Header with Categories ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20, ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          state.translate('services'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextField(
                    controller: searchController,
                    onChanged: _searchServices,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: state.locale.languageCode == 'ar'
                          ? 'ابحث عن خدمة...'
                          : 'Search for a service...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.7)),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.white.withOpacity(0.7)),
                        onPressed: () {
                          searchController.clear();
                          _searchServices('');
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                // Categories
                Container(
                  height: 80,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _categoryChip(state, 'all', Icons.apps_rounded),
                      _categoryChip(state, 'hospital', Icons.local_hospital_rounded),
                      _categoryChip(state, 'water', Icons.water_drop_rounded),
                      _categoryChip(state, 'lost_found', Icons.search_rounded),
                      _categoryChip(state, 'transport', Icons.electric_car_rounded),
                      _categoryChip(state, 'toilet', Icons.wc_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Service List ──
        Expanded(
          child: filteredServices.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                Text(
                  state.locale.languageCode == 'ar'
                      ? 'لا توجد نتائج'
                      : 'No results found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) {
              final service = filteredServices[index];
              return _serviceCard(state, service);
            },
          ),
        ),
      ],
    );
  }

Widget _categoryChip(SmartHajjAppState state, String type, IconData icon) {
  final isSelected = selectedServiceType == type;
  final label = _getTranslatedLabel(state, type);

  return GestureDetector(
    onTap: () {
      _filterServices(type);
      HapticFeedback.selectionClick();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(left: 8), // مسافة بين العناصر
      padding: const EdgeInsets.symmetric(horizontal: 14), // حشوة داخلية بسيطة
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFC9A84C)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row( // استخدمنا Row بدل Column لحل مشكلة الحجم
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF3D2800) : Colors.white,
            size: 18, // صغرنا الأيقونة قليلاً
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF3D2800) : Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _serviceCard(SmartHajjAppState state, ServiceModel service) {
    final categoryColors = {
      'hospital': const Color(0xFFE63946),
      'water': const Color(0xFF4CC9F0),
      'lost_found': const Color(0xFFF77F00),
      'transport': const Color(0xFF40916C),
      'toilet': const Color(0xFF7209B7),
    };

    final categoryIcons = {
      'hospital': Icons.local_hospital_rounded,
      'water': Icons.water_drop_rounded,
      'lost_found': Icons.search_rounded,
      'transport': Icons.electric_car_rounded,
      'toilet': Icons.wc_rounded,
    };

    final color = categoryColors[service.serviceType] ?? Colors.grey;
    final icon = categoryIcons[service.serviceType] ?? Icons.room_service_rounded;

    return GestureDetector(
      onTap: () => _showServiceDetails(state, service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF0D2818).withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.getName(state.locale.languageCode),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A2E1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.getDescription(state.locale.languageCode),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.is24Hour) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF40916C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.locale.languageCode == 'ar' ? '24 ساعة' : '24 Hours',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF40916C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2818).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF3D5A47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDetails(SmartHajjAppState state, ServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.getName(state.locale.languageCode),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E1F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.getDescription(state.locale.languageCode),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (service.location != null && service.location!.isNotEmpty)
                      _infoBox(
                        Icons.location_on_outlined,
                        state.locale.languageCode == 'ar' ? 'الموقع' : 'Location',
                        service.location!,
                        const Color(0xFF0D2818),
                      ),
                    const SizedBox(height: 14),
                    if (service.latitude != null && service.longitude != null)
                      FutureBuilder<String>(
                        future: _calculateDistance(service.latitude!, service.longitude!),
                        builder: (context, snapshot) {
                          return _infoBox(
                            Icons.straighten_rounded,
                            state.locale.languageCode == 'ar'
                                ? 'المسافة التقريبية'
                                : 'Estimated Distance',
                            snapshot.data ?? '...',
                            const Color(0xFFC9A84C),
                          );
                        },
                      ),
                    const SizedBox(height: 28),
                    if (service.latitude != null && service.longitude != null)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapSafetyScreens(
                                  mode: 'map',
                                  targetLocation: ll.LatLng(
                                    service.latitude!,
                                    service.longitude!,
                                  ),
                                  targetName: service.getName(state.locale.languageCode),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined, color: Colors.white),
                          label: Text(
                            state.locale.languageCode == 'ar'
                                ? 'فتح في الخريطة'
                                : 'Open in Map',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2818),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ), 
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  🎨 Custom Painter - Circular Progress
// ═════════════════════════════════════════════════════════════
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  const _CircularProgressPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 16) / 2;
    const strokeW = 12.0;

    final bg = Paint()
      ..color = bgColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = fgColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bg);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.fgColor != fgColor;
}