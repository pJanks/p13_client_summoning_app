import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ioconic Qless App',
      home: const MyHomePage(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFE0000),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _windowNumberSectionAnimationController;
  late AnimationController _customerInfoSectionAnimationController;
  late AnimationController _registerAnimationController;

  late Animation<int> _windowNumberSectionAnimation;
  late Animation<int> _customerInfoSectionAnimation;
  late Animation<Color?> _registerAnimation;

  late Timer _intervalTimer;
  late List _windowData;

  String? _customerNumber;
  String? _customerName;
  String? _windowNumber;

  bool _customerWasCalled = false;
  double _fontSize = 400;

  // this value will have to be set for each window
  // in order for the app to know which window it is
  //
  // need to make this dynamic through socket.io ??
  final String _tid = '7ddf16bfb96a08877474de531c8b2b39';

  void _setCustomerWasCalled() {
    setState(() => _customerWasCalled = !_customerWasCalled);
  }

  void _setIntervalTimer() {
    _intervalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _setFontSize();
    });
  }

  void _setFontSize() {
    setState(() => _fontSize == 400 ? _fontSize = 220 : _fontSize = 400);
  }

  void _setWindowNumber(String windowNumber) {
    setState(() => _windowNumber = windowNumber);
  }

  void _setCustomerName(String? name) {
    setState(() => _customerName = name);
  }

  void _setCustomerNumber(String? number) {
    setState(() => _customerNumber = '*$number');
  }

  Future<void> _getWindowData() async {
    final String response =
        await rootBundle.loadString('assets/screen_data.json');
    final data = await json.decode(response);
    setState(() => _windowData = data['data']);
    _findWindowNumber();
  }

  void _findWindowNumber() {
    final window =
        _windowData.firstWhere((element) => element['tid'] == _tid, orElse: () {
      return null;
    });
    _setWindowNumber(window['windownumber']);
  }

  void _handleCustomerHasBeenCalled() {
    if (!_customerWasCalled) {
      _setCustomerWasCalled();
      _intervalTimer.cancel();

      // this data will come from backend via socket.io
      _setCustomerName('tester');
      _setCustomerNumber('1234');

      _windowNumberSectionAnimationController.forward();
      _customerInfoSectionAnimationController.forward();
      _registerAnimationController.forward();

      // need to change this duration in production
      Future.delayed(const Duration(seconds: 5), () {
        _setIntervalTimer();
        _windowNumberSectionAnimationController.reverse();
        _customerInfoSectionAnimationController.reverse();
        _registerAnimationController.reverse();
        Future.delayed(const Duration(milliseconds: 2500), () {
          _setCustomerWasCalled();
          _setCustomerName(null);
          _setCustomerNumber(null);
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _getWindowData();
    _setIntervalTimer();

    _windowNumberSectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _windowNumberSectionAnimation = IntTween(begin: 9999, end: 3000)
        .animate(_windowNumberSectionAnimationController)
      ..addListener(() => setState(() => _fontSize = 200));

    _customerInfoSectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _customerInfoSectionAnimation = IntTween(begin: 1, end: 7000)
        .animate(_customerInfoSectionAnimationController);

    _registerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _registerAnimation =
        ColorTween(begin: const Color(0xFFFE0000), end: const Color(0xFFFFFFFF))
            .animate(_registerAnimationController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            Expanded(
              flex: _windowNumberSectionAnimation.value,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  Positioned(
                    top: 0,
                    child: Text(
                      'register',
                      style: TextStyle(
                        color: _registerAnimation.value,
                        fontFamily: 'ZingRust',
                        fontSize: 50,
                      ),
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: _fontSize,
                    ),
                    duration: const Duration(milliseconds: 1500),
                    child: Text(
                      // the tabs fix bug with edges of numbers getting cut
                      // off but displays 'no glyph' error in chrome browser
                      '\t$_windowNumber\t',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'ZingRust',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: _customerInfoSectionAnimation.value,
              child: Container(
                color: const Color(0xFFFFFFFF),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    const Positioned(
                      top: 55,
                      child: Text(
                        'now serving',
                        style: TextStyle(
                          fontFamily: 'ZingRust',
                          fontSize: 120,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 180,
                      child: Text(
                        _customerName ?? '',
                        style: const TextStyle(
                          color: Color(0xFFFE0000),
                          fontFamily: 'ZingRust',
                          fontSize: 120,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 280,
                      child: Text(
                        _customerNumber ?? '',
                        style: const TextStyle(
                          fontFamily: 'ZingRust',
                          fontSize: 200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // remove this button in production and
      // call _handleCustomerHasBeenCalled fn
      // on socket.io emitted events
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCustomerHasBeenCalled,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _windowNumberSectionAnimationController.dispose();
    _customerInfoSectionAnimationController.dispose();
    _registerAnimationController.dispose();
  }
}
