import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<Gift> _gifts = [];
  double _totalAmount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _loading = true);
    final gifts = await DbService.getGiftsByEvent(widget.event.id!);
    final total = await DbService.getTotalAmount(widget.event.id!);
    setState(() {
      _gifts = gifts;
      _totalAmount = total;
      _loading = false;
    });
  }

  Future<void> _showAddGiftDialog() async {
    final result = await showDialog<Gift>(
      context: context,
      builder: (ctx) => _GiftDialog(eventId: widget.event.id!),
    );
    if (result != null) {
      await DbService.insertGift(result);
      _loadGifts();
    }
  }

  Future<void> _showEditGiftDialog(Gift gift) async {
    final result = await showDialog<Gift>(
      context: context,
      builder: (ctx) => _GiftDialog(eventId: widget.event.id!, gift: gift),
    );
    if (result != null) {
      await DbService.updateGift(result);
      _loadGifts();
    }
  }

  Future<void> _deleteGift(Gift gift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除"${gift.giverName}"的礼金记录吗？'),
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
    final dateFmt = DateFormat('yyyy年MM月dd日');
    final currencyFmt = NumberFormat.currency(symbol: '¥');
    final isWedding = widget.event.occasion == '婚宴';
    final color = isWedding ? Colors.pink : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        backgroundColor: Colors.red[100],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 顶部信息卡
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isWedding ? Icons.favorite : Icons.cake,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.occasion,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  dateFmt.format(widget.event.eventDate),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                if (widget.event.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.event.note!,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('礼金总计', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        currencyFmt.format(_totalAmount),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 礼金列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _gifts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('暂无礼金记录', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                            const SizedBox(height: 8),
                            Text('点击下方按钮添加', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _gifts.length,
                        itemBuilder: (ctx, index) {
                          final gift = _gifts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(Icons.person, color: color),
                              ),
                              title: Text(gift.giverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (gift.phone != null)
                                    Text(gift.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  if (gift.note != null)
                                    Text(gift.note!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFmt.format(gift.amount),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') _showEditGiftDialog(gift);
                                      if (v == 'delete') _deleteGift(gift);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                      const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGiftDialog,
        backgroundColor: color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('记礼金', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _GiftDialog extends StatefulWidget {
  final int eventId;
  final Gift? gift;
  const _GiftDialog({required this.eventId, this.gift});

  @override
  State<_GiftDialog> createState() => _GiftDialogState();
}

class _GiftDialogState extends State<_GiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.gift != null) {
      _nameController.text = widget.gift!.giverName;
      _amountController.text = widget.gift!.amount.toStringAsFixed(0);
      _phoneController.text = widget.gift!.phone ?? '';
      _noteController.text = widget.gift!.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gift == null ? '记礼金' : '编辑礼金'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名 *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? '请输入姓名' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '礼金金额 *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '请输入金额';
                  if (double.tryParse(v.trim()) == null) return '请输入有效金额';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '联系电话（可选）',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final gift = Gift(
              id: widget.gift?.id,
              eventId: widget.eventId,
              giverName: _nameController.text.trim(),
              amount: double.parse(_amountController.text.trim()),
              phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            );
            Navigator.pop(context, gift);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
