import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import'package:home_genie/Inventory.dart';

Future<String?> _getFirebaseCode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('globalConnectCode');
}

void fetchData(String response) async {
  if (response != null) {
    Map<String, dynamic> jsonResponse = jsonDecode(
      response);
       // '{"items":[{"category":"fruits","item":"banana","metric_weight":"3 kgs"}],"labels":["add","pantry"]}');
    //print(jsonResponse);

    var items = jsonResponse['items'];
    var labels = jsonResponse['labels'];

    if (labels.contains('add') && labels.contains('pantry')) {
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

          if (firebaseCode.isNotEmpty && category.isNotEmpty) {
            // Check if item already exists
            bool exists = await checkIfItemExists(
              firebaseCode,
              itemName,
              category,
            );

            if (exists) {
              print('$itemName in category $category already exists.');
              // Fetch the quantity and metric weight from Firebase
              String? existingQuantity = await getQuantityFromFirebase(
                  firebaseCode, itemName, category);
              String? existingMetricWeight = await getMetricWeightFromFirebase(
                  firebaseCode, itemName, category);

              if (existingQuantity != null && existingQuantity != 'N/A' &&
                  quantity != null) {
                // Convert existing quantity to an integer, add new quantity, and save as a string to Firebase
                int existingQuantityInt = int.tryParse(existingQuantity) ?? 0;
                int newQuantityInt = int.tryParse(quantity) ?? 0;
                int totalQuantity = existingQuantityInt + newQuantityInt;
                await updateQuantityInFirebase(
                    firebaseCode, itemName, category, totalQuantity.toString());
                print('Quantity for $itemName is not N/A: $totalQuantity');
              } else if (existingMetricWeight != null &&
                  existingMetricWeight != 'N/A' && metricWeight != null) {
                String result = metricCalc(
                    existingMetricWeight, metricWeight, "add");
                await updateMetricWeightInFirebase(
                    firebaseCode, itemName, category, result);
                print(
                    'Metric weight for $itemName is not N/A: $existingMetricWeight');
              } else {
                print('Both quantity and metric_weight for $itemName are N/A.');
              }
            } else {
              // Example: Adding data to Firestore
              await addFruit(
                firebaseCode: firebaseCode,
                itemName: itemName,
                category: category,
                quantity: quantity,
                // n/a
                metricWeight: metricWeight, //5kg
              );
            }
          } else {
            print('Error: firebaseCode or category is null or empty.');
          }
        }
      } else {
        print('Global connect code not found in SharedPreferences.');
      }
    }


    else if (labels.contains('add') && labels.contains('chores')) {
      String? firebaseCode = await _getFirebaseCode();
      for (var item in items) {
        var itemName = item['item'] ?? null; // Move itemName declaration here
        try {
          await FirebaseFirestore.instance
              .collection('sharedCollection')
              .doc(firebaseCode)
              .collection('todos') // Subcollection name
              .add({
            'title': itemName,
            'description':''
          });
          print('Item added to todos subcollection.');
        } catch (e) {
          print('Error adding item to todos subcollection: $e');
        }
      }
    }
    else if (labels.contains('fetch')) {
      // Retrieve the global connect code
      String? firebaseCode = await _getFirebaseCode();

      if (firebaseCode != null) {
        for (var item in items) {
          var itemName = item['item'] ?? null;
          var category = item['category'] ?? null;

          if (firebaseCode.isNotEmpty && category.isNotEmpty && itemName != null) {
            // Fetch the item data from Firebase
            var itemData = await fetchItemData(firebaseCode, category, itemName);

            if (itemData != null) {
              print('Item Name: $itemName');
              print('Quantity: ${itemData['quantity']}');
              print('Weight: ${itemData['weight']}');
            } else {
              print('Item $itemName not found in category $category.');
            }
          } else {
            print('Error: firebaseCode, category, or itemName is null or empty.');
          }
        }
      } else {
        print('Global connect code not found in SharedPreferences.');
      }
    }

