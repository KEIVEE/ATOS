//메인 화면. MVVM 해보고 싶지만 시간이 좀 부족할 듯
//control이라는 폴더는 만들어 놨는데 로직 처리를 분리하지는 않았음
//IP를 가리기 위해서 uri.dart에 있는 ControlUri.BASE_URL을 사용하는 경우가 있음
//uri.dart는 gitignore에 추가해서 ip를 가림

import 'package:flutter/material.dart';
import 'package:atos/account/login.dart';
import 'package:atos/account/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:atos/firebase_options.dart';
import 'package:atos/control/ui.dart';

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
        title: '서울말로',
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Color.fromRGBO(42, 52, 110, 1), // 주요 색상
            secondary: Colors.white, // 보조 색상
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const MyHomePage(),
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(42, 52, 110, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //const SizedBox(height: 400),
            Image.asset('assets/images/seoulMallo.png'),
            const SizedBox(height: 50),
            CustomedButton(
                text: '로그인',
                buttonColor: Colors.white,
                textColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/login"),
                      builder: (context) => const LoginPage(),
                    ),
                  );
                }),
            const SizedBox(height: 10),
            CustomedButton(
                text: '회원가입',
                buttonColor: Colors.white,
                textColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/register"),
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
