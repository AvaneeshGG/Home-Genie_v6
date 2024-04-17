import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_genie/todo.dart';
import 'Inventory.dart';
import 'firebase_options.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import './profile_page.dart';
import './login_page.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import './manager.dart';
import './pantry.dart';
import './todo.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(HomeGenie());

  fetchData('a');
}

class HomeGenie extends StatelessWidget {
  const HomeGenie({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: LoginPage(),
    );
  }
}

class HG_App extends StatefulWidget {
  const HG_App({Key? key}) : super(key: key);

  @override
  HG_AppState createState() => HG_AppState();
}

class HG_AppState extends State<HG_App> {
  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _httpResponse = '';
  String _fullStatement = ''; // Accumulate full statement
  bool _isListening = false; // Keep track of listening state
  bool _showFullStatement = false;
  double _containerHeight = 0.0;
  double _containerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechToText = SpeechToText();
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _toggleListening() async {
    if (!_isListening) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    } else {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _showFullStatement = true; // Show the full statement container
        _containerHeight = MediaQuery.of(context).size.height; // Extend container to bottom
        _containerOpacity = 1.0; // Make container fully visible
      });
      await sendGetRequest(_fullStatement.trim()); // Send full statement
      _fullStatement = ''; // Reset the statement after sending
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    String currentWords = result.recognizedWords.trim();
    List<String> currentWordList = currentWords.split(' ');

    for (String word in currentWordList) {
      if (!_fullStatement.contains(word.trim())) {
        setState(() {
          _lastWords = word.trim();
          _fullStatement += ' ' + _lastWords; // Accumulate recognized word
        });
      }
    }
  }

  Future<void> sendGetRequest(String statement) async {
    var url = Uri.parse('http://45.248.65.97:5000/api?text=$statement');

    var response = await http.get(url);

    if (response.statusCode == 200) {
      print('Request successful');
      print('Response body: ${response.body}');
      setState(() {
        _httpResponse = response.body;
        fetchData(_httpResponse);
      });
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }

  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.ltr,
        child: WillPopScope(
            onWillPop: () async {
              if (_showFullStatement) {
                setState(() {
                  _showFullStatement = false; // Hide the full statement container
                  _containerHeight = 0.0; // Set container height back to 0
                  _containerOpacity = 0.0; // Make container fully invisible
                });
                return false; // Prevent back navigation
              }
              return true; // Allow back navigation
            },
            child: Scaffold(
              backgroundColor: Color(0xFF202020),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.97,
                              height: MediaQuery.of(context).size.width * 0.18,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6FF80), // Changed here
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      ' Hi User!\n Welcome back',
                                      style: GoogleFonts.openSans(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(Icons.person, size: 45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.97,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                _httpResponse, // Display the httpResponse
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.97,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.97,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.97,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).size.height * 0.1,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: _containerHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Visibility(
                        visible: _showFullStatement,
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: _containerOpacity,
                          child: Center(
                            child: Text(
                              _fullStatement, // Display the full statement
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentPageIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                  // Handle navigation based on the index if needed
                  switch (index) {
                    case 0:
                    // Navigate to home page
                      break;
                    case 1:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Inventory(),
                        ),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Todo(),
                        ),
                      );
                      break;
                    case 3:
                    // Navigate to profile page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            toggleListening: _toggleListening,
                            isListening: _isListening,
                          ),

                        ),
                      );
                      break;
                  }
                },
                backgroundColor: Color(0xFF202020),
                indicatorColor: Theme.of(context).primaryColor,
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.door_sliding_outlined),
                    label: 'Pantry',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.task),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: FloatingActionButton(
                onPressed: _toggleListening,
                child: Icon(_isListening ? Icons.stop : Icons.mic),
                tooltip: 'Listen',
                elevation: 0,
                shape: CircleBorder(),
              ),
            ),
            ),
        );
    }
}