// Function to fetch item data from Firebase

  // Handle 'fetch' label
    else if (labels.contains('remove') && labels.contains('pantry')) {
      print("Removing");
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

        if (firebaseCode.isNotEmpty && category.isNotEmpty) {
          // Check if item already exists
          bool exists = await checkIfItemExists(
            firebaseCode,
            itemName,
            category,
          );

          if (exists) {
            print('$itemName in category $category already exists.');
            // Fetch the quantity and metric weight from Firebase
            String? existingQuantity = await getQuantityFromFirebase(
                firebaseCode, itemName, category);
            String? existingMetricWeight = await getMetricWeightFromFirebase(
                firebaseCode, itemName, category);

            if (existingQuantity != null && existingQuantity != 'N/A' &&
                quantity != null) {
              // Convert existing quantity to an integer, add new quantity, and save as a string to Firebase
              int existingQuantityInt = int.tryParse(existingQuantity) ?? 0;
              int newQuantityInt = int.tryParse(quantity) ?? 0;
              int totalQuantity = (existingQuantityInt - newQuantityInt);
                if(totalQuantity<=0){
                  await deleteItemFromFirebase(firebaseCode, itemName, category);
                }
                else {
                  await updateQuantityInFirebase(
                      firebaseCode, itemName, category,
                      totalQuantity.toString());
                }
              print('Quantity for $itemName is not N/A: $totalQuantity');
            } else if (existingMetricWeight != null &&
                existingMetricWeight != 'N/A' && metricWeight != null) {
              String result = metricCalc(
                  existingMetricWeight, metricWeight, "subtract");
              print(result);

              if(result=="N/A"){
                await deleteItemFromFirebase(firebaseCode, itemName, category);
              }
              else {
                await updateMetricWeightInFirebase(
                    firebaseCode, itemName, category, result);
              }
              print(
                  'Metric weight for $itemName is not N/A: $existingMetricWeight');
            } else {
              print('Both quantity and metric_weight for $itemName are N/A.');
              await deleteItemFromFirebase(firebaseCode, itemName, category);
            }
          }
        } else {
          print('Global connect code not found in SharedPreferences.');
        }
      }
    }
  }
 else {
        print('The given case does not exist');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

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
        .add({
      'title': itemName,
      'quantity': quantity,
      'weight': metricWeight,
    });
    print('add + pantry block executed');
  } catch (e) {
    print('Error adding fruit: $e');
  }
}

Future<bool> checkIfItemExists(
    String firebaseCode,
    String itemName,
    String category,
    ) async {
  var query = FirebaseFirestore.instance
      .collection('sharedCollection')
      .doc(firebaseCode)
      .collection(category)
      .where('title', isEqualTo: itemName);

  var result = await query.get();
  return result.docs.isNotEmpty;
}


Future<String?> getQuantityFromFirebase(String firebaseCode, String itemName, String category) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document for each item in the category
      var document = querySnapshot.docs.first;
      return document['quantity'];
    } else {
      return null; // Item not found
    }
  } catch (e) {
    print('Error fetching quantity from Firebase: $e');
    return null;
  }
}


Future<String?> getMetricWeightFromFirebase(String firebaseCode, String itemName, String category) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document for each item in the category
      var document = querySnapshot.docs.first;
      return document['weight'];
    } else {
      return null; // Item not found
    }
  } catch (e) {
    print('Error fetching metric weight from Firebase: $e');
    return null;
  }
}

Future<void> updateQuantityInFirebase(String firebaseCode, String itemName, String category, String newQuantity) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var documentID = querySnapshot.docs.first.id;
        FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(firebaseCode)
            .collection(category)
            .doc(documentID)
            .update({'quantity': newQuantity});
      }
    });
    print('Quantity updated successfully for $itemName');
  } catch (e) {
    print('Error updating quantity in Firebase: $e');
  }
}

Future<void> updateMetricWeightInFirebase(String firebaseCode, String itemName, String category, String newMetricWeight) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var documentID = querySnapshot.docs.first.id;
        FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(firebaseCode)
            .collection(category)
            .doc(documentID)
            .update({'weight': newMetricWeight});
      }
    });
    print('Metric weight updated successfully for $itemName');
  } catch (e) {
    print('Error updating metric weight in Firebase: $e');
  }
}


String metricCalc(String metric1, String metric2, String operation) {
  // Function to convert metric to kilograms
  double toKgs(String metric) {
    List<String> splitMetric = metric.split(" ");
    double value = double.parse(splitMetric[0]);
    String unit = splitMetric[1].toLowerCase();
    if (unit == "gms") {
      return value / 1000;
    } else if (unit == "kgs") {
      return value;
    } else {
      // Handle invalid unit
      return 0;
    }
  }

  // Perform the operation based on the operation string
  if (operation == "normalize") {
    // Convert metric1 to kilograms and return
    return "${toKgs(metric1).toStringAsFixed(2)} kgs";
  } else {
    // Convert input metrics to kilograms
    double value1 = toKgs(metric1);
    double value2 = toKgs(metric2);

    // Perform the specified operation
    double result;
    if (operation == "add") {
      result = value1 + value2;
    } else if (operation == "subtract") {
      result = value1 - value2;
      if(result<=0){
        return "N/A";
      }
    } else {
      // Handle invalid operation
      return "N/A";
    }

    // Construct the result string in kgs
    return "${result.toStringAsFixed(2)} kgs";
  }
}

Future<void> deleteItemFromFirebase(String firebaseCode, String itemName, String category) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });
    print('Item $itemName in category $category deleted successfully.');
  } catch (e) {
    print('Error deleting item: $e');
  }
}
// Additional code goes here...


Future<Map<String, dynamic>?> fetchItemData(String firebaseCode, String category, String itemName) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(firebaseCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document for each item in the category
      var document = querySnapshot.docs.first;
      return {
        'quantity': document['quantity'],
        'weight': document['weight'],
      };
    } else {
      return null; // Item not found
    }
  } catch (e) {
    print('Error fetching item data from Firebase: $e');
    return null;
  }
}





