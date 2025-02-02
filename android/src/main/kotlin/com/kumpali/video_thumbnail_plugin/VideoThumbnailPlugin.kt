package com.kumpali.video_thumbnail_plugin

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import com.bumptech.glide.gifencoder.AnimatedGifEncoder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.FileOutputStream
import java.io.IOException

class VideoThumbnailPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "video_thumbnail_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "generateImageThumbnail") {
            val videoPath = call.argument<String>("videoPath")
            val thumbnailPath = call.argument<String>("thumbnailPath")
            val width = call.argument<Int?>("width")
            val height = call.argument<Int?>("height")
            if (videoPath != null && thumbnailPath != null) {
                val format = call.argument<Int>("format")
                val quality = call.argument<Int?>("quality") // jpg, png, or webp
                result.success(
                    generateImageThumbnail(
                        videoPath,
                        thumbnailPath,
                        width,
                        height,
                        format ?:0,
                        quality ?:100
                    )
                )
            } else {
                result.error("INVALID_ARGUMENT", "Invalid arguments received", null)
            }
        } else if (call.method == "generateGifThumbnail") {
            val videoPath = call.argument<String>("videoPath")
            val thumbnailPath = call.argument<String>("thumbnailPath")
            if (videoPath != null && thumbnailPath != null) {
                val width = call.argument<Int?>("width")
                val height = call.argument<Int?>("height")
                val frameCount = call.argument<Int?>("frameCount") ?: 10 // Default frame count is 10
                val delay = call.argument<Int?>("delay") ?: 100 // Default delay is 100
                val repeat = call.argument<Int?>("repeat") ?: 0 // Default repeat is 0
                val multiProcess = call.argument<Boolean>("multiProcess")
                if (multiProcess == true) {
                    GlobalScope.launch(Dispatchers.Main) {
                        val gifPath = withContext(Dispatchers.IO) {
                            generateGifThumbnailMultiProcess(
                                videoPath,
                                thumbnailPath,
                                width,
                                height,
                                frameCount,
                                delay,
                                repeat
                            )
                        }
                        result.success(gifPath)
                    }
                } else {
                    result.success(
                        generateGifThumbnail(
                            videoPath,
                            thumbnailPath,
                            width,
                            height,
                            frameCount,
                            delay,
                            repeat
                        )
                    )
                }
            } else {
                result.error("INVALID_ARGUMENT", "Invalid arguments received", null)
            }
        } else {
            result.notImplemented()
        }
    }

    private fun generateImageThumbnail(
        videoPath: String,
        thumbnailPath: String,
        width: Int?,
        height: Int?,
        format: Int,
        quality: Int
    ): String? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)
            var bitmap =
                retriever.getFrameAtTime(1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            if (bitmap != null) {
                if (width != null && height != null) {
                    bitmap = Bitmap.createScaledBitmap(bitmap, width, height, true)
                } else if (width != null) {
                    val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                    val newHeight = (width / aspectRatio).toInt()
                    bitmap = Bitmap.createScaledBitmap(bitmap, width, newHeight, true)
                } else if (height != null) {
                    val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                    val newWidth = (height * aspectRatio).toInt()
                    bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, height, true)
                }
                val fileOutputStream = FileOutputStream(thumbnailPath)
                val compressFormat = when (format) {
                    0 -> Bitmap.CompressFormat.PNG
                    2 -> Bitmap.CompressFormat.WEBP
                    else -> Bitmap.CompressFormat.JPEG
                }
                if (quality in 1..100) {
                    bitmap.compress(compressFormat, quality, fileOutputStream)
                } else {
                    bitmap.compress(compressFormat, 100, fileOutputStream)
                }
                fileOutputStream.flush()
                fileOutputStream.close()
                thumbnailPath
            } else {
                null
            }
        } catch (e: IOException) {
            e.printStackTrace()
            null
        } finally {
            retriever.release()
        }
    }

    private fun generateGifThumbnailMultiProcess(
        videoPath: String,
        thumbnailPath: String,
        width: Int? = null,
        height: Int? = null,
        frameCount: Int,
        delay: Int,
        repeat: Int
    ): String? {
        val retriever = MediaMetadataRetriever()
        val encoder = AnimatedGifEncoder()
        return try {
            retriever.setDataSource(videoPath)
            val outputStream = FileOutputStream(thumbnailPath)
            encoder.start(outputStream)
            encoder.setRepeat(repeat)
            encoder.setDelay(delay)

            val duration =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong()
                    ?: 0L
            val frameInterval = duration / frameCount

            runBlocking {
                val jobs = mutableListOf<Job>()
                for (i in 0 until frameCount) {
                    val time = i * frameInterval
                    jobs.add(launch(Dispatchers.Default) {
                        var bitmap = retriever.getFrameAtTime(
                            time * 1000,
                            MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                        )
                        if (bitmap != null) {
                            if (width != null && height != null) {
                                bitmap = Bitmap.createScaledBitmap(bitmap, width, height, true)
                            } else if (width != null) {
                                val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                                val newHeight = (width / aspectRatio).toInt()
                                bitmap = Bitmap.createScaledBitmap(bitmap, width, newHeight, true)
                            } else if (height != null) {
                                val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                                val newWidth = (height * aspectRatio).toInt()
                                bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, height, true)
                            }
                            synchronized(encoder) {
                                encoder.addFrame(bitmap)
                            }
                        }
                    })
                }
                jobs.forEach { it.join() }
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

    private fun generateGifThumbnail(
        videoPath: String,
        thumbnailPath: String,
        width: Int? = null,
        height: Int? = null,
        frameCount: Int,
        delay: Int,
        repeat: Int
    ): String? {
        val retriever = MediaMetadataRetriever()
        val encoder = AnimatedGifEncoder()
        return try {
            retriever.setDataSource(videoPath)
            val outputStream = FileOutputStream(thumbnailPath)
            encoder.start(outputStream)
            encoder.setRepeat(repeat)
            encoder.setDelay(delay)
            val duration =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong()
                    ?: 0L
            val frameInterval = duration / frameCount
            for (i in 0 until frameCount) {
                val time = i * frameInterval
                var bitmap = retriever.getFrameAtTime(
                    time * 1000,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                )
                if (bitmap != null) {
                    if (width != null && height != null) {
                        bitmap = Bitmap.createScaledBitmap(bitmap, width, height, true)
                    } else if (width != null) {
                        val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                        val newHeight =
                            (width / aspectRatio).toInt()
                        bitmap = Bitmap.createScaledBitmap(bitmap, width, newHeight, true)
                    } else if (height != null) {
                        val aspectRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
                        val newWidth =
                            (height * aspectRatio).toInt()
                        bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, height, true)
                    }
                    encoder.addFrame(bitmap)
                }
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
}
