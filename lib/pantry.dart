import 'package:flutter/material.dart';
import './main.dart';
import './profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Pantry extends StatefulWidget {
  const Pantry(
      {Key? key, required this.toggleListening, required this.isListening})
      : super(key: key);

  final VoidCallback toggleListening;
  final bool isListening;

  PantryState createState() => PantryState();
}

class PantryState extends State<Pantry> {
  int _currentPageIndex = 1;

  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentPageIndex = index;
            });
            // Handle navigation based on the index if needed
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HG_App(),
                  ),
                );
                break;
              case 1:
              // Navigate to search page
                break;
              case 2:
              // Navigate to notifications page
                break;
              case 3:
              // Navigate to profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsPage(
                          toggleListening: widget.toggleListening,
                          isListening: widget.isListening,
                        ),
                  ),
                );
                break;
            }
          },
          backgroundColor: Color(0xFF202020),
          indicatorColor: Theme
              .of(context)
              .primaryColor,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.door_sliding),
              label: 'Pantry',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: widget.toggleListening,
          child: Icon(widget.isListening ? Icons.stop : Icons.mic),
          tooltip: 'Listen',
          elevation: 0,
          shape: CircleBorder(),
        ),
        body: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ItemsPage()
                  )
              );
            },
            tooltip: 'Add Items',
            child: Icon(Icons.add),
          ),
        )
    );
  }
}

class Item {
  final String category;
  final String detail1;
  final String detail2;

  Item({
    required this.category,
    required this.detail1,
    required this.detail2,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      category: json['category'],
      detail1: json['detail1'],
      detail2: json['detail2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'detail1': detail1,
      'detail2': detail2,
    };
  }
}

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  TextEditingController _detail1Controller = TextEditingController();
  TextEditingController _detail2Controller = TextEditingController();
  String _selectedCategory = 'Category 1'; // Default category
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? itemsJson = prefs.getStringList('items');
    if (itemsJson != null) {
      setState(() {
        _items = itemsJson
            .map((itemJson) => Item.fromJson(jsonDecode(itemJson)))
            .toList();
      });
    }
  }

  Future<void> _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> itemsJson =
    _items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('items', itemsJson);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _saveItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items Storage'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Dismissible(
                  key: Key(item.category),
                  onDismissed: (direction) {
                    _removeItem(index);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(item.category),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail 1: ${item.detail1}'),
                          Text('Detail 2: ${item.detail2}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: <String>[
                    'Category 1',
                    'Category 2',
                    'Category 3',
                    // Add more categories here if needed
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                TextField(
                  controller: _detail1Controller,
                  decoration: InputDecoration(labelText: 'Detail 1'),
                ),
                TextField(
                  controller: _detail2Controller,
                  decoration: InputDecoration(labelText: 'Detail 2'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _items.add(Item(
                        category: _selectedCategory,
                        detail1: _detail1Controller.text,
                        detail2: _detail2Controller.text,
                      ));
                      _saveItems();
                      _detail1Controller.clear();
                      _detail2Controller.clear();
                    });
                  },
                  child: Text('Add Item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
