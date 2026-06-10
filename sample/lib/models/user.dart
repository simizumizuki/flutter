// ユーザーアカウントタイプ
enum AccountType { regularUser, shopOwner }

// 一般ユーザー
class RegularUser {
  final String id;
  final String username;
  final String email;
  final String password;
  final String profileImageUrl;
  final String bio;
  final List<String> uploadedVideoIds; // アップロードした動画のID
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;

  RegularUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.profileImageUrl,
    this.bio = '',
    this.uploadedVideoIds = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });
}

// お店関係者
class ShopOwner {
  final String id;
  final String shopName;
  final String email;
  final String password;
  final String shopImageUrl;
  final String bio;
  final String shopId; // 関連するRamenShopのID
  final List<String> managedVideoIds; // 管理している動画のID
  final DateTime createdAt;

  ShopOwner({
    required this.id,
    required this.shopName,
    required this.email,
    required this.password,
    required this.shopImageUrl,
    this.bio = '',
    required this.shopId,
    this.managedVideoIds = const [],
    required this.createdAt,
  });
}

// 現在のユーザーセッション
class UserSession {
  final String userId;
  final AccountType accountType;
  final dynamic userAccount; // RegularUser or ShopOwner

  UserSession({
    required this.userId,
    required this.accountType,
    required this.userAccount,
  });

  bool get isRegularUser => accountType == AccountType.regularUser;
  bool get isShopOwner => accountType == AccountType.shopOwner;
}

// モックユーザーデータ
final mockRegularUsers = [
  RegularUser(
    id: 'user1',
    username: 'ラーメン好き太郎',
    email: 'ramen_lover1@example.com',
    password: 'password1',
    profileImageUrl: 'https://via.placeholder.com/200x200?text=User1',
    bio: 'ラーメン巡りが趣味です！',
    uploadedVideoIds: [],
    followerCount: 250,
    followingCount: 150,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  ),
  RegularUser(
    id: 'user2',
    username: 'グルメ女子ミサ',
    email: 'gourmet_misa@example.com',
    password: 'password2',
    profileImageUrl: 'https://via.placeholder.com/200x200?text=User2',
    bio: '美味しいもの探し中🍜',
    uploadedVideoIds: [],
    followerCount: 1200,
    followingCount: 450,
    createdAt: DateTime.now().subtract(const Duration(days: 200)),
  ),
];

final mockShopOwners = [
  ShopOwner(
    id: 'shop_owner1',
    shopName: 'とんこつ家',
    email: 'tonkotsu_ya@example.com',
    password: 'tonkotsu123',
    shopImageUrl: 'https://via.placeholder.com/200x200?text=Shop1',
    bio: '濃厚豚骨ラーメン専門店です',
    shopId: '1',
    managedVideoIds: [],
    createdAt: DateTime.now().subtract(const Duration(days: 500)),
  ),
  ShopOwner(
    id: 'shop_owner2',
    shopName: '味噌ラーメンラボ',
    email: 'miso_lab@example.com',
    password: 'miso123',
    shopImageUrl: 'https://via.placeholder.com/200x200?text=Shop2',
    bio: '北海道味噌ラーメン専門',
    shopId: '3',
    managedVideoIds: [],
    createdAt: DateTime.now().subtract(const Duration(days: 300)),
  ),
];
