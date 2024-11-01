import 'package:flutter/material.dart';
import 'package:atos/account/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userName, required this.id});

  final String userName;
  final String id;

  @override
  State<HomePage> createState() => HomeState();
}

class HomeState extends State<HomePage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  var connected = false;
  var connectTried = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 50), // Add spacing to avoid overlap
                const Text('오늘의 추천 문장:'),
                const Text('사투리 교정'),
                // Safely displaying the user's email
                //Text(auth.currentUser?.photoURL ?? '지역이 없습니다.'),
                //Text(widget.id),
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('시도하기'),
                ),
                const SizedBox(height: 10),
                const Text('잔디심기 부분',
                    style: TextStyle(fontSize: 30, height: 3)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: "/settiing"),
                    builder: (context) =>
                        SettingPage(userName: widget.userName, id: widget.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}