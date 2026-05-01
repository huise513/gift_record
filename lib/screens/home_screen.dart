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
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

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

  Future<void> _addGift() async {
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

    await DbService.insertGift(GiftEntry(giverName: name, amount: amount));
    _nameController.clear();
    _amountController.clear();
    _loadGifts();
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
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: SafeArea(
        child: Column(
          children: [
            _buildCover(currencyFmt),
            _buildInputArea(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _gifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '暂无记录',
                                style: TextStyle(fontSize: 16, color: Colors.brown[300]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '输入姓名和金额开始记录',
                                style: TextStyle(fontSize: 13, color: Colors.brown[200]),
                              ),
                            ],
                          ),
                        )
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
                      gifts: _gifts.reversed.toList(),
                      totalAmount: _totalAmount,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF8B0000),
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('导出礼金本', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildCover(NumberFormat currencyFmt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '礼 金 本',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 8,
              shadows: [
                Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('yyyy年').format(DateTime.now()),
            style: const TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Column(
              children: [
                const Text(
                  '礼金合计',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFmt.format(_totalAmount),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '共 ${_gifts.length} 笔',
            style: const TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '姓名',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: '金额',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addGift(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addGift,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('记礼金'),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftList() {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('MM-dd HH:mm');

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.2)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _gifts.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.brown.withOpacity(0.1)),
        itemBuilder: (ctx, index) {
          final gift = _gifts[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF8B0000).withOpacity(0.1),
              child: Text(
                gift.giverName.isNotEmpty ? gift.giverName[0] : '?',
                style: const TextStyle(
                  color: Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              gift.giverName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              dateFmt.format(gift.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.brown[300]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFmt.format(gift.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.brown[300]),
                  onPressed: () => _deleteGift(gift),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}