import 'package:flutter/material.dart';
import '../models/user.dart';

class SignupScreen extends StatefulWidget {
  final Function() onSignupCancel;
  final Function(UserSession) onSignupSuccess;

  const SignupScreen({
    Key? key,
    required this.onSignupCancel,
    required this.onSignupSuccess,
  }) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AccountType _selectedAccountType = AccountType.regularUser;
  final _shopNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    final username = _selectedAccountType == AccountType.regularUser
        ? _usernameController.text
        : _shopNameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // バリデーション
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのフィールドを入力してください')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが一致しません')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは6文字以上にしてください')),
      );
      return;
    }

    // メールアドレスの重複チェック
    bool emailExists = mockRegularUsers.any((u) => u.email == email) ||
        mockShopOwners.any((s) => s.email == email);
    
    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このメールアドレスは既に登録されています')),
      );
      return;
    }

    UserSession session;

    if (_selectedAccountType == AccountType.regularUser) {
      // 一般ユーザーとして新規作成
      final newUser = RegularUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        password: password,
        profileImageUrl: 'https://via.placeholder.com/200x200?text=${username[0]}',
        bio: '',
        uploadedVideoIds: [],
        followerCount: 0,
        followingCount: 0,
        createdAt: DateTime.now(),
      );

      // モックデータに追加（実際にはバックエンドで保存）
      mockRegularUsers.add(newUser);

      session = UserSession(
        userId: newUser.id,
        accountType: AccountType.regularUser,
        userAccount: newUser,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウント作成成功！')),
      );
    } else {
      // お店として新規作成
      final newShop = ShopOwner(
        id: 'shop_owner_${DateTime.now().millisecondsSinceEpoch}',
        shopName: username,
        email: email,
        password: password,
        shopImageUrl: 'https://via.placeholder.com/200x200?text=${username[0]}',
        bio: '',
        shopId: 'shop_${DateTime.now().millisecondsSinceEpoch}',
        managedVideoIds: [],
        createdAt: DateTime.now(),
      );

      // モックデータに追加（実際にはバックエンドで保存）
      mockShopOwners.add(newShop);

      session = UserSession(
        userId: newShop.id,
        accountType: AccountType.shopOwner,
        userAccount: newShop,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お店アカウント作成成功！')),
      );
    }

    widget.onSignupSuccess(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    '🍜 アカウント作成',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ラーメンマップに参加しよう',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // アカウントタイプ選択
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'アカウントタイプを選択',
                          style: TextStyle(
                            color: Color(0xff424242),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedAccountType = AccountType.regularUser;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedAccountType == AccountType.regularUser
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '👤 一般ユーザー',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedAccountType == AccountType.regularUser
                                          ? Colors.red[700]
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedAccountType = AccountType.shopOwner;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedAccountType == AccountType.shopOwner
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🏪 お店関係者',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedAccountType == AccountType.shopOwner
                                          ? Colors.red[700]
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ユーザー名/店舗名入力
                  TextField(
                    controller: _selectedAccountType == AccountType.regularUser
                        ? _usernameController
                        : _shopNameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: _selectedAccountType == AccountType.regularUser
                          ? 'ユーザー名'
                          : '店舗名',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: _selectedAccountType == AccountType.regularUser
                          ? 'ユーザー名を入力'
                          : '店舗名を入力',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        _selectedAccountType == AccountType.regularUser
                            ? Icons.person
                            : Icons.business,
                        color: Colors.orange,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // メールアドレス入力
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: 'メールアドレスを入力',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.email, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // パスワード入力
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.black),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: 'パスワードを入力',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // パスワード確認入力
                  TextField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.black),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'パスワード確認',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: 'パスワードを再度入力',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 作成ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'アカウント作成',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // キャンセルボタン
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onSignupCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
