import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screens.dart';
import 'notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;     
import 'services/prayer_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_safety_screens.dart';
import 'utility_screens.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة الفايربيس
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 1. طلب إذن الإشعارات 
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 2. طلب إذن الموقع 
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  // تهيئة خدمة الإشعارات 
  await NotificationService.init();

  // 3. جدولة إشعارات الصلاة (هنا تأكدي من وجود التعريفات)
  try {
    final prayers = await PrayerService.instance.calculatePrayerTimes();
    
    // تأكدي أن هذه الأسطر موجودة داخل الـ try وقبل الـ loop
    final List<String> names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final List<DateTime> times = [
      prayers.fajr,
      prayers.dhuhr,
      prayers.asr,
      prayers.maghrib,
      prayers.isha,
    ];

    // ا لضمان جدولة الصلوات القادمة دائماy
for (int i = 0; i < 5; i++) {
  DateTime prayerTime = times[i];

  // 1. التحقق: إذا كان وقت الصلاة (ناقص 10 دقائق) قد مضى اليوم
  if (prayerTime.subtract(const Duration(minutes: 10)).isBefore(DateTime.now())) {
    // 2. الميزة المضمونة: جدولة الصلاة لليوم التالي في نفس الوقت
    prayerTime = prayerTime.add(const Duration(days: 1));
  }

  await NotificationService.schedulePrayerReminder(
    i + 1,
    names[i],
    prayerTime,
  );
}
    print('✅ تم جدولة إشعارات الصلاة بنجاح');
  } catch (e) {
    print('❌ خطأ في جدولة الإشعارات: $e');
  }

  runApp(const SmartHajjApp()); 
}
class SmartHajjApp extends StatefulWidget {
  const SmartHajjApp({super.key});

  @override
  State<SmartHajjApp> createState() => SmartHajjAppState();
}

