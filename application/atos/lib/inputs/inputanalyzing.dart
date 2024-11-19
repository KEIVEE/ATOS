import 'package:atos/inputs/show.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InputAnalyzingPage extends StatefulWidget {
  const InputAnalyzingPage({
    super.key,
    required this.id,
    required this.inputText,
  });

  final String id;
  final String inputText;

  @override
  State<InputAnalyzingPage> createState() => InputAnalyzingState();
}

class InputAnalyzingState extends State<InputAnalyzingPage> {
  var region = '';
  var translatedText = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  Future<void> _fetchRegion() async {
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await db.collection('userData').doc(widget.id).get();
      setState(() {
        region = userDoc['region'];
      });
    }
  }

  @override
  void initState() async {
    super.initState();
    _fetchRegion();

    try {
      http.Response response = await http.post(
          Uri.parse('http://http://222.237.88.211:8000/translate-text'),
          body: json.encode({
            'text': widget.inputText,
            'user_id': widget.id,
            "region": region
          }),
          headers: headers);

      if (response.statusCode != 200) {
        debugPrint("등록 오류.");
      }

      final responseData = jsonDecode(response.body);
      setState(() {
        translatedText = responseData['translated_text_data'];
      });
    } catch (e) {
      debugPrint("에러 발생: $e");
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: "/translated"),
        builder: (context) => ShowPage(id: widget.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // 뒤로 가기 동작 비활성화
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('분석중이에요'),
              SizedBox(
                width: 100, // 원하는 너비
                height: 100, // 원하는 높이
                child: CircularProgressIndicator(
                  strokeWidth: 10, // 두께 조절
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
