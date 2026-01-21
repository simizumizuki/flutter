import 'package:flutter/material.dart';
import '../models/ramen_shop.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // ショート動画のモックデータ
  final List<VideoItem> videos = [
    VideoItem(
      shop: mockRamenShops[0],
      title: '濃厚豚骨',
      duration: '00:30',
    ),
    VideoItem(
      shop: mockRamenShops[1],
      title: '醤油ラーメン',
      duration: '00:25',
    ),
    VideoItem(
      shop: mockRamenShops[2],
      title: '味噌ラーメン',
      duration: '00:35',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ラーメン動画'),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoPlayerCard(
            videoItem: videos[index],
            onTap: () => _showVideoDetail(context, videos[index]),
          );
        },
      ),
    );
  }

  void _showVideoDetail(BuildContext context, VideoItem video) {
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
                video.shop.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(video.title),
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

class VideoItem {
  final RamenShop shop;
  final String title;
  final String duration;

  VideoItem({
    required this.shop,
    required this.title,
    required this.duration,
  });
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
            // ビデオプレースホルダー
            Image.network(
              videoItem.shop.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.video_library,
                    color: Colors.white,
                    size: 80,
                  ),
                );
              },
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
