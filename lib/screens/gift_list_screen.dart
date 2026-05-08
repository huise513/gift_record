import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../models/gift_entry.dart';
import '../models/gift_book.dart';
import '../services/db_service.dart';
import '../services/export_excel_service.dart';
import 'export_screen.dart';

class GiftListScreen extends StatefulWidget {
  final int bookId;
  final String bookName;

  const GiftListScreen({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  @override
  State<GiftListScreen> createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  List<GiftEntry> _gifts = [];
  double _totalAmount = 0;
  bool _loading = true;
  DateTime _bookCreatedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _loading = true);
    final book = await DbService.getGiftBook(widget.bookId);
    final gifts = await DbService.getGiftsForBook(widget.bookId);
    final total = await DbService.getTotalAmountForBook(widget.bookId);
    setState(() {
      _gifts = gifts;
      _totalAmount = total;
      _bookCreatedAt = book?.createdAt ?? DateTime.now();
      _loading = false;
    });
  }

  Future<void> _deleteGift(GiftEntry gift) async {
    final deletedGift = gift;
    await DbService.deleteGift(gift.id!);
    setState(() {
      _gifts.removeWhere((g) => g.id == gift.id);
      _totalAmount = _totalAmount - gift.amount;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 "${deletedGift.giverName}" 的记录'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await DbService.restoreGift(deletedGift);
              _loadGifts();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (ctx, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout();
            }
            return _buildPortraitLayout();
          },
        ),
      ),
    );
  }

  // 竖屏：上下布局
  Widget _buildPortraitLayout() {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Column(
      children: [
        _buildHeaderPortrait(currencyFmt),
        _buildInputArea(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _gifts.isEmpty
              ? _buildEmptyState()
              : _buildGiftList(),
        ),
      ],
    );
  }

  // 横屏：左右布局
  Widget _buildLandscapeLayout() {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Row(
      children: [
        // 左侧：头部统计 + 输入表单
        Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeaderLandscape(currencyFmt),
              const SizedBox(height: 12),
              Expanded(child: _buildInputArea()),
            ],
          ),
        ),
        // 分隔线
        Container(width: 1, color: Colors.brown.withOpacity(0.1)),
        // 右侧：记录列表
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _gifts.isEmpty
              ? _buildEmptyState()
              : _buildGiftList(),
        ),
      ],
    );
  }

  Widget _buildHeaderPortrait(NumberFormat currencyFmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07B54).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('yyyy年MM月dd日').format(_bookCreatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              _ExportButton(
                onPressed: () {
                  _showExportSheet();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.bookName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_gifts.length}笔  ${currencyFmt.format(_totalAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLandscape(NumberFormat currencyFmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07B54).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.bookName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              _ExportButton(
                onPressed: () {
                  _showExportSheet();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LandscapeStatItem(label: '笔数', value: '${_gifts.length}'),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.25),
              ),
              _LandscapeStatItem(
                label: '总额',
                value: currencyFmt.format(_totalAmount),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return _AddGiftForm(bookId: widget.bookId, onAdded: () => _loadGifts());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 32,
              color: Color(0xFFE07B54),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无记录',
            style: TextStyle(fontSize: 15, color: Colors.brown[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftList() {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: _gifts.length,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex -= 1;
            final item = _gifts.removeAt(oldIndex);
            _gifts.insert(newIndex, item);
            setState(() {});
            await DbService.reorderGifts(_gifts);
          },
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (ctx, child) {
                final elev = Tween<double>(
                  begin: 0,
                  end: 6,
                ).evaluate(animation);
                return Material(
                  elevation: elev,
                  color: Colors.transparent,
                  shadowColor: const Color(0xFFE07B54).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
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

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFFE07B54)),
                title: const Text('导出为图片'),
                subtitle: const Text('生成高清图片，可分享至朋友圈'),
                onTap: () {
                  Navigator.pop(ctx);
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
              ),
              ListTile(
                leading: const Icon(
                  Icons.table_chart,
                  color: Color(0xFFE07B54),
                ),
                title: const Text('导出为 Excel'),
                subtitle: const Text('导出电子表格，方便编辑统计'),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正在导出 Excel...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  final book = GiftBook(
                    id: widget.bookId,
                    name: widget.bookName,
                    type: GiftBookType.wedding,
                    createdAt: _bookCreatedAt,
                  );
                  await ExportExcelService.exportSingleBook(book, _gifts);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandscapeStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _LandscapeStatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? const Color(0xFFFFE066) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExportButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, color: Colors.white, size: 16),
              SizedBox(width: 5),
              Text(
                '导出',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: Colors.red[50],
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE07B54).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            gift.giverName.isNotEmpty ? gift.giverName[0] : '?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE07B54),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                gift.giverName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (gift.note?.isNotEmpty == true) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B54).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gift.note!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE07B54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              dateFmt.format(gift.createdAt),
              style: TextStyle(fontSize: 10, color: Colors.brown[300]),
            ),
            const SizedBox(width: 6),
            Text(
              gift.paymentMethod,
              style: TextStyle(fontSize: 10, color: Colors.brown[300]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFmt.format(gift.amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE07B54),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.drag_handle, color: Colors.brown[200], size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── 新增表单 ──────────────────────────────────────────────────────────────

class _AddGiftForm extends StatefulWidget {
  final int bookId;
  final VoidCallback onAdded;

  const _AddGiftForm({required this.bookId, required this.onAdded});

  @override
  State<_AddGiftForm> createState() => _AddGiftFormState();
}

class _AddGiftFormState extends State<_AddGiftForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.cash;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();

    if (name.isEmpty || amountStr.isEmpty) return;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    await DbService.insertGift(
      GiftEntry(
        eventId: widget.bookId,
        giverName: name,
        amount: amount,
        paymentMethod: _selectedPayment.label,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );

    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() => _selectedPayment = PaymentMethod.cash);
    widget.onAdded();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusScope.of(context));
        }
      });
    });
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '姓名',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFE07B54),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      hintText: '金额',
                      prefixIcon: Icon(
                        Icons.monetization_on_outlined,
                        color: Color(0xFFE07B54),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [DecimalAmountInputFormatter()],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '记',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: PaymentMethod.all.map((method) {
                      final isSelected = _selectedPayment == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPayment = method),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE07B54)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                method.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.brown[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showNoteDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 15,
                        color: Colors.brown[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '备注',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('备注'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: '备注',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift.giverName);
    _amountController = TextEditingController(text: widget.gift.amountDisplay);
    _noteController = TextEditingController(text: widget.gift.note ?? '');
    _selectedPayment = PaymentMethod.fromLabel(widget.gift.paymentMethod);
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
    if (name.isEmpty || amountStr.isEmpty) return;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    final noteText = _noteController.text.trim();
    final note = noteText.isEmpty ? null : noteText;
    debugPrint('save note: "$noteText" -> note=$note');
    final updated = widget.gift.copyWith(
      giverName: name,
      amount: amount,
      paymentMethod: _selectedPayment.label,
      note: note,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.brown[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFE07B54),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '编辑记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.brown[300], size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '姓名',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFFE07B54),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  hintText: '金额',
                  prefixIcon: Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFFE07B54),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [DecimalAmountInputFormatter()],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: PaymentMethod.all.map((method) {
                  final isSelected = _selectedPayment == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPayment = method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE07B54)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(
                            method.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.brown[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: '备注',
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    color: Color(0xFFE07B54),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
