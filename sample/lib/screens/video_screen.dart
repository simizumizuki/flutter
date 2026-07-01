import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import '../models/ramen_shop.dart';
import '../models/user.dart';

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
          PageView.builder(
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

class VideoPlayerScreen extends StatelessWidget {
  final VideoItem videoItem;

  const VideoPlayerScreen({
    Key? key,
    required this.videoItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(videoItem.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              videoItem.shop.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              videoItem.title,
              style: const TextStyle(fontSize: 18),
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
  String? _selectedFilePath;
  String? _fileType; // 'video' または 'image'
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web環境では動画のアップロード機能は利用できません。モバイルアプリをご使用ください。')),
      );
      return;
    }

    try {
      // 最初にimage_pickerを試す
      try {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          setState(() {
            _selectedFilePath = video.path;
            _fileType = 'video';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画を選択しました')),
          );
          return;
        }
      } catch (e) {
        // image_pickerでエラーが起きた場合、file_pickerを使用
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('代替方法でファイルを選択します')),
        );
        _pickVideoWithFilePicker();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _pickVideoWithFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _fileType = 'video';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動画を選択しました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web環境では画像のアップロード機能は利用できません。モバイルアプリをご使用ください。')),
      );
      return;
    }

    try {
      // 最初にimage_pickerを試す
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (image != null) {
          setState(() {
            _selectedFilePath = image.path;
            _fileType = 'image';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像を選択しました')),
          );
          return;
        }
      } catch (e) {
        // image_pickerでエラーが起きた場合、file_pickerを使用
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('代替方法でファイルを選択します')),
        );
        _pickImageWithFilePicker();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _pickImageWithFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _fileType = 'image';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を選択しました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  void _uploadVideo() {
    if (_titleController.text.isEmpty || _selectedShop == null || _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトル、店舗、ファイルを選択してください')),
      );
      return;
    }

    // ユーザー名を取得
    String uploadedBy = 'あなた';
    if (widget.userSession.isRegularUser) {
      final user = widget.userSession.userAccount as RegularUser;
      uploadedBy = user.username;
    }

    final newVideo = VideoItem(
      shop: _selectedShop!,
      title: _titleController.text,
      duration: _selectedDuration ?? '00:30',
      uploadedBy: uploadedBy,
      filePath: _selectedFilePath,
      fileType: _fileType,
    );

    widget.onVideoUploaded(newVideo);

    _titleController.clear();
    _selectedShop = null;
    _selectedDuration = '00:30';
    _selectedFilePath = null;
    _fileType = null;

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_fileType == 'video' ? '動画' : '画像'}がアップロードされました！'),
          backgroundColor: Colors.green,
        ),
      );
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

            // Web環境での注記
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📱 ファイルアップロード機能はモバイルアプリでのみご利用いただけます。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              )
            else if (_selectedFilePath != null) ...[
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
                            _selectedFilePath = null;
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
            ] else if (!kIsWeb) ...[
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
            if (!kIsWeb)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadVideo,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('アップロード'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('アップロード（モバイルのみ）'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.grey[300],
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
