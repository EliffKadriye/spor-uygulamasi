import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SporUygulamasi());
}

// ============================================
// RENK VE STİL PALETİ
// ============================================
class Renkler {
  static const Color arkaPlan = Color(0xFFEFF3EC); // yumuşak adaçayı-beyaz
  static const Color yuzeyBeyaz = Color(0xFFFFFFFF);
  static const Color koyuCam = Color(0xFF26473B); // ana marka rengi
  static const Color metinKoyu = Color(0xFF223026);
  static const Color metinSoluk = Color(0xFF6B7B70);

  static const Color yogaRengi = Color(0xFF6E5A7E); // erik/mürdüm
  static const Color pilatesRengi = Color(0xFF3E7C79); // teal
  static const Color sporRengi = Color(0xFFC98A3D); // hardal/altın

  static Color kategoriRengi(String kategori) {
    switch (kategori) {
      case 'Yoga':
        return yogaRengi;
      case 'Pilates':
        return pilatesRengi;
      case 'Spor':
        return sporRengi;
      default:
        return koyuCam;
    }
  }

  static IconData kategoriIkonu(String kategori) {
    switch (kategori) {
      case 'Yoga':
        return Icons.self_improvement;
      case 'Pilates':
        return Icons.accessibility_new;
      case 'Spor':
        return Icons.fitness_center;
      default:
        return Icons.circle;
    }
  }
}

