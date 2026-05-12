import 'package:get/get.dart';

import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/services/admin_service.dart';
import '../routes/app_routes.dart';

class AdminCatalogController extends GetxController {
  final AdminService _adminService = AdminService();

  final categories = <CategoryModel>[].obs;
  final products = <ProductModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;
  final selectedCategoryId = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchProducts();
  }

  Future<void> fetchCategories({String search = ''}) async {
    if (!_ensureLogin()) return;
    try {
      isLoading.value = true;
      categories.assignAll(await _adminService.getCategories(search: search));
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProducts() async {
    if (!_ensureLogin()) return;
    try {
      isLoading.value = true;
      products.assignAll(
        await _adminService.getProducts(
          search: searchQuery.value,
          categoryId: selectedCategoryId.value,
        ),
      );
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveCategory({
    CategoryModel? currentCategory,
    required String name,
    required String icon,
  }) async {
    try {
      isSaving.value = true;
      final data = {
        'name': name.trim(),
        'icon': icon.trim().isEmpty ? '🍔' : icon.trim(),
      };
      final success = currentCategory == null
          ? await _adminService.createCategory(data)
          : await _adminService.updateCategory(currentCategory.id, data);
      if (success) {
        await fetchCategories();
        await fetchProducts();
        Get.back();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      isSaving.value = true;
      final success = await _adminService.deleteCategory(categoryId);
      if (success) {
        await fetchCategories();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveProduct({
    ProductModel? currentProduct,
    required String name,
    required String description,
    required String price,
    required String imageUrl,
    required String categoryId,
  }) async {
    try {
      isSaving.value = true;
      final data = {
        'name': name.trim(),
        'description': description.trim(),
        'price': double.tryParse(price.trim()) ?? 0,
        'imageUrl': imageUrl.trim(),
        'categoryId': categoryId,
      };
      final success = currentProduct == null
          ? await _adminService.createProduct(data)
          : await _adminService.updateProduct(currentProduct.id, data);
      if (success) {
        await fetchProducts();
        Get.back();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      isSaving.value = true;
      final success = await _adminService.deleteProduct(productId);
      if (success) {
        await fetchProducts();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void searchCategories(String query) {
    fetchCategories(search: query);
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    fetchProducts();
  }

  void filterProductsByCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
    fetchProducts();
  }

  String categoryName(String categoryId) {
    return categories
            .firstWhereOrNull((category) => category.id == categoryId)
            ?.name ??
        categoryId;
  }

  bool _ensureLogin() {
    if (_adminService.isLoggedIn) return true;
    Get.offAllNamed(AppRoutes.adminLogin);
    return false;
  }

  void _handleError(Object error) {
    if (error.toString().contains('Admin authentication required')) {
      Get.offAllNamed(AppRoutes.adminLogin);
      return;
    }
    Get.snackbar('Error', error.toString());
  }
}
