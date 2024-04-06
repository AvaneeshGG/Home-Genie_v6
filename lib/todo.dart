import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';

class TodoItem {
  final String title;
  final String description;

  TodoItem({
    required this.title,
    required this.description,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class Todo extends StatefulWidget {
  const Todo({Key? key}) : super(key: key);

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  bool _isExpanded1 = true;
  bool _isExpanded2 = false;
  bool _isLocal = true; // Variable to track the storage location

  List<TodoItem> _todoItems = [];
  FirebaseTodo firebaseTodo = FirebaseTodo();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? itemsJson = prefs.getStringList('todo_items');
    if (itemsJson != null) {
      setState(() {
        _todoItems = itemsJson
            .map((itemJson) => TodoItem.fromJson(jsonDecode(itemJson)))
            .toList();
      });
    }
  }

  Future<void> _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> itemsJson =
    _todoItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('todo_items', itemsJson);
  }

  void _addItem(TodoItem item, bool isChecked) {
    if (isChecked) {
      setState(() {
        _todoItems.add(item);
        _saveItems();
      });
    } else {
      firebaseTodo.addTodo(
        title: item.title,
        description: item.description,
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
      if (_isLocal) {
        _saveItems();
      } else {
        // Delete from Firebase if not stored locally
        // Here, you may want to handle deletion from Firebase
        // when implementing FirebaseTodo class
      }
    });
  }

  Future<void> _showAddDialog(BuildContext context) async {
    TextEditingController _titleController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();

    // Track the selected segment
    int _selectedSegment = 0; // 0 for Local, 1 for Cloud

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add To-Do Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 8),
                  // Wrap the CupertinoSegmentedControl with a Container
                  Container(
                    padding: EdgeInsets.all(8), // Add padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Curve the edges
                      color: Colors.grey[200], // Background color
                    ),
                    child: CupertinoSegmentedControl<int>(
                      children: {
                        0: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('Local'),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('Cloud'),
                        ),
                      },
                      groupValue: _selectedSegment,
                      onValueChanged: (int value) {
                        setState(() {
                          _selectedSegment = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    bool storeLocal = _selectedSegment == 0; // Determine whether to store locally or in the cloud
                    _addItem(
                      TodoItem(
                        title: _titleController.text,
                        description: _descriptionController.text,
                      ),
                      storeLocal,
                    );
                    _titleController.clear();
                    _descriptionController.clear();
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'To-do List (Shared Preferences)',
              content: TodoList(todoItems: _todoItems, removeItem: _removeItem),
              isExpanded: _isExpanded1,
              onTap: () {
                setState(() {
                  _isExpanded1 = !_isExpanded1;
                });
              },
            ),
            _buildSection(
              title: 'Chores List (Firebase)',
              content: FirebaseTodoList(firebaseTodo: firebaseTodo),
              isExpanded: _isExpanded2,
              onTap: () {
                setState(() {
                  _isExpanded2 = !_isExpanded2;
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddDialog(context);
        },
        label: Text('Add'),
        icon: Icon(Icons.add),
        // Checkbox to indicate storage location
        // If checked, store locally; otherwise, store in Firebase
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Colors.blue,
        elevation: 2.0,
        tooltip: 'Add a new item',
        isExtended: true,
        splashColor: Colors.blueAccent,
        // Removed secondary property
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.blue, // Header background color
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: isExpanded,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(16),
            color: Colors.grey[200], // Content background color
            child: content,
          ),
        ),
      ],
    );
  }
}

class FirebaseTodo {
  final CollectionReference _todosCollection = FirebaseFirestore.instance.collection('sharedCollection').doc('405898').collection('todos');

  Future<void> addTodo({
    required String title,
    required String description,
  }) async {
    await _todosCollection.add({
      'title': title,
      'description': description,
    });
  }

  Future<void> updateTodo({
    required String docId,
    required String title,
    required String description,
  }) async {
    await _todosCollection.doc(docId).update({
      'title': title,
      'description': description,
    });
  }

  Future<void> deleteTodo({
    required String docId,
  }) async {
    await _todosCollection.doc(docId).delete();
  }

  Stream<QuerySnapshot> getTodos() {
    return _todosCollection.snapshots();
  }
}


class FirebaseTodoList extends StatelessWidget {
  final FirebaseTodo firebaseTodo;

  FirebaseTodoList({required this.firebaseTodo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseTodo.getTodos(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var todos = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: todos.length,
            itemBuilder: (context, index) {
              var todo = todos[index];
              return ListTile(
                title: Text(todo['title']),
                subtitle: Text(todo['description']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    firebaseTodo.deleteTodo(docId: todo.id);
                  },
                ),
              );
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class TodoList extends StatelessWidget {
  final List<TodoItem> todoItems;
  final Function(int) removeItem;

  TodoList({required this.todoItems, required this.removeItem});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: todoItems.length,
      itemBuilder: (context, index) {
        final item = todoItems[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Text(item.description),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              removeItem(index);
            },
          ),
        );
      },
    );
  }
}
