import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.messageData});

  final Map<String, dynamic>? messageData;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
    token: dotenv.env['OPENAI_API_TOKEN'],
    baseOption: HttpSetup(
      receiveTimeout: const Duration(
        seconds: 5,
      ),
    ),
    enableLog: true,
  );

  late final ChatUser _currentUser;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentUser = ChatUser(id: '1', firstName: userProvider.email);
    if (widget.messageData != null) {
      List<ChatMessage> currentUserMessages = [];
      List<ChatMessage> gptChatUserMessages = [];
      widget.messageData!.forEach((key, value) {
        for (var entry in value.entries) {
          if (entry.value is List) {
            for (var message in entry.value) {
              if (message is Map<String, dynamic> &&
                  message.containsKey('text')) {
                if (entry.key == "_currentUser") {
                  currentUserMessages.add(
                    ChatMessage(
                      user: _currentUser,
                      createdAt: DateTime.parse(key),
                      text: message['text'],
                    ),
                  );
                } else {
                  gptChatUserMessages.add(
                    ChatMessage(
                      user: _gptChatUser,
                      createdAt: DateTime.parse(key),
                      text: message['text'],
                    ),
                  );
                }
              }
            }
          }
        }
      });

      // Alternate messages starting with _currentUser messages
      int totalMessages =
          currentUserMessages.length + gptChatUserMessages.length;
      for (int i = 0; i < totalMessages; i++) {
        if (i % 2 == 0) {
          // Even places for _currentUser
          if (currentUserMessages.isNotEmpty) {
            _messages.insert(0, currentUserMessages.removeLast());
          } else if (gptChatUserMessages.isNotEmpty) {
            _messages.insert(0, gptChatUserMessages.removeLast());
          }
        } else {
          // Odd places for gptChatUser
          if (gptChatUserMessages.isNotEmpty) {
            _messages.insert(0, gptChatUserMessages.removeLast());
          } else if (currentUserMessages.isNotEmpty) {
            _messages.insert(0, currentUserMessages.removeLast());
          }
        }
      }
    }
  }

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(
          0,
          166,
          126,
          1,
        ),
        title: const Text(
          'GPT Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          messageOptions: const MessageOptions(
            currentUserContainerColor: Colors.black,
            containerColor: Color.fromRGBO(
              0,
              166,
              126,
              1,
            ),
            textColor: Colors.white,
          ),
          onSend: (ChatMessage m) {
            getResponse(m);
          },
          messages: _messages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tips_and_updates),
            label: 'Interventions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
            tooltip: 'History',
          ),
        ],
        selectedItemColor: Colors.green,
        onTap: (index) {
          // Check the index and navigate accordingly
          if (index == 2) {
            // Assuming the User Profile is the third item
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewHistoryPage()),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InterventionsSummaryPage()),
            );
          }
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MealSummaryPage(
                        email: Provider.of<UserProvider>(context, listen: false)
                                .email ??
                            '',
                      )),
            );
          }
          // Handle other indices if needed
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            bottom: 75.0), // Added padding to lift the button up
        child: FloatingActionButton(
          onPressed: () {
            saveChatHistory(_messages);
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final String? userEmail = Provider.of<UserProvider>(context, listen: false)
        .email; // Using email as a unique identifier for the user
    if (userEmail == null) {
      if (kDebugMode) {
        print("User email is null, cannot save chat history.");
      }
      return;
    }
    Map<String, dynamic> organizedChatDump = {};
    for (var message in messages) {
      String date = DateFormat('yyyy-MM-dd').format(message.createdAt);
      if (!organizedChatDump.containsKey(date)) {
        organizedChatDump[date] = {
          '_currentUser': [],
          '_gptUser': [],
          'createdAt': date,
        };
      }
      if (message.user.id == _currentUser.id) {
        organizedChatDump[date]['_currentUser'].add({
          'text': message.text,
        });
      } else {
        organizedChatDump[date]['_gptUser'].add({
          'text': message.text,
        });
      }
    }
    final url = Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/save_user_chat_history');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'emailId': userEmail,
        'chatDump': json.encode(organizedChatDump),
      }),
    );

    if (response.statusCode == 201) {
      if (kDebugMode) {
        print("Chat history saved successfully.");
      }
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Chat Saved"),
            content: const Text("Do you want to continue chatting or exit?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Continue"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Exit"),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InterventionsSummaryPage()),
                  );
                },
              ),
            ],
          );
        },
      );
      _messages.clear();
    } else {
      if (kDebugMode) {
        print("Failed to save chat history: ${response.body}");
      }
    }
  }

  Future<void> getResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });
    // Prepend a context-setting message to guide the conversation.
    final contextMessage = Messages(
      role: Role.assistant,
      content:
          "This conversation will provide diet tips, health tips, suggest alternative foods for better calorie management, and help with calorie intake tracking.",
    );

    List<Messages> messagesHistory = [contextMessage] +
        _messages.reversed.map((m) {
          if (m.user == _currentUser) {
            return Messages(role: Role.user, content: m.text);
          } else {
            return Messages(role: Role.assistant, content: m.text);
          }
        }).toList();

    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: messagesHistory.map((message) => message.toJson()).toList(),
      maxToken: 200,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content),
          );
        });
      }
    }
    setState(() {
      _typingUsers.remove(_gptChatUser);
    });
  }
}
