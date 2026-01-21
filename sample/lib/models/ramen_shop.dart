class RamenShop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String description;
  final double rating;
  final bool isOfficialAccount;
  final List<String> videoUrls;
  final List<ShopProduct>? products;

  RamenShop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.isOfficialAccount,
    required this.videoUrls,
    this.products,
  });
}

class ShopProduct {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String description;

  ShopProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });
}

// モックデータ
List<RamenShop> mockRamenShops = [
  RamenShop(
    id: '1',
    name: 'とんこつ家',
    latitude: 35.6812,
    longitude: 139.7671,
    imageUrl: 'https://via.placeholder.com/400x300?text=Tonkotsu',
    description: '濃厚豚骨ラーメン専門店',
    rating: 4.5,
    isOfficialAccount: true,
    videoUrls: ['video1.mp4', 'video2.mp4'],
    products: [
      ShopProduct(
        id: 'p1',
        name: 'とんこつラーメン (2食)',
        price: 2500,
        imageUrl: 'https://via.placeholder.com/300x200?text=Ramen+Pack',
        description: '自宅で本店の味が楽しめます',
      ),
    ],
  ),
  RamenShop(
    id: '2',
    name: '醤油ラーメン太郎',
    latitude: 35.6895,
    longitude: 139.6917,
    imageUrl: 'https://via.placeholder.com/400x300?text=Shoyu',
    description: '昭和風醤油ラーメン',
    rating: 4.2,
    isOfficialAccount: false,
    videoUrls: [],
  ),
  RamenShop(
    id: '3',
    name: '味噌ラーメンラボ',
    latitude: 35.6762,
    longitude: 139.7501,
    imageUrl: 'https://via.placeholder.com/400x300?text=Miso',
    description: '北海道味噌ラーメン',
    rating: 4.7,
    isOfficialAccount: true,
    videoUrls: ['video3.mp4'],
    products: [
      ShopProduct(
        id: 'p2',
        name: '味噌ラーメンセット',
        price: 3000,
        imageUrl: 'https://via.placeholder.com/300x200?text=Miso+Set',
        description: 'スープ、麺、トッピングセット',
      ),
    ],
  ),
];
