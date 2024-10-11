import 'package:flutter/material.dart';
import 'package:atos/inputs/analyzing.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.userName, required this.id});

  final String userName;
  final String id;

  @override
  State<AddPage> createState() => AddState();
}

class AddState extends State<AddPage> {
  var inputText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('텍스트를 입력해주세요.'),
            TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 150.0,
                      maxWidth: 350.0,
                    )),
                onChanged: (text) {
                  inputText = text;
                }),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('불러오기')),
            OutlinedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyzingPage(
                          userName: widget.userName,
                          id: widget.id,
                          previousPageName: 'AddPage',
                          duration: const Duration(seconds: 3),
                        ),
                      ));
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('확인')),
            const Text('양옆으로 바꿀 거임'),
          ],
        ),
      ),
    );
  }
}
