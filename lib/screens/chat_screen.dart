import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;

class ChatScreen extends StatefulWidget {
  static String route = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;
  String messageText;
  final messageTextController = TextEditingController();

  ScrollController scrollController;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data.documents;
                  List<MessageBubble> textWidget = [];
                  for (var message in messages) {
                    var messageText = message.data['text'];
                    var messageSender = message.data['sender'];

                    var seen = message.data['readed'];

                    final messageWidget = MessageBubble(
                      message: messageText,
                      sender: messageSender,
                      isLoggedUser:
                          messageSender.toString() == loggedInUser.email,
                      seen: seen,
                    );
                    textWidget.add(messageWidget);
                  }
                  return Expanded(
                    child: ListView(
                controller: scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 10.0),
                      children: textWidget,
                    ),
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlue,
                    ),
                  );
                }
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      FocusScope.of(context).requestFocus(new FocusNode());

                      _firestore.collection('messages').add({
                        'sender': loggedInUser.email,
                        'text': messageText,
                        'readed': false,
                        'timestamp': Timestamp.fromDate(DateTime.now())
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String sender;
  final bool isLoggedUser;
  final bool seen;

  const MessageBubble(
      {this.message, this.sender, this.isLoggedUser, this.seen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isLoggedUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isLoggedUser ? Radius.circular(30.0) : Radius.zero,
              topRight: isLoggedUser ? Radius.zero : Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
            ),
            color: isLoggedUser ? Colors.lightBlueAccent : Colors.green,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Text(
                '$message',
                style: TextStyle(fontSize: 15.0, color: Colors.white),
              ),
            ),
          ),
          if (seen) Icon(Icons.check),
        ],
      ),
    );
  }
}
