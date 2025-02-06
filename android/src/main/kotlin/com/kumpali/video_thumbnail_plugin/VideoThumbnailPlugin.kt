package com.kumpali.video_thumbnail_plugin

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import com.bumptech.glide.gifencoder.AnimatedGifEncoder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class VideoThumbnailPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val client by lazy { OkHttpClient() }
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "video_thumbnail_plugin")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        coroutineScope.cancel()
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateImageThumbnail" -> handleImageThumbnail(call, result)
            "generateGifThumbnail" -> handleGifThumbnail(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleImageThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val thumbnailPath = call.argument<String>("thumbnailPath")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val format = call.argument<Int>("format") ?: 0
        val quality = call.argument<Int>("quality") ?: 100

        if (videoPath == null || thumbnailPath == null) {
            result.error("INVALID_ARGUMENT", "Missing required parameters", null)
            return
        }

        coroutineScope.launch {
            val success = withContext(Dispatchers.IO) { 
                generateImageThumbnail(videoPath, thumbnailPath, width, height, format, quality) 
            }
            withContext(Dispatchers.Main) { result.success(success) }
        }
    }

    private fun handleGifThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val thumbnailPath = call.argument<String>("thumbnailPath")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val frameCount = call.argument<Int>("frameCount") ?: 10
        val delay = call.argument<Int>("delay") ?: 100
        val repeat = call.argument<Int>("repeat") ?: 0

        if (videoPath == null || thumbnailPath == null) {
            result.error("INVALID_ARGUMENT", "Missing required parameters", null)
            return
        }

        coroutineScope.launch {
            val success = withContext(Dispatchers.IO) { 
                generateGifThumbnail(videoPath, thumbnailPath, width, height, frameCount, delay, repeat) 
            }
            withContext(Dispatchers.Main) { result.success(success) }
        }
    }

    private fun generateImageThumbnail(
        videoPath: String, thumbnailPath: String, width: Int?, height: Int?, format: Int, quality: Int
    ): Boolean {
        return executor.submit<Boolean> {
            val retriever = MediaMetadataRetriever()
            try {
                setDataSource(retriever, videoPath)
                var bitmap = retriever.getFrameAtTime(1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC) ?: return@submit false
                bitmap = resizeBitmap(bitmap, width, height)
                saveBitmap(bitmap, thumbnailPath, format, quality)
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            } finally {
                retriever.release()
            }
        }.get()
    }

    private fun generateGifThumbnail(
        videoPath: String, thumbnailPath: String, width: Int?, height: Int?, frameCount: Int, delay: Int, repeat: Int
    ): Boolean {
        return executor.submit<Boolean> {
            val retriever = MediaMetadataRetriever()
            val encoder = AnimatedGifEncoder()
            try {
                setDataSource(retriever, videoPath)
                FileOutputStream(thumbnailPath).use { outputStream ->
                    encoder.start(outputStream)
                    encoder.setRepeat(repeat)
                    encoder.setDelay(delay)
                    val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
                    val frameInterval = duration / frameCount

                    for (i in 0 until frameCount) {
                        val time = i * frameInterval * 1000
                        retriever.getFrameAtTime(time, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)?.let {
                            encoder.addFrame(resizeBitmap(it, width, height))
                        }
                    }

                    encoder.finish()
                }
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            } finally {
                retriever.release()
            }
        }.get()
    }

    private fun getAssetFilePath(assetPath: String): String {
        val file = File(context.cacheDir, assetPath)
        if (!file.exists()) {
            context.assets.open(assetPath).use { inputStream ->
                FileOutputStream(file).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
        }
        return file.absolutePath
    }
    private fun setDataSource(retriever: MediaMetadataRetriever, videoPath: String) {
        when {
            videoPath.startsWith("http") -> {
                val tempFile = downloadVideo(videoPath)
                retriever.setDataSource(tempFile.absolutePath)
                tempFile.deleteOnExit()
            }
            videoPath.startsWith("assets/") -> {
                val assetFilePath = getAssetFilePath(videoPath.removePrefix("assets/"))
                retriever.setDataSource(assetFilePath)
            }
            else -> retriever.setDataSource(videoPath)
        }
    }

    private fun downloadVideo(url: String): File {
        val request = Request.Builder().url(url).build()
        val response = client.newCall(request).execute()
        val tempFile = File.createTempFile("temp_video", ".mp4", context.cacheDir)
        response.body.byteStream().use { input -> tempFile.outputStream().use { output -> input.copyTo(output) } }
        return tempFile
    }

    private fun resizeBitmap(bitmap: Bitmap, width: Int?, height: Int?): Bitmap {
        return when {
            width != null && height != null -> Bitmap.createScaledBitmap(bitmap, width, height, true)
            width != null -> Bitmap.createScaledBitmap(bitmap, width, (width * bitmap.height / bitmap.width), true)
            height != null -> Bitmap.createScaledBitmap(bitmap, (height * bitmap.width / bitmap.height), height, true)
            else -> bitmap
        }
    }

    private fun saveBitmap(bitmap: Bitmap, path: String, format: Int, quality: Int): Boolean {
        val outputStream = FileOutputStream(path)
        val compressFormat = when (format) {
            0 -> Bitmap.CompressFormat.PNG
            2 -> Bitmap.CompressFormat.WEBP
            else -> Bitmap.CompressFormat.JPEG
        }
        val result = bitmap.compress(compressFormat, quality, outputStream)
        outputStream.close()
        return result
    }
}

