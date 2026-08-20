import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SporUygulamasi());
}

// ============================================
// BİLDİRİM SERVİSİ: Adım sayısını bildirim
// çubuğunda gösterir/günceller (uygulama arka
// planda çalıştığı sürece - tamamen kapatılırsa
// güncellenmeyi durdurur, native "foreground
// service" olmadan bu mümkün değil).
// ============================================
class BildirimServisi {
  static final FlutterLocalNotificationsPlugin _eklenti =
      FlutterLocalNotificationsPlugin();
  static bool _hazirlandi = false;
  static const int _bildirimId = 100;

 static Future<void> hazirla() async {
  if (_hazirlandi) return;
  
  const androidAyarlari = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ayarlar = InitializationSettings(android: androidAyarlari);
  await _eklenti.initialize(ayarlar);

  // Android 8.0+ için bildirim kanalı oluşturma
  const AndroidNotificationChannel kanal = AndroidNotificationChannel(
    'adim_sayar_kanal', // NotificationDetails içindeki ID ile BİREBİR AYNI olmalı
    'Adım Sayar',
    description: 'Günlük adım sayınızı gösterir',
    importance: Importance.low,
  );

  await _eklenti
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(kanal);

  _hazirlandi = true;
}

  static Future<void> adimBildirimiGuncelle(int adim, int hedef) async {
    await hazirla();
    final oran = hedef > 0 ? (adim / hedef * 100).clamp(0, 100).round() : 0;
    const androidDetay = AndroidNotificationDetails(
      'adim_sayar_kanal',
      'Adım Sayar',
      channelDescription: 'Günlük adım sayınızı gösterir',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // kullanıcı kaydırarak kapatamaz
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    const detaylar = NotificationDetails(android: androidDetay);
    await _eklenti.show(
      _bildirimId,
      'AsanaFit',
      '$adim adım • Hedefin %$oran\'i',
      detaylar,
    );
  }

  static Future<void> bildirimiKapat() async {
    await _eklenti.cancel(_bildirimId);
  }
}

// ============================================
// RENK VE STİL PALETİ
// ============================================
class Renkler {
  static const Color acikArkaPlan = Color(0xFFF5F7F5);
  static const Color acikYuzey = Color(0xFFFFFFFF);
  static const Color acikMetinKoyu = Color(0xFF1A2A1E);
  static const Color acikMetinSoluk = Color(0xFF6B7B70);
  static const Color acikKartKenar = Color(0xFFE5E7EB);
  
  static const Color koyuArkaPlan = Color(0xFF121212);
  static const Color koyuYuzey = Color(0xFF1E1E1E);
  static const Color koyuMetinKoyu = Color(0xFFE8E8E8);
  static const Color koyuMetinSoluk = Color(0xFFA0A0A0);
  static const Color koyuKartKenar = Color(0xFF333333);
  
  static const Color koyuCam = Color(0xFF26473B);
  static const Color yogaRengi = Color(0xFF6E5A7E);
  static const Color pilatesRengi = Color(0xFF3E7C79);
  static const Color sporRengi = Color(0xFFC98A3D);

  static Color arkaPlan(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? koyuArkaPlan : acikArkaPlan;
  }
  
  static Color yuzey(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? koyuYuzey : acikYuzey;
  }
  
  static Color metinKoyu(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? koyuMetinKoyu : acikMetinKoyu;
  }
  
  static Color metinSoluk(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? koyuMetinSoluk : acikMetinSoluk;
  }
  
  static Color kartKenar(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? koyuKartKenar : acikKartKenar;
  }

  static Color kategoriRengi(String kategori) {
    switch (kategori) {
      case 'Yoga': return yogaRengi;
      case 'Pilates': return pilatesRengi;
      case 'Spor': return sporRengi;
      default: return koyuCam;
    }
  }

  static IconData kategoriIkonu(String kategori) {
    switch (kategori) {
      case 'Yoga': return Icons.self_improvement;
      case 'Pilates': return Icons.accessibility_new;
      case 'Spor': return Icons.fitness_center;
      default: return Icons.circle;
    }
  }
}

// ============================================
// VERİ MODELLERİ
// ============================================
class Hareket {
  final String id;
  final String isim;
  final String kategori;
  final String? altKategori;
  final String aciklama;
  final String zorluk;
  final String? gorselYolu;

  const Hareket({
    required this.id,
    required this.isim,
    required this.kategori,
    this.altKategori,
    required this.aciklama,
    required this.zorluk,
    this.gorselYolu,
  });

