import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../models/ramen_shop.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class VideoScreen extends StatefulWidget {
  final UserSession userSession;

  const VideoScreen({Key? key, required this.userSession}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;

  // ショート動画のモックデータ
  late List<VideoItem> videos;
  late List<VideoItem> myUploadedVideos; // 自分でアップロードした動画
  bool _loadingReels = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);

    videos = [
      VideoItem(
        shop: mockRamenShops[0],
        title: '濃厚豚骨',
        duration: '00:30',
        uploadedBy: 'ユーザー1',
      ),
      VideoItem(
        shop: mockRamenShops[1],
        title: '醤油ラーメン',
        duration: '00:25',
        uploadedBy: 'ユーザー2',
      ),
      VideoItem(
        shop: mockRamenShops[2],
        title: '味噌ラーメン',
        duration: '00:35',
        uploadedBy: 'ユーザー3',
      ),
    ];
    myUploadedVideos = [];
    _loadUploadedVideos();
  }

  Future<void> _loadUploadedVideos() async {
    setState(() {
      _loadingReels = true;
    });

    try {
      final reels = await FirebaseService.fetchReels();
      final loaded = reels
          .where((item) => (item['downloadUrl'] as String?)?.isNotEmpty ?? false)
          .map((item) {
            final shopId = item['shopId']?.toString();
            final shopName = item['shopName']?.toString() ?? '店舗不明';
            final shop = _resolveShop(shopId, shopName);
            return VideoItem(
              shop: shop,
              title: item['title']?.toString() ?? '無題',
              duration: item['duration']?.toString() ?? '00:30',
              uploadedBy: item['uploadedBy']?.toString() ?? 'unknown',
              filePath: item['downloadUrl']?.toString(),
              fileType: item['fileType']?.toString() ?? 'video',
            );
          })
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        videos = [...loaded, ...videos];
        myUploadedVideos = loaded
            .where((v) => v.uploadedBy == _currentUserName())
            .toList();
      });
    } catch (_) {
      // Keep mock feed available even if Firestore fetch fails.
    } finally {
      if (mounted) {
        setState(() {
          _loadingReels = false;
        });
      }
    }
  }

  String _currentUserName() {
    if (widget.userSession.isRegularUser) {
      final user = widget.userSession.userAccount as RegularUser;
      return user.username;
    }
    return 'あなた';
  }

  RamenShop _resolveShop(String? shopId, String shopName) {
    for (final shop in mockRamenShops) {
      if (shop.id == shopId || shop.name == shopName) {
        return shop;
      }
    }
    return RamenShop(
      id: shopId ?? 'unknown',
      name: shopName,
      latitude: 0,
      longitude: 0,
      rating: 0,
      imageUrl: '',
      description: '',
      isOfficialAccount: false,
      videoUrls: const [],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ラーメン動画'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle), text: '動画を見る'),
            Tab(icon: Icon(Icons.upload), text: '動画をアップロード'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 動画閲覧タブ
          _loadingReels
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return VideoPlayerCard(
                      videoItem: videos[index],
                      onTap: () => _showVideoDetail(context, videos[index]),
                    );
                  },
                ),
          // 動画アップロードタブ
          UserVideoUploadScreen(
            videos: videos,
            myUploadedVideos: myUploadedVideos,
            userSession: widget.userSession,
            onVideoUploaded: (video) {
              setState(() {
                videos.add(video);
                myUploadedVideos.add(video);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showVideoDetail(BuildContext context, VideoItem video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoItem: video),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem videoItem;

  const VideoPlayerScreen({
    Key? key,
    required this.videoItem,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final src = widget.videoItem.filePath;
    final isVideo = widget.videoItem.fileType == 'video';
    if (!isVideo || src == null || !src.startsWith('http')) {
      return;
    }

    setState(() {
      _initializing = true;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(src));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
    } catch (_) {
      // Keep fallback UI.
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoItem.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            else if (_initializing)
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.play_circle_fill,
                size: 100,
                color: Colors.red,
              ),
            const SizedBox(height: 16),
            Text(
              widget.videoItem.shop.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoItem.title,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_controller != null && _controller!.value.isInitialized)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
                icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_controller!.value.isPlaying ? '停止' : '再生'),
              ),
          ],
        ),
      ),
    );
  }
}

