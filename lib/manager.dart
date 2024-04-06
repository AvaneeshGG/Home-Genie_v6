import 'dart:async';
import 'dart:convert';
import './main.dart';

class Manager {
  Future<void> printCats(String jsonData) async {
    var data = jsonDecode(jsonData);

    var entities = data['entities'];

    // Loop through entities
    for (var entity in entities) {
      // Check if entity contains "fruits" key
      if (entity.containsKey('fruits')) {
        // Print only the value associated with "fruits" key
        print(entity['fruits']);
      }
    }

    // Extracting categories
    var categories = data['cats'];

    // Printing extracted data
    print('Categories: $categories');

    // Extracting and parsing category values with null checks
    double add = categories['add'] != null ? double.parse(categories['add'].toString()) : 0.0;
    double chores = categories['chores'] != null ? double.parse(categories['chores'].toString()) : 0.0;
    double fetch = categories['fetch'] != null ? double.parse(categories['fetch'].toString()) : 0.0;
    double fruits = categories['fruits'] != null ? double.parse(categories['fruits'].toString()) : 0.0;
    double item = categories['item'] != null ? double.parse(categories['item'].toString()) : 0.0;
    double location = categories['location'] != null ? double.parse(categories['location'].toString()) : 0.0;
    double medicine = categories['medicine'] != null ? double.parse(categories['medicine'].toString()) : 0.0;
    double metric_weight = categories['metric_weight'] != null ? double.parse(categories['metric_weight'].toString()) : 0.0;
    double pantry = categories['pantry'] != null ? double.parse(categories['pantry'].toString()) : 0.0;
    double pulses = categories['pulses'] != null ? double.parse(categories['pulses'].toString()) : 0.0;
    double quantity = categories['quantity'] != null ? double.parse(categories['quantity'].toString()) : 0.0;
    double remove = categories['remove'] != null ? double.parse(categories['remove'].toString()) : 0.0;
    double strength = categories['strength'] != null ? double.parse(categories['strength'].toString()) : 0.0;
    double task = categories['task'] != null ? double.parse(categories['task'].toString()) : 0.0;
    double timeBound = categories['time-bound'] != null ? double.parse(categories['time-bound'].toString()) : 0.0;
    double toDo = categories['to-do'] != null ? double.parse(categories['to-do'].toString()) : 0.0;
    double vegetable = categories['vegetable'] != null ? double.parse(categories['vegetable'].toString()) : 0.0;

    print(add);
    print(fetch);

    if (add >= 0.7 && pantry >= 0.7) {}
    Future<String> CatOut() async {
      var entities = data['entities'];
      String fruit = ''; // Initialize fruit to an empty string

      // Loop through entities
      for (var entity in entities) {
        // Check if entity contains "fruits" key
        if (entity.containsKey('fruits')) {
          // Print only the value associated with "fruits" key
          fruit = entity['fruits'];
          break; // Exit the loop once the fruit is found
        }
      }

      return fruit; // Return the found fruit, or an empty string if none found
    }
  }
}