  @override
  bool operator ==(Object other) => other is Hareket && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class AntrenmanGecmisi {
  final DateTime tarih;
  final List<String> hareketIdleri;
  final int tamamlananSure;

  AntrenmanGecmisi({
    required this.tarih,
    required this.hareketIdleri,
    required this.tamamlananSure,
  });

  Map<String, dynamic> toJson() => {
    'tarih': tarih.toIso8601String(),
    'hareketIdleri': hareketIdleri,
    'tamamlananSure': tamamlananSure,
  };

  factory AntrenmanGecmisi.fromJson(Map<String, dynamic> json) => AntrenmanGecmisi(
    tarih: DateTime.parse(json['tarih']),
    hareketIdleri: List<String>.from(json['hareketIdleri']),
    tamamlananSure: json['tamamlananSure'],
  );
}

// ============================================
// TÜM HAREKETLER 
// ============================================
final List<Hareket> tumHareketler = [
  // ---------- YOGA ----------
  const Hareket(
    id: 'yoga_child_pose',
    isim: 'Çocuk Pozu (Balasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_child_pose.png',
    aciklama: 'Omurgayı uzatır, omuzları ve boynu rahatlatır. Zihni sakinleştirerek stresi azaltır.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_downward_dog',
    isim: 'Aşağı Bakan Köpek (Adho Mukha Svanasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_downward_dog.png',
    aciklama: 'Bacak arkası kaslarını esnetir, kolları ve bacakları güçlendirir. Kan akışını dengeleyerek enerji verir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_cat_cow',
    isim: 'Kedi - İnek Akışı (Marjaryasana - Bitilasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_cat_cow.png',
    aciklama: 'Omurganın esnekliğini artırır, sırt ve boyun ağrılarını hafifletir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_mountain_pose',
    isim: 'Dağ Pozu (Tadasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_mountain_pose.png',
    aciklama: 'Duruşu (postürü) düzeltir, vücut farkındalığını ve dengesini artırır.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_warrior',
    isim: 'Savaşçı Duruşu (Virabhadrasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_warrior.png',
    aciklama: 'Bacakları ve kalçaları güçlendirir, dayanıklılığı artırır ve özgüveni destekler.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'yoga_cobra',
    isim: 'Kobra Pozu (Bhujangasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_cobra.png',
    aciklama: 'Göğüs kafesini açar, sırt kaslarını güçlendirir ve duruş bozukluklarına iyi gelir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_bridge',
    isim: 'Köprü Pozu (Setu Bandhasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_bridge.png',
    aciklama: 'Kalça ve bacak kaslarını çalıştırır, karın organlarını uyarır ve sindirime yardım eder.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'yoga_corpse_pose',
    isim: 'Ceset Pozu (Savasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_corpse_pose.png',
    aciklama: 'Pratiğin sonunda tüm bedeni dinlendirir, sinir sistemini sakinleştirir ve zihinsel huzur sağlar.',
    zorluk: 'Kolay',
  ),

  // ---------- SPOR: ALETSİZ ----------
  const Hareket(
    id: 'spor_squat',
    isim: 'Squat',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_squat.png',
    aciklama: 'Kalça, but ve baldır kaslarını çalıştırır. Alt vücut gücünü ve dengeyi geliştirir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'spor_pushup',
    isim: 'Push-up (Şınav)',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_pushup.png',
    aciklama: 'Göğüs, omuz, triceps ve core kaslarını çalıştırır. Üst vücut gücünü artırır.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_lunge',
    isim: 'Lunge',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_lunge.png',
    aciklama: 'Bacak ve denge kaslarını çalıştırmada etkilidir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_plank',
    isim: 'Plank',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/pilates_plank.png',
    aciklama: 'Karın ve merkez (core) bölgesini sabit tutarak güçlendirir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_mountain_climber',
    isim: 'Mountain Climber (Dağ Tırmanışı)',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_mountain_climber.png',
    aciklama: 'Kardiyo ve karın kaslarını aynı anda tetikler.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_burpee',
    isim: 'Burpee',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_burpee.png',
    aciklama: 'Tüm vücudu çalıştıran yüksek yoğunluklu yağ yakıcı bir harekettir.',
    zorluk: 'Zor',
  ),
  const Hareket(
    id: 'spor_crunch',
    isim: 'Mekik / Crunch',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_crunch.png',
    aciklama: 'Karın kaslarını doğrudan hedef alır.',
    zorluk: 'Kolay',
  ),

  // ---------- SPOR: ALETLİ ----------
  const Hareket(
    id: 'spor_barbell_squat',
    isim: 'Barbell Squat / Halter ile Squat',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_barbell_squat.png',
    aciklama: 'Ekstra ağırlıkla bacak ve kalça gelişimini artırır.',
    zorluk: 'Zor',
  ),
  const Hareket(
    id: 'spor_dumbbell_bench_press',
    isim: 'Dambıl Bench Press',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_dumbbell_bench_press.png',
    aciklama: 'Sehpa üzerinde dambıllarla göğüs kaslarını çalıştırır.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_pullup',
    isim: 'Barfiks (Pull-up)',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_pullup.png',
    aciklama: 'Bar yardımıyla sırt ve kol kaslarını güçlendirir.',
    zorluk: 'Zor',
  ),
  const Hareket(
    id: 'spor_lat_pulldown',
    isim: 'Lat Pulldown',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_lat_pulldown.png',
    aciklama: 'Makara sistemiyle sırt (kanat) kaslarını çalıştırır.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'spor_dumbbell_curl',
    isim: 'Dambıl Curl',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_dumbbell_curl.png',
    aciklama: 'Dambıl ile biceps (ön kol) kaslarını büyütür.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'spor_deadlift',
    isim: 'Deadlift',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_deadlift.png',
    aciklama: 'Halter veya dambılla tüm arka zincir (sırt, kalça, bacak) kaslarını çalıştıran temel güç hareketidir.',
    zorluk: 'Zor',
  ),
  const Hareket(
    id: 'spor_shoulder_press',
    isim: 'Dambıl Omuz Presi',
    kategori: 'Spor',
    altKategori: 'Aletli',
    gorselYolu: 'assets/gorseller/spor_shoulder_press.png',
    aciklama: 'Omuz kaslarını geliştirmek için kullanılır.',
    zorluk: 'Orta',
  ),

  // ---------- PİLATES ----------
  const Hareket(
    id: 'pilates_hundred',
    isim: 'The Hundred (Yüz)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_hundred.png',
    aciklama: 'Sırt üstü yatıp bacakları ve başı havaya kaldırarak kolları aşağı yukarı hareket ettirme ve nefes dengeleme. Core kaslarını ve nefes kontrolünü güçlendirir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_criss_cross',
    isim: 'Criss Cross (Çapraz Mekik)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_criss_cross.png',
    aciklama: 'Sırt üstü pozisyonda dizleri büküp dirseği zıt dizle buluşturarak alt karın kaslarını çalıştırma.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_roll_up',
    isim: 'Roll Up',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_roll_up.png',
    aciklama: 'Sırt üstü uzanıp omurgayı tek tek kaldırarak gövdeyi öne doğru esnetme. Omurga esnekliğini ve core kontrolünü artırır.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_single_leg_stretch',
    isim: 'Single Leg Stretch',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_single_leg_stretch.png',
    aciklama: 'Sırt üstü yatarak tek bacağı göğse çekip diğer bacağı uzatma. Karın kaslarını ve koordinasyonu geliştirir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_glute_bridge',
    isim: 'Glute Bridge (Köprü Kurma)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_glute_bridge.png',
    aciklama: 'Sırt üstü dizler bükülü yatarak kalçayı yukarı kaldırma ve kalça/arka bacak kaslarını çalıştırma.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_back_extension',
    isim: 'Back Extension (Sırta Esneme)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_back_extension.png',
    aciklama: 'Yüzüstü yatarak elleri ve göğsü hafifçe yerden kaldırıp bel kaslarını güçlendirme.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_side_kick',
    isim: 'Side Kick (Yan Bacak)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_side_kick.png',
    aciklama: 'Yan yatarak üstteki bacağı öne ve arkaya kontrollü sallama. Kalça yan kaslarını güçlendirir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_plank',
    isim: 'Plank',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_plank.png',
    aciklama: 'Karın ve tüm vücut dayanıklılığını artıran ön destek duruşu. Omuz, sırt ve core kaslarını güçlendirir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_mermaid',
    isim: 'Mermaid (Deniz Kızı)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_mermaid.png',
    aciklama: 'Yanda oturarak gövdeyi yan tarafa uzatıp yan kaburga ve bel kaslarını esnetme.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_swimming',
    isim: 'Swimming (Yüzme)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_swimming.png',
    aciklama: 'Yüzüstü pozisyonda zıt kol ve bacağı aynı anda yukarı kaldırma. Sırt ve core kaslarını güçlendirir, dengeyi geliştirir.',
    zorluk: 'Orta',
  ),
];

List<String> kategoriListesiOlustur() {
  final kategoriler = tumHareketler.map((h) => h.kategori).toSet().toList();
  kategoriler.sort();
  return ['Tümü', ...kategoriler];
}

// ============================================
// KAYIT SERVİSİ
// ============================================
class KayitServisi {
  static const String anahtarAd = 'benim_listem';
  static const String gecmisAnahtar = 'antrenman_gecmisi';
  static const String onboardingAnahtar = 'onboarding_gosterildi';
  static const String temaAnahtar = 'tema_modu';

