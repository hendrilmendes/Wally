import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:wiredash/wiredash.dart';

Widget buildSupportSettings(BuildContext context) {
  return ListTile(
    title: Text(AppLocalizations.of(context)!.support),
    subtitle: Text(AppLocalizations.of(context)!.supportSub),
    leading: const Icon(Icons.support_outlined),
    onTap: () {
      Wiredash.of(context).show(inheritMaterialTheme: true);
    },
  );
}