// ============================================
// VERİ MODELİ: Bir hareketi temsil eden sınıf
// ============================================
class Hareket {
  final String id; // benzersiz tanımlayıcı (kaydetme için kullanılır)
  final String isim;
  final String kategori; // Yoga, Pilates, Spor
  final String? altKategori; // Sadece Spor için: Aletli / Aletsiz
  final String aciklama; // Vücuttaki işlevi/faydası
  final String zorluk; // Kolay, Orta, Zor
  final String? gorselYolu; // assets/gorseller/... altındaki dosya yolu

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

// ============================================
// ÖRNEK VERİ: Hareket kütüphanesi içeriği
// ============================================
final List<Hareket> tumHareketler = [
  // ---------- YOGA ----------
  const Hareket(
    id: 'yoga_child_pose',
    isim: 'Çocuk Pozu (Balasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_child_pose.png',
    aciklama:
        'Omurgayı uzatır, omuzları ve boynu rahatlatır. Zihni '
        'sakinleştirerek stresi azaltır.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_downward_dog',
    isim: 'Aşağı Bakan Köpek (Adho Mukha Svanasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_downward_dog.png',
    aciklama:
        'Bacak arkası kaslarını esnetir, kolları ve bacakları '
        'güçlendirir. Kan akışını dengeleyerek enerji verir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_cat_cow',
    isim: 'Kedi - İnek Akışı (Marjaryasana - Bitilasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_cat_cow.png',
    aciklama:
        'Omurganın esnekliğini artırır, sırt ve boyun ağrılarını '
        'hafifletir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_mountain_pose',
    isim: 'Dağ Pozu (Tadasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_mountain_pose.png',
    aciklama:
        'Duruşu (postürü) düzeltir, vücut farkındalığını ve dengesini '
        'artırır.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_warrior',
    isim: 'Savaşçı Duruşu (Virabhadrasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_warrior.png',
    aciklama:
        'Bacakları ve kalçaları güçlendirir, dayanıklılığı artırır ve '
        'özgüveni destekler.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'yoga_cobra',
    isim: 'Kobra Pozu (Bhujangasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_cobra.png',
    aciklama:
        'Göğüs kafesini açar, sırt kaslarını güçlendirir ve duruş '
        'bozukluklarına iyi gelir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'yoga_bridge',
    isim: 'Köprü Pozu (Setu Bandhasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_bridge.png',
    aciklama:
        'Kalça ve bacak kaslarını çalıştırır, karın organlarını uyarır '
        've sindirime yardım eder.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'yoga_corpse_pose',
    isim: 'Ceset Pozu (Savasana)',
    kategori: 'Yoga',
    gorselYolu: 'assets/gorseller/yoga_corpse_pose.png',
    aciklama:
        'Pratiğin sonunda tüm bedeni dinlendirir, sinir sistemini '
        'sakinleştirir ve zihinsel huzur sağlar.',
    zorluk: 'Kolay',
  ),

  // ---------- SPOR: ALETSİZ ----------
  const Hareket(
    id: 'spor_squat',
    isim: 'Squat',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_squat.png',
    aciklama:
        'Kalça, but ve baldır kaslarını çalıştırır. Alt vücut gücünü '
        've dengeyi geliştirir.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'spor_pushup',
    isim: 'Push-up (Şınav)',
    kategori: 'Spor',
    altKategori: 'Aletsiz',
    gorselYolu: 'assets/gorseller/spor_pushup.png',
    aciklama:
        'Göğüs, omuz, triceps ve core kaslarını çalıştırır. Üst '
        'vücut gücünü artırır.',
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
    aciklama:
        'Karın ve merkez (core) bölgesini sabit tutarak güçlendirir.',
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
    aciklama:
        'Tüm vücudu çalıştıran yüksek yoğunluklu yağ yakıcı bir '
        'harekettir.',
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
    aciklama:
        'Halter veya dambılla tüm arka zincir (sırt, kalça, bacak) '
        'kaslarını çalıştıran temel güç hareketidir.',
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

  // ---------- PİLATES: Karın ve Merkez (Core) ----------
  const Hareket(
    id: 'pilates_hundred',
    isim: 'The Hundred (Yüz)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_hundred.png',
    aciklama:
        'Sırt üstü yatıp bacakları ve başı havaya kaldırarak kolları '
        'aşağı yukarı hareket ettirme ve nefes dengeleme. Core kaslarını '
        've nefes kontrolünü güçlendirir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_criss_cross',
    isim: 'Criss Cross (Çapraz Mekik)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_criss_cross.png',
    aciklama:
        'Sırt üstü pozisyonda dizleri büküp dirseği zıt dizle '
        'buluşturarak alt karın kaslarını çalıştırma.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_roll_up',
    isim: 'Roll Up',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_roll_up.png',
    aciklama:
        'Sırt üstü uzanıp omurgayı tek tek kaldırarak gövdeyi öne '
        'doğru esnetme. Omurga esnekliğini ve core kontrolünü artırır.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_single_leg_stretch',
    isim: 'Single Leg Stretch',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_single_leg_stretch.png',
    aciklama:
        'Sırt üstü yatarak tek bacağı göğse çekip diğer bacağı uzatma. '
        'Karın kaslarını ve koordinasyonu geliştirir.',
    zorluk: 'Kolay',
  ),

  // ---------- PİLATES: Alt Vücut ve Sırt ----------
  const Hareket(
    id: 'pilates_glute_bridge',
    isim: 'Glute Bridge (Köprü Kurma)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_glute_bridge.png',
    aciklama:
        'Sırt üstü dizler bükülü yatarak kalçayı yukarı kaldırma ve '
        'kalça/arka bacak kaslarını çalıştırma.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_back_extension',
    isim: 'Back Extension (Sırta Esneme)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_back_extension.png',
    aciklama:
        'Yüzüstü yatarak elleri ve göğsü hafifçe yerden kaldırıp bel '
        'kaslarını güçlendirme.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_side_kick',
    isim: 'Side Kick (Yan Bacak)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_side_kick.png',
    aciklama:
        'Yan yatarak üstteki bacağı öne ve arkaya kontrollü sallama. '
        'Kalça yan kaslarını güçlendirir.',
    zorluk: 'Kolay',
  ),

  // ---------- PİLATES: Duruş ve Esneme ----------
  const Hareket(
    id: 'pilates_plank',
    isim: 'Plank',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_plank.png',
    aciklama:
        'Karın ve tüm vücut dayanıklılığını artıran ön destek duruşu. '
        'Omuz, sırt ve core kaslarını güçlendirir.',
    zorluk: 'Orta',
  ),
  const Hareket(
    id: 'pilates_mermaid',
    isim: 'Mermaid (Deniz Kızı)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_mermaid.png',
    aciklama:
        'Yanda oturarak gövdeyi yan tarafa uzatıp yan kaburga ve bel '
        'kaslarını esnetme.',
    zorluk: 'Kolay',
  ),
  const Hareket(
    id: 'pilates_swimming',
    isim: 'Swimming (Yüzme)',
    kategori: 'Pilates',
    gorselYolu: 'assets/gorseller/pilates_swimming.png',
    aciklama:
        'Yüzüstü pozisyonda zıt kol ve bacağı aynı anda yukarı '
        'kaldırma. Sırt ve core kaslarını güçlendirir, dengeyi geliştirir.',
    zorluk: 'Orta',
  ),
];

List<String> kategoriListesiOlustur() {
  final kategoriler = tumHareketler.map((h) => h.kategori).toSet().toList();
  kategoriler.sort();
  return ['Tümü', ...kategoriler];
}

// ============================================
// KAYIT YARDIMCISI: Listeyi telefon hafızasına
// kaydetme/okuma işlemleri
// ============================================
class KayitServisi {
  static const String anahtarAd = 'benim_listem';

  static Future<List<Hareket>> listeyiOku() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliVeri = prefs.getString(anahtarAd);
    if (kayitliVeri == null) return [];

    final List<dynamic> idListesi = jsonDecode(kayitliVeri);
    return tumHareketler
        .where((hareket) => idListesi.contains(hareket.id))
        .toList();
  }

  static Future<void> listeyiKaydet(List<Hareket> liste) async {
    final prefs = await SharedPreferences.getInstance();
    final idListesi = liste.map((h) => h.id).toList();
    await prefs.setString(anahtarAd, jsonEncode(idListesi));
  }
}

// ============================================
// ANA UYGULAMA: Tema ve ana ekranı ayarlar
// ============================================
class SporUygulamasi extends StatefulWidget {
  const SporUygulamasi({super.key});

