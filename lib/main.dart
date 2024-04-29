import 'package:flutter/cupertino.dart';
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
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    return MaterialApp(
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        textTheme: GoogleFonts.redHatDisplayTextTheme().apply(
          bodyColor: Colors.black, // Set text color for light theme
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.redHatDisplayTextTheme().apply(
          bodyColor: Colors.white, // Set text color for dark theme
        ),
      ),
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
  late final PanelController _panelController = PanelController();
  String? globalConnectCode;
  String? data = '';
  bool _isPanelOpen = false;

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

  Future<void> _toggleListening() async {
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
        _containerHeight =
            MediaQuery.of(context).size.height; // Extend container to bottom
        _containerOpacity = 1.0; // Make container fully visible
      });
      setState(() {
        sendGetRequest(_fullStatement.trim());
        _fullStatement = '';
      });// Send full statement

      // Reset the statement after sending
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

  void _togglePanel(bool isPanelOpen) {
    setState(() {
      _isPanelOpen = isPanelOpen; // Update the panel state
    });
  }

  Future<Widget> Data() async {
    print("What is the response? " + _httpResponse);
    data = (await fetchData(_httpResponse)) as String;
    print("Response to " + data!);
    _httpResponse = '';
    return
      Text(
      data != null && data!.isNotEmpty
          ? data!
          : 'Error: data is null or empty.',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Future<int> getTodosCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(globalConnectCode)
          .collection('todos')
          .get();
      return querySnapshot.size;
    } catch (e) {
      print("Error getting todos count: $e");
      return 0;
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

  double _containerHeight = 0.0;
  double _containerOpacity = 0.0;

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );


    final fontSize = MediaQuery.of(context).size.width*0.05;
    final h1 = MediaQuery.of(context).size.width*0.047;
    final h2 = MediaQuery.of(context).size.width*0.08;
    final h3 = MediaQuery.of(context).size.width*0.04;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // Place the RefreshIndicator above the SlidingUpPanel
            RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Your content here
                    SlidingUpPanel(
                      controller: _panelController,
                      backdropEnabled: true,
                      minHeight: 0.0,
                      // Set minimum height to 0.0
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      // Set maximum height to 70% of screen height
                      panel: SingleChildScrollView(
                        child: Container(
                          child: Column(
                            children: [
                              Icon(
                                Icons.arrow_drop_up,
                                color: Colors.black, // Set icon color to black
                              ), // Add the arrow icon here
                              SizedBox(height: 8), // Add some space between the icon and the container
                              Text(
                                _fullStatement,
                                style: TextStyle(color: Colors.black), // Set text color to black
                              ), // Add the _fullStatement text here
                              SizedBox(height: 8), // Add some space between the text and the container
                              Container(
                                width: double.infinity, // Make the container width match the parent width
                                height: MediaQuery.of(context).size.height * 0.45, // Set container height to 30% of screen height
                                padding: EdgeInsets.all(8), // Add padding to the container// Set container background color
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(), // Make the container always scrollable
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8), // Add some space between the texts
                                      FutureBuilder<Widget>(
                                        future: Data(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else {
                                            return snapshot.data ?? Container();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      borderRadius: radius,

                      body: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).padding.top),
                            // Use MediaQuery to get top padding
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width *
                                        0.05), // Make borders round

                              ),
                              height: MediaQuery.of(context).size.height * 0.1,
                              // Set container height to 10% of screen height
                              width: MediaQuery.of(context).size.width,
                              // Take full width
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Hi User!\nWelcome back',
                                        style: TextStyle(
                                          //color: Colors.black,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.person,
                                     // color: Colors.black,
                                      size: 48,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                MediaQuery.of(context).size.height * 0.01),
                            // Add some spacing between containers
                            Container(
                              width: MediaQuery.of(context).size.width * 0.98,
                              // Set container width to 98% of screen width
                              decoration: BoxDecoration(
                                color: Color(0xFFF6FF80),
                                // Set color based on theme
                                borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05),
                                // Make borders round
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.task,
                                          // Assuming you have an icon named 'characters'
                                          color: Colors.black,
                                          size: h1, // Adjust size as needed
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width *
                                                0.02),
                                        // Add some space between the icon and text
                                        Text(
                                          'Current Task',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: h1,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.01),
                                    StreamBuilder<QuerySnapshot>(
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
                                          return CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error: ${snapshot.error}');
                                        }
                                        if (snapshot.hasData) {
                                          final documents = snapshot.data!.docs;
                                          if (documents.isEmpty) {
                                            return Text('No pending task',
                                                style: TextStyle(
                                                  fontSize: h3,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ));
                                          }

                                          return FutureBuilder<int>(
                                            future: getTodosCount(),
                                            builder: (context, countSnapshot) {
                                              if (countSnapshot.connectionState == ConnectionState.waiting) {
                                                return CircularProgressIndicator();
                                              }
                                              if (countSnapshot.hasError) {
                                                return Text('Error: ${countSnapshot.error}');
                                              }
                                              int numberOfTodos = countSnapshot.data ?? 0;

                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'You have $numberOfTodos\n tasks for today',
                                                    style: TextStyle(
                                                      fontSize: h2,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                                                  ...documents.map((doc) {
                                                    final todo = doc.data() as Map<String, dynamic>;
                                                    return ListTile(
                                                      title: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            '${todo['title']}',
                                                            style: TextStyle(
                                                              color: Colors.black,
                                                              fontSize: h3,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      contentPadding: EdgeInsets.zero,
                                                      onTap: () {
                                                        // Add onTap functionality if needed
                                                      },
                                                    );
                                                  }).toList(),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),



                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                MediaQuery.of(context).size.height * 0.01),
                            // Add some spacing between containers
                            Container(
                              decoration: BoxDecoration(
                                color:  Color(0xFFF6F6F8),
                                // Set color based on theme
                                borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05),
                                // Make borders round
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              width: MediaQuery.of(context).size.width * 0.98,
                              // Set container width to 98% of screen width
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 0, top: 5, bottom: 20),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'You are',
                                            style: TextStyle(
                                              fontSize: h1,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'running low on',
                                            // Add your additional text here
                                            style: TextStyle(
                                              fontSize: h2,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: globalConnectCode != null &&
                                          globalConnectCode!.isNotEmpty
                                          ? FirebaseFirestore.instance
                                          .collection('sharedCollection')
                                          .doc(globalConnectCode)
                                          .collection('refill')
                                          .snapshots()
                                          : Stream.empty(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'),
                                          );
                                        }
                                        if (snapshot.hasData) {
                                          final documents = snapshot.data!.docs;
                                          if (documents.isEmpty) {
                                            return Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text('Nothing',
                                                      style: TextStyle(
                                                        fontSize: h3,
                                                        color: Colors.black,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ))
                                                  // Show message if no documents found
                                                ]);
                                          }
                                          return Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: documents.map((doc) {
                                              final document = doc.data()
                                              as Map<String, dynamic>;
                                              final title = document['title'];
                                              return ListTile(
                                                title: Text(title,
                                                    style: TextStyle(
                                                      fontSize: h3,
                                                      color: Colors.black,
                                                      fontWeight:
                                                      FontWeight.w800,
                                                    )), // Display the title field
                                                // Add onTap functionality if needed
                                              );
                                            }).toList(),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  ],
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
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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
                    builder: (context) => SettingsPage(),
                  ),
                );
                break;
            }
          },
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