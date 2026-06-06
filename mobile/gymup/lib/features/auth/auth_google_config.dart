class AuthGoogleConfig {
  static const androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '51666031528-l84iutqu53jjufufksvelnidtoj0av6i.apps.googleusercontent.com',
  );

  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '51666031528-8isbr5jhlfvdvg47ijht3i0b3l0kdkr6.apps.googleusercontent.com',
  );

  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '51666031528-8isbr5jhlfvdvg47ijht3i0b3l0kdkr6.apps.googleusercontent.com',
  );
}