class SmartHajjAppState extends State<SmartHajjApp> {
Locale _locale = const Locale('ar');
Locale get locale => _locale;

final Color primaryGreen = const Color(0xFF1B3022);
final Color goldColor = const Color(0xFFD4AF37);
final Color lightGold = const Color(0xFFF5E6D3);

// حالة المجموعة
String? currentGroupCode;
bool isGroupLeader = false;
List<Map<String, dynamic>> groupMembers = [];
String userName = '';

Future<void> _checkPermissions() async {
  // طلب الموقع العادي
  var status = await Permission.location.request();

  if (status.isGranted) {
    // طلب الموقع "طوال الوقت" (ضروري للأذان و SOS)
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
  }
  
  // طلب إذن المنبهات (لأندرويد 12 فأحدث)
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

void setLocale(Locale newLocale) {
setState(() {
_locale = newLocale;
});
}

void setUserName(String name) {
setState(() {
userName = name;
});
}

void setGroupData(String? code, bool leader, List<Map<String, dynamic>> members) {
  setState(() {
    currentGroupCode = code;
    isGroupLeader = leader;
    groupMembers = members;
  });

 
  if (code != null) {
    _startSOSListener();
  }
}

void leaveGroup() {
setState(() {
currentGroupCode = null;
isGroupLeader = false;
groupMembers.clear();
userName = '';
});
}

TextDirection get textDirection {
return _locale.languageCode == 'ar' || _locale.languageCode == 'ur'
? TextDirection.rtl
: TextDirection.ltr;
}

String getPrayerTime(String prayerKey) {
final prayerTimes = {
'p1': {'ar': '٥:١٠ ص', 'en': '05:10 AM', 'ur': '۰۵:۱۰ صبح', 'id': '05:10 pagi'},
'p2': {'ar': '١٢:٢٢ م', 'en': '12:22 PM', 'ur': '۱۲:۲۲ دوپہر', 'id': '12:22 siang'},
'p3': {'ar': '٣:٤٥ م', 'en': '03:45 PM', 'ur': '۰۳:۴۵ شام', 'id': '03:45 sore'},
'p4': {'ar': '٦:١٥ م', 'en': '06:15 PM', 'ur': '۰۶:۱۵ شام', 'id': '06:15 sore'},
'p5': {'ar': '٧:٤٥ م', 'en': '07:45 PM', 'ur': '۰۷:۴۵ رات', 'id': '07:45 malam'},
};
return prayerTimes[prayerKey]?[_locale.languageCode] ?? '';
}

String translate(String key) {
Map<String, Map<String, String>> dict = {
'ar': {
'app_title': 'تطبيق الحج والعمرة الذكي',
'welcome': 'مرحباً بك في',
'start': 'ابدأ الرحلة',
'ritual': 'دليل المناسك',
'dua': 'الأدعية المأثورة',
'settings': 'الإعدادات',
'map': 'خريطة الحرم',
'group': 'تتبع المجموعة',
'prayer': 'مواقيت الصلاة',
'counter': 'عداد الأشواط',
'qibla': 'بوصلة القبلة', 
'emergency': 'طوارئ SOS',
'emergency_desc': 'اضغط للطوارئ',
'lang': 'اختر اللغة',
'services': 'خدمات الحرم',
'back': 'رجوع',
'next': 'التالي',
'finish': 'إنهاء',
'reset': 'إعادة ضبط',
'wait': 'يرجى الانتظار..',
'hajj': 'الحج',
'umrah': 'العمرة',
'p1': 'الفجر',
'p2': 'الظهر',
'p3': 'العصر',
'p4': 'المغرب',
'p5': 'العشاء',
'd1': 'لبيك اللهم لبيك، لبيك لا شريك لك لبيك…',
'd2': 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة…',
'd3': 'اللهم اجعل حجاً مبروراً وسعياً مشكوراً…',
'd4': 'لا إله إلا الله وحده لا شريك له…',
'd5': 'اللهم اجعلها عمرة مقبولة وذنباً مغفوراً…',
'tamattu': 'حج التمتع',
'qiran': 'حج القران',
'ifrad': 'حج الإفراد',
'umrah_steps': 'خطوات العمرة',
's1': 'الإحرام والنية',
's2': 'طواف القدوم',
's3': 'السعي بين الصفا والمروة',
's4': 'التحلل من الإحرام',
's5': 'التوجه لمنى',
's6': 'طواف الإفاضة',
's7': 'رمي الجمرات',
's8': 'طواف الوداع',
'u1': 'الإحرام من الميقات',
'u2': 'طواف العمرة',
'u3': 'السعي',
'u4': 'الحلق أو التقصير',
'ser1': 'مستشفى أجياد للطوارئ',
'ser2': 'مياه زمزم المبردة',
'ser3': 'مكتب المفقودات',
'ser4': 'العربات الكهربائية',
'create_group': 'إنشاء مجموعة',
'join_group': 'الانضمام لمجموعة',
'scan_qr': 'مسح QR',
'show_qr': 'عرض QR',
'group_code': 'رمز المجموعة',
'group_members': 'أعضاء المجموعة',
'leave_group': 'مغادرة',
'leave_group_confirm': 'هل أنت متأكد من مغادرة المجموعة؟',
'group_created': 'تم إنشاء المجموعة',
'scan_to_join': 'امسح للانضمام',
'enter_code': 'أدخل الرمز',
'invalid_code': 'رمز خاطئ',
'joined_successfully': 'تم الانضمام',
'no_group': 'لا يوجد مجموعة',
'share_code': 'مشاركة',
'members_count': 'الأعضاء',
'enter_name': 'اسمك',
'name_hint': 'اكتب اسمك',
'continue': 'متابعة',
'create_new_group': 'مجموعة جديدة',
'join_existing_group': 'انضم لمجموعة',
'you_are_leader': 'أنت القائد',
'you_are_member': 'أنت العضو',
'copy_code': 'نسخ',
'code_copied': 'تم النسخ',
'group_full': 'المجموعة ممتلئة',
'group_not_found': 'لم نجد المجموعة',
'cancel': 'إلغاء',
'ok': 'حسناً',
'yes': 'نعم',
'no': 'لا',
'save': 'حفظ',
'delete': 'حذف',
'edit': 'تعديل',
'add': 'إضافة',
'remove': 'إزالة',
'update': 'تحديث',
'me': 'أنت',
'leader': 'القائد',
'member': 'عضو',
'sos_msg': 'تم إرسال موقعك',
'sos_hint': 'اضغط للطوارئ',
'locating': 'جاري تحديد الموقع',
'blessing_msg': 'بالتوفيق في رحلتك المباركة',
'view_group': 'عرض المجموعة',
'or': 'أو',


'main_services': 'الخدمات الرئيسية',
'prayer_times':  'مواقيت الصلاة',
'makkah':        'مكة المكرمة',
'counter':       'عداد الأشواط',
'tawaf_umrah':   'طواف العمرة',
'tawaf_qudum':   'طواف القدوم',
'tawaf_ifadah':  'طواف الإفاضة',
'tawaf_wada':    'طواف الوداع',

'prayer_notif': 'تنبيهات الصلاة',
'prayer_desc': 'تذكير قبل الأذان بـ 10 دقائق',
'sos_notif': 'تنبيهات الاستغاثة (SOS)',
'sos_desc': 'استقبال نداءات المساعدة من المجموعة',

'version': 'الإصدار',
'offline_work': 'يعمل بدون إنترنت',
'yes': 'نعم',

},
'en': {
'app_title': 'Smart Hajj & Umrah App',
'welcome': 'Welcome to',
'start': 'Get Started',
'ritual': 'Rituals Guide',
'dua': 'Supplications',
'settings': 'Settings',
'map': 'Haram Map',
'group': 'Group Tracking',
'prayer': 'Prayer Times',
'counter': 'Lap Counter',
'qibla': 'Qibla Finder',
'emergency': 'Emergency SOS',
'emergency_desc': 'Press for Emergency',
'lang': 'Choose Language',
'services': 'Haram Services',
'back': 'Back',
'next': 'Next',
'finish': 'Finish',
'reset': 'Reset',
'wait': 'Please Wait..',
'hajj': 'Hajj',
'umrah': 'Umrah',
'p1': 'Fajr',
'p2': 'Dhuhr',
'p3': 'Asr',
'p4': 'Maghrib',
'p5': 'Isha',
'd1': 'Labbayk Allahumma Labbayk...',
'd2': 'Our Lord, give us in this world...',
'd3': 'O Allah, make this Hajj accepted...',
'd4': 'There is no god but Allah alone...',
'd5': 'O Allah, accept this Umrah...',
'tamattu': 'Hajj Tamattu',
'qiran': 'Hajj Qiran',
'ifrad': 'Hajj Ifrad',
'umrah_steps': 'Umrah Steps',
's1': 'Ihram & Intention',
's2': 'Tawaf Al-Qudum',
's3': 'Sa\'i between Safa & Marwa',
's4': 'Tahalul',
's5': 'Going to Mina',
's6': 'Tawaf Al-Ifadah',
's7': 'Stoning Jamarat',
's8': 'Farewell Tawaf',
'u1': 'Ihram from Miqat',
'u2': 'Tawaf Al-Umrah',
'u3': 'Sa\'i',
'u4': 'Haircut or Trimming',
'ser1': 'Ajyad Emergency Hospital',
'ser2': 'Zamzam Water',
'ser3': 'Lost & Found',
'ser4': 'Electric Carts',
'create_group': 'Create Group',
'join_group': 'Join Group',
'scan_qr': 'Scan QR',
'show_qr': 'Show QR',
'group_code': 'Group Code',
'group_members': 'Group Members',
'leave_group': 'Leave',
'leave_group_confirm': 'Are you sure you want to leave the group?',
'group_created': 'Group Created',
'scan_to_join': 'Scan to Join',
'enter_code': 'Enter Code',
'invalid_code': 'Wrong Code',
'joined_successfully': 'Joined Successfully',
'no_group': 'No Group',
'share_code': 'Share',
'members_count': 'Members',
'enter_name': 'Your Name',
'name_hint': 'Write your name',
'continue': 'Continue',
'create_new_group': 'New Group',
'join_existing_group': 'Join Group',
'you_are_leader': 'You are Leader',
'you_are_member': 'You are Member',
'copy_code': 'Copy',
'code_copied': 'Copied',
'group_full': 'Group Full',
'group_not_found': 'Group Not Found',
'cancel': 'Cancel',
'ok': 'OK',
'yes': 'Yes',
'no': 'No',
'save': 'Save',
'delete': 'Delete',
'edit': 'Edit',
'add': 'Add',
'remove': 'Remove',
'update': 'Update',
'me': 'You',
'leader': 'Leader',
'member': 'Member',
'sos_msg': 'Location Sent',
'sos_hint': 'Press for Emergency',
'locating': 'Locating...',
'blessing_msg': 'May your blessed journey be successful',
'view_group': 'View Group',
'or': 'or',

  'main_services': 'Main Services',
  'prayer_times':  'Prayer Times',
  'makkah':        'Makkah Al-Mukarramah',
  'counter':       'Lap Counter',
  'tawaf_umrah':   'Umrah Tawaf',
  'tawaf_qudum':   'Tawaf Al-Qudum',
  'tawaf_ifadah':  'Tawaf Al-Ifadah',
  'tawaf_wada':    'Farewell Tawaf',

  'prayer_notif': 'Prayer Reminders',
'prayer_desc': '10 minutes before Adhan',
'sos_notif': 'SOS Notifications',
'sos_desc': 'Receive help requests from group',

'version': 'Version',
'offline_work': 'Works Offline',
'yes': 'Yes',

},
'ur': {
'app_title': 'اسمارٹ حج اور عمرہ ایپ',
'welcome': 'خوش آمدید',
'start': 'شروع کریں',
'ritual': 'مناسک گائیڈ',
'dua': 'دعائیں',
'settings': 'ترتیبات',
'map': 'حرم کا نقشہ',
'group': 'گروپ ٹریکنگ',
'prayer': 'نماز کے اوقات',
'counter': 'طواف کاؤنٹر',
'qibla': 'قبلہ کی سمت',
'emergency': 'ایمرجنسی SOS',
'emergency_desc': 'ایمرجنسی کے لیے دبائیں',
'lang': 'زبان منتخب کریں',
'services': 'حرم کی خدمات',
'back': 'واپس',
'next': 'اگلا',
'finish': 'ختم',
'reset': 'دوبارہ ترتیب',
'wait': 'براہ کرم انتظار کریں..',
'hajj': 'حج',
'umrah': 'عمرہ',
'p1': 'فجر',
'p2': 'ظہر',
'p3': 'عصر',
'p4': 'مغرب',
'p5': 'عشاء',
'd1': 'لبیک اللہم لبیک...',
'd2': 'اے ہمارے رب! ہمیں دنیا میں بھلائی دے...',
'd3': 'اے اللہ! اسے مقبول حج بنا...',
'd4': 'اللہ کے سوا کوئی معبود نہیں...',
'd5': 'اے اللہ! اسے مقبول عمرہ بنا...',
'tamattu': 'حج تمتع',
'qiran': 'حج قران',
'ifrad': 'حج افراد',
'umrah_steps': 'عمرہ کے مراحل',
's1': 'احرام اور نیت',
's2': 'طواف قدوم',
's3': 'صفا و مروہ کی سعی',
's4': 'احرام سے حلال ہونا',
's5': 'منیٰ جانا',
's6': 'طواف افاضہ',
's7': 'جمرات کو کنکریاں مارنا',
's8': 'طواف وداع',
'u1': 'میقات سے احرام',
'u2': 'عمرہ کا طواف',
'u3': 'سعی',
'u4': 'سر منڈوانا یا بال کٹوانا',
'ser1': 'اجیاد ایمرجنسی ہسپتال',
'ser2': 'زم زم کا پانی',
'ser3': 'کھوئی ہوئی اشیاء',
'ser4': 'برقی گاڑیاں',
'create_group': 'گروپ بنائیں',
'join_group': 'گروپ میں شامل ہوں',
'scan_qr': 'QR اسکین کریں',
'show_qr': 'QR دکھائیں',
'group_code': 'گروپ کوڈ',
'group_members': 'گروپ ممبران',
'leave_group': 'چھوڑیں',
'leave_group_confirm': 'کیا آپ واقعی گروپ چھوڑنا چاہتے ہیں؟',
'group_created': 'گروپ بن گیا',
'scan_to_join': 'اسکین کریں',
'enter_code': 'کوڈ درج کریں',
'invalid_code': 'غلط کوڈ',
'joined_successfully': 'شامل ہو گئے',
'no_group': 'کوئی گروپ نہیں',
'share_code': 'شیئر کریں',
'members_count': 'ممبران',
'enter_name': 'آپ کا نام',
'name_hint': 'نام لکھیں',
'continue': 'جاری رکھیں',
'create_new_group': 'نیا گروپ',
'join_existing_group': 'گروپ میں شامل ہوں',
'you_are_leader': 'آپ لیڈر ہیں',
'you_are_member': 'آپ ممبر ہیں',
'copy_code': 'کاپی',
'code_copied': 'کاپی ہو گیا',
'group_full': 'گروپ مکمل ہے',
'group_not_found': 'گروپ نہیں ملا',
'cancel': 'منسوخ کریں',
'ok': 'ٹھیک ہے',
'yes': 'جی ہاں',
'no': 'نہیں',
'save': 'محفوظ کریں',
'delete': 'حذف کریں',
'edit': 'ترمیم کریں',
'add': 'شامل کریں',
'remove': 'ہٹائیں',
'update': 'اپ ڈیٹ کریں',
'me': 'آپ',
'leader': 'لیڈر',
'member': 'ممبر',
'sos_msg': 'مقام بھیج دیا',
'sos_hint': 'ایمرجنسی کے لیے دبائیں',
'locating': 'مقام معلوم ہو رہا ہے',
'blessing_msg': 'آپ کے مبارک سفر میں کامیابی ہو',
'view_group': 'گروپ دیکھیں',
'or': 'یا',


'main_services': 'اہم خدمات',
'prayer_times':  'نماز کے اوقات',
'makkah':        'مکہ مکرمہ',
'counter':       'طواف کاؤنٹر',
'tawaf_umrah':   'عمرہ طواف',
'tawaf_qudum':   'طواف قدوم',
'tawaf_ifadah':  'طواف افاضہ',
'tawaf_wada':    'طواف وداع',

'prayer_notif': 'نماز کی یاد دہانی',
  'prayer_desc': 'اذان سے 10 منٹ پہلے',
  'sos_notif': 'ہنگامی الرٹس (SOS)',
  'sos_desc': 'گروپ سے مدد کی درخواستیں موصول کریں',
  'notif_enabled': 'الرٹس فعال کر دیے گئے',
  'notif_disabled': 'الرٹس غیر فعال کر دیے گئے',
'version': 'ورژن',
'offline_work': 'آف لائن کام کرتا ہے',
'yes': 'جی ہاں',

},
'id': {
'app_title': 'Aplikasi Haji & Umrah Pintar',
'welcome': 'Selamat Datang di',
'start': 'Mulai',
'ritual': 'Panduan Manasik',
'dua': 'Doa-doa',
'settings': 'Pengaturan',
'map': 'Peta Masjidil Haram',
'group': 'Lacak Grup',
'prayer': 'Waktu Shalat',
'counter': 'Penghitung Tawaf',
'qibla': 'Arah Kiblat',
'emergency': 'Darurat SOS',
'emergency_desc': 'Tekan untuk Darurat',
'lang': 'Pilih Bahasa',
'services': 'Layanan Haramain',
'back': 'Kembali',
'next': 'Lanjut',
'finish': 'Selesai',
'reset': 'Atur Ulang',
'wait': 'Mohon tunggu..',
'hajj': 'Haji',
'umrah': 'Umrah',
'p1': 'Subuh',
'p2': 'Dzuhur',
'p3': 'Ashar',
'p4': 'Maghrib',
'p5': 'Isya',
'd1': 'Labbaik Allahumma Labbaik...',
'd2': 'Ya Tuhan kami, berilah kami kebaikan...',
'd3': 'Ya Allah, jadikan haji ini mabrur...',
'd4': 'Tiada Tuhan selain Allah...',
'd5': 'Ya Allah, terimalah umrah ini...',
'tamattu': 'Haji Tamattu',
'qiran': 'Haji Qiran',
'ifrad': 'Haji Ifrad',
'umrah_steps': 'Langkah Umrah',
's1': 'Ihram & Niat',
's2': 'Tawaf Qudum',
's3': 'Sa\'i antara Safa & Marwa',
's4': 'Tahallul',
's5': 'Menuju Mina',
's6': 'Tawaf Ifadah',
's7': 'Lempar Jumrah',
's8': 'Tawaf Wada',
'u1': 'Ihram dari Miqat',
'u2': 'Tawaf Umrah',
'u3': 'Sa\'i',
'u4': 'Cukur atau Potong Rambut',
'ser1': 'Rumah Sakit Ajyad',
'ser2': 'Air Zamzam',
'ser3': 'Barang Hilang',
'ser4': 'Kereta Listrik',
'create_group': 'Buat Grup',
'join_group': 'Gabung Grup',
'scan_qr': 'Scan QR',
'show_qr': 'Tampilkan QR',
'group_code': 'Kode Grup',
'group_members': 'Anggota Grup',
'leave_group': 'Keluar',
'leave_group_confirm': 'Apakah Anda yakin ingin keluar dari grup?',
'group_created': 'Grup Dibuat',
'scan_to_join': 'Scan untuk Bergabung',
'enter_code': 'Masukkan Kode',
'invalid_code': 'Kode Salah',
'joined_successfully': 'Berhasil Bergabung',
'no_group': 'Tidak Ada Grup',
'share_code': 'Bagikan',
'members_count': 'Anggota',
'enter_name': 'Nama Anda',
'name_hint': 'Tulis nama Anda',
'continue': 'Lanjutkan',
'create_new_group': 'Grup Baru',
'join_existing_group': 'Gabung Grup',
'you_are_leader': 'Anda Pemimpin',
'you_are_member': 'Anda Anggota',
'copy_code': 'Salin',
'code_copied': 'Tersalin',
'group_full': 'Grup Penuh',
'group_not_found': 'Grup Tidak Ditemukan',
'cancel': 'Batal',
'ok': 'Oke',
'yes': 'Ya',
'no': 'Tidak',
'save': 'Simpan',
'delete': 'Hapus',
'edit': 'Edit',
'add': 'Tambah',
'remove': 'Hapus',
'update': 'Perbarui',
'me': 'Anda',
'leader': 'Pemimpin',
'member': 'Anggota',
'sos_msg': 'Lokasi Dikirim',
'sos_hint': 'Tekan untuk Darurat',
'locating': 'Mencari lokasi',
'blessing_msg': 'Semoga perjalanan ibadah Anda diberkahi',
'view_group': 'Lihat Grup',
'or': 'atau',

  'main_services': 'Layanan Utama',
  'prayer_times':  'Waktu Shalat',
  'makkah':        'Makkah Al-Mukarramah',
  'counter':       'Penghitung Tawaf',
  'tawaf_umrah':   'Tawaf Umrah',
  'tawaf_qudum':   'Tawaf Qudum',
  'tawaf_ifadah':  'Tawaf Ifadah',
  'tawaf_wada':    'Tawaf Wada',

   'prayer_notif': 'Pengingat Shalat',
  'prayer_desc': '10 menit sebelum Adzan',
  'sos_notif': 'Notifikasi SOS',
  'sos_desc': 'Terima permintaan bantuan dari grup',
  'notif_enabled': 'Peringatan diaktifkan',
  'notif_disabled': 'Peringatan dinonaktifkan',
  
  'version': 'Versi',
'offline_work': 'Bekerja Offline',
'yes': 'Ya',
}
};

return dict[_locale.languageCode]?[key] ?? key;
}
 @override
void initState() {
  super.initState();
  
  // نطلب الصلاحيات أولاً
  _checkPermissions().then((_) {
    // بمجرد الانتهاء من طلب الصلاحيات، نبدأ الاستماع لـ SOS
    _startSOSListener();
  });
}

 void _startSOSListener() async {
  // 1. محاولة أخذ الكود من حقل الكلاس الحالي أولاً، وإذا كان فارغاً نجلب المخزن
  String? groupCode = currentGroupCode;
  
  if (groupCode == null) {
    final prefs = await SharedPreferences.getInstance();
    groupCode = prefs.getString('current_group_code');
  }
  
  final myID = FirebaseAuth.instance.currentUser?.uid; 
  
  // إذا لا يوجد كود مجموعة حتى الآن، نتوقف
  if (groupCode == null) return;

  // تسجيل وقت بدء الإنصات
  DateTime startTime = DateTime.now();

  FirebaseFirestore.instance
      .collection('groups')
      .doc(groupCode) // يستمع للمجموعة النشطة الآن
      .collection('sos_alerts')
      .where('isResolved', isEqualTo: false)
      .snapshots()
      .listen((snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data()!;
        
        Timestamp? timestamp = data['timestamp'] as Timestamp?;
        
        if (timestamp != null) {
          DateTime alertTime = timestamp.toDate();
          
          if (alertTime.isAfter(startTime)) {
            final String senderID = data['memberID'] ?? '';
            final String senderName = data['member_name'] ?? 'عضو';

            if (myID != null && senderID != myID) {
              NotificationService.triggerSOSAlert(
                senderName: senderName, 
                langCode: _locale.languageCode
              );
            }
          }
        }
      }
    }
  });
}
@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
locale: _locale,
localizationsDelegates: const [
GlobalMaterialLocalizations.delegate,
GlobalWidgetsLocalizations.delegate,
GlobalCupertinoLocalizations.delegate,
],
supportedLocales: const [
Locale('ar'),
Locale('en'),
Locale('ur'),
Locale('id'),
],
theme: ThemeData(
fontFamily: _locale.languageCode == 'ar' || _locale.languageCode == 'ur'
? 'Cairo'
: 'Poppins',
appBarTheme: AppBarTheme(
backgroundColor: primaryGreen,
foregroundColor: Colors.white,
centerTitle: true,
elevation: 0,
),
scaffoldBackgroundColor: const Color(0xFFF5F5F5),
),
home: const LanguageSelectionScreen(),
);
}
} 