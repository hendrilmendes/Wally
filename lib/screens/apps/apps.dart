// ignore_for_file: deprecated_member_use

import 'package:projectx/screens/home/home.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncher {
  static Future<void> handleAppRequest(
      String message, Function(ChatMessage) addMessage) async {
    final lowerCaseMessage = message.toLowerCase();
    String? appUrlScheme;
    String? appStoreUrl;

    if (lowerCaseMessage.contains("whatsapp")) {
      appUrlScheme = "whatsapp://send?phone=";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.whatsapp";
    } else if (lowerCaseMessage.contains("instagram")) {
      appUrlScheme = "instagram://user?username=";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.instagram.android";
    } else if (lowerCaseMessage.contains("facebook")) {
      appUrlScheme = "fb://profile/";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.facebook.katana";
    } else if (lowerCaseMessage.contains("tiktok")) {
      appUrlScheme = "com.zhiliaoapp.musically://";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.zhiliaoapp.musically";
    } else if (lowerCaseMessage.contains("youtube")) {
      appUrlScheme = "vnd.youtube://";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.google.android.youtube";
    } else if (lowerCaseMessage.contains("youtube music")) {
      appUrlScheme = "vnd.youtube.music://";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.google.android.apps.youtube.music";
    } else if (lowerCaseMessage.contains("spotify")) {
      appUrlScheme = "spotify://";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=com.spotify.music";
    } else if (lowerCaseMessage.contains("telegram")) {
      appUrlScheme = "tg://";
      appStoreUrl =
          "https://play.google.com/store/apps/details?id=org.telegram.messenger";
    } else {
      addMessage(ChatMessage(
        role: Role.chatGPT,
        content: "Desculpe, não sei como abrir esse aplicativo.",
        name: "Wally",
      ));
      return;
    }

    bool isAppInstalled = await canLaunch(appUrlScheme);
    if (isAppInstalled) {
      await launch(appUrlScheme);
    } else {
      if (await canLaunch(appStoreUrl)) {
        await launch(appStoreUrl);
      } else {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content:
              "Não consegui abrir o aplicativo nem redirecionar para a loja de apps.",
          name: "Wally",
        ));
      }
    }
  }
}
