class PlantRecommendation {
  final String name;
  final String scientificName;
  final String description;
  final String imageUrl;

  PlantRecommendation({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imageUrl,
  });

  static List<PlantRecommendation> getRecommendations(double humidity) {
    // This can be expanded based on actual conditions
    return [
      PlantRecommendation(
        name: 'Snake Plant',
        scientificName: 'Sansevieria trifasciata',
        description: 'Perfect for beginners, tolerates low light and irregular watering.',
        imageUrl: 'assets/snake_plant.png',
      ),
      PlantRecommendation(
        name: 'Aloe Vera',
        scientificName: 'Aloe barbadensis millis',
        description: 'This plant is low maintenance and suitable for indoor spaces.',
        imageUrl: 'assets/aloe_vera.png',
      ),
      PlantRecommendation(
        name: 'Spider Plant',
        scientificName: 'Chlorophytum comosum',
        description: 'Perfectly matches the ${humidity.round()}% humidity in your home.',
        imageUrl: 'assets/spider_plant.png',
      ),
    ];
  }
}