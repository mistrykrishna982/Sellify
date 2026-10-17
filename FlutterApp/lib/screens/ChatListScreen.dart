import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ChatScreen.dart';

class ChatListScreen extends StatefulWidget {
const ChatListScreen({super.key});

@override
State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
List<Map<String, dynamic>> _chats = [];
bool _isLoading = true;
String? _error;

@override
void initState() {
super.initState();
_loadChats();
}

Future<void> _loadChats() async {
try {
final chats = await ApiService.getChats();

if (!mounted) return;

setState(() {
_chats = chats;
_error = null;
});
} catch (e) {
if (!mounted) return;

setState(() {
_error = e.toString();
});
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('My Chats'),
actions: [
IconButton(
onPressed: _loadChats,
icon: const Icon(Icons.refresh),
),
],
),
body: _isLoading
? const Center(child: CircularProgressIndicator())
    : _error != null
? Center(child: Text(_error!))
    : _chats.isEmpty
? const Center(
child: Text('No conversations yet'),
)
    : ListView.builder(
itemCount: _chats.length,
itemBuilder: (context, index) {
final chat = _chats[index];

return ListTile(
leading: const CircleAvatar(
child: Icon(Icons.chat),
),

  title: Text(
    chat['other_user_name']?.toString().trim().isNotEmpty == true
        ? chat['other_user_name'].toString()
        : 'User',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        chat['product_title']?.toString() ?? 'Product',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        (chat['last_message']?.toString().trim().isNotEmpty == true)
            ? chat['last_message'].toString()
            : 'Start a conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      ),
    ],
  ),

trailing: const Icon(
Icons.chevron_right,
),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(


builder: (_) => ChatScreen(
chatId: int.parse(chat['chat_id'].toString()),
  productId: int.parse(chat['product_id'].toString()),
  sellerId: int.parse(chat['seller_id'].toString()),
  productTitle: chat['product_title']?.toString() ?? 'Product',
  productPrice: chat['product_price']?.toString() ?? '',
  otherUserName: chat['other_user_name']?.toString(),
  ),

),
);
},
);
},
),
);
}
}