class VideoItem {
  final RamenShop shop;
  final String title;
  final String duration;
  final String uploadedBy;
  final String? filePath; // ローカルファイルパス
  final String? fileType; // 'video' または 'image'

  VideoItem({
    required this.shop,
    required this.title,
    required this.duration,
    required this.uploadedBy,
    this.filePath,
    this.fileType,
  });
}

class UserVideoUploadScreen extends StatefulWidget {
  final List<VideoItem> videos;
  final List<VideoItem> myUploadedVideos;
  final UserSession userSession;
  final Function(VideoItem) onVideoUploaded;

  const UserVideoUploadScreen({
    Key? key,
    required this.videos,
    required this.myUploadedVideos,
    required this.userSession,
    required this.onVideoUploaded,
  }) : super(key: key);

  @override
  State<UserVideoUploadScreen> createState() => _UserVideoUploadScreenState();
}

class _UserVideoUploadScreenState extends State<UserVideoUploadScreen> {
  final _titleController = TextEditingController();
  RamenShop? _selectedShop;
  String? _selectedDuration = '00:30';
  PlatformFile? _selectedFile;
  String? _fileType; // 'video' または 'image'
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    await _pickFile(FileType.video, 'video');
  }

  Future<void> _pickFile(FileType type, String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: type,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
          _fileType = fileType;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fileType == 'video' ? '動画を選択しました' : '画像を選択しました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    await _pickFile(FileType.image, 'image');
  }

  Future<void> _uploadVideo() async {
    if (_titleController.text.isEmpty || _selectedShop == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトル、店舗、ファイルを選択してください')),
      );
      return;
    }

    // Keep web upload predictable by avoiding very large in-memory payloads.
    const maxSizeBytes = 60 * 1024 * 1024;
    if (_selectedFile!.size > maxSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルサイズが大きすぎます（60MB以下にしてください）')),
      );
      return;
    }

    final bytes = _selectedFile!.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイル読み込みに失敗しました。再選択してください')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.01;
    });

    String uploadedBy = 'あなた';
    if (widget.userSession.isRegularUser) {
      final user = widget.userSession.userAccount as RegularUser;
      uploadedBy = user.username;
    }

    final sessionUid = widget.userSession.userId;
    final uid = FirebaseService.auth.currentUser?.uid ?? sessionUid;
    final originalName = _selectedFile!.name.isNotEmpty ? _selectedFile!.name : 'upload.bin';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';
    final contentType = _fileType == 'video' ? 'video/mp4' : 'image/jpeg';
    final sizeMb = bytes.length / (1024 * 1024);
    final timeoutSeconds = (90 + sizeMb * 25).clamp(180, 900).toInt();
    final uploadTimeout = Duration(seconds: timeoutSeconds);

    try {
      final downloadUrl = await (() async {
        final uploadedUrl = await FirebaseService.uploadReel(
          uid,
          fileName,
          bytes,
          contentType: contentType,
          timeout: uploadTimeout,
          stallTimeout: const Duration(seconds: 20),
          onProgress: (progress) {
            if (!mounted) {
              return;
            }
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        await FirebaseService.addReelMetadata({
          'sessionUid': sessionUid,
          'uid': uid,
          'uploadedBy': uploadedBy,
          'title': _titleController.text,
          'shopId': _selectedShop!.id,
          'shopName': _selectedShop!.name,
          'duration': _selectedDuration ?? '00:30',
          'fileType': _fileType,
          'fileName': originalName,
          'downloadUrl': uploadedUrl,
        }, timeout: const Duration(seconds: 60));

        return uploadedUrl;
      })();

      if (!mounted) {
        return;
      }

      final uploadedType = _fileType;
      final newVideo = VideoItem(
        shop: _selectedShop!,
        title: _titleController.text,
        duration: _selectedDuration ?? '00:30',
        uploadedBy: uploadedBy,
        filePath: downloadUrl,
        fileType: _fileType,
      );

      widget.onVideoUploaded(newVideo);

      _titleController.clear();
      setState(() {
        _selectedShop = null;
        _selectedDuration = '00:30';
        _selectedFile = null;
        _fileType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${uploadedType == 'video' ? '動画' : '画像'}をアップロードしました'),
          backgroundColor: Colors.green,
        ),
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アップロードがタイムアウトしました（${timeoutSeconds}秒）。ファイルを小さくするか再試行してください')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.toString();
      final isPermission = message.contains('permission-denied');
      final isAuthDisabled = message.contains('anonymous-auth-disabled');
      final isStorageUnauthorized = message.contains('storage/unauthorized');
      final isCors = message.toLowerCase().contains('cors');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAuthDisabled
                ? '匿名認証が無効です。Firebase Console で Authentication -> 匿名 を有効化してください。'
                : isStorageUnauthorized || isPermission
                    ? 'Storage権限エラーです。Firebase Storage ルールで auth!=null の書き込み許可を確認してください。'
                    : isCors
                        ? 'ブラウザのCORSでブロックされています。StorageバケットのCORS設定を確認してください。'
                        : 'アップロード失敗: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ラーメン動画をアップロード',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '食べたお店の動画を撮影してシェアしよう！',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 店舗選択
            const Text(
              'どこのお店ですか？',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RamenShop>(
              value: _selectedShop,
              decoration: InputDecoration(
                labelText: '店舗を選択',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.store),
              ),
              items: mockRamenShops
                  .map((shop) => DropdownMenuItem(
                        value: shop,
                        child: Text(shop.name),
                      ))
                  .toList(),
              onChanged: (shop) {
                setState(() {
                  _selectedShop = shop;
                });
              },
            ),
            const SizedBox(height: 24),

            // タイトル入力
            const Text(
              '動画のタイトルを入力',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'タイトル',
                hintText: '例：美味しい豚骨ラーメン食べてきた！',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 24),

            // 動画時間選択
            if (_fileType == 'video') ...[
              const Text(
                '動画の長さ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                decoration: InputDecoration(
                  labelText: '動画の長さ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: '00:15', child: Text('15秒')),
                  DropdownMenuItem(value: '00:30', child: Text('30秒')),
                  DropdownMenuItem(value: '00:45', child: Text('45秒')),
                  DropdownMenuItem(value: '01:00', child: Text('1分')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value;
                  });
                },
              ),
              const SizedBox(height: 32),
            ],

            // ファイル選択セクション
            const Text(
              'ファイルを選択',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _fileType == 'video' ? Icons.videocam : Icons.image,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ファイル選択済み',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '種類: ${_fileType == 'video' ? '動画' : '画像'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ファイル: ${_selectedFile!.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _fileType = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('ファイルを変更'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('動画を選択'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('画像を選択'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // アップロードボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadVideo,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading
                      ? 'アップロード中... ${(100 * _uploadProgress).toStringAsFixed(0)}%'
                      : 'アップロード',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // アップロードのコツ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 アップロードのコツ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 美味しそうに見える角度から撮影\n'
                    '• 照明に気をつけて撮影\n'
                    '• 麺をすする音や食べている様子を入れる\n'
                    '• 店舗名や雰囲気がわかるように\n'
                    '• 他のユーザーのお気に入り数が多い動画を参考に',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerCard extends StatelessWidget {
  final VideoItem videoItem;
  final VoidCallback onTap;

  const VideoPlayerCard({
    Key? key,
    required this.videoItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ビデオサムネイル（またはプレースホルダー）
            Container(
              color: Colors.grey[800],
              child: const Icon(
                Icons.video_library,
                color: Colors.white,
                size: 80,
              ),
            ),
            // 再生ボタン
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            // 情報オーバーレイ
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      videoItem.shop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      videoItem.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 再生時間
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  videoItem.duration,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
