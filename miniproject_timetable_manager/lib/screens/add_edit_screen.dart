import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/timetable_model.dart';
import '../providers/timetable_provider.dart';

class AddEditScreen extends StatefulWidget {
  final Timetable? timetable;

  const AddEditScreen({super.key, this.timetable});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _courseController;
  late TextEditingController _facultyController;
  late TextEditingController _locationController;
  late TextEditingController _durationController;

  String _selectedDay = 'Monday';
  String _selectedType = 'Theory';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _types = ['Theory', 'Lab', 'Aptitude'];

  bool get isEditing => widget.timetable != null;

  @override
  void initState() {
    super.initState();
    _codeController =
        TextEditingController(text: widget.timetable?.code ?? '');
    _courseController =
        TextEditingController(text: widget.timetable?.course ?? '');
    _facultyController =
        TextEditingController(text: widget.timetable?.faculty ?? '');
    _locationController =
        TextEditingController(text: widget.timetable?.location ?? '');
    _durationController =
        TextEditingController(text: widget.timetable?.duration ?? '');

    if (widget.timetable != null) {
      _selectedDay = widget.timetable!.day;
      _selectedType = widget.timetable!.type;
      _startTime = _parseTimeOfDay(widget.timetable!.time);
      _endTime = _parseTimeOfDay(widget.timetable!.endTime);
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final format = DateFormat.jm(); // e.g. "9:30 AM"
      final dateTime = format.parse(time);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _courseController.dispose();
    _facultyController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        _calculateDuration();
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
        _calculateDuration();
      });
    }
  }

  void _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes > startMinutes) {
      final diff = endMinutes - startMinutes;
      final hours = diff ~/ 60;
      final minutes = diff % 60;
      if (hours > 0 && minutes > 0) {
        _durationController.text = '${hours}h ${minutes}m';
      } else if (hours > 0) {
        _durationController.text = '${hours}h';
      } else {
        _durationController.text = '${minutes}m';
      }
    } else {
      _durationController.text = '';
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      _showSnackBar('End time must be after start time', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final timetable = Timetable(
        id: widget.timetable?.id,
        code: _codeController.text.trim(),
        course: _courseController.text.trim(),
        faculty: _facultyController.text.trim(),
        day: _selectedDay,
        time: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        location: _locationController.text.trim(),
        duration: _durationController.text.trim(),
        type: _selectedType,
      );

      final provider =
          Provider.of<TimetableProvider>(context, listen: false);

      if (isEditing) {
        await provider.updateTimetable(timetable);
        if (mounted) {
          _showSnackBar('Class updated successfully');
        }
      } else {
        await provider.addTimetable(timetable);
        if (mounted) {
          _showSnackBar('Class added successfully');
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Theory':
        return const Color(0xFF6366F1);
      case 'Lab':
        return const Color(0xFF10B981);
      case 'Aptitude':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Theory':
        return Icons.menu_book_rounded;
      case 'Lab':
        return Icons.science_rounded;
      case 'Aptitude':
        return Icons.psychology_rounded;
      default:
        return Icons.class_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Class' : 'Add New Class',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Section: Subject Details
            _buildSectionHeader(theme, 'Subject Details', Icons.school_rounded),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _codeController,
              label: 'Subject Code',
              hint: 'e.g. CS3401',
              icon: Icons.tag_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter subject code' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _courseController,
              label: 'Subject Name',
              hint: 'e.g. Data Structures',
              icon: Icons.book_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter subject name' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _facultyController,
              label: 'Faculty Name',
              hint: 'e.g. Dr. Smith',
              icon: Icons.person_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter faculty name' : null,
            ),

            const SizedBox(height: 28),

            // Section: Schedule
            _buildSectionHeader(
                theme, 'Schedule', Icons.calendar_month_rounded),
            const SizedBox(height: 12),

            // Day dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedDay,
              decoration: InputDecoration(
                labelText: 'Day of Week',
                prefixIcon:
                    const Icon(Icons.calendar_today_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withAlpha(80),
              ),
              borderRadius: BorderRadius.circular(14),
              items: _days
                  .map((day) =>
                      DropdownMenuItem(value: day, child: Text(day)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedDay = value!),
            ),

            const SizedBox(height: 16),

            // Time pickers
            Row(
              children: [
                Expanded(child: _buildTimePicker(
                  context: context,
                  label: 'Start Time',
                  time: _startTime,
                  onTap: () => _selectStartTime(context),
                  icon: Icons.play_circle_outline_rounded,
                )),
                const SizedBox(width: 14),
                Expanded(child: _buildTimePicker(
                  context: context,
                  label: 'End Time',
                  time: _endTime,
                  onTap: () => _selectEndTime(context),
                  icon: Icons.stop_circle_outlined,
                )),
              ],
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _locationController,
              label: 'Room / Location',
              hint: 'e.g. Room 301',
              icon: Icons.location_on_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter location' : null,
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _durationController,
              label: 'Duration (auto-calculated)',
              icon: Icons.timer_rounded,
              readOnly: true,
            ),

            const SizedBox(height: 28),

            // Section: Type
            _buildSectionHeader(theme, 'Class Type', Icons.category_rounded),
            const SizedBox(height: 12),

            // Type selector chips
            _buildTypeSelector(theme),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveForm,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : (isEditing ? 'Update Class' : 'Add Class'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      ),
      validator: validator,
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline.withAlpha(100)),
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeOfDay(time),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Row(
      children: _types.map((type) {
        final isSelected = _selectedType == type;
        final color = _getTypeColor(type);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: type != _types.last ? 10 : 0),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(25) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : theme.colorScheme.outlineVariant.withAlpha(120),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    color: isSelected
                        ? color
                        : theme.colorScheme.onSurface.withAlpha(150),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? color
                          : theme.colorScheme.onSurface.withAlpha(180),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
