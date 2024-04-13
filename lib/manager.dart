import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

Future<String?> _getFirebaseCode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('globalConnectCode');
}

void fetchData(String response) async {
  //String response =
  //   '{"items": [{"item": "kiwi", "category": "fruits", "metric_weight": "200 gms"}, {"item": "combiflam", "category": "pulses"}], "labels": ["add", "pantry"]}';

  if (response != null) {
    Map<String, dynamic> jsonResponse = jsonDecode(response);
    print(jsonResponse);

    var items = jsonResponse['items'];
    var labels = jsonResponse['labels'];

    if (labels.contains('add')) {
      // Retrieve the global connect code
      String? firebaseCode = await _getFirebaseCode();
      if (firebaseCode != null) {
        for (var item in items) {
          var itemName = item['item'] ?? null;
          var category = item['category'] ?? null;
          var quantity = item['quantity'] ?? null;
          var metricWeight = item['metric_weight'] ?? null;
          print(itemName);
          print(category);
          print(quantity);
          print(metricWeight);

          // Example: Adding data to Firestore
          await addFruit(
            firebaseCode: firebaseCode,
            itemName: itemName,
            category: category,
            quantity: quantity,
            metricWeight: metricWeight,
          );
        }
      } else {
        print('Global connect code not found in SharedPreferences.');
      }
    } else {
      print('Label "add" not found in the JSON response.');
    }
  } else {
    throw Exception('Failed to load data');
  }
}

// Function to add a fruit to Firestore
Future<void> addFruit({
  required String firebaseCode,
  required String? itemName,
  required String category,
  String? quantity,
  String? metricWeight,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .doc(itemName) // Use item name as document ID
        .set({
      'item': itemName,
      'quantity': quantity,
      'metric_weight': metricWeight,
    });
    print('Fruit added successfully.');
  } catch (e) {
    print('Error adding fruit: $e');
  }
}


