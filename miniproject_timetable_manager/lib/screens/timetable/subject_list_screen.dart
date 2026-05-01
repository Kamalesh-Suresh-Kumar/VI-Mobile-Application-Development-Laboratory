import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../models/subject_model.dart';
import 'add_edit_subject.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});
  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() { if (mounted) Provider.of<SubjectProvider>(context, listen: false).fetchSubjects(); });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subjects', style: TextStyle(fontWeight: FontWeight.w700)), elevation: 0, scrolledUnderElevation: 0),
      body: Consumer<SubjectProvider>(builder: (ctx, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.subjects.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(50), shape: BoxShape.circle),
            child: Icon(Icons.school_outlined, size: 56, color: theme.colorScheme.primary.withAlpha(120))),
          const SizedBox(height: 24),
          Text('No subjects yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(180))),
          const SizedBox(height: 8),
          Text('Add your subjects to get started', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120))),
        ]));

        return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), itemCount: provider.subjects.length, itemBuilder: (ctx, i) {
          final s = provider.subjects[i];
          return _buildSubjectCard(context, s, provider);
        });
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditSubjectScreen()));
          if (context.mounted) Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
        },
        icon: const Icon(Icons.add_rounded), label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext ctx, Subject s, SubjectProvider provider) {
    final theme = Theme.of(ctx);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          await Navigator.push(ctx, MaterialPageRoute(builder: (_) => AddEditSubjectScreen(subject: s)));
          if (ctx.mounted) provider.fetchSubjects();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.book_rounded, color: theme.colorScheme.primary, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.course, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${s.code} • ${s.faculty}', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 13)),
            ])),
            IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
              onPressed: () async {
                final confirm = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Delete Subject'), content: Text('Delete "${s.course}" and all its classes?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white)))],
                ));
                if (confirm == true && ctx.mounted) { await provider.deleteSubject(s.id!); }
              }),
          ]),
        ),
      ),
    );
  }
}
