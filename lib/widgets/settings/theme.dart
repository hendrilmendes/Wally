// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/theme/theme.dart';
import 'package:provider/provider.dart';

class ThemeSettings extends StatelessWidget {
  final ThemeModel themeModel;

  const ThemeSettings({super.key, required this.themeModel});

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              // O conteúdo principal com o efeito de vidro
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.themeSelect,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        // Opções de tema
                        _buildThemeOption(
                          context: context,
                          title: AppLocalizations.of(context)!.lightMode,
                          value: ThemeModeType.light,
                          groupValue: themeModel.themeMode,
                          onChanged: (newValue) {
                            themeModel.changeThemeMode(newValue);
                            setState(() {});
                            Future.delayed(
                              const Duration(milliseconds: 200),
                            ).then((_) => Navigator.pop(context));
                          },
                        ),
                        _buildThemeOption(
                          context: context,
                          title: AppLocalizations.of(context)!.darkMode,
                          value: ThemeModeType.dark,
                          groupValue: themeModel.themeMode,
                          onChanged: (newValue) {
                            themeModel.changeThemeMode(newValue);
                            setState(() {});
                            Future.delayed(
                              const Duration(milliseconds: 200),
                            ).then((_) => Navigator.pop(context));
                          },
                        ),
                        _buildThemeOption(
                          context: context,
                          title: AppLocalizations.of(context)!.systemMode,
                          value: ThemeModeType.system,
                          groupValue: themeModel.themeMode,
                          onChanged: (newValue) {
                            themeModel.changeThemeMode(newValue);
                            setState(() {});
                            Future.delayed(
                              const Duration(milliseconds: 200),
                            ).then((_) => Navigator.pop(context));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required ThemeModeType value,
    required ThemeModeType groupValue,
    required Function(ThemeModeType) onChanged,
  }) {
    final bool isSelected = value == groupValue;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context, listen: false);
    final appLocalizations = AppLocalizations.of(context)!;

    String getSubtitle() {
      switch (themeModel.themeMode) {
        case ThemeModeType.light:
          return appLocalizations.lightMode;
        case ThemeModeType.dark:
          return appLocalizations.darkMode;
        case ThemeModeType.system:
        return appLocalizations.systemMode;
      }
    }

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(appLocalizations.theme),
      subtitle: Text(getSubtitle()),
      onTap: () {
        _showThemeDialog(context);
      },
    );
  }
}
