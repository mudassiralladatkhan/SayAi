import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentIndex = 1;
  late int _selectedDay;
  late DateTime _weekStart;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // weekday: 1=Mon, 7=Sun — set selected to today's index (0-based)
    _selectedDay = today.weekday - 1;
    // Start of this week (Monday)
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
  }


  String _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health': return '💪';
      case 'work': return '💼';
      case 'learning': return '📚';
      case 'personal': return '🧘';
      case 'social': return '👥';
      default: return '📌';
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '30 min');
    String selectedCategory = 'General';
    TimeOfDay? selectedTime;
    final categories = ['General', 'Work', 'Health', 'Learning', 'Personal', 'Social'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.task_alt, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),

              // Time Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                  if (picked != null) setModalState(() => selectedTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime != null ? selectedTime!.format(ctx) : 'Select time (optional)',
                        style: TextStyle(color: selectedTime != null ? Colors.white : Colors.white38),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Duration
              TextField(
                controller: durationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Duration (e.g. 30 min)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.timer_outlined, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),

              // Category Chips
              Wrap(
                spacing: 8,
                children: categories.map((cat) => GestureDetector(
                  onTap: () => setModalState(() => selectedCategory = cat),
                  child: Chip(
                    label: Text(cat),
                    backgroundColor: selectedCategory == cat
                        ? AppTheme.primaryPurple
                        : Colors.white10,
                    labelStyle: TextStyle(
                      color: selectedCategory == cat ? Colors.white : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final selectedDate = _weekStart.add(Duration(days: _selectedDay));
                    DateTime? taskTime;
                    if (selectedTime != null) {
                      taskTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime!.hour, selectedTime!.minute);
                    }
                    final task = TaskModel(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      time: taskTime,
                      duration: durationController.text.trim().isEmpty ? '30 min' : durationController.text.trim(),
                      category: selectedCategory,
                      date: selectedDate.toIso8601String().split('T')[0],
                    );
                    await context.read<TaskProvider>().addTask(task);
                    if (mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add Task', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Schedule',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Consumer<TaskProvider>(
                          builder: (_, provider, __) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${provider.pendingCount} pending',
                              style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedDay;
                          final dayDate = _weekStart.add(Duration(days: index));
                          final isToday = dayDate.day == DateTime.now().day &&
                              dayDate.month == DateTime.now().month;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = index),
                            child: Container(
                              width: 52,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryPurple : AppTheme.backgroundCardMedium,
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected ? null : Border.all(
                                  color: isToday ? AppTheme.primaryPurple.withOpacity(0.5) : Colors.white10,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_days[index],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? Colors.white : (isToday ? AppTheme.primaryPurple : AppTheme.textGray),
                                      )),
                                  const SizedBox(height: 4),
                                  Text('${dayDate.day}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppTheme.textWhite,
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Consumer<TaskProvider>(
                      builder: (_, provider, __) => Row(
                        children: [
                          _buildStatCard('Total', '${provider.tasks.length}', Icons.list_alt, AppTheme.primaryPurple),
                          const SizedBox(width: 12),
                          _buildStatCard('Done', '${provider.completedCount}', Icons.check_circle_outline, AppTheme.success),
                          const SizedBox(width: 12),
                          _buildStatCard('Pending', '${provider.pendingCount}', Icons.pending_actions, AppTheme.gold),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tasks Section
                    Builder(
                      builder: (context) {
                        final selectedDate = _weekStart.add(Duration(days: _selectedDay));
                        final isToday = selectedDate.day == DateTime.now().day &&
                            selectedDate.month == DateTime.now().month;
                        final label = isToday
                            ? "Today's Tasks"
                            : DateFormat('EEE, d MMM').format(selectedDate);
                        return Text(label,
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ));
                      },
                    ),
                    const SizedBox(height: 12),

                    Consumer<TaskProvider>(
                      builder: (_, provider, __) {
                        // Filter tasks matching the selected date
                        final selectedDate = _weekStart.add(Duration(days: _selectedDay));
                        final filtered = provider.tasks.where((t) {
                          if (t.time != null) {
                            return t.time!.day == selectedDate.day &&
                                t.time!.month == selectedDate.month &&
                                t.time!.year == selectedDate.year;
                          }
                          // Tasks without a time: show on their saved date
                          if (t.date.isNotEmpty) {
                            try {
                              final taskDate = DateTime.parse(t.date);
                              return taskDate.day == selectedDate.day &&
                                  taskDate.month == selectedDate.month &&
                                  taskDate.year == selectedDate.year;
                            } catch (_) {}
                          }
                          return false;
                        }).toList();

                        if (filtered.isEmpty) {
                          return _buildEmptyState();
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = filtered[index];
                            return _buildTaskCard(task, provider);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    // Clear All Button
                    Consumer<TaskProvider>(
                      builder: (_, provider, __) => provider.tasks.isNotEmpty
                          ? Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  await NotificationService().cancelAll();
                                  await provider.clearAll();
                                },
                                icon: const Icon(Icons.delete_sweep, color: AppTheme.error),
                                label: const Text('Clear All Tasks', style: TextStyle(color: AppTheme.error)),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // + FAB sits above the bottom nav, not overlapping it
            Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showAddTaskDialog,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, TaskProvider provider) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await NotificationService().cancelTaskNotification(task.id);
        await provider.removeTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${task.title} deleted'), backgroundColor: AppTheme.backgroundCardMedium),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCardMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.completed ? AppTheme.success.withOpacity(0.4) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => provider.toggleComplete(task.id),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppTheme.success : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? AppTheme.success : AppTheme.textGray,
                    width: 2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_categoryColor(task.category)} ${task.title}',
                    style: TextStyle(
                      color: task.completed ? AppTheme.textGray : AppTheme.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (task.time != null)
                        Text(
                          DateFormat('hh:mm a').format(task.time!),
                          style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12),
                        ),
                      if (task.time != null) const SizedBox(width: 8),
                      Text(
                        task.duration,
                        style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.category,
                style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCardMedium,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'YOG ki koi task nahi hai aaj!',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Home pe jao aur YOG ko voice se bolo —\naapka schedule ban jayega!',
            style: TextStyle(color: AppTheme.textGray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
