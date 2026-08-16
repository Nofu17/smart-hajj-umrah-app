import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ritual_model.dart';
import '../models/ritual_step_model.dart';
import '../models/dua_model.dart';
import '../models/lap_session_model.dart';
import '../models/service_model.dart';
import '../models/group_model.dart'; 
import '../models/group_member_model.dart'; 
import '../models/sos_model.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hajj_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

 return await openDatabase(
  path,
  version: 16, 
  onCreate: _createDB,
onUpgrade: (db, oldVersion, newVersion) async {
  var batch = db.batch();
  
  // حذف كل الجداول القديمة لضمان تحديث نظيف
  batch.execute("DROP TABLE IF EXISTS rituals");
  batch.execute("DROP TABLE IF EXISTS services");
  batch.execute("DROP TABLE IF EXISTS ritual_steps");
  batch.execute("DROP TABLE IF EXISTS duas");
  batch.execute("DROP TABLE IF EXISTS lap_sessions");
  batch.execute("DROP TABLE IF EXISTS groups");
  batch.execute("DROP TABLE IF EXISTS group_members");
  batch.execute("DROP TABLE IF EXISTS sos_reports");
  
  await batch.commit();
  
  // إعادة إنشاء الجداول بالإصدار الجديد
  await _createDB(db, newVersion);
},);
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول الطقوس (Rituals)
    await db.execute('''
      CREATE TABLE rituals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ritual_type TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_ur TEXT NOT NULL,
        name_id TEXT NOT NULL,
        total_steps INTEGER NOT NULL
      )
    ''');
    // Table: Services
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_type TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_ur TEXT NOT NULL,
        name_id TEXT NOT NULL,
        description_ar TEXT NOT NULL,
        description_en TEXT NOT NULL,
        description_ur TEXT NOT NULL,
        description_id TEXT NOT NULL,
        phone_number TEXT,
        latitude REAL,
        longitude REAL,
        location TEXT,
        is_24_hour INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // جدول خطوات الطقوس
    await db.execute('''
      CREATE TABLE ritual_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ritual_id INTEGER NOT NULL,
        step_number INTEGER NOT NULL,
        title_ar TEXT NOT NULL,
        title_en TEXT NOT NULL,
        title_ur TEXT NOT NULL,
        title_id TEXT NOT NULL,
        description_ar TEXT NOT NULL,
        description_en TEXT NOT NULL,
        description_ur TEXT NOT NULL,
        description_id TEXT NOT NULL,
        image_path TEXT,
        FOREIGN KEY (ritual_id) REFERENCES rituals (id)
      )
    ''');

    // جدول الأدعية
    await db.execute('''
      CREATE TABLE duas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        arabic_text TEXT NOT NULL,
        transliteration TEXT NOT NULL,
        translation_ar TEXT NOT NULL,
        translation_en TEXT NOT NULL,
        translation_ur TEXT NOT NULL,
        translation_id TEXT NOT NULL,
        source TEXT
      )
    ''');

    // جدول سجلات العد
    await db.execute('''
      CREATE TABLE lap_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ritual_type TEXT NOT NULL,
        current_lap INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        is_complete INTEGER NOT NULL DEFAULT 0
      )
    ''');

// جدول المجموعات
await db.execute('''
  CREATE TABLE groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_code TEXT NOT NULL UNIQUE,
    group_name TEXT NOT NULL,
    leader_name TEXT NOT NULL,
    created_at TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1
  )
''');

