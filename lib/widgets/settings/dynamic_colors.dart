import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:projectx/theme/theme.dart';

class DynamicColorsSettings extends StatefulWidget {
  const DynamicColorsSettings({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DynamicColorsSettingsState createState() => _DynamicColorsSettingsState();
}

class _DynamicColorsSettingsState extends State<DynamicColorsSettings> {
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return ListTile(
      title: Text(AppLocalizations.of(context)!.dynamicColors),
      subtitle: Text(AppLocalizations.of(context)!.dynamicColorsSub),
      trailing: Switch(
        activeColor: Colors.blue,
        value: themeModel.isDynamicColorsEnabled,
        onChanged: (value) {
          themeModel.toggleDynamicColors();
          themeModel.saveDynamicPreference(value);
        },
      ),
    );
  }
}
