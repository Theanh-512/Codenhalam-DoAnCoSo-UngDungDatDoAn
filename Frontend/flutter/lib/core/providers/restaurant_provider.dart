import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRestaurants();
});
