import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../models/ramen_shop.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class ShopScreen extends StatefulWidget {
  final UserSession? userSession;

  const ShopScreen({Key? key, this.userSession}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Map<String, CartItem> _cartItems = {};
  bool _isPurchasing = false;

  int get _cartCount => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  int get _totalPrice => _cartItems.values.fold(0, (sum, item) => sum + item.subtotal);

  String _resolveBuyerUid() {
    return FirebaseService.auth.currentUser?.uid ?? widget.userSession?.userId ?? 'guest_user';
  }

  void _addToCart(RamenShop shop, ShopProduct product) {
    final key = '${shop.id}_${product.id}';
    setState(() {
      final existing = _cartItems[key];
      if (existing == null) {
        _cartItems[key] = CartItem(shop: shop, product: product, quantity: 1);
      } else {
        existing.quantity += 1;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} をカートに追加しました')),
    );
  }

  void _changeQuantity(String key, int delta) {
    setState(() {
      final item = _cartItems[key];
      if (item == null) {
        return;
      }
      item.quantity += delta;
      if (item.quantity <= 0) {
        _cartItems.remove(key);
      }
    });
  }

  void _removeItem(String key) {
    setState(() {
      _cartItems.remove(key);
    });
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartItems: _cartItems,
          onChangeQuantity: _changeQuantity,
          onRemoveItem: _removeItem,
          onPurchase: _handlePurchase,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openOrderHistory() async {
    final buyerUid = _resolveBuyerUid();

    List<Map<String, dynamic>> orders = const [];
    String? loadError;

    try {
      orders = await FirebaseService.fetchOrdersByBuyerUid(buyerUid);
    } catch (e) {
      loadError = e.toString();
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          orders: orders,
          errorMessage: loadError,
        ),
      ),
    );
  }

  Future<bool> _handlePurchase() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_isPurchasing) {
      return false;
    }

    if (_cartItems.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('カートが空です')),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入確認'),
        content: Text('合計 ¥$_totalPrice を購入しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('購入する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return false;
    }

    final buyerUid = FirebaseService.auth.currentUser?.uid ?? 'guest_user';
    final confirmedTotal = _totalPrice;
    final orderItems = _cartItems.values
        .map((item) => <String, dynamic>{
              'shopId': item.shop.id,
              'shopName': item.shop.name,
              'productId': item.product.id,
              'productName': item.product.name,
              'price': item.product.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            })
        .toList();

    // 購入確定時点でカートを空にする。
    setState(() {
      _cartItems.clear();
    });

    setState(() {
      _isPurchasing = true;
    });

    try {
      await FirebaseService.createOrder(
        buyerUid: buyerUid,
        items: orderItems,
        totalPrice: confirmedTotal,
      );
    } catch (e) {
      if (!mounted) {
        return true;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('購入は確定しましたが、注文データ保存に失敗しました: $e')),
      );
      return true;
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('購入が完了しました。ありがとうございます！')),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final officialShops = mockRamenShops.where((s) => s.isOfficialAccount).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('通販'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openOrderHistory,
            icon: const Icon(Icons.receipt_long),
            tooltip: '注文履歴',
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _openCart,
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'カートを見る',
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _cartCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: officialShops.isEmpty
          ? const Center(child: Text('公式通販はまだありません'))
          : ListView.builder(
              itemCount: officialShops.length,
              itemBuilder: (context, index) {
                return ShopCard(
                  shop: officialShops[index],
                  onAddToCart: _addToCart,
                );
              },
            ),
    );
  }
}

class ShopCard extends StatelessWidget {
  final RamenShop shop;
  final void Function(RamenShop shop, ShopProduct product) onAddToCart;

  const ShopCard({
    Key? key,
    required this.shop,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 60),
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
                    (product) => ProductTile(
                      product: product,
                      onAddToCart: () => onAddToCart(shop, product),
                    ),
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
  final VoidCallback onAddToCart;

  const ProductTile({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

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
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
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
            onPressed: onAddToCart,
            child: const Text('カートに追加'),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final RamenShop shop;
  final ShopProduct product;
  int quantity;

  CartItem({
    required this.shop,
    required this.product,
    required this.quantity,
  });

  int get subtotal => product.price * quantity;
}

class CartScreen extends StatefulWidget {
  final Map<String, CartItem> cartItems;
  final void Function(String key, int delta) onChangeQuantity;
  final void Function(String key) onRemoveItem;
  final Future<bool> Function() onPurchase;

  const CartScreen({
    Key? key,
    required this.cartItems,
    required this.onChangeQuantity,
    required this.onRemoveItem,
    required this.onPurchase,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  @override
  Widget build(BuildContext context) {
    final entries = widget.cartItems.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value.subtotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('カート'),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('カートに商品がありません'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final key = entries[index].key;
                      final item = entries[index].value;
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('${item.shop.name}  ¥${item.product.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                widget.onChangeQuantity(key, -1);
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              onPressed: () {
                                widget.onChangeQuantity(key, 1);
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () {
                                widget.onRemoveItem(key);
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '合計: ¥$total',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await widget.onPurchase();
                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('購入する'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String? errorMessage;

  const OrderHistoryScreen({
    Key? key,
    required this.orders,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注文履歴'),
      ),
      body: errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('履歴の取得に失敗しました: $errorMessage'),
              ),
            )
          : orders.isEmpty
              ? const Center(child: Text('注文履歴はまだありません'))
              : ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final total = order['totalPrice'] ?? 0;
                    final status = order['status']?.toString() ?? 'unknown';
                    final items = (order['items'] as List?)?.cast<dynamic>() ?? const [];
                    final itemCount = items.fold<int>(0, (sum, e) {
                      if (e is Map && e['quantity'] is int) {
                        return sum + (e['quantity'] as int);
                      }
                      return sum;
                    });
                    final ts = order['createdAt'];
                    final createdAtText = ts is Timestamp
                        ? ts.toDate().toString().replaceFirst('.000', '')
                        : '時刻未確定';

                    return ListTile(
                      title: Text('合計 ¥$total'),
                      subtitle: Text('商品数: $itemCount点  状態: $status\n$createdAtText'),
                      isThreeLine: true,
                    );
                  },
                ),
    );
  }
}
