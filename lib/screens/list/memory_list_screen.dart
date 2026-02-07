import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/share_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../detail/memory_detail_screen.dart';

class MemoryListScreen extends StatefulWidget {
  final MemoryCategory? filterCategory;

  const MemoryListScreen({super.key, this.filterCategory});

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> {
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  MemoryCategory? _activeFilter;
  String? _activeSubType;
  bool _sortNewestFirst = true;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filterCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Memory>> get _baseStream {
    if (_searchQuery.isNotEmpty) {
      return AppDatabase.instance.searchMemories(_searchQuery);
    }
    if (_activeFilter != null) {
      return AppDatabase.instance.watchMemoriesByCategory(_activeFilter!.name);
    }
    return AppDatabase.instance.watchAllMemories();
  }

  List<Memory> _applyFilters(List<Memory> items) {
    var filtered = items;

    // Sub-type filter
    if (_activeSubType != null) {
      filtered = filtered.where((m) => m.subType == _activeSubType).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((m) {
        return !m.createdAt.isBefore(_dateRange!.start) &&
            m.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort
    if (!_sortNewestFirst) {
      filtered = filtered.reversed.toList();
    }

    return filtered;
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _shareSelected(List<Memory> allItems) async {
    final selected = allItems.where((m) => _selectedIds.contains(m.id)).toList();
    if (selected.isEmpty) return;
    await ShareService.instance.shareMemories(selected);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.pink.shade300),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  List<String> get _availableSubTypes {
    if (_activeFilter == null) return [];
    return _activeFilter!.subTypes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'キーワードで検索...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : Text(
                _selectMode
                    ? '${_selectedIds.length}件選択中'
                    : _activeFilter?.label ?? 'すべての思い出',
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 22),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_sortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 20),
            onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
            tooltip: _sortNewestFirst ? '古い順にする' : '新しい順にする',
          ),
          if (_selectMode)
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: _toggleSelectMode)
          else
            IconButton(icon: const Icon(Icons.checklist_rounded), onPressed: _toggleSelectMode, tooltip: 'まとめてシェア'),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(null, 'すべて'),
                ...MemoryCategory.values.map((cat) => _buildFilterChip(cat, cat.label)),
              ],
            ),
          ),

          // Sub-type filter chips (when a category is active)
          if (_availableSubTypes.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSubTypeChip(null, 'すべて'),
                  ..._availableSubTypes.map((sub) => _buildSubTypeChip(sub, sub)),
                ],
              ),
            ),

          // Date range & active filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _dateRange != null ? Colors.pink.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _dateRange != null ? Colors.pink.shade200 : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14,
                            color: _dateRange != null ? Colors.pink.shade400 : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _dateRange != null
                              ? '${_dateRange!.start.month}/${_dateRange!.start.day} - ${_dateRange!.end.month}/${_dateRange!.end.day}'
                              : '期間',
                          style: TextStyle(
                            fontSize: 12,
                            color: _dateRange != null ? Colors.pink.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _dateRange = null),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Memory list
          Expanded(
            child: StreamBuilder<List<Memory>>(
              stream: _baseStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('まだ記録がありません', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                final items = _applyFilters(snapshot.data!);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('条件に一致する記録がありません', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                // 5件ごとに広告を挿入
                final adInterval = 5;
                final adCount = items.length > adInterval ? (items.length ~/ adInterval) : 0;
                final totalCount = items.length + adCount;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: totalCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    // 広告スロットか判定
                    final adsBefore = adInterval > 0 ? index ~/ (adInterval + 1) : 0;
                    final isAd = adInterval > 0 && index > 0 && (index + 1) % (adInterval + 1) == 0;
                    if (isAd) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Center(child: BannerAdWidget(adSize: AdSize.largeBanner)),
                      );
                    }
                    final memoryIndex = index - adsBefore;
                    if (memoryIndex >= items.length) return const SizedBox.shrink();
                    final memory = items[memoryIndex];
                    final cat = MemoryCategory.values.firstWhere(
                      (c) => c.name == memory.category,
                      orElse: () => MemoryCategory.words,
                    );
                    final isSelected = _selectedIds.contains(memory.id);

                    if (_selectMode) {
                      return GestureDetector(
                        onTap: () => _toggleSelection(memory.id),
                        child: _buildMemoryTile(memory, cat, isSelected: isSelected),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory)));
                      },
                      child: Dismissible(
                        key: Key(memory.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('削除しますか？'),
                              content: const Text('この思い出は元に戻せません'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text('削除', style: TextStyle(color: Colors.red.shade400)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => AppDatabase.instance.deleteMemory(memory.id),
                        child: _buildMemoryTile(memory, cat),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectMode && _selectedIds.isNotEmpty
          ? StreamBuilder<List<Memory>>(
              stream: _baseStream,
              builder: (context, snapshot) {
                return FloatingActionButton.extended(
                  onPressed: snapshot.hasData ? () => _shareSelected(snapshot.data!) : null,
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.share_rounded),
                  label: Text('${_selectedIds.length}件をシェア'),
                );
              },
            )
          : null,
    );
  }

  Widget _buildFilterChip(MemoryCategory? category, String label) {
    final isActive = _activeFilter == category;
    final color = category?.color ?? Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isActive,
        label: Text(label),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : color),
        backgroundColor: Colors.white,
        selectedColor: color,
        side: BorderSide(color: isActive ? color : Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _activeFilter = category;
            _activeSubType = null;
            _selectedIds.clear();
          });
        },
      ),
    );
  }

  Widget _buildSubTypeChip(String? subType, String label) {
    final isActive = _activeSubType == subType;
    final color = _activeFilter?.color ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isActive,
        label: Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : color)),
        backgroundColor: Colors.white,
        selectedColor: color.withValues(alpha: 0.8),
        side: BorderSide(color: isActive ? color : Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCheckmark: false,
        onSelected: (_) => setState(() => _activeSubType = subType),
      ),
    );
  }

  Widget _buildMemoryTile(Memory memory, MemoryCategory cat, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? cat.color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: cat.color, width: 1.5) : null,
        boxShadow: isSelected
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectMode)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? cat.color : Colors.grey.shade300,
                size: 24,
              ),
            ),
          if (memory.mediaPath != null && File(memory.mediaPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(memory.mediaPath!), width: 60, height: 60, fit: BoxFit.cover),
            )
          else
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (memory.subType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(memory.subType, style: TextStyle(fontSize: 11, color: cat.color, fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    Text(
                      '${memory.createdAt.month}/${memory.createdAt.day}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (memory.content.isNotEmpty)
                  Text(
                    memory.content,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (memory.amount != null)
                  Text(
                    '¥${memory.amount}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cat.color),
                  ),
              ],
            ),
          ),
          if (!_selectMode)
            GestureDetector(
              onTap: () => ShareService.instance.shareMemory(memory),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.share_rounded, size: 18, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }
}
