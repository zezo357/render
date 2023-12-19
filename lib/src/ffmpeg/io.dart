import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/statistics.dart';
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
    final ffmpegSession = await FFmpegSession.create(
      command,
      (ffmpegSession) async {
        session.recordActivity(
          RenderState.processing,
          progressShare,
          message: "Completed ffmpeg operation",
          details: "[async notification] Ffmpeg session completed: "
              "${ffmpegSession.getSessionId()}, time needed: "
              "${await ffmpegSession.getDuration()}, execution: "
              "${ffmpegSession.getCommand()}, logs: "
              "${await ffmpegSession.getLogsAsString()}, return code: "
              "${await ffmpegSession.getReturnCode()}, stack trace: "
              "${await ffmpegSession.getFailStackTrace()}",
        );
      },
      (Log log) {
        final message = log.getMessage();
        if (message.toLowerCase().contains("error")) {
          session.recordError(RenderException(
            "[Ffmpeg execution error] $message",
            fatal: true,
          ));
        } else {
          session.recordLog(message);
        }
      },
      (Statistics statistics) {
        if (totalFrameTarget != null && duration != null) {
          final progression = (statistics.getVideoFrameNumber() /
                  (totalFrameTarget! * duration!.inSeconds))
              .clamp(0.0, 1.0);
          session.recordActivity(RenderState.processing, progression,
              message: "Converting captures");
        } else {
          session.recordActivity(
            RenderState.processing,
            null,
            message: "Converting captures",
          );
        }
      },
    );
    await FFmpegKitConfig.ffmpegExecute(ffmpegSession).timeout(
      session.settings.processTimeout,
      onTimeout: () {
        session.recordError(
          const RenderException(
            "Processing session timeout",
            fatal: true,
          ),
        );
        ffmpegSession.cancel();
      },
    );
  }
}