  static Future<List<Hareket>> listeyiOku() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliVeri = prefs.getString(anahtarAd);
    if (kayitliVeri == null) return [];
    final List<dynamic> idListesi = jsonDecode(kayitliVeri);
    return tumHareketler.where((h) => idListesi.contains(h.id)).toList();
  }

  static Future<void> listeyiKaydet(List<Hareket> liste) async {
    final prefs = await SharedPreferences.getInstance();
    final idListesi = liste.map((h) => h.id).toList();
    await prefs.setString(anahtarAd, jsonEncode(idListesi));
  }

  static Future<List<AntrenmanGecmisi>> gecmisiOku() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliVeri = prefs.getString(gecmisAnahtar);
    if (kayitliVeri == null) return [];
    final List<dynamic> jsonList = jsonDecode(kayitliVeri);
    return jsonList.map((json) => AntrenmanGecmisi.fromJson(json)).toList();
  }

  static Future<void> gecmisiKaydet(List<AntrenmanGecmisi> gecmis) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = gecmis.map((g) => g.toJson()).toList();
    await prefs.setString(gecmisAnahtar, jsonEncode(jsonList));
  }

  static Future<void> gecmiseEkle(AntrenmanGecmisi yeni) async {
    final gecmis = await gecmisiOku();
    final yeniGecmis = [yeni, ...gecmis];
    await gecmisiKaydet(yeniGecmis);
  }

  static Future<bool> onboardingGosterildiMi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingAnahtar) ?? false;
  }

  static Future<void> onboardingGosterildi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingAnahtar, true);
  }

  static Future<String?> temaOku() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(temaAnahtar);
  }

  static Future<void> temaKaydet(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(temaAnahtar, tema);
  }
}

// ============================================
// SPLASH EKRANI 
// ============================================
class SplashEkrani extends StatefulWidget {
  const SplashEkrani({super.key});

  @override
  State<SplashEkrani> createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7)));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8)));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Renkler.koyuCam, Renkler.koyuCam.withValues(alpha: 0.8), const Color(0xFF1A3A2E)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Uygulama Simgesi (Daire içinde fitness ikonu)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'AsanaFit',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sağlıklı Yaşam, Güçlü Adımlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black12,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Yükleniyor animasyonu
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================
// ONBOARDING EKRANI (SADECE İLK AÇILIŞTA)
// ============================================
class OnboardingEkrani extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingEkrani({super.key, required this.onComplete});

  @override
  State<OnboardingEkrani> createState() => _OnboardingEkraniState();
}

class _OnboardingEkraniState extends State<OnboardingEkrani> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _sayfalar = [
    {'icon': Icons.fitness_center, 'title': 'Hareket Kütüphanesi', 'desc': 'Yoga, Pilates ve Spor hareketlerinden oluşan geniş kütüphaneye göz at.', 'color': Renkler.yogaRengi},
    {'icon': Icons.playlist_add, 'title': 'Kendi Listenizi Oluşturun', 'desc': 'Sevdiğiniz hareketleri ekleyerek kişisel antrenman listenizi oluşturun.', 'color': Renkler.pilatesRengi},
    {'icon': Icons.directions_walk, 'title': 'Adımlarınızı Takip Edin', 'desc': 'Günlük adım hedefinizi belirleyin ve ilerlemenizi grafiklerle izleyin.', 'color': Renkler.sporRengi},
    {'icon': Icons.history, 'title': 'Antrenman Geçmişi', 'desc': 'Tamamladığınız antrenmanları kaydedin ve gelişiminizi takip edin.', 'color': Renkler.koyuCam},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _sayfalar.length,
              itemBuilder: (context, index) {
                final s = _sayfalar[index];
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: s['color'].withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: s['color'].withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(s['icon'], size: 72, color: s['color']),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        s['title'],
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s['desc'],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Renkler.metinSoluk(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Renkler.yuzey(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(_sayfalar.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? Renkler.koyuCam 
                            : Renkler.koyuCam.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _sayfalar.length - 1) {
                      widget.onComplete();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Renkler.koyuCam,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentPage == _sayfalar.length - 1 ? 'Başla' : 'İleri',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

// ============================================
// ANA UYGULAMA
// ============================================
class SporUygulamasi extends StatefulWidget {
  const SporUygulamasi({super.key});

  @override
  State<SporUygulamasi> createState() => _SporUygulamasiState();
}

class _SporUygulamasiState extends State<SporUygulamasi> {
  ThemeMode _temaModu = ThemeMode.light;
  List<Hareket> benimListem = [];
  bool yukleniyor = true;
  bool onboardingGosterilsin = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final onboardingGosterildi = await KayitServisi.onboardingGosterildiMi();
    final kayitliListe = await KayitServisi.listeyiOku();
    final temaKayitli = await KayitServisi.temaOku();
    
    ThemeMode tema = ThemeMode.light;
    if (temaKayitli == 'dark') tema = ThemeMode.dark;
    else if (temaKayitli == 'system') tema = ThemeMode.system;

    setState(() {
      benimListem = kayitliListe;
      _temaModu = tema;
      onboardingGosterilsin = !onboardingGosterildi;
      yukleniyor = false;
    });
  }

  void _temaDegistir(ThemeMode yeniTema) async {
    String? kayit;
    if (yeniTema == ThemeMode.dark) kayit = 'dark';
    else if (yeniTema == ThemeMode.system) kayit = 'system';
    else kayit = 'light';
    await KayitServisi.temaKaydet(kayit);
    setState(() => _temaModu = yeniTema);
  }

  void hareketEkle(Hareket hareket) {
    setState(() { if (!benimListem.contains(hareket)) benimListem.add(hareket); });
    KayitServisi.listeyiKaydet(benimListem);
  }

  void hareketCikar(Hareket hareket) {
    setState(() { benimListem.remove(hareket); });
    KayitServisi.listeyiKaydet(benimListem);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsanaFit',
      debugShowCheckedModeBanner: false,
      themeMode: _temaModu,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: yukleniyor
          ? const SplashEkrani()
          : onboardingGosterilsin
              ? OnboardingEkrani(onComplete: () async {
                  await KayitServisi.onboardingGosterildi();
                  setState(() => onboardingGosterilsin = false);
                })
              : AnaEkran(
                  benimListem: benimListem,
                  onEkle: hareketEkle,
                  onCikar: hareketCikar,
                  temaModu: _temaModu,
                  onTemaDegistir: _temaDegistir,
                ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Renkler.acikArkaPlan,
      colorScheme: const ColorScheme.light(primary: Renkler.koyuCam, surface: Renkler.acikYuzey),
      useMaterial3: true,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Renkler.acikMetinKoyu),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Renkler.acikMetinKoyu),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Renkler.acikMetinKoyu),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Renkler.acikMetinKoyu),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Renkler.acikMetinKoyu),
        bodyLarge: TextStyle(fontSize: 16, color: Renkler.acikMetinKoyu, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: Renkler.acikMetinKoyu, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: Renkler.acikMetinSoluk),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Renkler.koyuCam,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Renkler.acikYuzey,
        indicatorColor: Renkler.koyuCam.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Renkler.acikMetinKoyu)),
      ),
      cardTheme: CardThemeData(
        color: Renkler.acikYuzey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Renkler.koyuArkaPlan,
      colorScheme: const ColorScheme.dark(primary: Renkler.koyuCam, surface: Renkler.koyuYuzey),
      useMaterial3: true,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Renkler.koyuMetinKoyu),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Renkler.koyuMetinKoyu),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Renkler.koyuMetinKoyu),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Renkler.koyuMetinKoyu),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Renkler.koyuMetinKoyu),
        bodyLarge: TextStyle(fontSize: 16, color: Renkler.koyuMetinKoyu, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: Renkler.koyuMetinKoyu, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: Renkler.koyuMetinSoluk),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Renkler.koyuCam,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Renkler.koyuYuzey,
        indicatorColor: Renkler.koyuCam.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Renkler.koyuMetinKoyu)),
      ),
      cardTheme: CardThemeData(
        color: Renkler.koyuYuzey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
    );
  }
}

