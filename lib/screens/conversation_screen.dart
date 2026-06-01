import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConversationScreen extends StatelessWidget {
  final List<Map<String, String>> messages;

  const ConversationScreen({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Conversation', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: messages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppTheme.textGray, size: 48),
                  SizedBox(height: 16),
                  Text('No conversation yet', style: TextStyle(color: AppTheme.textGray, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Say the wake word to start talking to YOG', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text('Y', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'You' : 'YOG',
                              style: TextStyle(
                                color: isUser ? AppTheme.primaryPurple : AppTheme.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['text'] ?? '',
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppTheme.textWhite, size: 16),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
