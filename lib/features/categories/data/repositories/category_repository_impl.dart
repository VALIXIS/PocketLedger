import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Category>> getCategories() {
    return localDataSource.getCategories();
  }

  @override
  Future<void> addCategory(Category category) {
    return localDataSource.saveCategory(category);
  }
}
