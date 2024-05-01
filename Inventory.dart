import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import './todo.dart';
import './profile_page.dart';
import './main.dart';

class FirebaseTodo {
  late CollectionReference _todosCollection;

  FirebaseTodo({required String category, required String globalConnectCode}) {
    _todosCollection = FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category);
  }

  Future<void> addTodo({
    required String title,
    required String quantity,
    required String weight,
    required String limit,
    required String globalConnectCode,
  }) async {
    await _todosCollection.add({
      'title': title,
      'quantity': quantity,
      'weight': weight,
      'limit': limit,
    });

    int parsedQuantity = quantity == 'N/A' ? 0 : int.tryParse(quantity) ?? 0;
    int parsedWeight = weight == 'N/A' ? 0 : int.tryParse(weight) ?? 0;
    int parsedLimit = int.tryParse(limit) ?? 2;

    // Check if either quantity or weight is less than the limit and not 'N/A'
    if ((parsedQuantity < parsedLimit && quantity != 'N/A') ||
        (parsedWeight < parsedLimit && weight != 'N/A')) {
      // Add the title to the "refill" subcollection
      await FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(globalConnectCode)
          .collection('refill')
          .add({'title': title});
    }
  }

  Future<void> updateTodo({
    required String docId,
    required String title,
    required String quantity,
    required String weight,
    required String limit,
  }) async {
    // Ensure that docId is not empty or null
    assert(docId.isNotEmpty);

    await _todosCollection.doc(docId).update({
      'title': title,
      'quantity': quantity,
      'weight': weight,
      'limit': limit,
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
  final Function(BuildContext, String, String, String, String, String) showEditDialog;

  FirebaseTodoList({
    required this.firebaseTodo,
    required this.showEditDialog,
  });


  Color _calculateBackgroundColor(String quantity, String weight, String limit, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Brightness platformBrightness = MediaQuery.of(context).platformBrightness;

    bool isQuantityNA = quantity == 'N/A';
    bool isWeightNA = weight == 'N/A';

    if (isQuantityNA && isWeightNA) {
      return colorScheme.surface;
    } else {
      int parsedQuantity = isQuantityNA ? 0 : int.tryParse(quantity) ?? 0;
      double parsedWeight = isWeightNA ? 0 : parseWeight(weight);
      int parsedLimit = int.tryParse(limit) ?? 2;

      if ((isQuantityNA && parsedWeight < parsedLimit) || (isWeightNA && parsedQuantity < parsedLimit)) {
        // Use dark red if system theme is dark, else use lighter shade of red
        return platformBrightness == Brightness.dark ? Colors.red[900]! : Colors.red[100]!;
      } else {
        // Use system color scheme (light or dark)
        return platformBrightness == Brightness.dark ? colorScheme.surface : colorScheme.background;
      }
    }
  }


  double parseWeight(String weightString) {
    // Split the weight string into its numerical value and unit
    List<String> parts = weightString.split(" ");
    // Ensure the parts contain at least two elements
    if (parts.length >= 2) {
      // Extract the numerical value and convert it to a double
      double numericValue = double.tryParse(parts[0]) ?? 0.0;
      // Return the parsed double value
      return numericValue;
    } else {
      // Handle invalid input, return 0.0 if parsing fails
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement your refresh logic here
        // For example, you could fetch new data from Firebase
        // or reload the existing data
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: firebaseTodo.getTodos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var todos = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: todos.length,
              itemBuilder: (context, index) {
                var inventory = todos[index];
                String documentName = inventory.id;
                Map<String, dynamic> data = inventory.data() as Map<String, dynamic>;
                String title = data['title'] != null ? data['title'].toString() : 'Untitled'; // Get the title from data
                String weight = data['weight'] != null ? data['weight'].toString() : 'N/A';
                String limit = data['limit'] != null ? data['limit'].toString() : '2';
                String quantity = data['quantity'] != null ? data['quantity'].toString() : 'N/A';

                // Determine the background color based on the quantity and the limit
                Color backgroundColor = _calculateBackgroundColor(quantity, weight, limit, context);

                return Slidable(
                  actionPane: SlidableDrawerActionPane(),
                  actions: [
                    IconSlideAction(
                      caption: 'Edit',
                      color: Colors.green,
                      icon: Icons.edit,
                      onTap: () {
                        showEditDialog(context, documentName, quantity, weight, title, limit);
                      },
                    ),
                  ],
                  secondaryActions: <Widget>[
                    IconSlideAction(
                      caption: 'Delete',
                      color: Colors.red,
                      icon: Icons.delete,
                      onTap: () async {
                        // Delete the document from the main collection
                        await firebaseTodo.deleteTodo(docId: inventory.id);

                      },
                    ),

                  ],
                  child: Container(
                    color: backgroundColor, // Set the background color
                    child: ListTile(
                      title: Text(title), // Display title instead of documentName
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity: $quantity'),
                          Text('Weight: $weight'),
                          Text('Limit: $limit'),
                        ],
                      ),
                    ),
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
      ),
    );
  }
}

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late TextEditingController _limitController;
  String? selectedCategory;
  String? globalConnectCode;
  FirebaseTodo? firebaseTodo;

  @override
  void initState() {
    super.initState();
    selectedCategory = 'fruits';
    _getGlobalConnectCode();
    _titleController = TextEditingController();
    _quantityController = TextEditingController();
    _weightController = TextEditingController();
    _limitController = TextEditingController();
  }

  void _getGlobalConnectCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      globalConnectCode = prefs.getString('globalConnectCode');
    });
  }



  void _addItem() {
    String title = _titleController.text.isEmpty ? 'N/A' : _titleController.text;
    String quantity = _quantityController.text.isEmpty ? 'N/A' : _quantityController.text;
    String weight = _weightController.text.isEmpty ? 'N/A' : _weightController.text;
    String limit = _limitController.text.isEmpty ? '2' : _limitController.text;
    if (selectedCategory != null && globalConnectCode != null) {
      firebaseTodo = FirebaseTodo(
        category: selectedCategory!,
        globalConnectCode: globalConnectCode!,
      );
      firebaseTodo!.addTodo(
        title: title,
        quantity: quantity,
        weight: weight,
        limit: limit,
        globalConnectCode: globalConnectCode!,
      );
    }
  }

  int _currentPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    if (globalConnectCode == null) {
      return Scaffold(
          body: Center(
            child: Text(
              'No family code',
              style: TextStyle(fontSize: 24.0),
            ),
          )
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Inventory'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildExpandableSection(
                title: 'Fruits',
                content: FirebaseTodoList(
                  firebaseTodo: FirebaseTodo(
                    category: 'fruits',
                    globalConnectCode: globalConnectCode ?? '',
                  ),
                  showEditDialog: _showEditDialog,
                ),
              ),
              _buildExpandableSection(
                title: 'Vegetable',
                content: FirebaseTodoList(
                  firebaseTodo: FirebaseTodo(
                    category: 'vegetable',
                    globalConnectCode: globalConnectCode ?? '',
                  ),
                  showEditDialog: _showEditDialog,
                ),
              ),
              _buildExpandableSection(
                title: 'Daily Essentials',
                content: FirebaseTodoList(
                  firebaseTodo: FirebaseTodo(
                    category: 'daily essentials',
                    globalConnectCode: globalConnectCode ?? '',
                  ),
                  showEditDialog: _showEditDialog,
                ),
              ),
              _buildExpandableSection(
                title: 'Medicines',
                content: FirebaseTodoList(
                  firebaseTodo: FirebaseTodo(
                    category: 'medicines',
                    globalConnectCode: globalConnectCode ?? '',
                  ),
                  showEditDialog: _showEditDialog,
                ),
              ),
              _buildExpandableSection(
                title: 'Pulses',
                content: FirebaseTodoList(
                  firebaseTodo: FirebaseTodo(
                    category: 'pulses',
                    globalConnectCode: globalConnectCode ?? '',
                  ),
                  showEditDialog: _showEditDialog,
                ),
              ),
              Text(
                'Global Connect Code: ${globalConnectCode ?? "Not Available"}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          //backgroundColor: Colors.blue,
          elevation: 2.0,
          tooltip: 'Add a new item',
          isExtended: true,
          splashColor: Colors.blueAccent,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HG_App(),
                  ),
                );
                break;
              case 1:

              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Todo(),
                  ),
                );
                break;
              case 3:
              // Navigate to profile page
                Navigator.pushReplacement(
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
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.door_sliding),
              label: 'Pantry',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_outlined),
              label: 'Tasks',
            ),
            NavigationDestination(

              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required Widget content,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 20.0),
      ),
      children: [
        SingleChildScrollView(
          child: content,
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    String? _chosenValue = selectedCategory;

    // Clear text controllers
    _titleController.clear();
    _quantityController.clear();
    _weightController.clear();
    _limitController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Item'),
              content: SingleChildScrollView( // Wrap the content with SingleChildScrollView
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: _chosenValue,
                      onChanged: (String? value) {
                        setState(() {
                          _chosenValue = value;
                        });
                      },
                      items: <String>[
                        'fruits',
                        'vegetable',
                        'daily essentials',
                        'medicines',
                        'pulses'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Item Name'),
                    ),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                    ),
                    TextField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: 'Weight'),
                    ),
                    TextField(
                      controller: _limitController,
                      decoration: InputDecoration(labelText: 'Limit'),
                    ),
                  ],
                ),
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
                    setState(() {
                      selectedCategory = _chosenValue;
                    });
                    _addItem();
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


  Future<void> _showEditDialog(BuildContext context, String documentId,
      String quantity, String weight, String title, String limit) async {
    if (documentId.isEmpty) {
      // If documentId is empty, show an error message or handle the situation accordingly
      print('Error: Document ID is empty');
      return;
    }

    // Set initial values for the TextFields
    _titleController.text = title.isNotEmpty ? title : 'Untitled';
    _quantityController.text = quantity.isNotEmpty ? quantity : '0';
    _weightController.text = weight.isNotEmpty ? weight : '0';
    _limitController.text = limit.isNotEmpty ? limit : '2';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Item Name'),
                  ),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight'),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  TextField(
                    controller: _limitController,
                    decoration: InputDecoration(labelText: 'Limit'),
                  ),
                ],
              );
            },
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
                String newTitle = _titleController.text;
                String newQuantity =
                _quantityController.text.isNotEmpty ? _quantityController.text : 'N/A';
                String newWeight =
                _weightController.text.isNotEmpty ? _weightController.text : 'N/A';
                String newLimit = _limitController.text;
                _updateItem(documentId, newTitle, newQuantity, newWeight, newLimit); // Pass the limit parameter
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }


  void _updateItem(String documentId, String title, String quantity, String weight, String limit) async {
    if (documentId.isNotEmpty && title.isNotEmpty) { // Ensure both documentId and title are not empty
      if (selectedCategory != null && globalConnectCode != null) {
        firebaseTodo = FirebaseTodo(
          category: selectedCategory!,
          globalConnectCode: globalConnectCode!,
        );

        // Update the document with the new title and limit
        await firebaseTodo!.updateTodo(
          docId: documentId, // Use the original document ID
          title: title,
          quantity: quantity,
          weight: weight,
          limit: limit, // Pass the limit value
        );

        int parsedQuantity = quantity == 'N/A' ? 0 : int.tryParse(quantity) ?? 0;
        double parsedWeight = weight == 'N/A' ? 0 : toKgs(weight);
        int parsedLimit = int.tryParse(limit) ?? 2;



        // Check if either quantity or weight is less than the limit and not 'N/A'
        if ((parsedQuantity < parsedLimit && quantity != 'N/A') || (parsedWeight < parsedLimit && weight != 'N/A')) {
          // Add the title to the "refill" subcollection
          await FirebaseFirestore.instance
              .collection('sharedCollection')
              .doc(globalConnectCode)
              .collection('refill')
              .add({'title': title});
        } else {
          // Remove the title from the "refill" subcollection
          QuerySnapshot refillSnapshot = await FirebaseFirestore.instance
              .collection('sharedCollection')
              .doc(globalConnectCode)
              .collection('refill')
              .where('title', isEqualTo: title)
              .get();
          refillSnapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
        }

        // Refresh the page by calling setState
        setState(() {});
      }
    } else {
      print('Error: Document ID or title is empty');
    }
  }


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


}


