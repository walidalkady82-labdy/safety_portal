import 'package:flutter/material.dart';

// 1. Create a simple data model or interface for the items 
// (Or just use your existing Report model)
class WatchlistItem {
  final String title;
  final String subtitle;
  final bool isHighPriority;

  WatchlistItem({
    required this.title,
    required this.subtitle,
    this.isHighPriority = false,
  });
}

class PriorityWatchlist extends StatelessWidget {
  final List<WatchlistItem> items;
  final String emptyMessage;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  const PriorityWatchlist({
    super.key,
    required this.items,
    required this.emptyMessage,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Handle Empty State
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // 3. Build List
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.symmetric(horizontal: 0), // Padding usually handled by parent
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _WatchlistTile(item: item);
      },
    );
  }
}

// Internal helper widget for the row
class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  const _WatchlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isHighPriority ? Colors.red.shade50 : Colors.amber.shade50,
          child: Icon(
            item.isHighPriority ? Icons.gpp_bad : Icons.warning_amber,
            color: item.isHighPriority ? Colors.red : Colors.amber,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: item.isHighPriority 
            ? const Icon(Icons.arrow_upward, color: Colors.red, size: 16) 
            : null,
      ),
    );
  }
}