// ============================================
// ANA EKRAN
// ============================================
class AnaEkran extends StatefulWidget {
  final List<Hareket> benimListem;
  final Function(Hareket) onEkle;
  final Function(Hareket) onCikar;
  final ThemeMode temaModu;
  final Function(ThemeMode) onTemaDegistir;

  const AnaEkran({super.key, required this.benimListem, required this.onEkle, required this.onCikar, required this.temaModu, required this.onTemaDegistir});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int seciliSekme = 0;

  @override
  Widget build(BuildContext context) {
    final ekranlar = [
      HareketListesiEkrani(onEkle: widget.onEkle),
      BenimListemEkrani(benimListem: widget.benimListem, onCikar: widget.onCikar),
      const AdimSayarEkrani(),
      const AntrenmanGecmisiEkrani(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AsanaFit'),
        actions: [
          IconButton(
            icon: Icon(widget.temaModu == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final yeniTema = widget.temaModu == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              widget.onTemaDegistir(yeniTema);
            },
          ),
        ],
      ),
      body: ekranlar[seciliSekme],
      bottomNavigationBar: NavigationBar(
        selectedIndex: seciliSekme,
        onDestinationSelected: (index) => setState(() => seciliSekme = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Hareketler'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Listem'),
          NavigationDestination(icon: Icon(Icons.directions_walk_outlined), selectedIcon: Icon(Icons.directions_walk), label: 'Adımlarım'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Geçmiş'),
        ],
      ),
    );
  }
}

// ============================================
// ORTAK BİLEŞENLER
// ============================================
class KategoriGlifi extends StatelessWidget {
  final String kategori;
  final double boyut;
  const KategoriGlifi({super.key, required this.kategori, this.boyut = 44});

  @override
  Widget build(BuildContext context) {
    final renk = Renkler.kategoriRengi(kategori);
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(color: renk.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(Renkler.kategoriIkonu(kategori), color: renk, size: boyut * 0.5),
    );
  }
}

class StilKart extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  const StilKart({super.key, required this.child, this.backgroundColor, this.padding});

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Renkler.yuzey(context);
    final borderColor = Renkler.kartKenar(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class SeciliKutucuk extends StatelessWidget {
  final String etiket;
  final bool secili;
  final Color renk;
  final VoidCallback onTap;
  const SeciliKutucuk({super.key, required this.etiket, required this.secili, required this.renk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: secili ? renk : Renkler.yuzey(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: secili ? renk : Renkler.metinSoluk(context).withValues(alpha: 0.3)),
        ),
        child: Text(etiket, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secili ? Colors.white : Renkler.metinKoyu(context))),
      ),
    );
  }
}

// ============================================
// EKRAN 1: HAREKET KÜTÜPHANESİ
// ============================================
class HareketListesiEkrani extends StatefulWidget {
  final Function(Hareket) onEkle;
  const HareketListesiEkrani({super.key, required this.onEkle});

  @override
  State<HareketListesiEkrani> createState() => _HareketListesiEkraniState();
}

class _HareketListesiEkraniState extends State<HareketListesiEkrani> {
  String seciliKategori = 'Tümü';
  String seciliAltKategori = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final kategoriler = kategoriListesiOlustur();

    List<Hareket> filtrelenmisListe = seciliKategori == 'Tümü'
        ? tumHareketler
        : tumHareketler.where((h) => h.kategori == seciliKategori).toList();

