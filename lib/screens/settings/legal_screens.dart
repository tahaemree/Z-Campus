import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Privacy Policy',
      content: '''
[UYGULAMA ADI] Mobil Uygulaması Gizlilik Politikası

Son Güncelleme Tarihi: 2 Mayıs 2025

İşbu Gizlilik Politikası, [Uygulama Adı] mobil uygulaması ("Uygulama") aracılığıyla topladığımız, kullandığımız, açıkladığımız ve koruduğumuz kişisel verilerinize ilişkin uygulamalarımızı açıklamaktadır. Uygulamayı kullanarak, işbu Gizlilik Politikası'nda açıklanan şartları kabul etmektesiniz.

1. Toplanan Kişisel Veriler

Uygulamamız, size kampüs içi navigasyon, hizmet bilgilendirmesi ve etkileşim imkanları sunmak amacıyla çeşitli türde kişisel veriler toplayabilir. Topladığımız veri türleri, Uygulama içindeki etkileşimlerinize ve kullandığınız özelliklere bağlı olarak değişebilir. Bu verilere örnek olarak aşağıdakiler verilebilir:

Konum Verileri: Kampüs içinde doğru navigasyon hizmeti sunabilmek amacıyla, Uygulama kullanımınız sırasında hassas konum verileriniz toplanabilir. Bu veriler, gerçek zamanlı olarak konumunuzu belirlemek ve size en uygun rota ve ilgili bina/hizmet bilgilerini sağlamak için kullanılır. Konum verilerinizin toplanması ve kullanılması tamamen sizin izninize tabidir.

Kullanım Verileri: Uygulamayı nasıl kullandığınıza ilişkin veriler toplanabilir. Bu veriler anonimleştirilmiş veya toplu halde olabilir ve Uygulamanın performansını artırmak, popüler özellikleri belirlemek ve kullanıcı deneyimini iyileştirmek için kullanılır. Örnek olarak, ziyaret ettiğiniz sayfalar, kullandığınız özellikler ve harcanan süre gibi bilgiler verilebilir.

Cihaz Bilgileri: Uygulamaya erişmek için kullandığınız cihaz türü, işletim sistemi, benzersiz cihaz tanımlayıcıları ve mobil ağ bilgileri gibi teknik bilgiler otomatik olarak toplanabilir. Bu bilgiler, Uygulamanın farklı cihazlarda düzgün çalışmasını sağlamak ve teknik sorunları gidermek amacıyla kullanılır.

İletişim Verileri: Uygulama içindeki etkileşim özellikleri (örneğin, geri bildirim formları veya destek talepleri) aracılığıyla bizimle paylaştığınız iletişim bilgileriniz (e-posta adresi gibi) toplanabilir ve taleplerinize yanıt vermek amacıyla kullanılabilir.

Kampüs Hizmetleri Etkileşim Verileri: Uygulama üzerinden kampüs hizmetleri (yemekhane menüsü görüntüleme, kütüphane çalışma saatlerini kontrol etme vb.) ile etkileşimlerinize ilişkin veriler, size daha iyi hizmet sunmak ve Uygulamayı ilgili kampüs olanaklarıyla entegre etmek amacıyla toplanabilir.

Kullanıcı Etkileşim Verileri: Uygulama içindeki sosyal veya etkileşimli özelliklerin (varsa) kullanımı sırasında paylaştığınız bilgiler (anonim geri bildirimler, genel yorumlar vb.) Uygulamanın topluluk yönünü desteklemek amacıyla, uygun kullanım politikalarımız çerçevesinde kullanılabilir.

2. Kişisel Verilerin Kullanım Amaçları

Topladığımız kişisel veriler aşağıdaki amaçlarla kullanılabilir:

- Kampüs içi navigasyon hizmeti sağlamak.
- Kampüsteki binalar, hizmetler ve olanaklar hakkında bilgi sunmak.
- Hizmetlerin çalışma saatleri, menüler (varsa) gibi güncel bilgileri sağlamak.
- Uygulamanın özelliklerini ve işlevselliğini sağlamak ve geliştirmek.
- Kullanıcı deneyimini kişiselleştirmek ve iyileştirmek.
- Uygulama kullanımına ilişkin analizler yapmak ve istatistiksel bilgiler oluşturmak.
- Teknik sorunları gidermek ve Uygulamanın güvenliğini sağlamak.
- Kullanıcı taleplerine ve geri bildirimlerine yanıt vermek.
- Uygulama ile ilgili önemli güncellemeler veya duyurular hakkında bilgi vermek.
- Yasal yükümlülüklerimize uymak.

3. Kişisel Verilerin Paylaşılması

Kişisel verileriniz, aşağıda belirtilen durumlar haricinde üçüncü taraflarla paylaşılmaz:

- Hukuki Yükümlülükler: Yasal gerekliliklere uymak, mahkeme emirlerine yanıt vermek veya yasal süreçlere katılmak amacıyla kişisel verileriniz yetkili kurumlarla paylaşılabilir.
- Hizmet Sağlayıcılar: Uygulamanın işletilmesi ve size hizmet sunulması için gerekli olan üçüncü taraf hizmet sağlayıcılarla, yalnızca belirli hizmetleri yerine getirmeleri amacıyla sınırlı olmak üzere kişisel verileriniz paylaşılabilir.
- Anonimleştirilmiş veya Toplu Veriler: Kişisel kimliğinizin belirlenmesine olanak tanımayan veriler, çeşitli amaçlarla üçüncü taraflarla paylaşılabilir.
- Onayınız: Kişisel verilerinizin üçüncü taraflarla paylaşılması konusunda açık rızanızın alınması durumunda paylaşım yapılabilir.

4. Veri Güvenliği

Kişisel verilerinizin yetkisiz erişim, kullanım veya açıklanmaya karşı korunması için uygun fiziksel, teknik ve idari güvenlik önlemlerini almaktayız. Ancak, internet üzerinden yapılan hiçbir veri aktarımının veya elektronik depolamanın %100 güvenli olduğu garanti edilemez.

5. Kişisel Verilerinizin Saklanması

Kişisel verileriniz, toplandığı amacın gerektirdiği süre boyunca veya ilgili yasal düzenlemeler uyarınca saklanacaktır. Kullanım amacının ortadan kalkması veya yasal saklama süresinin dolması halinde kişisel verileriniz silinecek veya anonim hale getirilecektir.

6. Kullanıcı Hakları

KVKK uyarınca aşağıdaki haklara sahipsiniz:

- Kişisel verilerinizin işlenip işlenmediğini öğrenme
- Kişisel verileriniz işlenmişse bilgi talep etme
- İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme
- Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme
- Eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme
- Silinmesini veya yok edilmesini isteme
- Otomatik sistemler vasıtasıyla analiz edilmesi sonucu aleyhinize çıkan sonuca itiraz etme
- Kanuna aykırı işleme sebebiyle zararın giderilmesini talep etme

7. Gizlilik Politikasındaki Değişiklikler

İşbu Gizlilik Politikası'nı zaman zaman güncelleyebiliriz. Güncellenmiş Gizlilik Politikası Uygulamada yayınlandığı anda yürürlüğe girer. Önemli değişiklikler yapılması durumunda sizi Uygulama aracılığıyla veya uygun diğer yollarla bilgilendirebiliriz.

8. İletişim

Gizlilik Politikası ile ilgili sorularınız için:

[E-posta Adresi]
[Telefon Numarası]
[Web Sitesi]

9. Yürürlülük

İşbu Gizlilik Politikası 2 Mayıs 2025 tarihinde yürürlüğe girmiştir.
      ''',
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Terms of Service',
      content: '''
[UYGULAMA ADI] Mobil Uygulaması Kullanım Koşulları

Son Güncelleme Tarihi: 2 Mayıs 2025

İşbu Kullanım Koşulları, [Uygulama Adı] mobil uygulamasının ("Uygulama") kullanımına ilişkin şartları ve koşulları belirlemektedir. Uygulamayı indirerek, kurarak veya kullanarak, işbu Kullanım Koşulları'nın tamamını okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan ve taahhüt etmektesiniz. İşbu Koşulları kabul etmiyorsanız, Uygulamayı kullanmamanız gerekmektedir.

1. Uygulamanın Sağladığı Hizmetler

Uygulama, kullanıcılara kampüs ortamında çeşitli hizmetler sunmaktadır. Bu hizmetler genel olarak şunları içerebilir:

- Kampüs içi binalara, hizmetlere ve önemli noktalara yönelik navigasyon ve yol tarifi.
- Kampüs hizmetleri (yemekhane, kütüphane, spor tesisleri vb.) hakkında güncel bilgiler (çalışma saatleri, menüler, duyurular vb.).
- Kampüsle ilgili etkinlikler ve duyurular hakkında bilgilendirme.
- Kullanıcılar arasında etkileşimi teşvik eden özellikler (varsa ve Gizlilik Politikasına uygun olarak).
- Kampüs yaşamını kolaylaştırmaya yönelik diğer ilgili özellikler ve bilgiler.

Uygulamanın kapsamı ve sunulan hizmetler zaman içinde güncellenebilir ve değiştirilebilir.

2. Kullanıcı Yükümlülükleri ve Sorumlulukları

Uygulamayı kullanırken aşağıdaki yükümlülüklere uymayı kabul etmektesiniz:

- Uygulamayı yalnızca yasalara ve işbu Kullanım Koşulları'na uygun olarak kullanmak.
- Uygulamayı kampüs ortamıyla ilgili amaçlar dışında kullanmamak.
- Uygulama üzerinden paylaştığınız bilgilerin doğru, güncel ve eksiksiz olmasını sağlamak.
- Uygulamanın işleyişine müdahale etmemek veya Uygulamaya zarar verecek eylemlerde bulunmamak.
- Diğer kullanıcıların Uygulama kullanımını engellememek veya ihlal etmemek.
- Uygulama aracılığıyla Fikri Mülkiyet haklarını ihlal eden içerikler paylaşmamak.
- Uygulama üzerinden yasa dışı, rahatsız edici, karalayıcı, iftira niteliğinde veya ahlaka aykırı içerikler paylaşmamak.
- Uygulama üzerinden yetkisiz erişim sağlamaya çalışmamak veya Uygulamanın güvenlik önlemlerini aşmaya teşebbüs etmemek.
- Uygulama kullanımınızdan doğacak her türlü sorumluluğun size ait olduğunu kabul etmek.

Uygulamayı bu koşullara aykırı şekilde kullanmanız durumunda, Uygulamayı kullanımınız askıya alınabilir veya sonlandırılabilir ve doğabilecek her türlü yasal sorumluluk size ait olacaktır.

3. Fikri Mülkiyet Hakları

Uygulamanın tüm içeriği, yazılımı, tasarımları, logoları, grafikleri ve diğer fikri mülkiyet hakları [Şirket/Kurum Adı]'na veya ilgili hak sahiplerine aittir ve ilgili yasalarla korunmaktadır.

- Uygulamayı kullanarak elde ettiğiniz bilgileri ticari amaçla kullanamaz, çoğaltamaz, dağıtamaz veya yayınlayamazsınız.
- Uygulama üzerindeki hiçbir telif hakkı, ticari marka veya diğer mülkiyet hakkı bildirimini kaldıramaz veya değiştiremezsiniz.
- Uygulamanın tersine mühendislik, kaynak koda dönüştürme veya parçalarına ayırma gibi eylemlerde bulunamazsınız.

İşbu Kullanım Koşulları size Uygulamayı kullanma konusunda sınırlı, münhasır olmayan, devredilemez bir lisans vermektedir. Uygulama üzerindeki diğer tüm haklar saklıdır.

4. Sorumluluk Reddi

Uygulama "olduğu gibi" ve "mevcut olduğu şekilde" sunulmaktadır. [Şirket/Kurum Adı], Uygulamanın kesintisiz, hatasız veya güvenli olacağına dair açık veya zımni hiçbir garanti vermemektedir.

- Uygulama aracılığıyla sunulan kampüs hizmetleri bilgileri (çalışma saatleri, menüler vb.) güncel olmayabilir. Bu bilgilerin doğruluğundan ve güncelliğinden [Şirket/Kurum Adı] sorumlu değildir. Kullanıcılar, kritik bilgiler için ilgili kampüs birimleriyle teyit sağlamalıdır.
- Uygulama aracılığıyla sağlanan navigasyon hizmeti, dış etkenler (GPS sinyalinin zayıflığı, harita verilerinin güncel olmaması vb.) nedeniyle her zaman tam doğru sonuç vermeyebilir. Kullanıcılar, navigasyon hizmetini kullanırken dikkatli olmalı ve çevrelerini gözlemlemelidir.
- Uygulamanın kullanımından kaynaklanabilecek doğrudan veya dolaylı zararlardan [Şirket/Kurum Adı] sorumlu tutulamaz.

5. Sorumluluğun Sınırlandırılması

Yürürlükteki yasaların izin verdiği en geniş ölçüde, [Şirket/Kurum Adı], Uygulamanın kullanımından veya kullanılamamasından kaynaklanan kar kaybı, veri kaybı veya diğer maddi/manevi zararlar dahil ancak bunlarla sınırlı olmamak üzere hiçbir durumda sorumlu olmayacaktır.

6. Üçüncü Taraf Bağlantıları ve İçerikleri

Uygulama, üçüncü taraf web sitelerine, hizmetlerine veya içeriklerine bağlantılar içerebilir. Bu bağlantılar yalnızca kolaylık sağlamak amacıyla sunulmaktadır. [Şirket/Kurum Adı], bu üçüncü taraf web sitelerinin, hizmetlerinin veya içeriklerinin doğruluğu, güncelliği veya güvenliği üzerinde herhangi bir kontrole sahip değildir ve bunlardan sorumlu tutulamaz. Üçüncü taraf bağlantılarına erişiminiz kendi riskinizdedir ve ilgili üçüncü tarafın kullanım koşulları ve gizlilik politikaları geçerlidir.

7. Kullanım Koşullarında Değişiklikler

İşbu Kullanım Koşulları'nı dilediğimiz zaman güncelleme hakkını saklı tutmaktayız. Güncellenmiş Kullanım Koşulları Uygulamada yayınlandığı anda yürürlüğe girer. Önemli değişiklikler yapılması durumunda sizi Uygulama aracılığıyla veya uygun diğer yollarla bilgilendirebiliriz. Değişikliklerden sonra Uygulamayı kullanmaya devam etmeniz, güncellenmiş Kullanım Koşulları'nı kabul ettiğiniz anlamına gelir.

8. Askıya Alma ve Sonlandırma

İşbu Kullanım Koşulları'na uymamanız durumunda, Uygulamayı kullanımınızı herhangi bir bildirimde bulunmaksızın derhal askıya alabilir veya sonlandırabiliriz. Kullanımınızın askıya alınması veya sonlandırılması durumunda Uygulamaya erişim hakkınız sona erecektir.

9. Uygulanacak Hukuk ve Yetkili Mahkeme

İşbu Kullanım Koşulları, Türkiye Cumhuriyeti yasalarına tabi olacaktır. İşbu Kullanım Koşulları'ndan doğacak her türlü uyuşmazlığın çözümünde [Şirket/Kurum Adı]'nın bulunduğu yer mahkemeleri ve icra daireleri yetkilidir.

10. İletişim

İşbu Kullanım Koşulları ile ilgili sorularınız için lütfen aşağıdaki iletişim bilgilerini kullanarak bizimle iletişime geçin:

[Şirket/Kurum Adı]
[Adres]
[E-posta Adresi]
[Telefon Numarası]
[Web Sitesi]

11. Yürürlülük

İşbu Kullanım Koşulları 2 Mayıs 2025 tarihinde yürürlüğe girmiştir.
      ''',
    );
  }
}
