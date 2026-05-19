class PlantCare {
  final String plantName;
  final String scientificName;
  final String light;
  final String water;
  final String temperature;
  final String humidity;
  final String soil;
  final String fertilizer;
  final String tips;
  final List<String> commonProblems;

  PlantCare({
    required this.plantName,
    required this.scientificName,
    required this.light,
    required this.water,
    required this.temperature,
    required this.humidity,
    required this.soil,
    required this.fertilizer,
    required this.tips,
    required this.commonProblems,
  });

  // Predefined care data for common plants
  static Map<String, PlantCare> get plantCareMap => {
    'Snake Plant': PlantCare(
      plantName: 'Snake Plant',
      scientificName: 'Sansevieria trifasciata',
      light: 'Low to bright indirect light. Avoid direct sunlight.',
      water: 'Water every 2-6 weeks. Let soil dry completely between waterings.',
      temperature: '18-27°C (65-80°F)',
      humidity: 'Low to moderate. Very adaptable.',
      soil: 'Well-draining cactus/succulent mix.',
      fertilizer: 'Fertilize once in spring and summer with cactus fertilizer.',
      tips: 'Very hard to kill! Perfect for beginners. Wipe leaves occasionally.',
      commonProblems: ['Overwatering (yellow leaves)', 'Cold damage', 'Root rot'],
    ),
    'ZZ Plant': PlantCare(
      plantName: 'ZZ Plant',
      scientificName: 'Zamioculcas zamiifolia',
      light: 'Low to bright indirect light. Very shade tolerant.',
      water: 'Water every 2-3 weeks. Allow soil to dry completely.',
      temperature: '18-24°C (65-75°F)',
      humidity: 'Low to high. Very adaptable.',
      soil: 'Well-draining potting mix with perlite.',
      fertilizer: 'Fertilize 2-3 times per year with balanced fertilizer.',
      tips: 'Drought tolerant. Wipe leaves to keep them shiny.',
      commonProblems: ['Yellow leaves (overwatering)', 'Root rot', 'Slow growth'],
    ),
    'Pothos': PlantCare(
      plantName: 'Pothos',
      scientificName: 'Epipremnum aureum',
      light: 'Low to bright indirect light. Variegation needs more light.',
      water: 'Water when top 2 inches of soil are dry.',
      temperature: '18-29°C (65-85°F)',
      humidity: 'Moderate to high. Benefits from occasional misting.',
      soil: 'Well-draining potting mix.',
      fertilizer: 'Fertilize monthly during growing season.',
      tips: 'Trailing or climbing. Propagate easily from cuttings.',
      commonProblems: ['Brown leaves (underwatering)', 'Yellow leaves (overwatering)', 'Leggy growth (not enough light)'],
    ),
    'Spider Plant': PlantCare(
      plantName: 'Spider Plant',
      scientificName: 'Chlorophytum comosum',
      light: 'Bright indirect light. Some direct morning sun OK.',
      water: 'Water when top inch of soil is dry.',
      temperature: '18-27°C (65-80°F)',
      humidity: 'Moderate. Tolerates dry air.',
      soil: 'Well-draining general potting mix.',
      fertilizer: 'Fertilize monthly during spring and summer.',
      tips: 'Produces baby "spiderettes" that can be propagated.',
      commonProblems: ['Brown tips (too much fertilizer or fluoride)', 'Pale leaves (not enough light)'],
    ),
    'Aloe Vera': PlantCare(
      plantName: 'Aloe Vera',
      scientificName: 'Aloe barbadensis miller',
      light: 'Bright indirect light to full sun.',
      water: 'Water deeply but infrequently. Let soil dry completely.',
      temperature: '18-27°C (65-80°F)',
      humidity: 'Low. Prefers dry conditions.',
      soil: 'Cactus/succulent soil with sand/perlite.',
      fertilizer: 'Fertilize once in spring with cactus fertilizer.',
      tips: 'Gel from leaves can soothe burns. Avoid overwatering.',
      commonProblems: ['Mushy leaves (overwatering)', 'Brown leaves (too much sun)', 'Leggy growth (not enough light)'],
    ),
    'Monstera': PlantCare(
      plantName: 'Monstera',
      scientificName: 'Monstera deliciosa',
      light: 'Bright indirect light. No direct sun.',
      water: 'Water when top 2 inches of soil are dry.',
      temperature: '20-30°C (68-86°F)',
      humidity: 'High. Mist regularly or use humidifier.',
      soil: 'Well-draining, rich potting mix with peat.',
      fertilizer: 'Fertilize monthly during growing season.',
      tips: 'Provide moss pole for climbing. Leaves develop holes/fenestrations with maturity.',
      commonProblems: ['Yellow leaves (overwatering)', 'Brown edges (low humidity)', 'No holes (not enough light)'],
    ),
  };

  static PlantCare? getPlantCare(String plantName) {
    return plantCareMap[plantName];
  }
}