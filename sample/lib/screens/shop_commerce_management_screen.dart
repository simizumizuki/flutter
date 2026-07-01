import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/ramen_shop.dart';

class ShopCommerceManagementScreen extends StatefulWidget {
  final UserSession userSession;

  const ShopCommerceManagementScreen({
    Key? key,
    required this.userSession,
  }) : super(key: key);

  @override
  State<ShopCommerceManagementScreen> createState() =>
      _ShopCommerceManagementScreenState();
}

class _ShopCommerceManagementScreenState
    extends State<ShopCommerceManagementScreen> {
  late RamenShop _shopData;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _productImageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  void _loadShopData() {
    final shopOwner = widget.userSession.userAccount as ShopOwner;
    _shopData = mockRamenShops.firstWhere(
      (shop) => shop.id == shopOwner.shopId,
      orElse: () => mockRamenShops[0],
    );
  }

  void _addProduct() {
    final name = _productNameController.text.trim();
    final priceStr = _productPriceController.text.trim();
    final description = _productDescriptionController.text.trim();
    final imageUrl = _productImageController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのフィールドを入力してください')),
      );
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('価格は数値で入力してください')),
      );
      return;
    }

    final newProduct = ShopProduct(
      id: 'product_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      imageUrl: imageUrl.isEmpty
          ? 'https://via.placeholder.com/300x200?text=$name'
          : imageUrl,
      description: description,
    );

    setState(() {
      if (_shopData.products == null) {
        _shopData = RamenShop(
          id: _shopData.id,
          name: _shopData.name,
          latitude: _shopData.latitude,
          longitude: _shopData.longitude,
          imageUrl: _shopData.imageUrl,
          description: _shopData.description,
          rating: _shopData.rating,
          isOfficialAccount: _shopData.isOfficialAccount,
          videoUrls: _shopData.videoUrls,
          products: [newProduct],
        );
      } else {
        _shopData.products!.add(newProduct);
      }

      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      _productImageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('商品を追加しました')),
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('商品を削除します'),
          content: const Text('この商品を削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _shopData.products?.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('商品を削除しました')),
                );
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    _productImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Text(
                  '通販管理',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // 商品追加フォーム
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🛍️ 商品を追加',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          hintText: '商品名',
                          prefixIcon: const Icon(Icons.shopping_bag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productPriceController,
                        decoration: InputDecoration(
                          hintText: '価格 (円)',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productDescriptionController,
                        decoration: InputDecoration(
                          hintText: '商品説明',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productImageController,
                        decoration: InputDecoration(
                          hintText: '画像URL (オプション)',
                          prefixIcon: const Icon(Icons.image),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('追加'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 登録済み商品一覧
                Text(
                  '登録済み商品',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_shopData.products == null || _shopData.products!.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '登録済み商品がありません',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _shopData.products!.length,
                    itemBuilder: (context, index) {
                      final product = _shopData.products![index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '¥${product.price}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      product.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
