import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuggestedRecipesPage extends StatefulWidget {
  @override
  _SuggestedRecipesPageState createState() => _SuggestedRecipesPageState();
}

class _SuggestedRecipesPageState extends State<SuggestedRecipesPage> {
  final TextEditingController _ingredientController = TextEditingController();
  List<dynamic> _recipes = [];
  bool _isLoading = false;

  Future<void> _fetchRecipes(String ingredient) async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = '01646fffd6474f3c95cb0383f07a9ceb';
    final url = Uri.parse('https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredient&number=10&apiKey=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _recipes = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch recipes. Please try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRecipeDetails(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recettes suggérées'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Entrez un ingrédient',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _fetchRecipes(_ingredientController.text);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: _recipes.isEmpty
                  ? Center(
                child: Text(
                  'Aucune recette trouvée. Veuillez essayer un autre ingrédient.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: recipe['image'] != null
                          ? Image.network(recipe['image'], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.fastfood, color: Colors.green),
                      title: Text(recipe['title'] ?? 'Recette sans titre'),
                      onTap: () => _navigateToRecipeDetails(recipe),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailsPage extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailsPage({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['title'] ?? 'Détails de la recette'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            recipe['image'] != null
                ? Image.network(recipe['image'], height: 200, fit: BoxFit.cover)
                : Icon(Icons.fastfood, size: 200, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              recipe['title'] ?? 'Titre inconnu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Instructions :',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  recipe['instructions'] ?? 'Aucune instruction disponible.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
