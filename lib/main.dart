import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_page.dart';
import 'expired_items_page.dart';
import 'suggested_recipes_page.dart';
import 'food_types_page.dart';
import 'SignUpPage.dart';
import 'LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteLess',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthHandler(),
    );
  }
}

class AuthHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return MainPage(); // Navigate to main page if logged in
        } else {
          return LoginPage(); // Navigate to login page if not logged in
        }
      },
    );
  }
}



class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Map<String, dynamic>> items = [
    {'name': 'Tomate', 'type': 'Fruits', 'expirationDate': DateTime.now().add(const Duration(days: 3))},
    {'name': 'Fromage', 'type': 'Produits laitiers', 'expirationDate': DateTime.now().add(const Duration(days: 5))},
    {'name': 'Poulet', 'type': 'Viandes', 'expirationDate': DateTime.now().subtract(const Duration(days: 2))},
    {'name': 'Carottes', 'type': 'Légumes', 'expirationDate': DateTime.now().add(const Duration(days: 7))},
    {'name': 'Pomme', 'type': 'Fruits', 'expirationDate': DateTime.now().add(const Duration(days: 1))},
  ];

  final Set<String> foodTypes = {'Fruits', 'Légumes', 'Viandes', 'Produits laitiers', 'Céréales', 'Boissons', 'Autres'};

  void addItem(Map<String, dynamic> newItem) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('items')
            .add(newItem);

        setState(() {
          newItem['id'] = docRef.id;
          items.add(newItem);
          foodTypes.add(newItem['type']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'ajout : $e")),
      );
    }
  }

  Future<void> loadItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('items')
            .get();

        setState(() {
          items.clear();
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['expirationDate'] is Timestamp) {
              data['expirationDate'] = (data['expirationDate'] as Timestamp).toDate();
            }

            data['id'] = doc.id;
            items.add(data);
            foodTypes.add(data['type']);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des articles : $e")),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void deleteItem(Map<String, dynamic> item) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && item['id'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(item['id'])
            .delete();

        setState(() {
          items.remove(item);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression : $e")),
      );
    }
  }

  void _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> getExpiredItems() {
    final now = DateTime.now();
    return items.where((item) {
      final expirationDate = item['expirationDate'] as DateTime;
      return expirationDate.isBefore(now);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expiredItems = getExpiredItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WasteLess', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logOut,
          ),
        ],
      ),
      drawer: AppDrawer(
        items: items,
        expiredItems: expiredItems,
        foodTypes: foodTypes,
        addItem: addItem,
        onDeleteItem: deleteItem,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Colors.yellow[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bienvenue dans WasteLess !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final newItem = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddItemPage(),
                  ),
                );
                if (newItem != null) {
                  addItem(newItem);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un article'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> expiredItems;
  final Set<String> foodTypes;
  final Function(Map<String, dynamic>) addItem;
  final Function(Map<String, dynamic>) onDeleteItem;

  const AppDrawer({
    Key? key,
    required this.items,
    required this.expiredItems,
    required this.foodTypes,
    required this.addItem,
    required this.onDeleteItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Ajouter un article', style: TextStyle(color: Colors.black)),
            onTap: () async {
              final newItem = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddItemPage()),
              );
              if (newItem != null) {
                addItem(newItem);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Articles expirés', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpiredItemsPage(items: expiredItems),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Recettes suggérées', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SuggestedRecipesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Types de nourriture', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodTypesPage(
                    items: items,
                    foodTypes: foodTypes,
                    onDeleteItem: onDeleteItem,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}