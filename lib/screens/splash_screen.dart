import 'dart:async';


import 'package:flutter/material.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2),
            () => Navigator.of(context).pushReplacementNamed('/register'));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Container(
                alignment: Alignment.center,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset("assets/logoimg.png",
                            width: 300, height: 300)),
                    SafeArea(
                        child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Column(
                              children: [
                                Text(
                                  "Twuni",
                                  style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  "Developed by SK Robotics",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic),
                                )
                              ],
                            )))
                  ],
                ))));
  }
}



