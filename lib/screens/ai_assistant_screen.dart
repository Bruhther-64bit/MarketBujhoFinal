import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // 1. ADD THIS IMPORT

import '../models/product_model.dart';
import '../services/ai_helper_service.dart';
import '../providers/compare_provider.dart'; // optional if you want to pass context

class AiAssistantScreen extends StatefulWidget {
  final List<Product>? contextProducts;

  const AiAssistantScreen({
    Key? key,
    this.contextProducts,
  }) : super(key: key);

  @override
  State<AiAssistantScreen> createState() =>
      _AiAssistantScreenState();
}

class _Message {
  final String text;
  final bool isUser;

  _Message({required this.text, required this.isUser});
}

class _AiAssistantScreenState
    extends State<AiAssistantScreen> {
  final TextEditingController _controller =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  final AiHelperService _aiService = AiHelperService();

  final List<_Message> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    List<Product>? contextProducts = widget.contextProducts;

    final reply =
        await _aiService.askShoppingAssistant(
      text,
      contextProducts: contextProducts,
    );

    setState(() {
      _messages.add(
          _Message(text: reply, isUser: false));
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Helper method to build the content widget (Text or MarkdownBody)
  Widget _buildMessageContent(
      String text, bool isUser, Color textColor) {
    if (isUser) {
      // User messages remain plain text
      return Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
      );
    } else {
      // 2. AI messages use MarkdownBody for rich text rendering
      return MarkdownBody(
        data: text,
        // Customize the style to ensure readability within the chat bubble
        styleSheet: MarkdownStyleSheet(
          // Set the default paragraph text color
          p: TextStyle(color: textColor, fontSize: 14, height: 1.4),
          // Set heading styles
          h1: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
          h2: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          // Set strong/bold text color
          strong: TextStyle(
              color: textColor, fontWeight: FontWeight.bold),
          // Set bullet point color
          listBullet: TextStyle(
              color: textColor, fontSize: 14),
          // Set blockquote style for better contrast
          blockquote: TextStyle(
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
          code: TextStyle(
            backgroundColor: Colors.black12,
            color: Colors.blueGrey.shade800,
          )
        ),
        // Ensure links are clickable if the AI provides them
        onTapLink: (text, href, title) {
          // You would typically use a package like url_launcher here
          // to open the link in a browser.
          if (href != null) {
            print('Tapped link: $href');
            // For example: launchUrl(Uri.parse(href));
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optional: if you ever want to pull context from providers
    final compareProvider =
        context.watch<CompareProvider>();
    final hasCompareContext =
        compareProvider.selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketBujho AI Assistant'),
        actions: [
          if (hasCompareContext)
            Padding(
              padding:
                  const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Using ${compareProvider.selected.length} items as context',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final alignment = msg.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft;
                final bgColor = msg.isUser
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.grey.shade200;
                final textColor = msg.isUser
                    ? Colors.white
                    : Colors.black87;

                return Align(
                  alignment: alignment,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(
                            vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context)
                              .size
                              .width *
                              0.8,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    // 3. Use the new helper method here
                    child: _buildMessageContent(
                      msg.text,
                      msg.isUser,
                      textColor,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding:
                  const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                        color:
                            Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) =>
                          _sendMessage(),
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Ask about deals, products, or what to buy...',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}