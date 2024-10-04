import 'package:atos/managing/add.dart';
import 'package:atos/managing/practice.dart';
import 'package:flutter/material.dart';
import 'package:atos/managing/home.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class ManagePage extends StatefulWidget {
  const ManagePage({super.key, required this.userName, required this.id});
  final String userName;
  final String id;

  @override
  State<ManagePage> createState() => ManageState();
}

class ManageState extends State<ManagePage>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(tabListener);
  }

  @override
  void dispose() {
    controller.removeListener(tabListener);
    super.dispose();
  }

  void tabListener() {
    setState(() {
      selectedIndex = controller.index;
    });
  }

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
          title: Text('안녕하세요, ${widget.userName}님'),
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: (int index) {
              controller.animateTo(index);
            },
            currentIndex: selectedIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: '입력'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: '연습'),
            ]),
        body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            children: const [
              HomePage(userName: '디버그', id: '디버그'),
              AddPage(userName: '디버그', id: '디버그'),
              PracticePage(userName: '디버그', id: '디버그'),
            ]));
  }
}
