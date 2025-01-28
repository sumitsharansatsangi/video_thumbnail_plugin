package com.kumpali.video_thumbnail_plugin

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import com.bumptech.glide.gifencoder.AnimatedGifEncoder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.FileOutputStream
import java.io.IOException

class VideoThumbnailPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(binding: FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "video_thumbnail_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "generateThumbnail") {
      val videoPath = call.argument<String>("videoPath")
      val thumbnailPath = call.argument<String>("thumbnailPath")
      val type = call.argument<String>("type") // image or gif
      val format = call.argument<String>("format") // jpg, png, or webp
      if (videoPath != null && thumbnailPath != null && type != null  && format != null) {
        if (type == "image") {
          result.success(generateImageThumbnail(videoPath, thumbnailPath, format))
        } else if (type == "gif") {
          result.success(generateGifThumbnail(videoPath, thumbnailPath))
        }
      } else {
        result.error("INVALID_ARGUMENT", "Invalid arguments received", null)
      }
    } else {
      result.notImplemented()
    }
  }

  private fun generateImageThumbnail(videoPath: String, thumbnailPath: String, format: String): String? {
    val retriever = MediaMetadataRetriever()
    return try {
      retriever.setDataSource(videoPath)
      val bitmap = retriever.getFrameAtTime(1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
      if (bitmap == null) {
        null
      }
      val fileOutputStream = FileOutputStream(thumbnailPath)
      val compressFormat = when (format.lowercase()) {
        "png" -> Bitmap.CompressFormat.PNG
        "webp" -> Bitmap.CompressFormat.WEBP
        else -> Bitmap.CompressFormat.JPEG
      }
      bitmap?.compress(compressFormat, 90, fileOutputStream)
      fileOutputStream.flush()
      fileOutputStream.close()
      thumbnailPath
    } catch (e: IOException) {
      e.printStackTrace()
      null
    } finally {
      retriever.release()
    }
  }

  private fun generateGifThumbnail(videoPath: String, thumbnailPath: String): String? {
    val retriever = MediaMetadataRetriever()
    val encoder = AnimatedGifEncoder()
    return try {
      retriever.setDataSource(videoPath)
      val outputStream = FileOutputStream(thumbnailPath)
      encoder.start(outputStream)
      encoder.setRepeat(0)
      encoder.setDelay(100)

      val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
      val frameInterval = 1000L

      var time = 0L
      while (time < duration) {
        val bitmap = retriever.getFrameAtTime(time * 1000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
        if (bitmap != null) {
          val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 320, 240, true)
          encoder.addFrame(scaledBitmap)
        }
        time += frameInterval
      }

      encoder.finish()
      outputStream.close()
      thumbnailPath
    } catch (e: IOException) {
      e.printStackTrace()
      null
    } finally {
      retriever.release()
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivityForConfigChanges() {}
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivity() {}
}
