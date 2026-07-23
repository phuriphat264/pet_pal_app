import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapo Camera Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  // ---------------------------------------------------------
  // TODO: เปลี่ยนค่าตรงนี้เป็นข้อมูลกล้อง Tapo C210 ของคุณ
  // ---------------------------------------------------------
  final String cameraIp = '10.5.50.80'; 
  final String cameraUser = 'petpal';
  final String cameraPass = 'puri2647';
  // ---------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    // นำข้อมูลมาสร้างเป็น RTSP URL สำหรับดึงภาพสตรีม
    // ใช้ stream2 (360p) ก่อนเพื่อความรวดเร็วและเสถียรบน Simulator
    // หากต้องการภาพชัดขึ้นให้เปลี่ยน stream2 เป็น stream1
    final String rtspUrl = 'rtsp://$cameraUser:$cameraPass@$cameraIp:554/stream1';

    // Play a [Media] or [Playlist].
    player.open(Media(rtspUrl));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tapo C210 Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(controller: controller),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'กำลังดึงภาพจากกล้อง...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}
