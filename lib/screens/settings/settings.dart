import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:projectx/theme/theme.dart';
import 'package:projectx/widgets/settings/about.dart';
import 'package:projectx/widgets/settings/category.dart';
import 'package:projectx/widgets/settings/dynamic_colors.dart';
import 'package:projectx/widgets/settings/review.dart';
import 'package:projectx/widgets/settings/support.dart';
import 'package:projectx/widgets/settings/theme.dart';
import 'package:projectx/widgets/settings/update.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          buildCategoryHeader(
              AppLocalizations.of(context)!.interface, Icons.palette_outlined),
          ThemeSettings(themeModel: themeModel),
          const DynamicColorsSettings(),
          buildCategoryHeader(
              AppLocalizations.of(context)!.outhers, Icons.more_horiz_outlined),
          buildUpdateSettings(context),
          buildReviewSettings(context),
          buildSupportSettings(context),
          buildAboutSettings(context),
        ],
      ),
    );
  }
}
