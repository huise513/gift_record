import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gift_book.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import 'gift_list_screen.dart';

class GiftBooksScreen extends StatefulWidget {
  const GiftBooksScreen({super.key});

  @override
  State<GiftBooksScreen> createState() => _GiftBooksScreenState();
}

class _GiftBooksScreenState extends State<GiftBooksScreen> {
  List<GiftBook> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    await DbService.ensureDefaultBook();
    final books = await DbService.getAllGiftBooks();
    // 加载每个礼金本的统计数据
    final booksWithStats = await Future.wait(
      books.map((b) async {
        final count = await DbService.getGiftRecordCount(b.id!);
        final total = await DbService.getTotalAmountForBook(b.id!);
        return b.copyWith(recordCount: count, totalAmount: total);
      }),
    );
    setState(() {
      _books = booksWithStats;
      _loading = false;
    });
  }

  Future<void> _deleteBook(GiftBook book) async {
    final deleted = await DbService.deleteGiftBook(book.id!);
    if (deleted > 0) {
      _loadBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除 "${book.name}"'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGiftBookSheet(onAdded: (book) {
        Navigator.pop(ctx);
        _loadBooks();
        // 打开新建的礼金本
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GiftListScreen(bookId: book.id!, bookName: book.name),
          ),
        ).then((_) => _loadBooks());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '我的礼金本',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE07B54),
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : _buildBooksList(currencyFmt, dateFmt),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFE07B54),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
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
            '暂无礼金本',
            style: TextStyle(fontSize: 16, color: Colors.brown[400]),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角 + 新建一个',
            style: TextStyle(fontSize: 13, color: Colors.brown[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(NumberFormat currencyFmt, DateFormat dateFmt) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _books.length,
      itemBuilder: (ctx, index) {
        final book = _books[index];
        return _GiftBookCard(
          book: book,
          currencyFmt: currencyFmt,
          dateFmt: dateFmt,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GiftListScreen(bookId: book.id!, bookName: book.name),
              ),
            );
            _loadBooks(); // 返回时刷新（可能有新增记录）
          },
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除确认'),
                content: Text('确定要删除 "${book.name}" 吗？该操作不可撤销。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await _deleteBook(book);
            }
          },
        );
      },
    );
  }
}

class _GiftBookCard extends StatelessWidget {
  final GiftBook book;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GiftBookCard({
    required this.book,
    required this.currencyFmt,
    required this.dateFmt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    book.type == GiftBookType.wedding
                        ? Icons.favorite
                        : Icons.cake,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // 中间信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            book.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3D2B1F),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07B54).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.type.label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFE07B54),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFmt.format(book.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.brown[300]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatChip(label: '笔数', value: '${book.recordCount}'),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: '总额',
                            value: currencyFmt.format(book.totalAmount),
                            highlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧操作
                Column(
                  children: [
                    IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      color: Colors.brown[200],
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red[200],
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(fontSize: 11, color: Colors.brown[300]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: highlight ? const Color(0xFFE07B54) : const Color(0xFF3D2B1F),
          ),
        ),
      ],
    );
  }
}

class _AddGiftBookSheet extends StatefulWidget {
  final void Function(GiftBook book) onAdded;

  const _AddGiftBookSheet({required this.onAdded});

  @override
  State<_AddGiftBookSheet> createState() => _AddGiftBookSheetState();
}

class _AddGiftBookSheetState extends State<_AddGiftBookSheet> {
  final _nameController = TextEditingController();
  GiftBookType _selectedType = GiftBookType.wedding;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final book = GiftBook(
      name: name,
      type: _selectedType,
      createdAt: DateTime.now(),
    );
    final id = await DbService.insertGiftBook(book);
    widget.onAdded(book.copyWith(id: id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          const SizedBox(height: 16),
          const Text(
            '新建礼金本',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D2B1F),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '礼金本名称',
              hintText: '例如：王先生婚宴',
              filled: true,
              fillColor: const Color(0xFFFAF7F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.book_outlined, color: Color(0xFFE07B54)),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const Text(
            '类型',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2B1F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeOption(
                type: GiftBookType.wedding,
                selected: _selectedType == GiftBookType.wedding,
                onTap: () => setState(() => _selectedType = GiftBookType.wedding),
              ),
              const SizedBox(width: 12),
              _TypeOption(
                type: GiftBookType.birthday,
                selected: _selectedType == GiftBookType.birthday,
                onTap: () => setState(() => _selectedType = GiftBookType.birthday),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final GiftBookType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFE07B54) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == GiftBookType.wedding ? Icons.favorite : Icons.cake,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFFE07B54),
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFFE07B54),
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
