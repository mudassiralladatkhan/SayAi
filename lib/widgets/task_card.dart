import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final bool showCategory;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggle,
    this.showCategory = true,
  }) : super(key: key);

  String _getCategoryEmoji() {
    switch (task.category.toLowerCase()) {
      case 'health': return '💪';
      case 'work': return '💼';
      case 'learning': return '📚';
      default: return '📝';
    }
  }

  Color _getCategoryColor() {
    switch (task.category.toLowerCase()) {
      case 'health': return AppTheme.success;
      case 'work': return const Color(0xFF4A90D9);
      case 'learning': return AppTheme.amber;
      default: return AppTheme.textGray;
    }
  }

  String _formatTime() {
    if (task.time == null) return '';
    final h = task.time!.hour;
    final m = task.time!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final formattedH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$formattedH:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardDark,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryPurple, width: 3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: task.completed ? AppTheme.success : AppTheme.textGray,
                width: 2,
              ),
              color: task.completed ? AppTheme.success : Colors.transparent,
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: task.completed ? AppTheme.textGray : AppTheme.textWhite,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                task.duration,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
              ),
              if (showCategory) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getCategoryEmoji(), style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        task.category,
                        style: TextStyle(fontSize: 10, color: _getCategoryColor()),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Text(
          _formatTime(),
          style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
      ),
    );
  }
}
