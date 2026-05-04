import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Returns the entered (name, amountInFen) via Navigator.pop.
/// Amount field clears after confirm, name field clears too — ready for next entry.
class AddRecordDialog extends StatefulWidget {
  const AddRecordDialog({super.key});

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _nameFocus = FocusNode();

  String? _nameError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    // Auto-focus name field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nameError = null;
      _amountError = null;
    });

    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = '请输入来宾姓名');
      return;
    }

    if (amountStr.isEmpty) {
      setState(() => _amountError = '请输入礼金金额');
      return;
    }

    // Parse amount in 元, convert to 分
    final amountYuan = double.tryParse(amountStr);
    if (amountYuan == null || amountYuan <= 0) {
      setState(() => _amountError = '请输入有效金额');
      return;
    }

    final amountFen = (amountYuan * 100).round();

    // Return result but keep dialog open for fast consecutive entry
    _nameController.clear();
    _amountController.clear();
    // 延迟聚焦，等待弹窗重新渲染完成
    Future.delayed(const Duration(milliseconds: 80), () {
      _nameFocus.requestFocus();
    });

    Navigator.pop(context, {'name': name, 'amountFen': amountFen});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('记礼金'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: InputDecoration(
                labelText: '来宾姓名',
                hintText: '输入姓名',
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '礼金金额',
                hintText: '输入金额',
                errorText: _amountError,
                prefixText: '¥ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('记一笔'),
        ),
      ],
    );
  }
}