    final sporSecili = seciliKategori == 'Spor';
    if (sporSecili && seciliAltKategori != 'Tümü') {
      filtrelenmisListe = filtrelenmisListe.where((h) => h.altKategori == seciliAltKategori).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hareket Kütüphanesi')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: kategoriler.map((kategori) {
                final secili = kategori == seciliKategori;
                final renk = kategori == 'Tümü' ? Renkler.koyuCam : Renkler.kategoriRengi(kategori);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SeciliKutucuk(
                    etiket: kategori,
                    secili: secili,
                    renk: renk,
                    onTap: () => setState(() { seciliKategori = kategori; seciliAltKategori = 'Tümü'; }),
                  ),
                );
              }).toList(),
            ),
          ),
          if (sporSecili) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['Tümü', 'Aletsiz', 'Aletli'].map((altKategori) {
                  final secili = altKategori == seciliAltKategori;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SeciliKutucuk(
                      etiket: altKategori,
                      secili: secili,
                      renk: Renkler.sporRengi,
                      onTap: () => setState(() { seciliAltKategori = altKategori; }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: filtrelenmisListe.isEmpty
                ? Center(child: Text('Bu kategoride hareket yok.', style: Theme.of(context).textTheme.bodySmall))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: filtrelenmisListe.length,
                    itemBuilder: (context, index) {
                      final hareket = filtrelenmisListe[index];
                      return StilKart(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: KategoriGlifi(kategori: hareket.kategori),
                          title: Text(hareket.isim, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(
                            hareket.altKategori != null
                                ? '${hareket.kategori} • ${hareket.altKategori} • ${hareket.zorluk}'
                                : '${hareket.kategori} • ${hareket.zorluk}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Icon(Icons.chevron_right, color: Renkler.metinSoluk(context)),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HareketDetayEkrani(hareket: hareket, onEkle: widget.onEkle)));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// EKRAN 2: HAREKET DETAYI
// ============================================
class HareketDetayEkrani extends StatelessWidget {
  final Hareket hareket;
  final Function(Hareket) onEkle;
  const HareketDetayEkrani({super.key, required this.hareket, required this.onEkle});

  @override
  Widget build(BuildContext context) {
    final renk = Renkler.kategoriRengi(hareket.kategori);
    return Scaffold(
      appBar: AppBar(title: Text(hareket.isim)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: Renkler.yuzey(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: renk.withValues(alpha: 0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: hareket.gorselYolu != null
                    ? Image.asset(hareket.gorselYolu!, width: double.infinity, height: 240, fit: BoxFit.contain)
                    : Container(
                        color: renk.withValues(alpha: 0.14),
                        child: Center(
                          child: Icon(Renkler.kategoriIkonu(hareket.kategori), size: 88, color: renk),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                KategoriGlifi(kategori: hareket.kategori, boyut: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _etiketKutusu(hareket.kategori, renk),
                      if (hareket.altKategori != null) _etiketKutusu(hareket.altKategori!, renk),
                      _etiketKutusu(hareket.zorluk, Renkler.metinSoluk(context)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Vücuttaki İşlevi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(hareket.aciklama, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Renkler.koyuCam,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Listeme Ekle'),
                onPressed: () {
                  onEkle(hareket);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${hareket.isim} listene eklendi')));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiketKutusu(String metin, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: renk.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(metin, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: renk)),
    );
  }
}

// ============================================
// EKRAN 3: BENİM LİSTEM
// ============================================
class BenimListemEkrani extends StatelessWidget {
  final List<Hareket> benimListem;
  final Function(Hareket) onCikar;
  const BenimListemEkrani({super.key, required this.benimListem, required this.onCikar});

  void antrenmaniBaslat(BuildContext context, int baslangicIndeksi) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AntrenmanOynaticiEkrani(hareketler: benimListem, baslangicIndeksi: baslangicIndeksi)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benim Listem')),
      body: benimListem.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add, size: 56, color: Renkler.metinSoluk(context)),
                    const SizedBox(height: 12),
                    Text('Listen henüz boş', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text('Hareketler sekmesinden istediğin hareketleri ekleyerek kendi programını oluştur.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Renkler.koyuCam,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Antrenmanı Başlat'),
                      onPressed: () => antrenmaniBaslat(context, 0),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: benimListem.length,
                    itemBuilder: (context, index) {
                      final hareket = benimListem[index];
                      return StilKart(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: KategoriGlifi(kategori: hareket.kategori),
                          title: Text(hareket.isim, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(hareket.kategori, style: Theme.of(context).textTheme.bodySmall),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Renkler.metinSoluk(context),
                            onPressed: () => onCikar(hareket),
                          ),
                          onTap: () => antrenmaniBaslat(context, index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================
// ANTRENMAN OYNATICI
// ============================================
enum OynatimTuru { hareket, hazirlik }

class OynatimAdimi {
  final OynatimTuru tur;
  final Hareket? hareket;
  final int sureSaniye;
  const OynatimAdimi({required this.tur, this.hareket, required this.sureSaniye});
}

class AntrenmanOynaticiEkrani extends StatefulWidget {
  final List<Hareket> hareketler;
  final int baslangicIndeksi;
  const AntrenmanOynaticiEkrani({super.key, required this.hareketler, this.baslangicIndeksi = 0});

  @override
  State<AntrenmanOynaticiEkrani> createState() => _AntrenmanOynaticiEkraniState();
}

class _AntrenmanOynaticiEkraniState extends State<AntrenmanOynaticiEkrani> with SingleTickerProviderStateMixin {
  static const int hareketSuresi = 30;
  static const int hazirlikSuresi = 15;

  late List<OynatimAdimi> adimlar;
  late PageController _sayfaKontrolcusu;
  late int mevcutAdimIndeksi;
  late int kalanSaniye;
  Timer? _zamanlayici;
  bool duraklatildi = false;
  late AnimationController _gecisController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    adimlar = _oynatimListesiOlustur();

    _gecisController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _gecisController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _gecisController, curve: Curves.easeOutCubic));

    int baslangicAdimIndeksi = 0;
    for (int i = 0; i < adimlar.length; i++) {
      if (adimlar[i].tur == OynatimTuru.hareket && adimlar[i].hareket == widget.hareketler[widget.baslangicIndeksi]) {
        baslangicAdimIndeksi = i;
        break;
      }
    }

    mevcutAdimIndeksi = baslangicAdimIndeksi;
    kalanSaniye = adimlar[mevcutAdimIndeksi].sureSaniye;
    _sayfaKontrolcusu = PageController(initialPage: mevcutAdimIndeksi);
    _zamanlayiciBaslat();
    _gecisController.forward();
  }

  List<OynatimAdimi> _oynatimListesiOlustur() {
    final liste = <OynatimAdimi>[];
    for (final hareket in widget.hareketler) {
      final aletliMi = hareket.kategori == 'Spor' && hareket.altKategori == 'Aletli';
      if (aletliMi) {
        liste.add(OynatimAdimi(tur: OynatimTuru.hazirlik, hareket: hareket, sureSaniye: hazirlikSuresi));
      }
      liste.add(OynatimAdimi(tur: OynatimTuru.hareket, hareket: hareket, sureSaniye: hareketSuresi));
    }
    return liste;
  }

  void _zamanlayiciBaslat() {
    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (_) {
      if (duraklatildi) return;
      setState(() {
        if (kalanSaniye > 1) {
          kalanSaniye--;
        } else {
          _sonrakiAdimaGec();
        }
      });
    });
  }

  void _sonrakiAdimaGec() {
    if (mevcutAdimIndeksi < adimlar.length - 1) {
      _gecisController.reset();
      setState(() {
        mevcutAdimIndeksi++;
        kalanSaniye = adimlar[mevcutAdimIndeksi].sureSaniye;
      });
      _sayfaKontrolcusu.animateToPage(mevcutAdimIndeksi, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _gecisController.forward();
    } else {
      _zamanlayici?.cancel();
      _antrenmanBitti();
    }
  }

  void _oncekiAdimaGec() {
    if (mevcutAdimIndeksi > 0) {
      _gecisController.reset();
      setState(() {
        mevcutAdimIndeksi--;
        kalanSaniye = adimlar[mevcutAdimIndeksi].sureSaniye;
      });
      _sayfaKontrolcusu.animateToPage(mevcutAdimIndeksi, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _gecisController.forward();
    }
  }

  Future<void> _antrenmanBitti() async {
    final gecmis = AntrenmanGecmisi(
      tarih: DateTime.now(),
      hareketIdleri: widget.hareketler.map((h) => h.id).toList(),
      tamamlananSure: adimlar.length * 30,
    );
    await KayitServisi.gecmiseEkle(gecmis);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Antrenman Tamamlandı! 🎉'),
        content: const Text('Tüm hareketleri başarıyla tamamladın.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    _sayfaKontrolcusu.dispose();
    _gecisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adim = adimlar[mevcutAdimIndeksi];
    final renk = adim.hareket != null ? Renkler.kategoriRengi(adim.hareket!.kategori) : Renkler.sporRengi;

    return Scaffold(
      backgroundColor: Renkler.arkaPlan(context),
      appBar: AppBar(
        title: Text('${mevcutAdimIndeksi + 1} / ${adimlar.length}'),
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            child: LinearProgressIndicator(
              value: (mevcutAdimIndeksi + 1) / adimlar.length,
              backgroundColor: renk.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(renk),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _sayfaKontrolcusu,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adimlar.length,
              itemBuilder: (context, index) {
                final gosterilecekAdim = adimlar[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: gosterilecekAdim.tur == OynatimTuru.hazirlik
                        ? _hazirlikGorunumu(gosterilecekAdim)
                        : _hareketGorunumu(gosterilecekAdim),
                  ),
                );
              },
            ),
          ),
          _kontrolCubugu(),
        ],
      ),
    );
  }

  Widget _hazirlikGorunumu(OynatimAdimi adim) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 72, color: Renkler.sporRengi),
          const SizedBox(height: 20),
          Text('Ekipmanını Hazırla', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Sıradaki hareket: ${adim.hareket?.isim ?? ""}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          _sayacGorunumu(),
        ],
      ),
    );
  }

  Widget _hareketGorunumu(OynatimAdimi adim) {
    final hareket = adim.hareket!;
    final renk = Renkler.kategoriRengi(hareket.kategori);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: Renkler.yuzey(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: renk.withValues(alpha: 0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: hareket.gorselYolu != null
                  ? Image.asset(hareket.gorselYolu!, width: double.infinity, height: 260, fit: BoxFit.contain)
                  : Container(color: renk.withValues(alpha: 0.14), child: Icon(Renkler.kategoriIkonu(hareket.kategori), size: 88, color: renk)),
            ),
          ),
          const SizedBox(height: 20),
          Text(hareket.isim, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(hareket.aciklama, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _sayacGorunumu(),
        ],
      ),
    );
  }

  Widget _sayacGorunumu() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Text('$kalanSaniye', key: ValueKey(kalanSaniye), style: Theme.of(context).textTheme.displayLarge),
        ),
        Text('saniye', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _kontrolCubugu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Renkler.yuzey(context),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_previous),
            color: Renkler.metinKoyu(context),
            onPressed: mevcutAdimIndeksi > 0 ? _oncekiAdimaGec : null,
          ),
          IconButton(
            iconSize: 56,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(duraklatildi ? Icons.play_circle_fill : Icons.pause_circle_filled, key: ValueKey(duraklatildi)),
            ),
            color: Renkler.koyuCam,
            onPressed: () => setState(() => duraklatildi = !duraklatildi),
          ),
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_next),
            color: Renkler.metinKoyu(context),
            onPressed: () => setState(() => _sonrakiAdimaGec()),
          ),
        ],
      ),
    );
  }
}

// ============================================
// EKRAN 4: ADIM SAYAR
// ============================================
class AdimSayarEkrani extends StatefulWidget {
  const AdimSayarEkrani({super.key});

  @override
  State<AdimSayarEkrani> createState() => _AdimSayarEkraniState();
}

class _AdimSayarEkraniState extends State<AdimSayarEkrani> {
  static const String _anahtarBaslangicTarih = 'adim_baslangic_tarih';
  static const String _anahtarHedef = 'adim_hedef';
  static const String _anahtarHaftalikVeri = 'haftalik_adim_verisi';
  static const int varsayilanHedef = 8000;
  static const String _anahtarSonHamDeger = 'son_ham_sensor_degeri';
  static const String _anahtarBugunToplam = 'bugun_toplam_adim';
  Stream<StepCount>? _stepCountStream;
  StreamSubscription<StepCount>? _subscription;
  
  int _gunlukAdim = 0;
  int _gunlukHedef = varsayilanHedef;
  int? _sonHamDeger;
  bool _izinVerildi = false;
  bool _yukleniyor = true;
  String _durumMesaji = '';
  List<int> _haftalikVeri = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _hedefiYukle();
    _haftalikVeriyiYukle();
    _bugunToplamiYukle(); // ✅ FIX: kayıtlı bugünkü adımı hemen göster, sensörden ilk olayı bekleme
    _adimSayariniBaslat();
  }

  // ✅ FIX: BUGÜNKÜ TOPLAMI HEMEN YÜKLE
  // Daha önce kaydedilmiş "bugun_toplam_adim" değerini SharedPreferences'tan
  // okuyup ekrana/bildirime hemen yazar. Böylece kullanıcı uygulamayı açtığında
  // yeni bir sensör olayı (yani fiziksel bir adım) gelene kadar beklemek zorunda kalmaz.
  Future<void> _bugunToplamiYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bugun = _tarihAnahtari(DateTime.now());
      final kayitliTarih = prefs.getString(_anahtarBaslangicTarih);

      // Kayıtlı tarih bugünle aynıysa, kayıtlı toplamı ve ham sensör değerini geri yükle
      final int kayitliToplam = (kayitliTarih == bugun)
          ? (prefs.getInt(_anahtarBugunToplam) ?? 0)
          : 0;
      final int? kayitliHam = prefs.getInt(_anahtarSonHamDeger);

      if (mounted) {
        setState(() {
          _gunlukAdim = kayitliToplam;
          _sonHamDeger = kayitliHam;
        });
        if (kayitliToplam > 0) {
          BildirimServisi.adimBildirimiGuncelle(_gunlukAdim, _gunlukHedef);
        }
      }
    } catch (e) {
      debugPrint('Bugünkü toplam yükleme hatası: $e');
    }
  }

  // ✅ HEDEF YÜKLE
  Future<void> _hedefiYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kayitliHedef = prefs.getInt(_anahtarHedef);
      if (kayitliHedef != null) {
        setState(() => _gunlukHedef = kayitliHedef);
      }
    } catch (e) {
      debugPrint('Hedef yükleme hatası: $e');
    }
  }

  // ✅ HAFTALIK VERİ YÜKLE
  Future<void> _haftalikVeriyiYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kayitliVeri = prefs.getString(_anahtarHaftalikVeri);
      if (kayitliVeri != null) {
        final List<dynamic> decoded = jsonDecode(kayitliVeri);
        if (decoded.length == 7) {
          setState(() => _haftalikVeri = decoded.map((e) => e as int).toList());
          return;
        }
      }
    } catch (e) {
      debugPrint('Haftalık veri yükleme hatası: $e');
    }
    setState(() => _haftalikVeri = List.filled(7, 0));
  }

  // ✅ HAFTALIK VERİ KAYDET
  Future<void> _haftalikVeriyiKaydet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_anahtarHaftalikVeri, jsonEncode(_haftalikVeri));
    } catch (e) {
      debugPrint('Haftalık veri kaydetme hatası: $e');
    }
  }

  // ✅ HEDEF KAYDET
  Future<void> _hedefiKaydet(int yeniHedef) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_anahtarHedef, yeniHedef);
      setState(() => _gunlukHedef = yeniHedef);
    } catch (e) {
      debugPrint('Hedef kaydetme hatası: $e');
    }
  }

  // ✅ ADIM SAYARINI BAŞLAT 
  Future<void> _adimSayariniBaslat() async {
    try {
      // İzin kontrolü
      final status = await Permission.activityRecognition.request();
      // Android 13+ için bildirim izni ayrıca istenmeli
      await Permission.notification.request();
      
      if (!status.isGranted) {
        setState(() {
          _izinVerildi = false;
          _yukleniyor = false;
          _durumMesaji = 'Adım sayabilmek için "Fiziksel Aktivite" iznine ihtiyacımız var.';
        });
        return;
      }

      setState(() {
        _izinVerildi = true;
        _yukleniyor = true;
      });

      // Stream'i oluştur
      _stepCountStream = Pedometer.stepCountStream;
      
      // Abone ol
      _subscription = _stepCountStream?.listen(
        _onStepCount,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('✅ Adım sayar başlatıldı. İzin durumu: $status');

      // İlk veri gelene kadar bekle
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
        BildirimServisi.adimBildirimiGuncelle(_gunlukAdim, _gunlukHedef);
      }

    } catch (e) {
      debugPrint('❌ Adım sayar başlatma hatası: $e');
      setState(() {
        _yukleniyor = false;
        _durumMesaji = 'Adım sayar başlatılamadı: $e';
      });
    }
  }

  // ✅ ADIM GELDİĞİNDE 
