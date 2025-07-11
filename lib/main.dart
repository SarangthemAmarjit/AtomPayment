import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Web Views',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Arial",
      ),
      home: const Home(),
    );
  }
}
