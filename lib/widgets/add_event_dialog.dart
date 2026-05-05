import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class AddEventDialog extends StatefulWidget {
  final Event? event; // null = create, non-null = edit

  const AddEventDialog({super.key, this.event});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  late final TextEditingController _nameController;
  late EventType _selectedType;
  late DateTime _selectedDate;

  bool get isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _selectedType = widget.event?.type ?? EventType.wedding;
    _selectedDate = widget.event?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入宴席名称'), duration: Duration(seconds: 2)),
      );
      return;
    }
    Navigator.pop(context, {
      'name': name,
      'type': _selectedType,
      'date': _selectedDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? '编辑宴席' : '创建宴席'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '宴席名称',
                hintText: '如：张三婚宴',
              ),
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            const Text('宴席类型', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    label: '婚宴',
                    emoji: '囍',
                    selected: _selectedType == EventType.wedding,
                    onTap: () => setState(() => _selectedType = EventType.wedding),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeOption(
                    label: '寿宴',
                    emoji: '寿',
                    selected: _selectedType == EventType.birthday,
                    onTap: () => setState(() => _selectedType = EventType.birthday),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('宴席日期', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Spacer(),
                    Icon(Icons.edit, size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? '保存' : '创建'),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$emoji $label',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