void _onStepCount(StepCount event) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bugun = _tarihAnahtari(DateTime.now());
    final kayitliTarih = prefs.getString(_anahtarBaslangicTarih);

    int bugunToplam = prefs.getInt(_anahtarBugunToplam) ?? 0;
    final int? sonGorulenHam = prefs.getInt(_anahtarSonHamDeger);

    if (kayitliTarih != bugun) {
      bugunToplam = 0;
      await prefs.setString(_anahtarBaslangicTarih, bugun);
    } else if (sonGorulenHam != null) {
      if (event.steps >= sonGorulenHam) {
        bugunToplam += (event.steps - sonGorulenHam);
      } else {
        bugunToplam += event.steps;
      }
    }

    // İlk kez sensör verisi geliyorsa anchor olarak kaydet
    await prefs.setInt(_anahtarSonHamDeger, event.steps);
    await prefs.setInt(_anahtarBugunToplam, bugunToplam);

    _sonHamDeger = event.steps;

    // ✅ FIX: Haftalık grafik verisini de güncelle ve kaydet.
    // Daha önce bu adım hiç atılmıyordu, bu yüzden sütun grafik hep sıfır kalıyordu.
    final gunIndex = DateTime.now().weekday - 1; // 0=Pzt ... 6=Paz
    if (gunIndex >= 0 && gunIndex < _haftalikVeri.length) {
      _haftalikVeri[gunIndex] = bugunToplam;
      await _haftalikVeriyiKaydet();
    }
    
    if (mounted) {
      setState(() {
        _gunlukAdim = bugunToplam;
        _yukleniyor = false;
      });
      BildirimServisi.adimBildirimiGuncelle(_gunlukAdim, _gunlukHedef);
    }
  } catch (e) {
    debugPrint('Hata: $e');
  }
}

  // ✅ HATA YÖNETİMİ
  void _onError(Object error) {
    debugPrint('❌ Pedometer hatası: $error');
    if (mounted) {
      setState(() {
        _yukleniyor = false;
        _durumMesaji = 'Adım sensörü hatası: $error';
      });
    }
  }

  // ✅ İŞLEM TAMAMLANDI
  void _onDone() {
    debugPrint('✅ Pedometer tamamlandı');
  }

  // ✅ TARİH ANAHTARI
  String _tarihAnahtari(DateTime tarih) => '${tarih.year}-${tarih.month}-${tarih.day}';

  // ✅ GÜNLÜK SAYACI SIFIRLA
  
