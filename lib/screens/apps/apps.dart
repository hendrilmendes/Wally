// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:projectx/screens/home/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:io' show Platform;

class AppLauncher {
  static Future<void> handleAppRequest(
      String message, Function(ChatMessage) addMessage) async {
    if (!kIsWeb && Platform.isAndroid) {
      final lowerCaseMessage = message.toLowerCase();
      String? packageName;
      String? appStoreUrl;

      if (lowerCaseMessage.contains("whatsapp")) {
        packageName = "com.whatsapp";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.whatsapp";
      } else if (lowerCaseMessage.contains("instagram")) {
        packageName = "com.instagram.android";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.instagram.android";
      } else if (lowerCaseMessage.contains("facebook")) {
        packageName = "com.facebook.katana";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.facebook.katana";
      } else if (lowerCaseMessage.contains("tiktok")) {
        packageName = "com.zhiliaoapp.musically";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.zhiliaoapp.musically";
      } else if (lowerCaseMessage.contains("youtube")) {
        packageName = "com.google.android.youtube";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.google.android.youtube";
      } else if (lowerCaseMessage.contains("youtube music")) {
        packageName = "com.google.android.apps.youtube.music";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.google.android.apps.youtube.music";
      } else if (lowerCaseMessage.contains("spotify")) {
        packageName = "com.spotify.music";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.spotify.music";
      } else if (lowerCaseMessage.contains("telegram")) {
        packageName = "org.telegram.messenger";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=org.telegram.messenger";
      } else if (lowerCaseMessage.contains("twitter")) {
        packageName = "com.twitter.android";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.twitter.android";
      } else if (lowerCaseMessage.contains("snapchat")) {
        packageName = "com.snapchat.android";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.snapchat.android";
      } else if (lowerCaseMessage.contains("linkedin")) {
        packageName = "com.linkedin.android";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.linkedin.android";
      } else if (lowerCaseMessage.contains("pinterest")) {
        packageName = "com.pinterest";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.pinterest";
      } else if (lowerCaseMessage.contains("discord")) {
        packageName = "com.discord";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.discord";
      } else if (lowerCaseMessage.contains("reddit")) {
        packageName = "com.reddit.frontpage";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.reddit.frontpage";
      } else if (lowerCaseMessage.contains("twitch")) {
        packageName = "tv.twitch.android.app";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=tv.twitch.android.app";
      } else if (lowerCaseMessage.contains("zoom")) {
        packageName = "us.zoom.videomeetings";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=us.zoom.videomeetings";
      } else if (lowerCaseMessage.contains("microsoft teams")) {
        packageName = "com.microsoft.teams";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.microsoft.teams";
      } else if (lowerCaseMessage.contains("netflix")) {
        packageName = "com.netflix.mediaclient";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.netflix.mediaclient";
      } else if (lowerCaseMessage.contains("disney plus")) {
        packageName = "com.disney.disneyplus";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.disney.disneyplus";
      } else if (lowerCaseMessage.contains("amazon prime")) {
        packageName = "com.amazon.avod.thirdpartyclient";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=com.amazon.avod.thirdpartyclient";
      } else if (lowerCaseMessage.contains("pluto tv")) {
        packageName = "tv.pluto.android";
        appStoreUrl =
            "https://play.google.com/store/apps/details?id=tv.pluto.android";
      } else {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Desculpe, não sei como abrir esse app.",
          name: "Wally",
        ));
        return;
      }

      if (kDebugMode) {
        print("Verificando se o app $packageName está instalado.");
      }

      bool isAppInstalled = await DeviceApps.isAppInstalled(packageName);

      if (isAppInstalled) {
        if (kDebugMode) {
          print("O app $packageName está instalado. Tentando abrir...");
        }
        bool didOpen = await DeviceApps.openApp(packageName);
        if (didOpen) {
          addMessage(ChatMessage(
            role: Role.chatGPT,
            content: "Abrindo o app solicitado: $packageName.",
            name: "Wally",
          ));
        } else {
          if (kDebugMode) {
            print("Falha ao abrir o app $packageName.");
          }
          addMessage(ChatMessage(
            role: Role.chatGPT,
            content: "Falha ao abrir o app.",
            name: "Wally",
          ));
        }
      } else {
        if (kDebugMode) {
          print(
              "O app $packageName não está instalado. Redirecionando para a Play Store.");
        }
        if (await canLaunch(appStoreUrl)) {
          await launch(appStoreUrl);
          addMessage(ChatMessage(
            role: Role.chatGPT,
            content:
                "O app não está instalado. Redirecionando para a Play Store.",
            name: "Wally",
          ));
        } else {
          addMessage(ChatMessage(
            role: Role.chatGPT,
            content:
                "Não consegui abrir o app nem redirecionar para a loja de apps.",
            name: "Wally",
          ));
        }
      }
    } else {
      if (kIsWeb) {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível na versão web.",
          name: "Wally",
        ));
      } else if (Platform.isIOS) {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível no iOS.",
          name: "Wally",
        ));
      } else if (Platform.isWindows) {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível no Windows.",
          name: "Wally",
        ));
      } else if (Platform.isLinux) {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível no Linux.",
          name: "Wally",
        ));
      } else if (Platform.isMacOS) {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível no macOS.",
          name: "Wally",
        ));
      } else {
        addMessage(ChatMessage(
          role: Role.chatGPT,
          content: "Esta funcionalidade não está disponível nesta plataforma.",
          name: "Wally",
        ));
      }
      return;
    }
  }
}
