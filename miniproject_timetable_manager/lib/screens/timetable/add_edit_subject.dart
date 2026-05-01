import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subject_model.dart';
import '../../providers/subject_provider.dart';

class AddEditSubjectScreen extends StatefulWidget {
  final Subject? subject;
  const AddEditSubjectScreen({super.key, this.subject});
  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl, _courseCtrl, _facultyCtrl;
  bool _saving = false;
  bool get isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.subject?.code ?? '');
    _courseCtrl = TextEditingController(text: widget.subject?.course ?? '');
    _facultyCtrl = TextEditingController(text: widget.subject?.faculty ?? '');
  }

  @override
  void dispose() { _codeCtrl.dispose(); _courseCtrl.dispose(); _facultyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = Provider.of<SubjectProvider>(context, listen: false);
      final subject = Subject(id: widget.subject?.id, code: _codeCtrl.text.trim(), course: _courseCtrl.text.trim(), faculty: _facultyCtrl.text.trim());
      if (isEditing) { await provider.updateSubject(subject); } else { await provider.addSubject(subject); }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Subject updated' : 'Subject added'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Subject' : 'Add Subject', style: const TextStyle(fontWeight: FontWeight.w700)), elevation: 0),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
        _section(theme, 'Subject Details', Icons.school_rounded),
        const SizedBox(height: 14),
        _field(_codeCtrl, 'Subject Code', 'e.g. CS3401', Icons.tag_rounded, (v) => v == null || v.trim().isEmpty ? 'Enter code' : null),
        const SizedBox(height: 14),
        _field(_courseCtrl, 'Course Name', 'e.g. Data Structures', Icons.book_rounded, (v) => v == null || v.trim().isEmpty ? 'Enter name' : null),
        const SizedBox(height: 14),
        _field(_facultyCtrl, 'Faculty Name', 'e.g. Dr. Smith', Icons.person_rounded, (v) => v == null || v.trim().isEmpty ? 'Enter faculty' : null),
        const SizedBox(height: 32),
        SizedBox(height: 54, child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
          label: Text(_saving ? 'Saving...' : (isEditing ? 'Update Subject' : 'Add Subject'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
      ])),
    );
  }

  Widget _section(ThemeData theme, String title, IconData icon) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(80), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: theme.colorScheme.primary)),
    const SizedBox(width: 10),
    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
  ]);

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, String? Function(String?) validator) {
    final theme = Theme.of(context);
    return TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80)), validator: validator);
  }
}
