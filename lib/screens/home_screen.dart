import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gift_entry.dart';
import '../services/db_service.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GiftEntry> _gifts = [];
  double _totalAmount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _loading = true);
    final gifts = await DbService.getAllGifts();
    final total = await DbService.getTotalAmount();
    setState(() {
      _gifts = gifts;
      _totalAmount = total;
      _loading = false;
    });
  }

  Future<void> _deleteGift(GiftEntry gift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除"${gift.giverName}"的记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbService.deleteGift(gift.id!);
      _loadGifts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(currencyFmt),
            _buildInputArea(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _gifts.isEmpty
                      ? _buildEmptyState()
                      : _buildGiftList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _gifts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExportGiftBookScreen(
                      gifts: _gifts,
                      totalAmount: _totalAmount,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFFE07B54),
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
              label: const Text('导出礼金本', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildHeader(NumberFormat currencyFmt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07B54).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('yyyy年 MM月').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '礼 金 本',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  label: '笔数',
                  value: '${_gifts.length}',
                  valueStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _StatColumn(
                  label: '礼金合计',
                  value: currencyFmt.format(_totalAmount),
                  valueStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFE066)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return _AddGiftForm(
      onAdded: () => _loadGifts(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.card_giftcard, size: 40, color: Color(0xFFE07B54)),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无礼金记录',
            style: TextStyle(fontSize: 16, color: Colors.brown[400], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            '输入姓名和金额开始记录',
            style: TextStyle(fontSize: 13, color: Colors.brown[200]),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftList() {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 18, color: Color(0xFFE07B54)),
                const SizedBox(width: 8),
                Text(
                  '礼金记录（共 ${_gifts.length} 笔）',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B6347),
                  ),
                ),
                const Spacer(),
                Text(
                  '长按或侧滑编辑/删除',
                  style: TextStyle(fontSize: 11, color: Colors.brown[200]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _gifts.length,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _gifts.removeAt(oldIndex);
                _gifts.insert(newIndex, item);
                setState(() {});

                // 异步保存排序到数据库
                await DbService.reorderGifts(_gifts);
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (ctx, child) {
                    final elev = Tween<double>(begin: 0, end: 8).evaluate(animation);
                    return Material(
                      elevation: elev,
                      color: Colors.transparent,
                      shadowColor: const Color(0xFFE07B54).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (ctx, index) {
                final gift = _gifts[index];
                return _GiftListItem(
                  key: ValueKey('${gift.id}'),
                  gift: gift,
                  currencyFmt: currencyFmt,
                  onTap: () => _showEditDialog(gift),
                  onDelete: () => _deleteGift(gift),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(GiftEntry gift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditGiftSheet(
        gift: gift,
        onSaved: (updated) async {
          await DbService.updateGift(updated);
          _loadGifts();
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _GiftListItem extends StatelessWidget {
  final GiftEntry gift;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GiftListItem({
    super.key,
    required this.gift,
    required this.currencyFmt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MM-dd HH:mm');

    return Dismissible(
      key: ValueKey('dismiss_${gift.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[50],
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除确认'),
            content: Text('确定要删除"${gift.giverName}"的记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) onDelete();
        return false;
      },
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE07B54).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            gift.giverName.isNotEmpty ? gift.giverName[0] : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE07B54),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              gift.giverName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            if (gift.note != null && gift.note!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07B54).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  gift.note!,
                  style: const TextStyle(fontSize: 10, color: Color(0xFFE07B54)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              dateFmt.format(gift.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.brown[300]),
            ),
            const SizedBox(width: 8),
            _PaymentBadge(method: gift.paymentMethod),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFmt.format(gift.amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE07B54),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.drag_handle, color: Colors.brown[200], size: 20),
          ],
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String method;

  const _PaymentBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (method) {
      '微信' => '💚',
      '支付宝' => '🔵',
      '银行转账' => '🏦',
      _ => '💵',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            method,
            style: TextStyle(fontSize: 10, color: Colors.brown[300]),
          ),
        ],
      ),
    );
  }
}

// ─── 新增/编辑表单 ────────────────────────────────────────────────────────────

class _AddGiftForm extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddGiftForm({required this.onAdded});

  @override
  State<_AddGiftForm> createState() => _AddGiftFormState();
}

class _AddGiftFormState extends State<_AddGiftForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _showNote = false;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();

    if (name.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入姓名和金额')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    await DbService.insertGift(GiftEntry(
      giverName: name,
      amount: amount,
      paymentMethod: _selectedPayment.label,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    ));

    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedPayment = PaymentMethod.cash;
      _showNote = false;
    });
    widget.onAdded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '请输入姓名',
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFFE07B54)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      hintText: '礼金金额',
                      prefixIcon: Icon(Icons.monetization_on_outlined, color: Color(0xFFE07B54)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.payment_outlined, size: 18, color: Color(0xFFE07B54)),
                const SizedBox(width: 8),
                Text('支付方式', style: TextStyle(fontSize: 12, color: Colors.brown[400])),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: PaymentMethod.all.map((method) {
                      final isSelected = _selectedPayment == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPayment = method),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE07B54) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(method.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  method.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.brown[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showNote = !_showNote),
            child: Row(
              children: [
                Icon(
                  _showNote ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.brown[300],
                ),
                const SizedBox(width: 4),
                Text(
                  '添加备注',
                  style: TextStyle(fontSize: 12, color: Colors.brown[300]),
                ),
              ],
            ),
          ),

          if (_showNote) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: '备注（可选），如：关系/酒席名称等',
                  prefixIcon: Icon(Icons.note_outlined, color: Color(0xFFE07B54), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Text('记礼金', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 编辑礼金底部弹窗 ──────────────────────────────────────────────────────

class _EditGiftSheet extends StatefulWidget {
  final GiftEntry gift;
  final Future<void> Function(GiftEntry) onSaved;

  const _EditGiftSheet({required this.gift, required this.onSaved});

  @override
  State<_EditGiftSheet> createState() => _EditGiftSheetState();
}

class _EditGiftSheetState extends State<_EditGiftSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late PaymentMethod _selectedPayment;
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift.giverName);
    _amountController = TextEditingController(text: widget.gift.amount.toString());
    _noteController = TextEditingController(text: widget.gift.note ?? '');
    _selectedPayment = PaymentMethod.fromLabel(widget.gift.paymentMethod);
    _showNote = widget.gift.note?.isNotEmpty == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();

    if (name.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入姓名和金额')));
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }

    final updated = widget.gift.copyWith(
      giverName: name,
      amount: amount,
      paymentMethod: _selectedPayment.label,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await widget.onSaved(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.brown[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: Color(0xFFE07B54)),
                const SizedBox(width: 8),
                const Text(
                  '编辑礼金',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.brown[300]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 姓名
            _buildFieldLabel('姓名'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, '请输入姓名', Icons.person_outline),

            const SizedBox(height: 16),

            // 金额
            _buildFieldLabel('金额'),
            const SizedBox(height: 8),
            _buildTextField(_amountController, '礼金金额', Icons.monetization_on_outlined, keyboardType: TextInputType.number),

            const SizedBox(height: 16),

            // 支付方式
            _buildFieldLabel('支付方式'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: PaymentMethod.all.map((method) {
                  final isSelected = _selectedPayment == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPayment = method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE07B54) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(method.emoji, style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 4),
                            Text(
                              method.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.brown[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 备注
            GestureDetector(
              onTap: () => setState(() => _showNote = !_showNote),
              child: Row(
                children: [
                  Icon(
                    _showNote ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.brown[300],
                  ),
                  const SizedBox(width: 4),
                  Text('添加备注', style: TextStyle(fontSize: 12, color: Colors.brown[300])),
                ],
              ),
            ),

            if (_showNote) ...[
              const SizedBox(height: 8),
              _buildTextField(_noteController, '备注（可选）', Icons.note_outlined, maxLines: 2),
            ],

            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 8),
                    Text('保存修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.brown[400],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFE07B54)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}