//메인 화면. MVVM 해보고 싶지만 시간이 좀 부족할 듯
//control이라는 폴더는 만들어 놨는데 로직 처리를 분리하지는 않았음
//IP를 가리기 위해서 uri.dart에 있는 ControlUri.BASE_URL을 사용하는 경우가 있음
//uri.dart는 gitignore에 추가해서 ip를 가림

import 'package:flutter/material.dart';
import 'package:atos/account/login.dart';
import 'package:atos/account/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:atos/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ATOS', //수정
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const MyHomePage(title: 'ATOS'),
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: "/login"),
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('로그인'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: "/register"),
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
