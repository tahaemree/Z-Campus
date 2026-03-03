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
      title: 'Gizlilik Politikası',
      content: '''
Campus Online Mobil Uygulaması Gizlilik Politikası

Son Güncelleme Tarihi: 2 Mayıs 2025

İşbu Gizlilik Politikası, Campus Online mobil uygulaması ("Uygulama") aracılığıyla topladığımız, kullandığımız, açıkladığımız ve koruduğumuz kişisel verilerinize ilişkin uygulamalarımızı açıklamaktadır. Uygulamayı kullanarak, işbu Gizlilik Politikası'nda açıklanan şartları kabul etmektesiniz.

1. Toplanan Kişisel Veriler

Uygulamamız, size kampüs içi navigasyon, hizmet bilgilendirmesi ve etkileşim imkanları sunmak amacıyla çeşitli türde kişisel veriler toplayabilir. Topladığımız veri türleri, Uygulama içindeki etkileşimlerinize ve kullandığınız özelliklere bağlı olarak değişebilir. Bu verilere örnek olarak aşağıdakiler verilebilir:

Konum Verileri: Kampüs içinde doğru navigasyon hizmeti sunabilmek amacıyla, Uygulama kullanımınız sırasında hassas konum verileriniz toplanabilir. Bu veriler, gerçek zamanlı olarak konumunuzu belirlemek ve size en uygun rota ve ilgili bina/hizmet bilgilerini sağlamak için kullanılır. Konum verilerinizin toplanması ve kullanılması tamamen sizin izninize tabidir.

Kullanım Verileri: Uygulamayı nasıl kullandığınıza ilişkin veriler toplanabilir. Bu veriler anonimleştirilmiş veya toplu halde olabilir ve Uygulamanın performansını artırmak, popüler özellikleri belirlemek ve kullanıcı deneyimini iyileştirmek için kullanılır.

Cihaz Bilgileri: Uygulamaya erişmek için kullandığınız cihaz türü, işletim sistemi, benzersiz cihaz tanımlayıcıları ve mobil ağ bilgileri gibi teknik bilgiler otomatik olarak toplanabilir.

İletişim Verileri: Uygulama içindeki etkileşim özellikleri aracılığıyla bizimle paylaştığınız iletişim bilgileriniz (e-posta adresi gibi) toplanabilir.

Kampüs Hizmetleri Etkileşim Verileri: Uygulama üzerinden kampüs hizmetleri ile etkileşimlerinize ilişkin veriler toplanabilir.

2. Kişisel Verilerin Kullanım Amaçları

Topladığımız kişisel veriler aşağıdaki amaçlarla kullanılabilir:

- Kampüs içi navigasyon hizmeti sağlamak.
- Kampüsteki binalar, hizmetler ve olanaklar hakkında bilgi sunmak.
- Uygulamanın özelliklerini ve işlevselliğini sağlamak ve geliştirmek.
- Kullanıcı deneyimini kişiselleştirmek ve iyileştirmek.
- Teknik sorunları gidermek ve Uygulamanın güvenliğini sağlamak.
- Yasal yükümlülüklerimize uymak.

3. Kişisel Verilerin Paylaşılması

Kişisel verileriniz, yasal gereklilikler, hizmet sağlayıcılar ve açık rızanız dışında üçüncü taraflarla paylaşılmaz.

4. Veri Güvenliği

Kişisel verilerinizin yetkisiz erişim, kullanım veya açıklanmaya karşı korunması için uygun fiziksel, teknik ve idari güvenlik önlemlerini almaktayız.

5. Kullanıcı Hakları

KVKK uyarınca kişisel verilerinizin işlenip işlenmediğini öğrenme, düzeltilmesini veya silinmesini isteme haklarına sahipsiniz.

6. İletişim

Gizlilik Politikası ile ilgili sorularınız için: campusonline@iletisim.com

7. Yürürlülük

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
      title: 'Kullanım Koşulları',
      content: '''
Campus Online Mobil Uygulaması Kullanım Koşulları

Son Güncelleme Tarihi: 2 Mayıs 2025

İşbu Kullanım Koşulları, Campus Online mobil uygulamasının ("Uygulama") kullanımına ilişkin şartları ve koşulları belirlemektedir. Uygulamayı indirerek, kurarak veya kullanarak, işbu Kullanım Koşulları'nın tamamını okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan ve taahhüt etmektesiniz.

1. Uygulamanın Sağladığı Hizmetler

Uygulama, kullanıcılara kampüs ortamında çeşitli hizmetler sunmaktadır:

- Kampüs içi binalara, hizmetlere ve önemli noktalara yönelik navigasyon ve yol tarifi.
- Kampüs hizmetleri hakkında güncel bilgiler (çalışma saatleri, menüler, duyurular vb.).
- Kampüsle ilgili etkinlikler ve duyurular hakkında bilgilendirme.
- Kampüs yaşamını kolaylaştırmaya yönelik diğer ilgili özellikler ve bilgiler.

2. Kullanıcı Yükümlülükleri ve Sorumlulukları

Uygulamayı kullanırken:

- Uygulamayı yalnızca yasalara ve işbu Kullanım Koşulları'na uygun olarak kullanmayı,
- Uygulama üzerinden paylaştığınız bilgilerin doğru ve güncel olmasını sağlamayı,
- Uygulamanın işleyişine müdahale etmemeyi,
- Diğer kullanıcıların Uygulama kullanımını engellememeyi kabul etmektesiniz.

3. Fikri Mülkiyet Hakları

Uygulamanın tüm içeriği, yazılımı, tasarımları ve diğer fikri mülkiyet hakları Campus Online ekibine aittir ve ilgili yasalarla korunmaktadır.

4. Sorumluluk Reddi

Uygulama "olduğu gibi" sunulmaktadır. Uygulama aracılığıyla sunulan bilgiler güncel olmayabilir. Kullanıcılar, kritik bilgiler için ilgili kampüs birimleriyle teyit sağlamalıdır.

5. Uygulanacak Hukuk

İşbu Kullanım Koşulları, Türkiye Cumhuriyeti yasalarına tabidir.

6. İletişim

Kullanım Koşulları ile ilgili sorularınız için: campusonline@iletisim.com

7. Yürürlülük

İşbu Kullanım Koşulları 2 Mayıs 2025 tarihinde yürürlüğe girmiştir.
      ''',
    );
  }
}
