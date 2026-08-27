import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  return HiveCategoryLocalDataSource();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  return CategoryRepositoryImpl(localDataSource: localDataSource);
});

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository repository;

  CategoryListNotifier({required this.repository})
    : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final list = await repository.getCategories();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await repository.addCategory(category);
      final currentList = state.value ?? [];
      // Replace or append
      final index = currentList.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        final newList = List<Category>.from(currentList);
        newList[index] = category;
        state = AsyncValue.data(newList);
      } else {
        state = AsyncValue.data([...currentList, category]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>((
      ref,
    ) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryListNotifier(repository: repository);
    });
