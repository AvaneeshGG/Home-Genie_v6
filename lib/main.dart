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
  String? data='';

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
        _containerHeight = MediaQuery.of(context).size.height; // Extend container to bottom
        _containerOpacity = 1.0; // Make container fully visible

      });
      await sendGetRequest(_fullStatement.trim()); // Send full statement
      _fullStatement = '';
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

  Future<Widget> Data() async {
    data= (await fetchData(_httpResponse)) as String;
    return Text(
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

  @override
  Widget build(BuildContext context) {
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
                      minHeight: 0.0, // Set minimum height to 0.0
                      maxHeight: 500.0, // Set maximum height to 0.0
                      panel: Center(
                        child: Text(_fullStatement,
                        ),
                      ),
                      body: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: MediaQuery.of(context).padding.top),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF6FF80),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.black, // Set border color here
                                  width: 2, // Set border width here
                                ),
                              ),
                              //color: Colors.red, // Set color here
                              height: 100,
                              width: MediaQuery.of(context).size.width, // Take full width
                              child: Center(
                                  child: FutureBuilder<Widget>(
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
                              ),
                            ),
                            SizedBox(height: 5), // Add some spacing between containers
                            Container(
                              width: MediaQuery.of(context).size.width * 0.98, // Set container width to 98% of screen width
                                decoration: BoxDecoration(
                                    color: Color(0xFFF6FF80), // Set color based on theme
                                    borderRadius: BorderRadius.circular(15), // Make borders round
                                    boxShadow: [
                                BoxShadow(
                                color: Colors.black.withOpacity(0.2), // Set shadow color and opacity
                                spreadRadius: 2, // Set spread radius
                                blurRadius: 5, // Set blur radius
                                offset: Offset(0, 3), // Set shadow offset
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
                                          Icons.task, // Assuming you have an icon named 'characters'
                                          color: Colors.black,
                                          size: 20, // Adjust size as needed
                                        ),
                                        SizedBox(width: 5), // Add some space between the icon and text
                                        Text(
                                          'Current Task',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),
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
                                          return CircularProgressIndicator(); // Show loading indicator while fetching data
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error: ${snapshot.error}'); // Show error if encountered
                                        }
                                        if (snapshot.hasData) {
                                          final documents = snapshot.data!.docs;
                                          int numberOfTodos = documents.length; // Count the number of documents in todos
                                          if (documents.isEmpty) {
                                            return Text('No pending task',
                                              style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),); // Show message if no documents found
                                          }
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('You have $numberOfTodos\ntasks for today',
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ), // Display the count
                                              SizedBox(height: 10),
                                              ...documents.map((doc) {
                                                final todo = doc.data() as Map<String, dynamic>;
                                                return ListTile(
                                                  title: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        ' ${todo['title']}', // Assuming 'title' is a field in your document
                                                        style: TextStyle(
                                                          color: Colors.black, // Set text color to white
                                                          fontSize: 16, // Example font size, adjust as needed
                                                          fontWeight: FontWeight.w400, // Example font weight, adjust as needed
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  contentPadding: EdgeInsets.zero, // Remove ListTile content padding
                                                  onTap: () {
                                                    // Add onTap functionality if needed
                                                  },
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        }
                                        return SizedBox.shrink(); // If none of the above conditions are met, return an empty SizedBox
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),




                            SizedBox(height: 5), // Add some spacing between containers
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE8EAF6), // Set color based on theme
                                borderRadius: BorderRadius.circular(15), // Make borders round
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2), // Set shadow color and opacity
                                    spreadRadius: 2, // Set spread radius
                                    blurRadius: 5, // Set blur radius
                                    offset: Offset(0, 3), // Set shadow offset
                                  ),
                                ],
                              ),
                              width: MediaQuery.of(context).size.width * 0.98, // Set container width to 98% of screen width
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 0, top: 5, bottom: 20), // Adjust vertical padding
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Text(
                                            'You are',
                                            style: TextStyle(
                                              fontSize: 22,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'running low on', // Add your additional text here
                                            style: TextStyle(

                                              fontSize: 28,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    StreamBuilder<QuerySnapshot>(
                                      stream: globalConnectCode != null && globalConnectCode!.isNotEmpty
                                          ? FirebaseFirestore.instance
                                          .collection('sharedCollection')
                                          .doc(globalConnectCode)
                                          .collection('refill')
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
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children:[
                                                Text('Nothing',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ] // Show message if no documents found
                                            );
                                          }
                                          return Column(
                                            children: documents.map((doc) {
                                              final document = doc.data() as Map<String, dynamic>;
                                              final title = document['title'];
                                              return ListTile(
                                                title: Text(title), // Display the title field
                                                // Add onTap functionality if needed
                                              );
                                            }).toList(),
                                          );
                                        }
                                        return SizedBox.shrink(); // If none of the above conditions are met, return an empty SizedBox
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
