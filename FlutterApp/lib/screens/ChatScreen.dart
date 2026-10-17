import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
final int productId;
final int sellerId;
final String productTitle;
final String productPrice;
final int? chatId;
final String? otherUserName;

const ChatScreen({
super.key,
required this.productId,
required this.sellerId,
required this.productTitle,
required this.productPrice,
  this.chatId,
  this.otherUserName,

});

@override
State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _messageController =
  TextEditingController();

  final List<Map<String, dynamic>> _messages = [];

  int? _chatId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }



  Future<void> _unsendMessage(Map<String, dynamic> message) async {
    final chatId = _chatId;
    final messageId = int.tryParse(
      message['message_id'].toString(),
    );

    if (chatId == null || messageId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsend message?'),
        content: const Text(
          'This message will be removed from the conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Unsend'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.unsendChatMessage(
        chatId: chatId,
        messageId: messageId,
      );

      if (!mounted) return;

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not unsend message: $e';
      });
    }
  }




  Future<void> _initializeChat() async {
    try {
      final userId = await AuthService.getUserId();

      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isLoading = true;
          _error = null;
        });
      }

      int chatId;

      if (widget.chatId != null) {
        // Open an existing conversation from My Chats.
        chatId = widget.chatId!;
      } else {
        // Create or find a conversation from the product page.
        final chat = await ApiService.createOrGetChat(
          productId: widget.productId,
        );

        chatId = int.parse(chat['chat_id'].toString());
      }

      if (!mounted) return;

      setState(() {
        _chatId = chatId;
      });

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to open chat: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _loadMessages() async {
    final chatId = _chatId;
    if (chatId == null) return;

    try {
      final messages = await ApiService.getChatMessages(
        chatId: chatId,
      );

      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(
            messages.map((message) {
              final senderId = int.parse(
                message['sender_id'].toString(),
              );

              final createdAt = message['created_at']?.toString();
              final parsedDate = createdAt == null
                  ? null
                  : DateTime.tryParse(createdAt)?.toLocal();

              return {
                ...message,
                'isMe': _currentUserId != null &&
                    senderId.toString() == _currentUserId,
                'time': parsedDate == null
                    ? ''
                    : TimeOfDay.fromDateTime(
                  parsedDate,
                ).format(context),
              };
            }),
          );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }


  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final chatId = _chatId;

    if (message.isEmpty) {
      debugPrint('Chat: message is empty');
      return;
    }

    if (chatId == null) {
      debugPrint('Chat: chatId is null; chat is not initialized');
      setState(() {
        _error = 'Chat is not ready. Please reopen the chat.';
      });
      return;
    }

    if (_isSending) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      debugPrint('Chat: sending message to chatId=$chatId');

      await ApiService.sendChatMessage(
        chatId: chatId,
        message: message,
      );

      if (!mounted) return;

      _messageController.clear();
      await _loadMessages();
    } catch (e, stackTrace) {
      debugPrint('Chat send error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = 'Failed to send message: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }



@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
appBar: AppBar(
backgroundColor: Colors.white,
foregroundColor: Colors.black,
elevation: 1,
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

  Text(
    widget.otherUserName?.trim().isNotEmpty == true
        ? widget.otherUserName!.trim()
        : 'Chat',
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
  ),

Text(
widget.productTitle,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
body: Column(
children: [

Expanded(
child: _messages.isEmpty
? Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.chat_bubble_outline,
size: 55,
color: Colors.grey.shade400,
),
const SizedBox(height: 12),
const Text(
'Start a conversation',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 5),
Text(
'Ask the seller about this product.',
style: TextStyle(
color: Colors.grey.shade600,
),
),
],
),
)
    : ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: _messages.length,
itemBuilder: (context, index) {
final message = _messages[index];
final isMe = message['isMe'] as bool;


return Align(
  alignment: isMe
      ? Alignment.centerRight
      : Alignment.centerLeft,
  child: GestureDetector(
    onLongPress: isMe &&
        message['is_deleted'] != true
        ? () => _unsendMessage(message)
        : null,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      constraints: BoxConstraints(
        maxWidth:
        MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.shade800
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message['message'] as String,
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message['time'] as String,
            style: TextStyle(
              fontSize: 10,
              color: isMe
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    ),
  ),
);

},
),
),
SafeArea(
top: false,
child: Container(
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
  decoration: BoxDecoration(
  color: Colors.white,
  border: Border(
  top: BorderSide(color: Colors.grey.shade300),
  ),
  ),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  if (_error != null)
  Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: SizedBox(
  width: double.infinity,
  child: Text(
  _error!,
  style: const TextStyle(
  color: Colors.red,
  fontSize: 12,
  ),
  ),
  ),
  ),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: _messageController,
  minLines: 1,
  maxLines: 4,
  textCapitalization: TextCapitalization.sentences,
  decoration: InputDecoration(
  hintText: 'Type a message...',
  filled: true,
  fillColor: Colors.grey.shade100,
  contentPadding: const EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
  ),
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(25),
  borderSide: BorderSide.none,
  ),
  ),
  onSubmitted: (_) => _sendMessage(),
  ),
  ),
  const SizedBox(width: 8),
  IconButton(
  onPressed: _isSending ? null : _sendMessage,
  icon: _isSending
  ? const SizedBox(
  width: 22,
  height: 22,
  child: CircularProgressIndicator(
  strokeWidth: 2,
  color: Colors.white,
  ),
  )
      : const Icon(Icons.send_rounded),
  color: Colors.white,
  style: IconButton.styleFrom(
  backgroundColor: Colors.blue.shade800,
  ),
  ),
  ],
  ),
  ],
  ),
  )

),
],
),
);
}
}
