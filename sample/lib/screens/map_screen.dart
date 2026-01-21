import 'package:flutter/material.dart';
import '../models/ramen_shop.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('近くのラーメン屋'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Stack(
                children: [
                  // マップエリア（プレースホルダー）
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.map, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('マップが表示されます'),
                      ],
                    ),
                  ),
                  // マーカー
                  ...mockRamenShops.asMap().entries.map(
                    (entry) {
                      int idx = entry.key;
                      final shop = entry.value;
                      return Positioned(
                        left: 100 + (idx * 40.0),
                        top: 200 + (idx * 50.0),
                        child: GestureDetector(
                          onTap: () {
                            _showShopDetails(context, shop);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              '※ この画面はデモンストレーションです。\n実装時にGoogle Maps APIを統合してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showShopDetails(BuildContext context, RamenShop shop) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(shop.description),
              const SizedBox(height: 8),
              Text('評価: ${shop.rating} ⭐'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
    );
  }
}