// جدول أعضاء المجموعات
await db.execute('''
  CREATE TABLE group_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    member_id TEXT NOT NULL, 
    group_code TEXT NOT NULL,
    member_name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    role TEXT NOT NULL,
    joined_at TEXT NOT NULL,
    last_location_update TEXT,
    FOREIGN KEY (group_code) REFERENCES groups (group_code)
  )
''');
// جدول بلاغات الاستغاثة SOS
await db.execute('''
  CREATE TABLE sos_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_code TEXT NOT NULL,
    member_id TEXT NOT NULL,
    member_name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp TEXT NOT NULL,
    is_resolved INTEGER NOT NULL DEFAULT 0
  )
''');
    // إدراج البيانات الأولية
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async
  { // إدخال الخدمات
    final services = [
      {
        'service_type': 'hospital',
        'name_ar': 'مستشفى أجياد للطوارئ',
        'name_en': 'Ajyad Emergency Hospital',
        'name_ur': 'اجیاد ایمرجنسی ہسپتال',
        'name_id': 'Rumah Sakit Darurat Ajyad',
        'description_ar': 'خدمات طبية طارئة على مدار الساعة - قريب من الحرم المكي',
        'description_en': '24/7 emergency medical services - Near Masjid al-Haram',
        'description_ur': '۲۴/۷ ایمرجنسی طبی خدمات - مسجد الحرام کے قریب',
        'description_id': 'Layanan medis darurat 24/7 - Dekat Masjidil Haram',
        'phone_number': '+966-12-569-0000',
        'latitude': 21.4202,
        'longitude': 39.8263,
        'location': 'Ajyad St, Makkah',
        'is_24_hour': 1,
      },
      {
        'service_type': 'hospital',
        'name_ar': 'مستشفى النور التخصصي',
        'name_en': 'Al Noor Specialist Hospital',
        'name_ur': 'النور سپیشلسٹ ہسپتال',
        'name_id': 'Rumah Sakit Spesialis Al Noor',
        'description_ar': 'مستشفى متخصص - جراحة وعناية مركزة',
        'description_en': 'Specialist hospital - Surgery and intensive care',
        'description_ur': 'سپیشلسٹ ہسپتال - سرجری اور انتہائی نگہداشت',
        'description_id': 'Rumah sakit spesialis - Bedah dan perawatan intensif',
        'phone_number': '+966-12-556-2222',
        'latitude': 21.4189,
        'longitude': 39.8156,
        'location': 'Al Aziziyah, Makkah',
        'is_24_hour': 1,
      },
      {
        'service_type': 'water',
        'name_ar': 'محطة مياه زمزم - باب الملك عبدالعزيز',
        'name_en': 'Zamzam Water Station - King Abdulaziz Gate',
        'name_ur': 'زم زم واٹر سٹیشن - شاہ عبدالعزیز گیٹ',
        'name_id': 'Stasiun Air Zamzam - Gerbang King Abdulaziz',
        'description_ar': 'مياه زمزم المباركة مجاناً - مبردة على مدار الساعة',
        'description_en': 'Free blessed Zamzam water - Chilled 24/7',
        'description_ur': 'مفت مبارک زم زم کا پانی - ۲۴/۷ ٹھنڈا',
        'description_id': 'Air Zamzam suci gratis - Dingin 24/7',
        'latitude': 21.4225,
        'longitude': 39.8262,
        'location': 'King Abdulaziz Gate',
        'is_24_hour': 1,
      },
      {
        'service_type': 'water',
        'name_ar': 'محطة مياه زمزم - باب الصفا',
        'name_en': 'Zamzam Water Station - Al-Safa Gate',
        'name_ur': 'زم زم واٹر سٹیشن - الصفا گیٹ',
        'name_id': 'Stasiun Air Zamzam - Gerbang Al-Safa',
        'description_ar': 'مياه زمزم المباركة - بجوار المسعى',
        'description_en': 'Blessed Zamzam water - Near Mas\'a',
        'description_ur': 'مبارک زم زم کا پانی - مسعیٰ کے قریب',
        'description_id': 'Air Zamzam suci - Dekat Mas\'a',
        'latitude': 21.4231,
        'longitude': 39.8269,
        'location': 'Al-Safa Gate',
        'is_24_hour': 1,
      },
      {
        'service_type': 'lost_found',
        'name_ar': 'مكتب المفقودات - المسجد الحرام',
        'name_en': 'Lost & Found Office - Masjid al-Haram',
        'name_ur': 'کھوئی ہوئی اشیاء کا دفتر - مسجد الحرام',
        'name_id': 'Kantor Barang Hilang - Masjidil Haram',
        'description_ar': 'استرجاع الأغراض المفقودة - خدمة مجانية',
        'description_en': 'Lost items retrieval - Free service',
        'description_ur': 'کھوئی ہوئی اشیاء کی بازیابی - مفت خدمت',
        'description_id': 'Pengambilan barang hilang - Layanan gratis',
        'phone_number': '+966-12-560-2000',
        'latitude': 21.4220,
        'longitude': 39.8258,
        'location': 'Ground Floor, Masjid al-Haram',
        'is_24_hour': 1,
      },
      {
        'service_type': 'transport',
        'name_ar': 'العربات الكهربائية - باب الملك فهد',
        'name_en': 'Electric Carts - King Fahd Gate',
        'name_ur': 'برقی گاڑیاں - شاہ فہد گیٹ',
        'name_id': 'Kereta Listrik - Gerbang King Fahd',
        'description_ar': 'خدمة نقل مجانية لكبار السن وذوي الاحتياجات الخاصة',
        'description_en': 'Free transport for elderly and people with special needs',
        'description_ur': 'بزرگوں اور خصوصی ضروریات والے لوگوں کے لیے مفت ٹرانسپورٹ',
        'description_id': 'Transportasi gratis untuk lansia dan penyandang disabilitas',
        'latitude': 21.4218,
        'longitude': 39.8255,
        'location': 'King Fahd Gate',
        'is_24_hour': 1,
      },
      {
        'service_type': 'transport',
        'name_ar': 'العربات الكهربائية - باب العمرة',
        'name_en': 'Electric Carts - Umrah Gate',
        'name_ur': 'برقی گاڑیاں - عمرہ گیٹ',
        'name_id': 'Kereta Listrik - Gerbang Umrah',
        'description_ar': 'نقل داخلي في الحرم - مجاني',
        'description_en': 'Internal Haram transport - Free',
        'description_ur': 'حرم کے اندر ٹرانسپورٹ - مفت',
        'description_id': 'Transportasi internal Haram - Gratis',
        'latitude': 21.4228,
        'longitude': 39.8270,
        'location': 'Umrah Gate',
        'is_24_hour': 1,
      },
     {
  'service_type': 'toilet', 
  'name_ar': 'دورات مياه (نساء)',
  'name_en': 'Restrooms (Women)',
  'name_ur': 'بیت الخلا (خواتین)', // الترجمة الأوردو
  'name_id': 'Toilet (Wanita)',    // الترجمة الإندونيسية
  'description_ar': 'دورات مياه مجهزة وأماكن للوضوء - الدور الأرضي',
  'description_en': 'Equipped restrooms and wudu areas - Ground Floor',
  'description_ur': 'وضو اور بیت الخلا کی سہولیات - گراؤنڈ فلور', // الترجمة الأوردو
  'description_id': 'Fasilitas wudhu dan toilet - Lantai Dasar', // الترجمة الإندونيسية
  'latitude': 21.4239, 
  'longitude': 39.8272,
  'location': 'Ground Floor',
  'is_24_hour': 1,
}, 
{
  'service_type': 'toilet', 
  'name_ar': 'دورات مياه (رجال)',
  'name_en': 'Restrooms (Men)',
  'name_ur': 'بیت الخلا (مرد)',
  'name_id': 'Toilet (Pria)',
  'description_ar': 'دورات مياه مجهزة وأماكن للوضوء - الدور الأرضي بجوار باب الملك فهد',
  'description_en': 'Equipped restrooms and wudu areas - Ground Floor near King Fahd Gate',
  'description_ur': 'وضو اور بیت الخلا کی سہولیات - شاہ فہد گیٹ کے قریب',
  'description_id': 'Fasilitas wudhu dan toilet - Dekat Gerbang King Fahd',
  'latitude': 21.4210, 
  'longitude': 39.8250,
  'location': 'Near King Fahd Gate',
  'is_24_hour': 1,
},
{
  'service_type': 'toilet', 
  'name_ar': 'دورات مياه (ذوي الاحتياجات الخاصة)',
  'name_en': 'Accessible Restrooms',
  'name_ur': 'معذور افراد کے لیے بیت الخلا',
  'name_id': 'Toilet Disabilitas',
  'description_ar': 'دورات مياه مجهزة بالكامل لتناسب ذوي الاحتياجات الخاصة - ممرات واسعة',
  'description_en': 'Fully equipped accessible restrooms - Wide entrances',
  'description_ur': 'خصوصی افراد کے لیے مکمل طور پر لیس بیت الخلا',
  'description_id': 'Toilet yang dilengkapi fasilitas untuk penyandang disabilitas',
  'latitude': 21.4225, 
  'longitude': 39.8265,
  'location': 'Multiple Locations',
  'is_24_hour': 1,
},
    ];

    for (var service in services) {
      await db.insert('services', service);
    }
    // إدخال العمرة
    await db.insert('rituals', {
      'ritual_type': 'umrah',
      'name_ar': 'العمرة',
      'name_en': 'Umrah',
      'name_ur': 'عمرہ',
      'name_id': 'Umrah',
      'total_steps': 4,
    });

    // إدخال خطوات العمرة
    final umrahSteps = [
      {
        'ritual_id': 1,
        'step_number': 1,
        'title_ar': 'الإحرام من الميقات',
        'title_en': 'Ihram from Miqat',
        'title_ur': 'میقات سے احرام',
        'title_id': 'Ihram dari Miqat',
        'description_ar': 'الاغتسال والنية ولبس ملابس الإحرام والتلبية',
        'description_en': 'Bathe, make intention, wear Ihram clothes and say Talbiyah',
        'description_ur': 'غسل، نیت، احرام کے کپڑے پہننا اور تلبیہ کہنا',
        'description_id': 'Mandi, berniat, mengenakan pakaian Ihram dan mengucapkan Talbiyah',
      },
      {
        'ritual_id': 1,
        'step_number': 2,
        'title_ar': 'طواف العمرة',
        'title_en': 'Tawaf Al-Umrah',
        'title_ur': 'عمرہ کا طواف',
        'title_id': 'Tawaf Umrah',
        'description_ar': 'الطواف حول الكعبة سبعة أشواط ابتداءً من الحجر الأسود',
        'description_en': 'Circle the Kaaba seven times starting from the Black Stone',
        'description_ur': 'حجر اسود سے شروع کرتے ہوئے کعبہ کے گرد سات چکر لگانا',
        'description_id': 'Mengelilingi Ka\'bah tujuh kali dimulai dari Hajar Aswad',
      },
      {
        'ritual_id': 1,
        'step_number': 3,
        'title_ar': 'السعي بين الصفا والمروة',
        'title_en': 'Sa\'i between Safa and Marwah',
        'title_ur': 'صفا اور مروہ کے درمیان سعی',
        'title_id': 'Sa\'i antara Safa dan Marwah',
        'description_ar': 'السعي سبعة أشواط بين الصفا والمروة',
        'description_en': 'Walk seven times between Safa and Marwah hills',
        'description_ur': 'صفا اور مروہ کے درمیان سات چکر لگانا',
        'description_id': 'Berjalan tujuh kali antara bukit Safa dan Marwah',
      },
      {
        'ritual_id': 1,
        'step_number': 4,
        'title_ar': 'الحلق أو التقصير',
        'title_en': 'Haircut or Trimming',
        'title_ur': 'سر منڈوانا یا بال کٹوانا',
        'title_id': 'Cukur atau Potong Rambut',
        'description_ar': 'حلق الرأس أو تقصير الشعر للتحلل من الإحرام',
        'description_en': 'Shave head or trim hair to exit Ihram state',
        'description_ur': 'احرام سے نکلنے کے لیے سر منڈوانا یا بال کٹوانا',
        'description_id': 'Cukur rambut atau potong rambut untuk keluar dari Ihram',
      },
    ];

    for (var step in umrahSteps) {
      await db.insert('ritual_steps', step);
    }

// إدخال الأدعية
final List<Map<String, String>> duas = [
  // 1-12 (الأدعية التي أرفقتها أنتِ - ستبقى كما هي لضمان عملها)
  {
    'arabic_text': 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
    'transliteration': 'Labbayka Allahumma labbayk, labbayka la shareeka laka labbayk, inna alhamda wan-ni\'mata laka wal-mulk, la shareeka lak',
    'translation_ar': 'لبيك اللهم لبيك، لبيك لا شريك لك لبيك، إن الحمد والنعمة لك والملك، لا شريك لك',
    'translation_en': 'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Verily all praise and blessings are Yours, and all sovereignty, You have no partner',
    'translation_ur': 'میں حاضر ہوں اے اللہ، میں حاضر ہوں۔ میں حاضر ہوں، تیرا کوئی شریک نہیں، میں حاضر ہوں۔ بے شک تمام تعریف اور نعمت تیری ہے اور بادشاہی، تیرا کوئی شریک نہیں',
    'translation_id': 'Aku penuhi panggilan-Mu ya Allah. Aku penuhi panggilan-Mu, tiada sekutu bagi-Mu. Sesungguhnya segala puji dan nikmat adalah milik-Mu, dan kerajaan, tiada sekutu bagi-Mu',
    'source': 'التلبية - Talbiyah',
  },
  {
    'arabic_text': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    'transliteration': 'Allahumma iftah li abwaba rahmatik',
    'translation_ar': 'اللهم افتح لي أبواب رحمتك',
    'translation_en': 'O Allah, open for me the doors of Your mercy',
    'translation_ur': 'اے اللہ! میرے لیے اپنی رحمت کے دروازے کھول دے',
    'translation_id': 'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu',
    'source': 'دخول المسجد - Entering Mosque',
  },
  {
    'arabic_text': 'اللَّهُمَّ زِدْ هَذَا الْبَيْتَ تَشْرِيفًا وَتَعْظِيمًا وَتَكْرِيمًا وَمَهَابَةً، وَزِدْ مَنْ شَرَّفَهُ وَكَرَّمَهُ مِمَّنْ حَجَّهُ أَوِ اعْتَمَرَهُ تَشْرِيفًا وَتَكْرِيمًا وَتَعْظِيمًا وَبِرًّا',
    'transliteration': 'Allahumma zid hadha al-bayta tashreefan wa ta\'zeeman wa takreeman wa mahabatan, wa zid man sharrafahu wa karramahu mimman hajjahu aw i\'tamarahu tashreefan wa takreeman wa ta\'zeeman wa birra',
    'translation_ar': 'اللهم زد هذا البيت تشريفاً وتعظيماً وتكريماً ومهابة، وزد من شرفه وكرمه ممن حجه أو اعتمره تشريفاً وتكريماً وتعظيماً وبراً',
    'translation_en': 'O Allah, increase this House in honor, reverence and awe. And increase those who honor it with Hajj or Umrah in honor, respect and piety',
    'translation_ur': 'اے اللہ! اس گھر کی عزت، عظمت، تکریم اور رعب میں اضافہ فرما، اور جو اس کی حج یا عمرہ کے ذریعے تعظیم کرے اس کی عزت، تکریم، عظمت اور نیکی میں اضافہ فرما',
    'translation_id': 'Ya Allah, tambahkanlah kehormatan rumah ini, dan tambahkanlah kehormatan bagi orang yang berhaji atau berumrah',
    'source': 'عند رؤية الكعبة - Seeing Kaaba',
  },
  {
    'arabic_text': 'بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ، اللَّهُمَّ إِيمَانًا بِكَ وَتَصْدِيقًا بِكِتَابِكَ وَوَفَاءً بِعَهْدِكَ وَاتِّبَاعًا لِسُنَّةِ نَبِيِّكَ مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ',
    'transliteration': 'Bismillah wa Allahu Akbar, Allahumma eemanan bika wa tasdeeqan bi kitabika wa wafa\'an bi ahdika wa ittiba\'an li sunnati nabiyyika Muhammad',
    'translation_ar': 'بسم الله والله أكبر، اللهم إيماناً بك وتصديقاً بكتابك ووفاءً بعهدك واتباعاً لسنة نبيك محمد صلى الله عليه وسلم',
    'translation_en': 'In the name of Allah, Allah is Greatest. O Allah, with faith in You, belief in Your Book, fulfillment of Your covenant, and following the Sunnah of Your Prophet Muhammad',
    'translation_ur': 'اللہ کے نام سے، اللہ سب سے بڑا ہے۔ اے اللہ! تجھ پر ایمان، تیری کتاب کی تصدیق، تیرے عہد کی وفا اور تیرے نبی محمد ﷺ کی سنت کی پیروی کرتے ہوئے',
    'translation_id': 'Dengan nama Allah, Allah Maha Besar. Ya Allah, dengan iman kepada-Mu, membenarkan kitab-Mu, dan mengikuti sunnah Nabi-Mu Muhammad',
    'source': 'عند الحجر الأسود - Black Stone',
  },
  {
    'arabic_text': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'transliteration': 'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina adhaban-nar',
    'translation_ar': 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    'translation_en': 'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire',
    'translation_ur': 'اے ہمارے رب! ہمیں دنیا میں بھلائی دے اور آخرت میں بھی بھلائی دے، اور ہمیں آگ کے عذاب سے بچا',
    'translation_id': 'Ya Tuhan kami, berilah kami kebaikan di dunia dan akhirat, dan lindungilah kami dari azab neraka',
    'source': 'القرآن 2:201 - Quran 2:201',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    'transliteration': 'Allahumma inni as\'aluka ilman nafi\'an wa rizqan tayyiban wa \'amalan mutaqabbalan',
    'translation_ar': 'اللهم إني أسألك علماً نافعاً ورزقاً طيباً وعملاً متقبلاً',
    'translation_en': 'O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds',
    'translation_ur': 'اے اللہ! میں تجھ سے نفع بخش علم، پاکیزہ رزق اور قبول شدہ عمل مانگتا ہوں',
    'translation_id': 'Ya Allah, aku memohon ilmu yang bermanfaat, rezeki yang baik, dan amal yang diterima',
    'source': 'بعد ركعتي الطواف - After Tawaf',
  },
  {
    'arabic_text': 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ، أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ',
    'transliteration': 'Inna as-Safa wal-Marwata min sha\'a\'iri Allah, abda\'u bima bada\'a Allahu bihi',
    'translation_ar': 'إن الصفا والمروة من شعائر الله، أبدأ بما بدأ الله به',
    'translation_en': 'Indeed, As-Safa and Al-Marwah are among the symbols of Allah. I begin with what Allah began with',
    'translation_ur': 'بے شک صفا اور مروہ اللہ کی نشانیوں میں سے ہیں، میں اس سے شروع کرتا ہوں جس سے اللہ نے شروع کیا',
    'translation_id': 'Sesungguhnya Safa dan Marwah termasuk syi\'ar Allah. Aku mulai dengan apa yang Allah mulai',
    'source': 'عند الصفا - At Safa',
  },
  {
    'arabic_text': 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ وَلِلَّهِ الْحَمْدُ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'transliteration': 'Allahu Akbar (3x), wa lillahi al-hamd. La ilaha illa Allah wahdahu la shareeka lah, lahu al-mulku wa lahu al-hamd wa huwa \'ala kulli shay\'in qadeer',
    'translation_ar': 'الله أكبر (3 مرات)، ولله الحمد. لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
    'translation_en': 'Allah is the Greatest (3x), and all praise is for Allah. There is no deity except Allah alone, without partner. His is the dominion and praise, and He is over all things competent',
    'translation_ur': 'اللہ سب سے بڑا ہے (3 بار)، اور اللہ کے لیے تمام تعریفیں ہیں۔ اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اسی کی بادشاہی ہے اور اسی کے لیے تعريف ہے',
    'translation_id': 'Allah Maha Besar (3x), segala puji bagi Allah. Tiada tuhan selain Allah, bagi-Nya kerajaan dan segala puji',
    'source': 'على الصفا والمروة - On Safa & Marwah',
  },
  {
    'arabic_text': 'اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَتَجَاوَزْ عَمَّا تَعْلَمُ إِنَّكَ أَنْتَ الْأَعَزُّ الْأَكْرَمُ',
    'transliteration': 'Allahumma ighfir li warhamni wa tajawaz \'amma ta\'lam innaka anta al-a\'azzu al-akram',
    'translation_ar': 'اللهم اغفر لي وارحمني وتجاوز عما تعلم إنك أنت الأعز الأكرم',
    'translation_en': 'O Allah, forgive me, have mercy on me, and pardon what You know. Indeed, You are the Most Mighty, the Most Generous',
    'translation_ur': 'اے اللہ! مجھے بخش دے، مجھ پر رحم فرما، اور جو تو جانتا ہے اس سے درگزر فرما۔ بے شک تو سب سے زیادہ عزت والا اور كريم ہے',
    'translation_id': 'Ya Allah, ampunilah aku, rahmatilah aku, dan maafkan apa yang Engkau ketahui. Sesungguhnya Engkau Maha Mulia dan Maha Pemurah',
    'source': 'عند الحلق - During Haircut',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ',
    'transliteration': 'Allahumma inni as\'aluka al-jannata wa a\'udhu bika minan-nar',
    'translation_ar': 'اللهم إني أسألك الجنة وأعوذ بك من النار',
    'translation_en': 'O Allah, I ask You for Paradise and I seek refuge in You from the Fire',
    'translation_ur': 'اے اللہ! میں تجھ سے جنت مانگتا ہوں اور جہنم سے تیری پناہ چاہتا ہوں',
    'translation_id': 'Ya Allah, aku memohon surga kepada-Mu dan berlindung dari neraka',
    'source': 'دعاء عام - General Dua',
  },
  {
    'arabic_text': 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    'transliteration': 'Rabbi irhamhuma kama rabbayani saghira',
    'translation_ar': 'رب ارحمهما كما ربياني صغيراً',
    'translation_en': 'My Lord, have mercy upon them as they brought me up when I was small',
    'translation_ur': 'اے میرے رب! ان دونوں پر رحم فرما جیسا کہ انہوں نے مجھے بچپن میں پالا',
    'translation_id': 'Ya Tuhanku, kasihanilah mereka berdua sebagaimana mereka mendidikku waktu kecil',
    'source': 'القرآن 17:24 - Quran 17:24',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
    'transliteration': 'Allahumma inni as\'aluka min fadhlika',
    'translation_ar': 'اللهم إني أسألك من فضلك',
    'translation_en': 'O Allah, I ask You from Your bounty',
    'translation_ur': 'اے اللہ! میں تجھ سے تیرے فضل کا سوال کرتا ہوں',
    'translation_id': 'Ya Allah, aku memohon karunia-Mu',
    'source': 'الخروج من المسجد - Leaving Mosque',
  },

  // 13-30 (الإضافات الجديدة بنفس الصيغة)
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أُرِيدُ الْعُمْرَةَ فَيَسِّرْهَا لِي وَتَقَبَّلْهَا مِنِّي',
    'transliteration': 'Allahumma inni ureedu al-umrata fayassirha lee wa taqabbalha minnee',
    'translation_ar': 'اللهم إني أريد العمرة فيسرها لي وتقبلها مني',
    'translation_en': 'O Allah, I intend to perform Umrah, so make it easy for me and accept it from me',
    'translation_ur': 'اے اللہ! میں عمرہ کا ارادہ کرتا ہوں، اسے میرے لیے آسان کر دے',
    'translation_id': 'Ya Allah, aku berniat umrah, mudahkanlah bagiku dan terimalah dariku',
    'source': 'النية - Intention',
  },
  {
    'arabic_text': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
    'transliteration': 'Subhanal-ladhee sakhkhara lana hadha wa ma kunna lahu muqrineen',
    'translation_ar': 'سبحان الذي سخر لنا هذا وما كنا له مقرنين',
    'translation_en': 'Glory be to Him who has placed this at our service, and we are to our Lord to return',
    'translation_ur': 'پاک ہے وہ ذات جس نے اسے ہمارے بس میں کر دیا',
    'translation_id': 'Maha Suci Allah yang telah menundukkan semua ini bagi kami',
    'source': 'دعاء السفر - Travel Dua',
  },
  {
    'arabic_text': 'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَاوَاتِ وَالْأَرْضِ وَمَنْ فِيهِنَّ',
    'transliteration': 'Allahumma lakal hamdu anta noorus-samawati wal-ard',
    'translation_ar': 'اللهم لك الحمد أنت نور السماوات والأرض',
    'translation_en': 'O Allah, to You belongs all praise, You are the Light of the heavens and the earth',
    'translation_ur': 'اے اللہ! تمام تعریفیں تیرے لیے ہیں، تو آسمانوں اور زمین کا نور ہے',
    'translation_id': 'Ya Allah, bagi-Mu segala puji, Engkau cahaya langit dan bumi',
    'source': 'ثناء - Praise',
  },
  {
    'arabic_text': 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
    'transliteration': 'Astaghfirullahal-azeem al-ladhee la ilaha illa huwal hayyul qayyoom',
    'translation_ar': 'أستغفر الله العظيم وأتوب إليه',
    'translation_en': 'I seek forgiveness from Allah the Almighty, besides whom there is no god',
    'translation_ur': 'میں اللہ سے بخشش مانگتا ہوں اور اس کی طرف توبہ کرتا ہوں',
    'translation_id': 'Aku memohon ampun kepada Allah yang Maha Agung dan bertaubat kepada-Nya',
    'source': 'استغفار - Forgiveness',
  },
  {
    'arabic_text': 'اللَّهُمَّ اجْعَلْهُ حَجًّا مَبْرُورًا، وَذَنْبًا مَغْفُورًا، وَسَعْيًا مَشْكُورًا',
    'transliteration': 'Allahummaj-alhu hajjan mabruran wa dhanban maghfooran',
    'translation_ar': 'اللهم اجعله حجاً مبروراً وذنباً مغفوراً وسعياً مشكوراً',
    'translation_en': 'O Allah, make it an accepted Hajj, a forgiven sin, and a praised effort',
    'translation_ur': 'اے اللہ! اسے حج مبرور، بخشا ہوا گناہ اور مقبول کوشش بنا دے',
    'translation_id': 'Ya Allah, jadikanlah haji yang mabrur, dosa yang diampuni, dan usaha yang disyukuri',
    'source': 'دعاء الحج - Hajj Dua',
  },
  {
    'arabic_text': 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    'transliteration': 'Allahumma a\'innee ala dhikrika wa shukrika wa husni ibadatik',
    'translation_ar': 'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
    'translation_en': 'O Allah, help me to remember You, thank You, and worship You excellently',
    'translation_ur': 'اے اللہ! اپنے ذکر، شکر اور بہترین عبادت پر میری مدد فرما',
    'translation_id': 'Ya Allah, bantulah aku untuk mengingat-Mu, bersyukur kepada-Mu, dan beribadah dengan baik',
    'source': 'ذكر - Remembrance',
  },
  {
    'arabic_text': 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
    'transliteration': 'Ya Muqallibal-quloob thabbit qalbee ala deenik',
    'translation_ar': 'يا مقلب القلوب ثبت قلبي على دينك',
    'translation_en': 'O Turner of hearts, keep my heart firm on Your religion',
    'translation_ur': 'اے دلوں کو پھیرنے والے! میرے دل کو اپنے دین پر ثابت قدم رکھ',
    'translation_id': 'Wahai Dzat yang membolak-balikkan hati, teguhkanlah hatiku di atas agama-Mu',
    'source': 'ثبات - Steadfastness',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    'transliteration': 'Allahumma innee as-alukal-afwa wal-afiyah',
    'translation_ar': 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة',
    'translation_en': 'O Allah, I ask You for forgiveness and well-being in this world and the Hereafter',
    'translation_ur': 'اے اللہ! میں تجھ سے دنیا اور آخرت میں معافی اور عافیت مانگتا ہوں',
    'translation_id': 'Ya Allah, aku memohon ampunan dan keselamatan di dunia dan akhirat',
    'source': 'عافية - Well-being',
  },
  {
    'arabic_text': 'اللَّهُمَّ رَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمَاوَاتِ وَمِلْءَ الْأَرْضِ',
    'transliteration': 'Allahumma rabbana lakal hamdu mil-as-samawati wa mil-al-ard',
    'translation_ar': 'اللهم ربنا لك الحمد ملء السماوات والأرض',
    'translation_en': 'O Allah, our Lord, to You belongs praise filling the heavens and the earth',
    'translation_ur': 'اے اللہ! ہمارے رب، تیرے لیے ایسی تعریف ہے جو آسمانوں اور زمین کو بھر دے',
    'translation_id': 'Ya Allah, Tuhan kami, bagi-Mu segala puji sepenuh langit dan bumi',
    'source': 'حمد - Praise',
  },
  {
    'arabic_text': 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    'transliteration': 'Hasbiyallahu la ilaha illa huwa alayhi tawakkaltu',
    'translation_ar': 'حسبي الله لا إله إلا هو عليه توكلت',
    'translation_en': 'Allah is sufficient for me; there is no deity except Him. In Him I have put my trust',
    'translation_ur': 'مجھے اللہ کافی ہے، اس کے سوا کوئی معبود نہیں، اسی پر میں نے بھروسہ کیا',
    'translation_id': 'Cukuplah Allah bagiku; tidak ada Tuhan selain Dia. Hanya kepada-Nya aku bertawakal',
    'source': 'توكل - Trust',
  },
  {
    'arabic_text': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'transliteration': 'Allahumma salli ala Muhammadin wa ala ali Muhammad',
    'translation_ar': 'اللهم صل على محمد وعلى آل محمد',
    'translation_en': 'O Allah, send blessings upon Muhammad and the family of Muhammad',
    'translation_ur': 'اے اللہ! محمد ﷺ اور ان کی آل پر درود بھیج',
    'translation_id': 'Ya Allah, limpahkanlah rahmat kepada Muhammad dan keluarga Muhammad',
    'source': 'صلاة على النبي - Blessings',
  },
  {
    'arabic_text': 'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    'transliteration': 'Allahummak-finee bihalalika an haramik',
    'translation_ar': 'اللهم اكفني بحلالك عن حرامك وأغنني بفضلك عمن سواك',
    'translation_en': 'O Allah, suffice me with Your lawful instead of Your forbidden',
    'translation_ur': 'اے اللہ! مجھے اپنے حلال کے ساتھ اپنے حرام سے بچا اور اپنے فضل سے غنی کر دے',
    'translation_id': 'Ya Allah, cukupkanlah aku dengan yang halal-Mu dari yang haram-Mu',
    'source': 'رزق - Provision',
  },
  {
    'arabic_text': 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ',
    'transliteration': 'Rabbij-alnee muqeemas-salati wa min dhurriyyatee',
    'translation_ar': 'رب اجعلني مقيم الصلاة ومن ذريتي ربنا وتقبل دعاء',
    'translation_en': 'My Lord, make me an establisher of prayer, and from my descendants',
    'translation_ur': 'اے میرے رب! مجھے اور میری اولاد کو نماز قائم کرنے والا بنا دے',
    'translation_id': 'Ya Tuhanku, jadikanlah aku dan anak cucuku orang-orang yang tetap mendirikan shalat',
    'source': 'إبراهيم 40 - Ibrahim 40',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحُزْنِ وَالْعَجْزِ وَالْكَسَلِ',
    'transliteration': 'Allahumma innee a-oodhu bika minal hammi wal hazan',
    'translation_ar': 'اللهم إني أعوذ بك من الهم والحزن والعجز والكسل',
    'translation_en': 'O Allah, I seek refuge in You from anxiety, sorrow, weakness, and laziness',
    'translation_ur': 'اے اللہ! میں فکر، غم، عاجزي اور سستی سے تیری پناه چاہتا ہوں',
    'translation_id': 'Ya Allah, aku berlindung kepada-Mu dari kegelisahan, kesedihan, dan kelemahan',
    'source': 'الاستعاذة - Refuge',
  },
  {
    'arabic_text': 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'transliteration': 'La ilaha illa anta subhanaka innee kuntu minaz-zalimeen',
    'translation_ar': 'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    'translation_en': 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers',
    'translation_ur': 'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بے شک میں ہی ظالموں میں سے تھا',
    'translation_id': 'Tiada Tuhan selain Engkau. Maha Suci Engkau, sesungguhnya aku termasuk orang-orang yang zalim',
    'source': 'الأنبياء 87 - Al-Anbiya 87',
  },
  {
    'arabic_text': 'اللَّهُمَّ مَتِّعْنِي بِسَمْعِي وَبَصَرِي وَاجْعَلْهُمَا الْوَارِثَ مِنِّي',
    'transliteration': 'Allahumma matti\'nee bisam\'ee wa basaree',
    'translation_ar': 'اللهم متعني بسمعي وبصري واجعلهما الوارث مني',
    'translation_en': 'O Allah, give me enjoyment of my hearing and my sight, and make them my heirs',
    'translation_ur': 'اے اللہ! مجھے میری سماعت اور بصارت سے فائدہ دے اور انہیں میرا وارث بنا',
    'translation_id': 'Ya Allah, berikanlah aku kenikmatan dengan pendengaran و penglihatanku',
    'source': 'دعاء - Dua',
  },
  {
    'arabic_text': 'رَبِّ زِدْنِي عِلْمًا',
    'transliteration': 'Rabbi zidnee ilman',
    'translation_ar': 'رب زدني علماً',
    'translation_en': 'My Lord, increase me in knowledge',
    'translation_ur': 'اے میرے رب! میرے علم میں اضافہ فرما',
    'translation_id': 'Ya Tuhanku, tambahkanlah kepadaku ilmu pengetahuan',
    'source': 'طه 114 - Taha 114',
  },
  {
    'arabic_text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ حُسْنَ الْخَاتِمَةِ',
    'transliteration': 'Allahumma innee as-aluka husnal khatimah',
    'translation_ar': 'اللهم إني أسألك حسن الخاتمة',
    'translation_en': 'O Allah, I ask You for a good end to my life',
    'translation_ur': 'اے اللہ! میں تجھ سے اچھے خاتمے کا سوال کرتا ہوں',
    'translation_id': 'Ya Allah, aku memohon kepada-Mu akhir yang baik',
    'source': 'خاتمة - Finality',
  },
];
for (var dua in duas) {
      await db.insert('duas', dua);
    }
  }

  // ==================== CRUD Operations ====================

  // الطقوس
  Future<List<RitualModel>> getAllRituals() async {
    final db = await database;
    final result = await db.query('rituals');
    return result.map((map) => RitualModel.fromMap(map)).toList();
  }

  // خطوات الطقوس
  Future<List<RitualStepModel>> getStepsByRitualId(int ritualId) async {
    final db = await database;
    final result = await db.query(
      'ritual_steps',
      where: 'ritual_id = ?',
      whereArgs: [ritualId],
      orderBy: 'step_number ASC',
    );
    return result.map((map) => RitualStepModel.fromMap(map)).toList();
  }

  // الأدعية
  Future<List<DuaModel>> getAllDuas() async {
    final db = await database;
    final result = await db.query('duas');
    return result.map((map) => DuaModel.fromMap(map)).toList();
  }

  // سجلات العد
  Future<int> insertLapSession(LapSessionModel session) async {
    final db = await database;
    return await db.insert('lap_sessions', session.toMap());
  }

  Future<LapSessionModel?> getActiveLapSession() async {
    final db = await database;
    final result = await db.query(
      'lap_sessions',
      where: 'is_complete = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return LapSessionModel.fromMap(result.first);
  }
Future<int> deleteLapSession(int id) async {
  final db = await database;
  return await db.delete(
    'lap_sessions',
    where: 'id = ?',
    whereArgs: [id],
  );
}
  Future<int> updateLapSession(LapSessionModel session) async {
    final db = await database;
    return await db.update(
      'lap_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<LapSessionModel>> getLapHistory() async {
    final db = await database;
    final result = await db.query(
      'lap_sessions',
      where: 'is_complete = ?',
      whereArgs: [1],
      orderBy: 'start_time DESC',
      limit: 20,
    );
    return result.map((map) => LapSessionModel.fromMap(map)).toList();
  }

  // ==================== Services Operations ====================

  // الحصول على جميع الخدمات
  Future<List<ServiceModel>> getAllServices() async {
    final db = await database;
    final result = await db.query('services');
    return result.map((map) => ServiceModel.fromMap(map)).toList();
  }

  // الحصول على الخدمات حسب النوع
  Future<List<ServiceModel>> getServicesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'services',
      where: 'service_type = ?',
      whereArgs: [type],
    );
    return result.map((map) => ServiceModel.fromMap(map)).toList();
  }

  // البحث في الخدمات
  Future<List<ServiceModel>> searchServices(String query, String languageCode) async {
    final db = await database;
    final nameColumn = 'name_$languageCode';
    final result = await db.query(
      'services',
      where: '$nameColumn LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((map) => ServiceModel.fromMap(map)).toList();
  }

  // ==================== Group Operations ====================

// إنشاء مجموعة جديدة
Future<int> createGroup(GroupModel group) async {
  final db = await database;
  return await db.insert('groups', group.toMap());
}

// الحصول على مجموعة بالكود
Future<GroupModel?> getGroupByCode(String code) async {
  final db = await database;
  final result = await db.query(
    'groups',
    where: 'group_code = ? AND is_active = ?',
    whereArgs: [code, 1],
    limit: 1,
  );

  if (result.isEmpty) return null;
  return GroupModel.fromMap(result.first);
}

// إضافة عضو للمجموعة
Future<int> addGroupMember(GroupMemberModel member) async {
  final db = await database;
  return await db.insert('group_members', member.toMap());
}

// الحصول على أعضاء المجموعة
Future<List<GroupMemberModel>> getGroupMembers(String groupCode) async {
  final db = await database;
  final result = await db.query(
    'group_members',
    where: 'group_code = ?',
    whereArgs: [groupCode],
    orderBy: 'joined_at ASC',
  );
  return result.map((map) => GroupMemberModel.fromMap(map)).toList();
}

// تحديث موقع العضو
Future<int> updateMemberLocation(
  String groupCode,
  String memberName,
  double lat,
  double lng,
) async {
  final db = await database;
  return await db.update(
    'group_members',
    {
      'latitude': lat,
      'longitude': lng,
      'last_location_update': DateTime.now().toIso8601String(),
    },
    where: 'group_code = ? AND member_name = ?',
    whereArgs: [groupCode, memberName],
  );
}

// حذف عضو من المجموعة
Future<int> removeMemberFromGroup(String groupCode, String memberName) async {
  final db = await database;
  return await db.delete(
    'group_members',
    where: 'group_code = ? AND member_name = ?',
    whereArgs: [groupCode, memberName],
  );
}

// إيقاف المجموعة
Future<int> deactivateGroup(String groupCode) async {
  final db = await database;
  return await db.update(
    'groups',
    {'is_active': 0},
    where: 'group_code = ?',
    whereArgs: [groupCode],
  );
}

// الحصول على المجموعات النشطة
Future<List<GroupModel>> getActiveGroups() async {
  final db = await database;
  final result = await db.query(
    'groups',
    where: 'is_active = ?',
    whereArgs: [1],
    orderBy: 'created_at DESC',
  );
  return result.map((map) => GroupModel.fromMap(map)).toList();
}
// ==================== SOS Operations ====================

// إضافة بلاغ SOS
Future<int> insertSOSReport(SOSModel sos) async {
  final db = await database;
  return await db.insert('sos_reports', sos.toMap());
}

// الحصول على بلاغات SOS غير المحلولة
Future<List<SOSModel>> getActiveSOSReports(String groupCode) async {
  final db = await database;
  final result = await db.query(
    'sos_reports',
    where: 'group_code = ? AND is_resolved = ?',
    whereArgs: [groupCode, 0],
    orderBy: 'timestamp DESC',
  );
  return result.map((map) => SOSModel.fromMap(map)).toList();
}

// تحديث حالة بلاغ SOS
Future<int> resolveSOSReport(int sosId) async {
  final db = await database;
  return await db.update(
    'sos_reports',
    {'is_resolved': 1},
    where: 'id = ?',
    whereArgs: [sosId],
  );
}
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}