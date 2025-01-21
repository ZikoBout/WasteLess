import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodTypesPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Set<String> foodTypes;
  final Function(Map<String, dynamic>) onDeleteItem;

  const FoodTypesPage({
    Key? key,
    required this.items,
    required this.foodTypes,
    required this.onDeleteItem,
  }) : super(key: key);

  @override
  _FoodTypesPageState createState() => _FoodTypesPageState();
}

class _FoodTypesPageState extends State<FoodTypesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types de Nourriture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.foodTypes.length,
          itemBuilder: (context, index) {
            final type = widget.foodTypes.elementAt(index);
            final icon = _getIconForType(type);
            final color = _getColorForType(type);

            return GestureDetector(
              onTap: () {
                _showItemsForType(context, type);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 50,
                      color: color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showItemsForType(BuildContext context, String type) {
    final itemsForType = widget.items.where((item) => item['type'] == type).toList();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Articles : $type'),
          ),
          body: itemsForType.isEmpty
              ? Center(
            child: Text(
              'Aucun article trouvé pour $type.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: itemsForType.length,
            itemBuilder: (context, index) {
              final item = itemsForType[index];
              final expirationDate = item['expirationDate'] as DateTime;

              // Déterminer l'état
              final status = _getItemStatus(expirationDate);
              final statusColor = _getStatusColor(status);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text(item['name']),
                  subtitle: Text(
                    status,
                    style: TextStyle(color: statusColor),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _deleteItem(item);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && item['id'] != null) {
        // Supprime l'article de Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(item['id'])
            .delete();

        // Supprime localement
        setState(() {
          widget.onDeleteItem(item);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Article supprimé avec succès.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression : $e")),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Fruits':
        return Icons.apple;
      case 'Légumes':
        return Icons.grass;
      case 'Viandes':
        return Icons.set_meal;
      case 'Produits laitiers':
        return Icons.local_drink;
      case 'Céréales':
        return Icons.rice_bowl;
      case 'Boissons':
        return Icons.local_cafe;
      default:
        return Icons.category;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Fruits':
        return Colors.redAccent;
      case 'Légumes':
        return Colors.green;
      case 'Viandes':
        return Colors.brown;
      case 'Produits laitiers':
        return Colors.blueAccent;
      case 'Céréales':
        return Colors.amber;
      case 'Boissons':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  String _getItemStatus(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;

    if (difference < 0) {
      return 'Expiré';
    } else if (difference <= 3) {
      return 'Proche d\'expiration';
    } else {
      return 'Valide';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Expiré':
        return Colors.red;
      case 'Proche d\'expiration':
        return Colors.orange;
      case 'Valide':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
