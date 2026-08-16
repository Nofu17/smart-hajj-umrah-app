import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'data/database/database_helper.dart';
import 'data/models/group_model.dart';
import 'data/models/group_member_model.dart';
import 'main.dart';
import 'map_data.dart';
import 'services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

// ═════════════════════════════════════════════════════════════
//  Map & Safety Screens - الخريطة والمجموعات
// ═════════════════════════════════════════════════════════════
class MapSafetyScreens extends StatefulWidget {
  final String mode;
  final ll.LatLng? targetLocation;
  final String? targetName;

  const MapSafetyScreens({
    super.key,
    required this.mode,
    this.targetLocation,
    this.targetName,
  });

  @override
  State<MapSafetyScreens> createState() => _MapSafetyScreensState();
}

class _MapSafetyScreensState extends State<MapSafetyScreens>
    with SingleTickerProviderStateMixin {
  int _selectedFloor = 0;
  String? _selectedCategory;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadGroupDataIfExists();}



  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showServiceOnMap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              widget.targetName ?? 'Service Location',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2818),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _loadGroupDataIfExists() async {
  if (!mounted) return;
  
  final state = context.findAncestorStateOfType<SmartHajjAppState>();
  if (state == null) return; // تأمين للبرنامج

  if (state.currentGroupCode == null) {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('current_group_code');
    final savedName = prefs.getString('member_name');
    final isLeader = prefs.getBool('is_leader') ?? false;

    if (savedCode != null && savedName != null) {
      state.setGroupData(savedCode, isLeader, []);
      state.setUserName(savedName);
    } else {
      return;
    }
  }

  FirebaseFirestore.instance
      .collection('groups')
      .doc(state.currentGroupCode)
      .collection('members')
      .snapshots()
      .listen((snapshot) {
    if (!mounted) return;

    final membersList = snapshot.docs.map((doc) {
      final data = doc.data();
      final isMe = doc.id == FirebaseAuth.instance.currentUser?.uid;
      final isLeaderMember = data['role'] == 'leader';

      return {
        "id": isMe ? "me" : doc.id,
        "name": data['name'] ?? doc.id,
        "dist": isMe ? state.translate('me') : '...',
        "color": isLeaderMember ? Colors.blue : Colors.green,
        "lat": data['latitude'] ?? 0.0,
        "lng": data['longitude'] ?? 0.0,
        "role": data['role'] ?? 'member',
      };
    }).toList();

    state.setGroupData(
      state.currentGroupCode!,
      state.isGroupLeader,
      membersList,
    );

    if (mounted) setState(() {});
  });
}

  String _generateGroupCode() {
    final random = math.Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // ═════════════════════════════════════════════════════════════
  //  GROUP MANAGEMENT METHODS
  // ═════════════════════════════════════════════════════════════
  void _createGroup(SmartHajjAppState state) {
    _showEnterNameDialog(state, true);
  }

  void _joinGroup(SmartHajjAppState state) {
    _showEnterCodeDialog(state);
  }

  void _scanQRCode(SmartHajjAppState state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onCodeScanned: (String code) {
            Navigator.pop(context);

            String digits = code.replaceAll(RegExp(r'[^0-9]'), '');
            print("النص الممسوح: $code");
            print("الأرقام المستخرجة: $digits");

            if (digits.length == 6) {
              _showEnterNameDialog(state, false, digits);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.translate('invalid_code')),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _processCreateGroup(SmartHajjAppState state, String userName) async {
    final newGroupCode = _generateGroupCode();
    // جلب معرف المستخدم الحالي من Firebase لحل مشكلة الـ NOT NULL constraint
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "user_${DateTime.now().millisecondsSinceEpoch}";

    try {
      await FirebaseService.instance.createFirebaseGroup(newGroupCode, userName);

      final group = GroupModel(
        groupCode: newGroupCode,
        groupName: 'Group $newGroupCode',
        leaderName: userName,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.createGroup(group);

      // التعديل هنا: أضفنا الـ memberId
      final member = GroupMemberModel(
        memberId: userId, 
        groupCode: newGroupCode,
        memberName: userName,
        latitude: 0.0,
        longitude: 0.0,
        role: 'leader',
        joinedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.addGroupMember(member);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_group_code', newGroupCode);
      await prefs.setString('member_name', userName);
      // التعديل هنا: القيمة يجب أن تكون true لأن هذا هو المنشئ (Leader)
      await prefs.setBool('is_leader', true); 

      final members = [
        {
          "id": userId, // استخدام المعرف الحقيقي بدلاً من "me" لتوحيد البيانات
          "name": userName,
          "dist": state.translate('me'),
          "color": Colors.blue,
          "lat": 0.0,
          "lng": 0.0,
          "role": "leader",
        }
      ];

      state.setGroupData(newGroupCode, true, members);
      state.setUserName(userName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.locale.languageCode == 'ar'
                  ? 'تم إنشاء المجموعة بنجاح'
                  : 'Group created successfully',
            ),
            backgroundColor: const Color(0xFF40916C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _showQRCodeDialog(state, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.locale.languageCode == 'ar'
                  ? 'حدث خطأ أثناء إنشاء المجموعة'
                  : 'An error occurred while creating the group',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      print("❌ Error creating group: $e");
    }
  }
  void _processJoinGroup(SmartHajjAppState state, String code, String userName) async {
    String cleanCode = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.translate('invalid_code')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // جلب معرف المستخدم الحالي من Firebase
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "user_${DateTime.now().millisecondsSinceEpoch}";

    final ok = await FirebaseService.instance.joinFirebaseGroup(cleanCode, userName);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.translate('invalid_code')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // إضافة العضو لقاعدة البيانات المحلية لتجنب تعارض البيانات
    try {
      final member = GroupMemberModel(
        memberId: userId, // استخدام المعرف الحقيقي
        groupCode: cleanCode,
        memberName: userName,
        latitude: 0.0,
        longitude: 0.0,
        role: 'member',
        joinedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.addGroupMember(member);
    } catch (e) {
      print("Error saving member locally: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_group_code', cleanCode);
    await prefs.setString('member_name', userName);
    await prefs.setBool('is_leader', false); // هنا false صحيحة لأنه عضو منضم

    final members = [
      {
        "id": userId, // استبدال "me" بالمعرف الحقيقي
        "name": userName,
        "dist": state.translate('me'),
        "color": Colors.blue,
        "lat": 0.0,
        "lng": 0.0,
        "role": "member",
      }
    ];

    state.setGroupData(cleanCode, false, members);
    state.setUserName(userName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.translate('joined_successfully')),
        backgroundColor: const Color(0xFF40916C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    setState(() {});
  }
  void _leaveGroup(SmartHajjAppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.translate('leave_group'),
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          state.translate('leave_group_confirm'),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              state.translate('cancel'),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // داخل ElevatedButton الخاص بالمغادرة (onPressed):
    // مسح الذاكرة الدائمة
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_group_code');
    await prefs.remove('member_name');
    await prefs.remove('is_leader');

    // مسح الـ state والخروج
    state.leaveGroup();
    Navigator.pop(context);
    if (mounted) setState(() {});
  } catch (e) {
    print("❌ Error leaving: $e");
  

                if (state.currentGroupCode != null && state.userName.isNotEmpty) {
                  await DatabaseHelper.instance.removeMemberFromGroup(
                    state.currentGroupCode!,
                    state.userName,
                  );

                  if (state.isGroupLeader) {
                    await DatabaseHelper.instance.deactivateGroup(
                      state.currentGroupCode!,
                    );
                  }
                }

                state.leaveGroup();
                Navigator.pop(context);

                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                print("❌ Error leaving: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              state.translate('leave_group'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  DIALOG WIDGETS - محسّنة
  // ═════════════════════════════════════════════════════════════
  void _showEnterNameDialog(SmartHajjAppState state, bool isCreating, [String? code]) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0D2818).withOpacity(0.15),
                      const Color(0xFF0D2818).withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 36,
                  color: Color(0xFF0D2818),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.translate('enter_name'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E1F),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: state.translate('name_hint'),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF0D2818).withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0D2818), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        state.translate('cancel'),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          if (isCreating) {
                            _processCreateGroup(state, nameController.text.trim());
                          } else if (code != null) {
                            _processJoinGroup(state, code, nameController.text.trim());
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0D2818),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        state.translate('continue'),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnterCodeDialog(SmartHajjAppState state) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0D2818).withOpacity(0.15),
                      const Color(0xFF0D2818).withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 40,
                  color: Color(0xFF0D2818),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.translate('join_group'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E1F),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: Color(0xFF0D2818),
                ),
                decoration: InputDecoration(
                  hintText: state.translate('enter_code'),
                  hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 20, letterSpacing: 5),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF0D2818).withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0D2818), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _scanQRCode(state);
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0D2818)),
                  label: Text(
                    state.translate('scan_qr'),
                    style: const TextStyle(color: Color(0xFF0D2818), fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: Color(0xFF0D2818)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        state.translate('cancel'),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (codeController.text.length == 6) {
                          Navigator.pop(context);
                          _showEnterNameDialog(state, false, codeController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0D2818),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        state.translate('continue'),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCodeDialog(SmartHajjAppState state, [bool autoNavigate = false]) {
    showDialog(
      context: context,
      barrierDismissible: !autoNavigate,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF40916C).withOpacity(0.2),
                        const Color(0xFF40916C).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 36,
                    color: Color(0xFF40916C),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.translate('group_created'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF40916C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.translate('group_code'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: state.currentGroupCode!,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        state.currentGroupCode!,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: Color(0xFF0D2818),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.currentGroupCode!));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(state.translate('code_copied')),
                              backgroundColor: const Color(0xFF40916C),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0D2818)),
                        label: Text(
                          state.locale.languageCode == 'ar' ? 'نسخ' : 'Copy',
                          style: const TextStyle(color: Color(0xFF0D2818), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  state.translate('scan_to_join'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (autoNavigate) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0D2818),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      autoNavigate ? state.translate('view_group') : state.translate('ok'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((value) {
      if (autoNavigate) {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {});
        });
      }
    });
  }

  void _showPOIDetails(SmartHajjAppState state, MapPOI poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: poi.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(poi.icon, size: 36, color: poi.color),
            ),
            const SizedBox(height: 18),
            Text(
              state.locale.languageCode == 'ar' ? poi.nameAr : poi.nameEn,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E1F),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2818).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.locale.languageCode == 'ar' ? 'الطابق' : 'Floor'}: ${poi.floor == -1 ? (state.locale.languageCode == 'ar' ? 'القبو' : 'Basement') : poi.floor == 0 ? (state.locale.languageCode == 'ar' ? 'الأرضي' : 'Ground') : poi.floor}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.directions_rounded, color: Colors.white),
                label: Text(
                  state.locale.languageCode == 'ar' ? 'اتجاهات' : 'Directions',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0D2818),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        appBar: AppBar(
          title: Text(
            state.translate(widget.mode),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A2E1F),
          elevation: 0,
          surfaceTintColor: Colors.white,
          actions: widget.mode == "group" && state.currentGroupCode != null
              ? [
                  
                  const SizedBox(width: 5), // مسافة بسيطة من الحافة
                  
                  // أيقونة الباركود (تفتح النافذة اللي فيها الـ QR والرقم عند الضغط)
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFF0D2818),
                    ),
                    onPressed: () => _showQRCodeDialog(state),
                    tooltip: state.translate('show_qr'),
                  ),
                  
                  // أيقونة الخروج
                  IconButton(
                    icon: Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.red.shade600,
                    ),
                    onPressed: () => _leaveGroup(state),
                    tooltip: state.translate('leave_group'),
                  ),
                ]
              : null,),
        body: widget.mode == "group" && state.currentGroupCode == null
            ? _buildGroupSetupScreen(state)
            : _buildMapScreen(state),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  GROUP SETUP SCREEN - محسّن
  // ═════════════════════════════════════════════════════════════
  Widget _buildGroupSetupScreen(SmartHajjAppState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF2F5F3)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0D2818).withOpacity(0.15 + 0.05 * _pulseCtrl.value),
                        const Color(0xFF0D2818).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 55,
                    color: Color(0xFF0D2818),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                state.translate('group_members'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2818),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.locale.languageCode == 'ar'
                    ? 'ابقَ متصلاً مع عائلتك وأصدقائك'
                    : 'Stay connected with your family and friends',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createGroup(state),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  label: Text(
                    state.translate('create_new_group'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF0D2818),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      state.translate('or'),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _joinGroup(state),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24, color: Color(0xFF0D2818)),
                  label: Text(
                    state.translate('join_existing_group'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2818),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Color(0xFF0D2818), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  MAP SCREEN - محسّن
  // ═════════════════════════════════════════════════════════════
  Widget _buildMapScreen(SmartHajjAppState state) {
    return StatefulBuilder(
      builder: (context, setStateFloor) {
        final poisToShow = _selectedCategory == null
            ? HaramMapData.getPOIsByFloor(_selectedFloor)
            : HaramMapData.getPOIsByCategory(_selectedCategory!)
            .where((poi) => poi.floor == _selectedFloor)
            .toList();

        return Column(
          children: [
            // ── شريط التحكم ──
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // اختيار الطابق
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D2818).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.layers_rounded, color: Color(0xFF0D2818), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.locale.languageCode == 'ar' ? 'الطابق' : 'Floor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2818),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [-1, 0, 1, 2, 3, 4, 5].map((floor) {
                              final isSelected = floor == _selectedFloor;
                              return GestureDetector(
                                onTap: () => setStateFloor(() => _selectedFloor = floor),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    floor == -1
                                        ? (state.locale.languageCode == 'ar' ? 'قبو' : 'B')
                                        : floor == 0
                                        ? (state.locale.languageCode == 'ar' ? 'أرضي' : 'G')
                                        : '$floor',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // فلتر الفئات
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(state, null, Icons.all_inclusive_rounded,
                            state.locale.languageCode == 'ar' ? 'الكل' : 'All', setStateFloor),
                        _buildCategoryChip(state, 'gate', Icons.door_front_door_rounded,
                            state.locale.languageCode == 'ar' ? 'أبواب' : 'Gates', setStateFloor),
                        _buildCategoryChip(state, 'zamzam', Icons.water_drop_rounded,
                            state.locale.languageCode == 'ar' ? 'زمزم' : 'Zamzam', setStateFloor),
                        _buildCategoryChip(state, 'toilet', Icons.wc_rounded,
                            state.locale.languageCode == 'ar' ? 'دورات مياه' : 'Restrooms', setStateFloor),
                        _buildCategoryChip(state, 'medical', Icons.local_hospital_rounded,
                            state.locale.languageCode == 'ar' ? 'طبي' : 'Medical', setStateFloor),
                        _buildCategoryChip(state, 'elevator', Icons.elevator_rounded,
                            state.locale.languageCode == 'ar' ? 'مصاعد' : 'Elevators', setStateFloor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── الخريطة ──
            Expanded(
              flex: 6,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: HaramMapData.kaaba,
                      initialZoom: 17.0,
                      minZoom: 15.0,
                      maxZoom: 19.0,
                    ),
                    children: [
                      TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.smart_hajj_umrah_app',
),
                      MarkerLayer(
                        markers: [
                          // الكعبة
                          Marker( 
                            point: HaramMapData.kaaba,
                            width: 100,
                            height: 100,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                  ),
                                  child: Text(
                                    state.locale.languageCode == 'ar' ? 'الكعبة المشرفة' : 'Holy Kaaba',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D2818),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.place_rounded, color: Color(0xFFD4AF37), size: 40),
                              ],
                            ),
                          ),

                          // POIs
                          ...poisToShow.map((poi) {
                            return Marker(
                              point: poi.location,
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () => _showPOIDetails(state, poi),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                      ),
                                      child: Text(
                                        state.locale.languageCode == 'ar' ? poi.nameAr : poi.nameEn,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: poi.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(poi.icon, color: poi.color, size: 24),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // الخدمة المستهدفة
                          if (widget.targetLocation != null)
                            Marker(
                              point: widget.targetLocation!,
                              width: 100,
                              height: 100,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 30),
                                  ),
                                  Text(
                                    widget.targetName ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // أعضاء المجموعة
                          if (widget.mode == "group" && state.currentGroupCode != null)
                            ...state.groupMembers.map((member) {
                              return Marker(
                                point: ll.LatLng(member['lat'], member['lng']),
                                width: 70,
                                height: 70,
                                child: _buildMapMarker(
                                  member['name'],
                                  member['color'],
                                  member['dist'],
                                ),
                              );
                            }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── قائمة الأعضاء ──
            if (widget.mode == "group" && state.currentGroupCode != null)
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            state.translate('group_members'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2818),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2818).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group_rounded, size: 16, color: Color(0xFF0D2818)),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.groupMembers.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D2818),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: state.groupMembers.length,
                          separatorBuilder: (context, index) => Divider(height: 16, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final member = state.groupMembers[index];
                            final isMe = member['id'] == 'me';
                            final isLeader = member['role'] == 'leader';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: member['color'].withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isMe ? member['color'] : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: member['color'],
                                    size: 24,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    member['name'],
                                    style: TextStyle(
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 15,
                                      color: isMe ? const Color(0xFF0D2818) : Colors.grey.shade800,
                                    ),
                                  ),
                                  if (isLeader) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC9A84C).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        state.translate('leader'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8B6914),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                member['dist'],
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              trailing: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    isMe ? Icons.my_location_rounded : Icons.call_rounded,
                                    color: isMe ? Colors.blue : Colors.green,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapMarker(String name, Color c, String distance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            name,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c),
          ),
        ),
        Icon(Icons.location_on_rounded, color: c, size: 30),
      ],
    );
  }

  Widget _buildCategoryChip(
      SmartHajjAppState state,
      String? category,
      IconData icon,
      String label,
      StateSetter setStateFloor,
      ) {
    final isSelected = category == _selectedCategory;
    return GestureDetector(
      onTap: () => setStateFloor(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D2818) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  QR SCANNER SCREEN - شاشة مسح QR محسّنة
// ═════════════════════════════════════════════════════════════
class QRScannerScreen extends StatefulWidget {
  final Function(String) onCodeScanned;

  const QRScannerScreen({super.key, required this.onCodeScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح الباركود',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              widget.onCodeScanned(barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}