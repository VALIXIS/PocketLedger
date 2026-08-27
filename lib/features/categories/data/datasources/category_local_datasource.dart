import 'package:hive/hive.dart';
import '../../domain/models/category.dart';

abstract class CategoryLocalDataSource {
  Future<List<Category>> getCategories();
  Future<void> saveCategory(Category category);
}

class HiveCategoryLocalDataSource implements CategoryLocalDataSource {
  static const String boxName = 'categories_box';

  Future<Box<Category>> _openBox() async {
    return await Hive.openBox<Category>(boxName);
  }

  @override
  Future<List<Category>> getCategories() async {
    final box = await _openBox();
    final customCategories = box.values.toList();

    // Combine defaults and custom categories
    final allCategoriesMap = <String, Category>{};
    for (var cat in Category.defaultCategories) {
      allCategoriesMap[cat.id] = cat;
    }
    for (var cat in customCategories) {
      allCategoriesMap[cat.id] = cat;
    }
    return allCategoriesMap.values.toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }
}