  @override
  State<SporUygulamasi> createState() => _SporUygulamasiState();
}

class _SporUygulamasiState extends State<SporUygulamasi> {
  List<Hareket> benimListem = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    kayitliListeyiYukle();
  }

  Future<void> kayitliListeyiYukle() async {
    final kayitliListe = await KayitServisi.listeyiOku();
    setState(() {
      benimListem = kayitliListe;
      yukleniyor = false;
    });
  }

  void hareketEkle(Hareket hareket) {
    setState(() {
      if (!benimListem.contains(hareket)) {
        benimListem.add(hareket);
      }
    });
    KayitServisi.listeyiKaydet(benimListem);
  }

  void hareketCikar(Hareket hareket) {
    setState(() {
      benimListem.remove(hareket);
    });
    KayitServisi.listeyiKaydet(benimListem);
  }

  @override
  Widget build(BuildContext context) {
    final govdeYazi = GoogleFonts.manropeTextTheme();

    return MaterialApp(
      title: 'Spor Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Renkler.arkaPlan,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Renkler.koyuCam,
          primary: Renkler.koyuCam,
          surface: Renkler.yuzeyBeyaz,
        ),
        useMaterial3: true,
        textTheme: govdeYazi.copyWith(
          headlineMedium: GoogleFonts.fraunces(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Renkler.metinKoyu,
          ),
          titleLarge: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Renkler.metinKoyu,
          ),
          bodyMedium: GoogleFonts.manrope(
            fontSize: 15,
            color: Renkler.metinKoyu,
            height: 1.5,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Renkler.koyuCam,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Renkler.yuzeyBeyaz,
          indicatorColor: Renkler.koyuCam.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: yukleniyor
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : AnaEkran(
              benimListem: benimListem,
              onEkle: hareketEkle,
              onCikar: hareketCikar,
            ),
    );
  }
}

// ============================================
// ANA EKRAN: Alt sekmeli (Hareketler / Listem)
// ============================================
class AnaEkran extends StatefulWidget {
  final List<Hareket> benimListem;
  final Function(Hareket) onEkle;
  final Function(Hareket) onCikar;

  const AnaEkran({
    super.key,
    required this.benimListem,
    required this.onEkle,
    required this.onCikar,
  });

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int seciliSekme = 0;

  @override
  Widget build(BuildContext context) {
    final ekranlar = [
      HareketListesiEkrani(onEkle: widget.onEkle),
      BenimListemEkrani(
        benimListem: widget.benimListem,
        onCikar: widget.onCikar,
      ),
    ];

    return Scaffold(
      body: ekranlar[seciliSekme],
      bottomNavigationBar: NavigationBar(
        selectedIndex: seciliSekme,
        onDestinationSelected: (index) {
          setState(() {
            seciliSekme = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Hareketler',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Listem',
          ),
        ],
      ),
    );
  }
}

// ============================================
// ORTAK BİLEŞEN: Kategori rengiyle boyanmış
// dairesel ikon (tüm ekranlarda tutarlı kullanılır)
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
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Renkler.kategoriIkonu(kategori), color: renk, size: boyut * 0.5),
    );
  }
}

// Seçilebilir kategori/alt kategori kutucuğu (özel tasarım)
class SeciliKutucuk extends StatelessWidget {
  final String etiket;
  final bool secili;
  final Color renk;
  final VoidCallback onTap;

  const SeciliKutucuk({
    super.key,
    required this.etiket,
    required this.secili,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: secili ? renk : Renkler.yuzeyBeyaz,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: secili ? renk : Renkler.metinSoluk.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          etiket,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: secili ? Colors.white : Renkler.metinKoyu,
          ),
        ),
      ),
    );
  }
}

