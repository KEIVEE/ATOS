import 'dart:convert';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:atos/practice/titlebutton.dart';

class PracticePage extends StatefulWidget {
  final String id;

  const PracticePage({super.key, required this.id});

  @override
  State<PracticePage> createState() => PracticeState();
}

class PracticeState extends State<PracticePage> {
  late Future<List<dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  Future<List<dynamic>> _fetchData() async {
    final response = await http.get(
        Uri.parse('${ControlUri.BASE_URL}/get-user-practice/${widget.id}'));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No data available');
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var item = snapshot.data![index];
                  return TitleButton(
                    title: item['text'],
                    id: widget.id,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
