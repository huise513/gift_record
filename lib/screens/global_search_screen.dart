import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_result.dart';
import '../services/db_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final results = await DbService.searchGifts(query);
    setState(() {
      _results = results;
      _loading = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE07B54),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: '搜索来宾姓名...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.65)),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: (v) {
            setState(() {}); // 更新清除按钮
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_controller.text == v) _search(v);
            });
          },
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _buildBody(currencyFmt, dateFmt),
    );
  }

  Widget _buildBody(NumberFormat currencyFmt, DateFormat dateFmt) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE07B54)));
    }

    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.brown.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('输入姓名搜索', style: TextStyle(fontSize: 14, color: Colors.brown.withOpacity(0.4))),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.brown.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('未找到 "${_controller.text}" 的记录', style: TextStyle(fontSize: 14, color: Colors.brown.withOpacity(0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final result = _results[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE07B54).withOpacity(0.1),
              child: Text(
                result.gift.giverName.isNotEmpty ? result.gift.giverName[0] : '?',
                style: const TextStyle(color: Color(0xFFE07B54), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              result.gift.giverName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5C3D2E)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _tag(result.book.name, const Color(0xFFE07B54)),
                    const SizedBox(width: 8),
                    _tag(dateFmt.format(result.book.createdAt), const Color(0xFFB8907A)),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${result.gift.amountDisplay}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE07B54),
                  ),
                ),
                if (result.gift.paymentMethod != '现金')
                  Text(
                    result.gift.paymentMethod,
                    style: TextStyle(fontSize: 10, color: Colors.green[600]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
