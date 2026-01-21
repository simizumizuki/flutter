import 'package:flutter/material.dart';
import '../models/ramen_shop.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final officialShops = mockRamenShops.where((s) => s.isOfficialAccount).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('通販'),
        elevation: 0,
      ),
      body: officialShops.isEmpty
          ? const Center(child: Text('公式通販はまだありません'))
          : ListView.builder(
              itemCount: officialShops.length,
              itemBuilder: (context, index) {
                return ShopCard(shop: officialShops[index]);
              },
            ),
    );
  }
}

class ShopCard extends StatelessWidget {
  final RamenShop shop;

  const ShopCard({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            shop.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shop.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (shop.products != null && shop.products!.isNotEmpty)
                  ...shop.products!.map(
                    (product) => ProductTile(product: product),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final ShopProduct product;

  const ProductTile({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${product.price.toString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('カートに追加しました')),
              );
            },
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }
}
