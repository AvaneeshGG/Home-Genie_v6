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
      await sharedCollectionRef.set({
        'createdBy': user!.email,
      }, SetOptions(merge: true));
      await sharedCollectionRef
          .set({'accessCode': code}, SetOptions(merge: true));
    }
  }

  void grantAccessToCollection(String connectCode) async {
    try {
      // Check if the sharedCollection with the provided access code exists
      final sharedCollectionRef = FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(connectCode);
      final sharedCollectionSnapshot = await sharedCollectionRef.get();

      if (sharedCollectionSnapshot.exists) {
        // Collection with the same access code exists, display its name
        final collectionName =
            sharedCollectionSnapshot.reference.parent?.id;

        // Fetch existing members to determine the next member number
        final memberQuerySnapshot =
        await sharedCollectionRef.collection(connectCode).get();
        final nextMemberNumber = memberQuerySnapshot.docs.length + 1;

        // Add the current user's email to the 'Member' subcollection
        await sharedCollectionRef.set({
          'member$nextMemberNumber': user!.email,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Connected to collection: $collectionName'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Collection with the access code does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No collection found with the provided access code!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Handle any errors that occur during the process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void exitCollection() async {
    setState(() {
      globalConnectCode = null;
    });
    await _saveGlobalConnectCode('null');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Access code')),
      body: ListView(
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
                        if (connectCode != null &&
                            connectCode!.isNotEmpty) {
                          setState(() {
                            globalConnectCode = connectCode;
                          });
                          await _saveGlobalConnectCode(connectCode!);
                          grantAccessToCollection(connectCode!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please enter a valid connect code!'),
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}'));
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
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final fieldName =
                                data.keys.elementAt(index);
                                final fieldValue =
                                data.values.elementAt(index);
                                return ListTile(
                                  title:
                                  Text('$fieldName: $fieldValue'),
                                );
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
    );
  }
}
