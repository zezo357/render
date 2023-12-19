import 'dart:io';

import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/statistics.dart';
import 'package:render/src/ffmpeg/ffmpeg.dart';
import 'package:render/src/formats/abstract.dart';
import 'package:render/src/service/notifier.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'service/exception.dart';

abstract class RenderProcessor<T extends RenderFormat> {
  final RenderSession<T, RenderSettings> session;

  RenderProcessor(this.session, this.width, this.height);

  bool _processing = false;

  String get inputPath;

  int width;

  int height;

  int? totalFrameTarget;

  Duration? duration;

  /// Converts the captures into a video file.
  Future<void> process({Duration? duration}) async {
    if (_processing) {
      throw const RenderException(
          "Cannot start new process, during an active one.");
    }
    totalFrameTarget = session.settings.asMotion?.frameRate ?? 1;
    this.duration = duration;
    _processing = true;
    try {
      final output = await _processTask(session.format.processShare);
      session.recordResult(output);
      _processing = false;
    } on RenderException catch (error) {
      session.recordError(error);
    }
  }

  /// Processes task frames and writes the output with the specific format
  /// Returns the process output file.
  Future<File> _processTask(double progressShare) async {
    final mainOutputFile =
        session.createOutputFile("output_main.${session.format.extension}");
    double frameRate = session.settings.asMotion?.frameRate.toDouble() ?? 1;
    // Receive main operation processing instructions
    final operation = session.format.processor(
        inputPath: inputPath,
        outputPath: mainOutputFile.path,
        frameRate: frameRate,
        width: width,
        height: height);
    await UniversalFfmpeg(session, totalFrameTarget, duration).executeCommand(
      operation.arguments,
      progressShare: progressShare,
    );
    return mainOutputFile;
  }
}

class ImageProcessor extends RenderProcessor<ImageFormat> {
  ImageProcessor(super.session, super.width, super.height);

  @override
  String get inputPath => session.inputPipe;
}

class MotionProcessor extends RenderProcessor<MotionFormat> {
  MotionProcessor(super.session, super.width, super.height);

  @override
  String get inputPath => session.inputPipe;
}
