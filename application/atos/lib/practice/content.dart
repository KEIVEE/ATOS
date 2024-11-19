import 'package:flutter/material.dart';
import 'package:atos/practice/try.dart';

class ContentPage extends StatefulWidget {
  const ContentPage(
      {super.key,
      required this.id,
      required this.title,
      required this.sentence});
  final String id;
  final String title;
  final String sentence;

  @override
  State<ContentPage> createState() => ContentState();
}

class ContentState extends State<ContentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(widget.title),
            Text(widget.sentence),
            const Text('문명 그래프'),
            OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/try"),
                      builder: (context) => TryPage(id: widget.id),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('연습하기')),
          ],
        ),
      ),
    );
  }
}
