import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class Connect extends StatefulWidget {
  const Connect({Key? key});

  @override
  State<Connect> createState() => _ConnectState();
}

class _ConnectState extends State<Connect> {
  String? accessCode;
  String? connectCode;
  String? globalConnectCode;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _getGlobalConnectCode(); // Load globalConnectCode when the app starts
    // Check if access code is already generated for the user
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          accessCode = documentSnapshot['accessCode'];
        });
      }
    });
  }

  Future<void> _saveGlobalConnectCode(String connectCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('globalConnectCode', connectCode);
    setState(() {
      globalConnectCode = connectCode;
    });
  }

  Future<void> _getGlobalConnectCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedConnectCode = prefs.getString('globalConnectCode');
    setState(() {
      globalConnectCode = savedConnectCode;
    });
  }

  Future<void> _generateAccessCode() async {
    // Check if access code is already generated
    if (accessCode != null) {
      // Access code is already generated, no need to generate again
      return;
    }

    // Generate a random 6-digit access code
    final random = Random();
    final code = List.generate(6, (index) => random.nextInt(10)).join('');

    // Store the access code in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({'accessCode': code}, SetOptions(merge: true));

    setState(() {
      accessCode = code;
    });

    // Check if the sharedCollection with access code exists
    final sharedCollectionRef =
    FirebaseFirestore.instance.collection('sharedCollection').doc(code);
    final sharedCollectionSnapshot = await sharedCollectionRef.get();
    if (!sharedCollectionSnapshot.exists) {
      // Create a new subcollection with the access code as the collection ID
      await sharedCollectionRef
          .set({'accessCode': code}, SetOptions(merge: true));

      // Add the user's email to the members collection
      final membersRef = sharedCollectionRef.collection('members');
      await membersRef.add({
        'email': user!.email,
      });
    }
  }

  void grantAccessToCollection(String connectCode, BuildContext context) async {
    try {
      // Check if the sharedCollection with the provided access code exists
      final sharedCollectionRef = FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(connectCode);
      final sharedCollectionSnapshot = await sharedCollectionRef.get();

      if (sharedCollectionSnapshot.exists) {
        // Check if the current user's email exists in the members subcollection
        final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
        final membersRef = sharedCollectionRef.collection('members');
        final currentUserRef =
        membersRef.where('email', isEqualTo: currentUserEmail);
        final currentUserSnapshot = await currentUserRef.get();

        if (currentUserSnapshot.docs.isEmpty) {
          // Add the current user's email to the connectCode collection
          await membersRef.add({
            'email': currentUserEmail,
            // Removed the timestamp
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to collection with email: $currentUserEmail'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Collection with the access code does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No collection found with the provided access code!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error occurred: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void exitCollection() async {
    if (globalConnectCode != null) {
      // Remove the user's email from the members collection
      final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
      final membersRef = FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(globalConnectCode)
          .collection('members');
      final querySnapshot = await membersRef
          .where('email', isEqualTo: currentUserEmail)
          .get();

      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    }

    // Reset globalConnectCode and save it to 'null'
    setState(() {
      globalConnectCode = null;
    });
    await _saveGlobalConnectCode('null');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Access code')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic goes here, for example, fetching updated data from Firestore
          // For simplicity, you can just reload the page
          setState(() {});
        },
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('User Email: ${user!.email}'),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (accessCode != null) ...[
                        Text('Your Access Code: $accessCode'),
                        const SizedBox(height: 20),
                      ],
                      ElevatedButton(
                        onPressed: globalConnectCode == 'null' ? _generateAccessCode : null,
                        child: Text('Generate Access Code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            connectCode = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Enter Connect Code',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (connectCode != null && connectCode!.isNotEmpty) {
                            setState(() {
                              globalConnectCode = connectCode;
                            });
                            await _saveGlobalConnectCode(connectCode!);
                            grantAccessToCollection(connectCode!, context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a valid connect code!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Text('Connect to User'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (globalConnectCode != null) ...[
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('sharedCollection')
                          .doc(globalConnectCode)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else {
                          final Map<String, dynamic>? data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                          if (data == null) {
                            return Center(child: Text('No data available'));
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Members in current Family:'),
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('sharedCollection')
                                    .doc(globalConnectCode)
                                    .collection('members')
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (snapshot.hasData) {
                                    final members = snapshot.data!.docs;
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: members.length,
                                      itemBuilder: (context, index) {
                                        final fieldValue = members[index].get('email');
                                        return ListTile(
                                          leading: Icon(Icons.circle),
                                          title: Text('$fieldValue'),
                                        );
                                      },
                                    );
                                  }
                                  return Text('No members found.');
                                },
                              ),
                              ElevatedButton(
                                onPressed: exitCollection,
                                child: Text('Exit'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
