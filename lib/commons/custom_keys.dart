class CustomKeys {
  CustomKeys._();

  /// Login
  static const userName = 'Kullanıcı Adı';
  static const email = 'E-mail';
  static const password = 'Password';
  static const buttonNameIn = 'Giriş Yap';
  static const buttonNameUp = 'Kayıt Ol';
  static const myAccount = 'Hesabım Var';

  @Deprecated('Use myAccount instead')
  static const myAccunt = myAccount;

  /// Services Keys
  static const successSignUp = 'Kayıt Başarılı';
  static const errorSignUp = 'Kayıt Başarısız';
  static const successLogin = 'Giriş Başarılı';
  static const successLogOut = 'Çıkış Başarılı';
  static const errorLogin = 'Şifre ya da E-mail Hatalı Tekrar Deneyiniz';

  @Deprecated('Use successSignUp instead')
  static const succesSignUp = successSignUp;

  @Deprecated('Use successLogin instead')
  static const succesLogin = successLogin;

  @Deprecated('Use successLogOut instead')
  static const succesLogOut = successLogOut;
}