// ============================================
// EKRAN 1: Hareket Kütüphanesi (liste + kategori/alt kategori filtresi)
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
      filtrelenmisListe = filtrelenmisListe
          .where((h) => h.altKategori == seciliAltKategori)
          .toList();
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
                final renk = kategori == 'Tümü'
                    ? Renkler.koyuCam
                    : Renkler.kategoriRengi(kategori);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SeciliKutucuk(
                    etiket: kategori,
                    secili: secili,
                    renk: renk,
                    onTap: () {
                      setState(() {
                        seciliKategori = kategori;
                        seciliAltKategori = 'Tümü';
                      });
                    },
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
                      onTap: () {
                        setState(() {
                          seciliAltKategori = altKategori;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: filtrelenmisListe.isEmpty
                ? Center(
                    child: Text(
                      'Bu kategoride hareket yok.',
                      style: GoogleFonts.manrope(color: Renkler.metinSoluk),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: filtrelenmisListe.length,
                    itemBuilder: (context, index) {
                      final hareket = filtrelenmisListe[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Renkler.yuzeyBeyaz,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: KategoriGlifi(kategori: hareket.kategori),
                          title: Text(
                            hareket.isim,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: Renkler.metinKoyu,
                            ),
                          ),
                          subtitle: Text(
                            hareket.altKategori != null
                                ? '${hareket.kategori} • ${hareket.altKategori} • ${hareket.zorluk}'
                                : '${hareket.kategori} • ${hareket.zorluk}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Renkler.metinSoluk,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right,
                              color: Renkler.metinSoluk),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HareketDetayEkrani(
                                  hareket: hareket,
                                  onEkle: widget.onEkle,
                                ),
                              ),
                            );
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
// EKRAN 2: Hareket Detayı
// ============================================
class HareketDetayEkrani extends StatelessWidget {
  final Hareket hareket;
  final Function(Hareket) onEkle;

  const HareketDetayEkrani({
    super.key,
    required this.hareket,
    required this.onEkle,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Renkler.kategoriRengi(hareket.kategori);
    return Scaffold(
      appBar: AppBar(title: Text(hareket.isim)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Büyük illüstrasyon paneli. Hareketin kendi görseli
              // varsa (gorselYolu) onu gösterir; yoksa kategori ikonlu
              // basit bir yer tutucu gösterir.
              // BoxFit.contain kullanıyoruz ki görsel ORANI KORUNARAK
              // tamamı görünsün, hiçbir kenarı kesilmesin.
              hareket.gorselYolu != null
                  ? Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Renkler.yuzeyBeyaz,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: renk.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.asset(
                          hareket.gorselYolu!,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dekoratif arka daire (derinlik hissi verir)
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: renk.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            Renkler.kategoriIkonu(hareket.kategori),
                            size: 88,
                            color: renk,
                          ),
                          Positioned(
                            bottom: 14,
                            child: Text(
                              hareket.kategori,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: renk,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
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
                        if (hareket.altKategori != null)
                          _etiketKutusu(hareket.altKategori!, renk),
                        _etiketKutusu(hareket.zorluk, Renkler.metinSoluk),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Vücuttaki İşlevi',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(hareket.aciklama,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Renkler.koyuCam,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Listeme Ekle'),
                  onPressed: () {
                    onEkle(hareket);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${hareket.isim} listene eklendi')),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiketKutusu(String metin, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        metin,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: renk,
        ),
      ),
    );
  }
}

// ============================================
// EKRAN 3: Benim Listem
// ============================================
class BenimListemEkrani extends StatelessWidget {
  final List<Hareket> benimListem;
  final Function(Hareket) onCikar;

  const BenimListemEkrani({
    super.key,
    required this.benimListem,
    required this.onCikar,
  });

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
                    Icon(Icons.playlist_add,
                        size: 56, color: Renkler.metinSoluk),
                    const SizedBox(height: 12),
                    Text(
                      'Listen henüz boş',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hareketler sekmesinden istediğin hareketleri ekleyerek kendi programını oluştur.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                          color: Renkler.metinSoluk, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: benimListem.length,
              itemBuilder: (context, index) {
                final hareket = benimListem[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Renkler.yuzeyBeyaz,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: KategoriGlifi(kategori: hareket.kategori),
                    title: Text(
                      hareket.isim,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      hareket.kategori,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: Renkler.metinSoluk),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Renkler.metinSoluk,
                      onPressed: () => onCikar(hareket),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