Future<void> _gunlukSayaciSifirla() async {
  if (_sonHamDeger == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final bugun = _tarihAnahtari(DateTime.now());
    await prefs.setString(_anahtarBaslangicTarih, bugun);
    await prefs.setInt(_anahtarSonHamDeger, _sonHamDeger!);
    await prefs.setInt(_anahtarBugunToplam, 0);

    // ✅ FIX: bugünün haftalık grafik sütununu da sıfırla
    final gunIndex = DateTime.now().weekday - 1;
    if (gunIndex >= 0 && gunIndex < _haftalikVeri.length) {
      _haftalikVeri[gunIndex] = 0;
      await _haftalikVeriyiKaydet();
    }

    setState(() => _gunlukAdim = 0);
    debugPrint('🔄 Adım sayacı sıfırlandı');
  } catch (e) {
    debugPrint('❌ Sıfırlama hatası: $e');
  }
}
  

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ✅ HEDEF DÜZENLEME DİYALOĞU
  Future<void> _hedefDuzenlemeDiyalogu() async {
    final controller = TextEditingController(text: '$_gunlukHedef');
    final yeniDeger = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Hedefini Belirle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hedef adım sayısı'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () {
              final girilenDeger = int.tryParse(controller.text);
              if (girilenDeger != null && girilenDeger > 0) {
                Navigator.pop(context, girilenDeger);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (yeniDeger != null) _hedefiKaydet(yeniDeger);
  }

  // ✅ SIFIRLAMA ONAY DİYALOĞU
  Future<void> _sifirlamaOnayDiyalogu() async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adım Sayacını Sıfırla'),
        content: const Text('Bugünkü adım sayısı sıfırlanacak. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sıfırla')),
        ],
      ),
    );
    if (onaylandi == true) _gunlukSayaciSifirla();
  }

  // ✅ BUILD
  @override
  Widget build(BuildContext context) {
    final oran = (_gunlukAdim / _gunlukHedef).clamp(0.0, 1.0);
    final kalori = (_gunlukAdim * 0.04).round();
    final kilometre = (_gunlukAdim * 0.0007).toStringAsFixed(2);
    final kalanHedef = (_gunlukHedef - _gunlukAdim).clamp(0, _gunlukHedef);
    final maxHaftalik = _haftalikVeri.isEmpty ? 1 : _haftalikVeri.reduce((a, b) => a > b ? a : b);
    final gunIsimleri = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adımlarım'),
        actions: _izinVerildi
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Sıfırla',
                  onPressed: _sifirlamaOnayDiyalogu,
                ),
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Yenile',
                  onPressed: () {
                    setState(() => _yukleniyor = true);
                    _adimSayariniBaslat();
                  },
                ),
              ]
            : null,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : !_izinVerildi
              ? _izinIsteniyorGorunumu()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: oran,
                              strokeWidth: 12,
                              backgroundColor: Renkler.koyuCam.withValues(alpha: 0.10),
                              valueColor: AlwaysStoppedAnimation(Renkler.koyuCam),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text('$_gunlukAdim', 
                                    key: ValueKey(_gunlukAdim),
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
                                  ),
                                ),
                                Text('adım', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text('Kalan: $kalanHedef',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600, 
                                    color: Renkler.metinSoluk(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _hedefDuzenlemeDiyalogu,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Günlük hedef: $_gunlukHedef adım',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: Renkler.metinSoluk(context)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: StilKart(
                              child: Column(
                                children: [
                                  Icon(Icons.map_outlined, color: Renkler.koyuCam, size: 22),
                                  const SizedBox(height: 6),
                                  Text('$kilometre km', 
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  Text('Mesafe', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StilKart(
                              child: Column(
                                children: [
                                  Icon(Icons.local_fire_department_outlined, color: Renkler.koyuCam, size: 22),
                                  const SizedBox(height: 6),
                                  Text('$kalori kcal', 
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  Text('Kalori', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ============================================
// HAFTALIK GRAFİK (SADELEŞTİRİLMİŞ)
// ============================================
StilKart(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Son 7 Gün', 
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      const SizedBox(height: 16),
      // 🔧 FIX: SingleChildScrollView ile kaydırılabilir yap
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final deger = _haftalikVeri[index];
            final yukseklik = maxHaftalik > 0 ? (deger / maxHaftalik) * 80 : 0.0;
            final gunAdi = gunIsimleri[index];
            final bugunMu = index == DateTime.now().weekday - 1;
            
            return Container(
              width: 40, // Sabit genişlik
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (deger > 0)
                    Text(
                      deger.toString(),
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    width: 16,
                    height: yukseklik > 0 ? yukseklik.toDouble() : 4.0,
                    decoration: BoxDecoration(
                      color: bugunMu ? Renkler.koyuCam : Renkler.koyuCam.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gunAdi,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: bugunMu ? FontWeight.w700 : FontWeight.w400,
                      color: bugunMu ? Renkler.metinKoyu(context) : Renkler.metinSoluk(context),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    ],
  ),
),
                      const SizedBox(height: 16),
                      if (oran >= 1.0)
                        StilKart(
                          backgroundColor: Renkler.sporRengi.withValues(alpha: 0.12),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events, color: Renkler.sporRengi, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Bugünkü hedefine ulaştın, tebrikler! 🎉',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _izinIsteniyorGorunumu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, size: 56, color: Renkler.metinSoluk(context)),
            const SizedBox(height: 16),
            Text('İzin Gerekli', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(_durumMesaji, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Renkler.koyuCam, 
                foregroundColor: Colors.white,
              ),
              onPressed: openAppSettings,
              child: const Text('Ayarları Aç'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _adimSayariniBaslat, 
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// EKRAN 5: ANTRENMAN GEÇMİŞİ
// ============================================
class AntrenmanGecmisiEkrani extends StatefulWidget {
  const AntrenmanGecmisiEkrani({super.key});

  @override
  State<AntrenmanGecmisiEkrani> createState() => _AntrenmanGecmisiEkraniState();
}

class _AntrenmanGecmisiEkraniState extends State<AntrenmanGecmisiEkrani> {
  List<AntrenmanGecmisi> gecmis = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _gecmisiYukle();
  }

  Future<void> _gecmisiYukle() async {
    final veri = await KayitServisi.gecmisiOku();
    setState(() {
      gecmis = veri;
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Geçmişi'),
        actions: [
          if (gecmis.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final onay = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Geçmişi Temizle'),
                    content: const Text('Tüm geçmiş kayıtlar silinecek. Emin misin?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Temizle')),
                    ],
                  ),
                );
                if (onay == true) {
                  await KayitServisi.gecmisiKaydet([]);
                  setState(() => gecmis = []);
                }
              },
            ),
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : gecmis.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 56, color: Renkler.metinSoluk(context)),
                        const SizedBox(height: 12),
                        Text('Henüz geçmiş kayıt yok', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text('Bir antrenmanı tamamladığında burada görünecek.',
                            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gecmis.length,
                  itemBuilder: (context, index) {
                    final kayit = gecmis[index];
                    final hareketler = kayit.hareketIdleri
                        .map((id) => tumHareketler.firstWhere((h) => h.id == id, orElse: () => tumHareketler.first))
                        .toList();
                    final dakika = (kayit.tamamlananSure / 60).round();
                    return StilKart(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTarih(kayit.tarih), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Renkler.koyuCam.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('$dakika dk', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Renkler.koyuCam)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: hareketler.map((h) {
                              final renk = Renkler.kategoriRengi(h.kategori);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(h.isim, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: renk)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.fitness_center, size: 14, color: Renkler.metinSoluk(context)),
                              const SizedBox(width: 4),
                              Text('${hareketler.length} hareket', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTarih(DateTime tarih) {
    final now = DateTime.now();
    final fark = now.difference(tarih);
    if (fark.inDays == 0) return 'Bugün ${_formatSaat(tarih)}';
    if (fark.inDays == 1) return 'Dün ${_formatSaat(tarih)}';
    if (fark.inDays < 7) return '${fark.inDays} gün önce';
    return '${tarih.day}.${tarih.month}.${tarih.year}';
  }

  String _formatSaat(DateTime tarih) => '${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
}