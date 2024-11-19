import 'package:flutter/material.dart';
import 'package:atos/inputs/translating.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.id});
  final String id;

  @override
  State<AddPage> createState() => AddState();
}

class AddState extends State<AddPage> {
  var inputText = '';
  var region = '';
  var translatedText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 5),
            TextField(
              maxLines: 20,
              decoration: const InputDecoration(
                  labelText: '텍스트를 입력해주세요.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 250.0,
                    maxWidth: 350.0,
                  )),
              onChanged: (text) {
                inputText = text;
              },
            ),
            const Text('바로 연습할건지, 아니면 번역을 거칠 건지'),
            OutlinedButton(
                onPressed: () async {
                  if (inputText.isEmpty) {
                    // 입력 텍스트가 비어있을 경우
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('텍스트를 입력해주세요.')),
                    );
                    return;
                  } else if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: "/translating"),
                        builder: (context) => AnalyzingPage(
                          id: widget.id,
                          inputText: inputText,
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('확인')),
            const Text('양옆으로 바꿀 거임\n그리고 테마선택'),
          ],
        ),
      ),
    );
  }
}
