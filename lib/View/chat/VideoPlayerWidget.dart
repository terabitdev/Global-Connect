import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../../core/const/app_color.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocalFile;
  final double? width;
  final double? height;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isLocalFile = false,
    this.width,
    this.height,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.isLocalFile) {
        _videoController = VideoPlayerController.file(File(widget.videoUrl));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        showControls: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: AppColors.gray20,
          bufferedColor: AppColors.gray20.withOpacity(0.5),
        ),
        placeholder: _buildVideoPlaceholder(),
        autoInitialize: true,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.video_library,
          color: AppColors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppColors.gray20,
      highlightColor: AppColors.gray20.withOpacity(0.5),
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: AppColors.gray20,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.video_library,
            color: AppColors.darkGrey,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: AppColors.gray20,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.darkGrey,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load video',
            style: TextStyle(
              color: AppColors.darkGrey,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isInitialized = false;
              });
              _initializePlayer();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildShimmerLoader();
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Chewie(
          controller: _chewieController!,
        ),
      ),
    );
  }
}

// Widget for full-screen video playback
class FullScreenVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final bool isLocalFile;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    this.isLocalFile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      body: Center(
        child: VideoPlayerWidget(
          videoUrl: videoUrl,
          isLocalFile: isLocalFile,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),
      ),
    );
  }
}