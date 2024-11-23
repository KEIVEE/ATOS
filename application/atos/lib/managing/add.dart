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
  bool willTranslate = true;
  String selectedTheme = '차분한';

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
            Row(
              children: [
                Checkbox(
                  value: willTranslate,
                  onChanged: (bool? value) {
                    setState(() {
                      willTranslate = value ?? false;
                    });
                  },
                ),
                const Text('번역할 거에요'),
              ],
            ),
            DropdownButton<String>(
              value: selectedTheme,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTheme = newValue!;
                });
              },
              items: <String>['성급한', '느긋한', '차분한']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            OutlinedButton(
                onPressed: () async {
                  if (inputText.isEmpty) {
                    // 입력 텍스트가 비어있을 경우
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('텍스트를 입력해주세요.')),
                    );
                    return;
                  } else if (mounted) {
                    if (willTranslate) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: "/translating"),
                          builder: (context) => TranslatingPage(
                            id: widget.id,
                            inputText: inputText,
                            todo: "번역중이에요..",
                            theme: selectedTheme,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        settings: const RouteSettings(name: "/processing"),
                        builder: (context) => TranslatingPage(
                            id: widget.id,
                            inputText: inputText,
                            todo: "처리중이에요..",
                            theme: selectedTheme),
                      ));
                    }
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
