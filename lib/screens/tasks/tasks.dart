// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/service/item.dart';
import 'package:url_launcher/url_launcher.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final ItemsService _itemsService = ItemsService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showItemFormModal({required bool isNote, Item? itemToEdit}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: itemToEdit?.title);
    final noteController = TextEditingController(text: itemToEdit?.note ?? '');
    DateTime? selectedDate = itemToEdit?.dateTime;
    final isCreating = itemToEdit == null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (modalContext, modalSetState) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isCreating
                            ? (isNote ? "Nova Anotação" : "Nova Tarefa")
                            : (isNote ? "Editar Anotação" : "Editar Tarefa"),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: isNote
                              ? "Título da Anotação"
                              : "O que você precisa fazer?",
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'O título é obrigatório.'
                            : null,
                      ),
                      if (isNote) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: noteController,
                          decoration: InputDecoration(
                            labelText: "Conteúdo da anotação",
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 5,
                          minLines: 3,
                        ),
                      ],
                      if (!isNote) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          label: Text(
                            selectedDate == null
                                ? "Agendar e notificar"
                                : DateFormat(
                                    'dd/MM/yyyy \'às\' HH:mm',
                                  ).format(selectedDate!),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date == null) return;

                            final time = await showTimePicker(
                              // ignore: use_build_context_synchronously
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                selectedDate ?? DateTime.now(),
                              ),
                            );
                            if (time == null) return;

                            modalSetState(
                              () => selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate() &&
                              _currentUser != null) {
                            final item = Item(
                              id: itemToEdit?.id ?? '',
                              title: titleController.text,
                              note: noteController.text.isNotEmpty
                                  ? noteController.text
                                  : null,
                              userId: _currentUser.uid,
                              isCompleted: itemToEdit?.isCompleted ?? false,
                              dateTime: isNote ? DateTime.now() : selectedDate,
                              isNote: isNote,
                            );
                            if (isCreating) {
                              await _itemsService.addItem(item);
                            } else {
                              await _itemsService.updateItem(item);
                            }
                            // ignore: use_build_context_synchronously
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: Text(
                          isCreating ? "Salvar" : "Salvar Alterações",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () =>
                  _showItemFormModal(isNote: _tabController.index == 1),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: isMobile
            ? _buildMobileContent(context)
            : _buildDesktopContent(context),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(
                l10n.tarefasApp,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              pinned: true,
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(0.7),
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              actions: [
                _buildDownloadButton(l10n, theme),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: l10n.tasks),
                  Tab(text: l10n.notes),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildItemsList(isNotesTab: false, l10n: l10n, isDesktop: false),
            _buildItemsList(isNotesTab: true, l10n: l10n, isDesktop: false),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Botão de voltar
              Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 8.0,
                  right: 8.0,
                  bottom: 0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.tarefasApp,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.check_box_outlined),
                      title: Text(l10n.tasks),
                      selected: _tabController.index == 0,
                      onTap: () => setState(() => _tabController.index = 0),
                      selectedTileColor: theme.colorScheme.primaryContainer,
                      selectedColor: theme.colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: Text(l10n.notes),
                      selected: _tabController.index == 1,
                      onTap: () => setState(() => _tabController.index = 1),
                      selectedTileColor: theme.colorScheme.primaryContainer,
                      selectedColor: theme.colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _buildDownloadButton(
                  l10n,
                  theme,
                ), // Botão de download na sidebar
              ),
              // Botão Adicionar para desktop, substituindo o FAB
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showItemFormModal(isNote: _tabController.index == 1),
                  icon: const Icon(Icons.add),
                  label: Text(
                    l10n.add,
                  ), // Supondo que você tenha "Adicionar" no l10n
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      50,
                    ), // Faz o botão ocupar a largura total
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Conteúdo Principal
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildItemsList(
                isNotesTab: false,
                l10n: l10n,
                isDesktop: true,
              ), // Desktop Tasks
              _buildItemsList(
                isNotesTab: true,
                l10n: l10n,
                isDesktop: true,
              ), // Desktop Notes
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList({
    required bool isNotesTab,
    required AppLocalizations l10n,
    required bool isDesktop, // Novo parâmetro para adaptar o layout
  }) {
    return StreamBuilder<List<Item>>(
      stream: _currentUser != null
          ? _itemsService.getCombinedStream(_currentUser.uid)
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isNotesTab, l10n);
        }
        final items = snapshot.data!
            .where((item) => item.isNote == isNotesTab)
            .toList();
        if (items.isEmpty) {
          return _buildEmptyState(isNotesTab, l10n);
        }

        // Adapta o layout da lista para desktop
        if (isNotesTab) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop
                  ? (MediaQuery.of(context).size.width > 900 ? 4 : 3)
                  : 2, // 4 colunas para desktop largo, 3 para desktop médio, 2 para mobile
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop
                  ? 1 / 1.1
                  : 1 / 1.2, // Ajusta a proporção
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildItemCard(items[index], Theme.of(context)),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildItemCard(items[index], Theme.of(context)),
          );
        }
      },
    );
  }

  Widget _buildItemCard(Item item, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: GestureDetector(
          onTap: () =>
              _showItemFormModal(isNote: item.isNote, itemToEdit: item),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.colorScheme.surface.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!item.isNote)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Checkbox(
                          value: item.isCompleted,
                          visualDensity: VisualDensity.compact,
                          onChanged: (bool? newValue) {
                            if (newValue != null &&
                                item.id != null &&
                                _currentUser != null) {
                              _itemsService.updateItem(
                                Item(
                                  id: item.id,
                                  title: item.title,
                                  note: item.note,
                                  userId: _currentUser.uid,
                                  isCompleted: newValue,
                                  dateTime: item.dateTime,
                                  isNote: item.isNote,
                                ),
                              );
                            }
                          },
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Icon(
                          Icons.note_alt_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: item.isNote ? 2 : null,
                        overflow: item.isNote ? TextOverflow.ellipsis : null,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isCompleted
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.isNote && item.note != null && item.note!.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        item.note!,
                        overflow: TextOverflow.ellipsis,
                        maxLines:
                            5, // Aumenta o número de linhas visíveis no grid
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                if (!item.isNote && item.dateTime != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'dd/MM/yy \'às\' HH:mm',
                        ).format(item.dateTime!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isNotesTab, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNotesTab
                ? Icons.lightbulb_outline_rounded
                : Icons.check_box_outline_blank_rounded,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            isNotesTab ? l10n.noNotes : l10n.noTask,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Adicione o primeiro item no botão '+'.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(AppLocalizations l10n, ThemeData theme) {
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.tarefas',
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.download_for_offline_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.downloadApp,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
