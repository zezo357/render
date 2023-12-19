import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:render/render.dart';
import 'package:render/src/service/session.dart';

class UniversalFfmpeg<T extends RenderFormat> {
  RenderSession<T, RenderSettings> session;
  int? totalFrameTarget;
  Duration? duration;

  UniversalFfmpeg(this.session, this.totalFrameTarget, this.duration);

  /// Wrapper around the FFmpeg command execution. Takes care of notifying the
  /// session about the progress of execution.
  Future<void> executeCommand(List<String> command,
      {required double progressShare}) async {
    FFmpeg? ffmpeg;
    try {
      ffmpeg = createFFmpeg(CreateFFmpegParam(log: true));
      // ffmpeg.setLogger(_onLogHandler);
      // ffmpeg.setProgress(_onProgressHandler);

      await ffmpeg.load();
      final result = await ffmpeg.run(command);

      // if (result.exitCode != 0) {
      //   // Handle error
      //   session.recordError(RenderException(
      //     "[Ffmpeg execution error] ${result.stderr}",
      //     fatal: true,
      //   ));
      // } else {
        // Handle success
        session.recordActivity(
          RenderState.processing,
          progressShare,
          message: "Completed ffmpeg operation",
          details: "FFmpeg operation successful",
        );
      // }
    } catch (e) {
      // Handle exception
      session.recordError(RenderException(
        "[Ffmpeg execution error] $e",
        fatal: true,
      ));
    }
  }
}
