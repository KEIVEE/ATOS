//텍스트 등록 페이지
import 'package:atos/control/ui.dart';
import 'package:flutter/material.dart';
import 'package:atos/inputs/translating.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.id});
  final String id;

  @override
  State<AddPage> createState() => AddState();
}

class AddState extends State<AddPage> {
  var inputText = ''; //입력한 텍스트
  var region = ''; //본인 지역
  bool willTranslate = true; //번역을 할 건가
  String selectedTheme = '일상생활'; //테마

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 100),
                ManageSizedBox(
                    content: Column(
                      children: [
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: '텍스트를 입력해주세요.',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    12.0), // Rounded corners
                                borderSide: BorderSide.none, // No border line
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            onChanged: (text) {
                              inputText = text;
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
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
                                const Text('번역하기'),
                              ],
                            ),
                            DropdownButton<String>(
                              value: selectedTheme,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedTheme = newValue!;
                                });
                              },
                              items: <String>[
                                '아나운서',
                                '발표',
                                '일상생활',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomedButton(
                          text: '확인',
                          buttonColor: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          onTap: () async {
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
                                    settings: const RouteSettings(
                                        name: "/translating"),
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
                                  settings:
                                      const RouteSettings(name: "/processing"),
                                  builder: (context) => TranslatingPage(
                                      id: widget.id,
                                      inputText: inputText,
                                      todo: "처리중이에요..",
                                      theme: selectedTheme),
                                ));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    boxHeight: 600)
              ],
            ),
          ),
        ));
  }
}
