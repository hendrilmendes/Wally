import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildReviewSettings(BuildContext context) {
  return ListTile(
    title: Text(AppLocalizations.of(context)!.review),
    subtitle: Text(AppLocalizations.of(context)!.reviewSub),
    leading: const Icon(Icons.rate_review_outlined),
    onTap: () async {
      final InAppReview inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        final hasReviewed = await checkReviewed();
        if (hasReviewed) {
          Fluttertoast.showToast(
            // ignore: use_build_context_synchronously
            msg: AppLocalizations.of(context)!.alreadyReviewed,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.grey[700],
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          inAppReview.requestReview();
          await markReviewed();
        }
      }
    },
  );
}

Future<bool> checkReviewed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasReviewed') ?? false;
}

Future<void> markReviewed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hasReviewed', true);
}
