// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui'; // Import necessário para o BackdropFilter

import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/theme/theme.dart';
import 'package:provider/provider.dart'; // Importe o Provider aqui se não estiver global

class ThemeSettings extends StatelessWidget {
  final ThemeModel themeModel;

  const ThemeSettings({super.key, required this.themeModel});

  // MÉTODO _showThemeDialog TOTALMENTE REFEITO
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      // Permite que o fundo seja transparente
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        // StatefulBuilder é essencial para que a UI do diálogo se atualize
        // ao selecionar uma nova opção, sem fechar a tela de fundo.
        return StatefulBuilder(
          builder: (context, setState) {
            // O widget Dialog nos dá o formato base de um diálogo
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
                            // setState é chamado para atualizar o ícone de check
                            setState(() {});
                            // Um pequeno delay antes de fechar dá tempo para a animação do tap
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

  // NOVO: Widget auxiliar para construir cada opção de tema de forma estilizada
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
    // É necessário obter o ThemeModel aqui para passar para a função
    final themeModel = Provider.of<ThemeModel>(context, listen: false);
    final appLocalizations = AppLocalizations.of(context)!;

    // Define o subtítulo com base no tema atual
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
