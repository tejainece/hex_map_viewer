import 'package:flutter/material.dart';
import 'package:mapeditor/ui/map/map.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp(this.prefs, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(prefs),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage(this.prefs, {super.key});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  SharedPreferences get prefs => widget.prefs;

  @override
  Widget build(BuildContext context) {
    return const Material(color: Colors.transparent, child: MapWidget());
  }
}
