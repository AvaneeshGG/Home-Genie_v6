import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_genie/todo.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(HomeGenie());
}

class HomeGenie extends StatelessWidget {
  const HomeGenie({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.light,
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
  late final PanelController _panelController = PanelController();
  String? globalConnectCode;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _getFirebaseCode(); // Call the method to fetch globalConnectCode
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

  void _getFirebaseCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('globalConnectCode');
    setState(() {
      globalConnectCode = code;
      print(globalConnectCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            // Simulate a refresh delay
            await Future.delayed(Duration(seconds: 1));

            // Once the delay is over, update the UI with new data or perform any necessary operations
            setState(() {
              // Update data or perform any necessary operations here
            });
          },
          child: Stack(
            children: [
              SlidingUpPanel(
                controller: _panelController,
                backdropEnabled: true,
                minHeight: 0.0, // Set minimum height to 0.0
                maxHeight: 500.0, // Set maximum height to 0.0
                panel: Center(
                  child: Text(_fullStatement),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),

                      Container(
                        color: Colors.red, // Set color here
                        height: 100,
                        width: MediaQuery.of(context).size.width, // Take full width
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
                      SizedBox(height: 20), // Add some spacing between containers
                      Container(
                        color: Colors.green, // Set color here
                        height: 300,
                        width: MediaQuery.of(context).size.width, // Take full width
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Text(
                                'To Do',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(

                                stream: globalConnectCode != null && globalConnectCode!.isNotEmpty
                                    ? FirebaseFirestore.instance
                                    .collection('sharedCollection')
                                    .doc(globalConnectCode)
                                    .collection('todos')
                                    .orderBy('timestamp', descending: true)
                                    .limit(3)
                                    .snapshots()
                                    : Stream.empty(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(), // Show loading indicator while fetching data
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'), // Show error if encountered
                                    );
                                  }
                                  if (snapshot.hasData) {
                                    final documents = snapshot.data!.docs;
                                    if (documents.isEmpty) {
                                      return Center(
                                        child: Text('No data available'), // Show message if no documents found
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: documents.length,
                                      itemBuilder: (context, index) {
                                        // Build UI for each document
                                        final todo = documents[index].data() as Map<String, dynamic>;
                                        return ListTile(
                                          title: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '• ${todo['title']}', // Assuming 'title' is a field in your document
                                                style: TextStyle(
                                                  color: Colors.white, // Set text color to white
                                                  fontSize: 16, // Example font size, adjust as needed
                                                  fontWeight: FontWeight.bold, // Example font weight, adjust as needed
                                                ),
                                              ),
                                              SizedBox(height: 1), // Add spacing between bullet point and description
                                              Text(
                                                todo['description'], // Assuming 'description' is a field in your document
                                                style: TextStyle(
                                                  color: Colors.white70, // Set text color to a lighter shade of white
                                                  fontSize: 14, // Example font size, adjust as needed
                                                ),
                                              ),
                                            ],
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 20), // Add padding to ListTile content
                                          onTap: () {
                                            // Add onTap functionality if needed
                                          },
                                        );
                                      },
                                    );
                                  }
                                  return SizedBox.shrink(); // If none of the above conditions are met, return an empty SizedBox
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20), // Add some spacing between containers
                      Container(
                        color: Colors.blue, // Set color here
                        height: 100,
                        width: MediaQuery.of(context).size.width, // Take full width
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                child: Visibility(
                  visible: _isListening,
                  child: FloatingActionButton(
                    onPressed: () {
                      _panelController.open();
                      _toggleListening();
                      // Open the SlidingUpPanel
                    },
                    child: Icon(Icons.stop),
                    tooltip: 'Stop',
                    elevation: 0,
                    shape: CircleBorder(),
                  ),
                  replacement: FloatingActionButton(
                    onPressed: () {
                      _panelController.open();
                      _toggleListening();
                      // Open the SlidingUpPanel
                    },
                    child: Icon(Icons.mic),
                    tooltip: 'Listen',
                    elevation: 0,
                    shape: CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
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
          backgroundColor: Colors.white,
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
      ),
    );
  }
}
