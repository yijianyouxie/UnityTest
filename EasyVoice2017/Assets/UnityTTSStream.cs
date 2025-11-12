using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Networking;

#if UNITY_2019_1_OR_NEWER
/// <summary>
/// Custom certificate handler to accept self-signed certificates
/// </summary>
public class CustomCertificateHandler : CertificateHandler
{
    protected override bool ValidateCertificate(byte[] certificateData)
    {
        // In production, you should implement proper certificate validation
        // For self-signed certificates in development, we accept all
        return true;
    }
}
#endif

/// <summary>
/// Custom DownloadHandler that processes audio data chunks as they arrive
/// </summary>
public class DownloadHandlerAudioStream : DownloadHandlerScript
{
    private Action<byte[], int> onAudioDataReceived;
    private List<byte[]> audioChunks = new List<byte[]>();
    private int totalBytesReceived = 0;

    public DownloadHandlerAudioStream(Action<byte[], int> onAudioDataReceived) : base(new byte[1024])
    {
        this.onAudioDataReceived = onAudioDataReceived;
    }

    protected override bool ReceiveData(byte[] data, int dataLength)
    {
        // This method is called as data chunks arrive
        if (data == null || dataLength < 1)
            return false;

        // Store the chunk
        byte[] chunk = new byte[dataLength];
        Array.Copy(data, chunk, dataLength);
        audioChunks.Add(chunk);
        totalBytesReceived += dataLength;

        // Notify that we received data
        if (onAudioDataReceived != null)
        {
            onAudioDataReceived(chunk, dataLength);
        }

        // Return true to continue receiving data
        return true;
    }

    public int GetTotalBytesReceived()
    {
        return totalBytesReceived;
    }

    public List<byte[]> GetAudioChunks()
    {
        return audioChunks;
    }
    
    public int GetChunkCount()
    {
        return audioChunks.Count;
    }
}

/// <summary>
/// Unity script for streaming TTS from EasyVoice service
/// </summary>
public class UnityTTSStream : MonoBehaviour
{
    [Header("Service Configuration")]
    public string ttsServiceUrl = ""; // Base URL of EasyVoice service
    public string voice = "zh-CN-XiaoxiaoNeural"; // Default voice
    public string rate = "+0%"; // Speech rate
    public string volume = "+0%"; // Volume level
    public string pitch = "+0Hz"; // Voice pitch
    
    [Header("Text to Convert")]
    [TextArea(3, 10)]
    public string textToConvert = "这是一个示例文本，用于演示如何在Unity中使用EasyVoice服务进行流式文本转语音播放。";
    
    [Header("Audio Configuration")]
    [Tooltip("Force WAV format processing to match server-generated audio")]
    public bool forceWavFormat = true; // 强制使用WAV格式处理
    
    private AudioSource audioSource;
    private bool isPlaying = false;
    private UnityWebRequest currentRequest;
    private DownloadHandlerAudioStream downloadHandler;

    public delegate void UpdateStatusHandler(string text);
    private UpdateStatusHandler updateStatusHandler;
    
    void Start()
    {
        Debug.Log("Initializing AudioSource...");
        audioSource = gameObject.GetComponent<AudioSource>();
        if (audioSource == null)
        {
            Debug.Log("AudioSource not found, adding component...");
            audioSource = gameObject.AddComponent<AudioSource>();
        }
        audioSource.playOnAwake = false;
        Debug.Log("AudioSource initialized. Volume: " + audioSource.volume + ", Mute: " + audioSource.mute + ", Enabled: " + audioSource.enabled);
        Debug.Log("GameObject name: " + gameObject.name + ", Active: " + gameObject.activeInHierarchy);
        
        // 检查音频系统状态
        CheckAudioSystemStatus();
    }

    private void UpdateStatus(string text)
    {
        if(updateStatusHandler != null)
        {
            updateStatusHandler(text);
        }
    }
    
    /// <summary>
    /// Start streaming TTS from the service
    /// </summary>
    public void StartTTSStreaming(UpdateStatusHandler handler)
    {
        updateStatusHandler = handler;

        // 检查待转换文本是否为空
        if (string.IsNullOrEmpty(textToConvert))
        {
            Debug.LogError("Text to convert is empty!");
            return;
        }

        // 检查是否正在播放
        if (isPlaying)
        {
            Debug.LogWarning("Already playing TTS stream!");
            return;
        }

        // 检查服务URL是否有效
        if (string.IsNullOrEmpty(ttsServiceUrl))
        {
            Debug.LogError("TTS service URL is not configured!");
            return;
        }

        try
        {
            Uri uri = new Uri(ttsServiceUrl);
            if (!uri.IsWellFormedOriginalString())
            {
                Debug.LogError("Invalid TTS service URL format: " + ttsServiceUrl);
                return;
            }
        }
        catch (UriFormatException e)
        {
            Debug.LogError("Invalid TTS service URL: " + e.Message);
            return;
        }

        // 所有检查通过，开始流式TTS
        StartCoroutine(StreamTTS());
    }
    
    /// <summary>
    /// Stop streaming TTS
    /// </summary>
    public void StopTTSStreaming()
    {
        isPlaying = false;
        if (currentRequest != null)
        {
            currentRequest.Abort();
            currentRequest = null;
        }
        if (audioSource != null && audioSource.isPlaying)
        {
            audioSource.Stop();
        }
    }
    
    private void OnAudioDataReceived(byte[] chunk, int dataLength)
    {
        // This will be called as audio data chunks arrive
        // We can process them here if needed
    }
    
    /// <summary>
    /// Force flush file to disk (platform specific)
    /// </summary>
    private void ForceFlushToDisk(FileStream stream)
    {
        try
        {
            stream.Flush();
        }
        catch (Exception e)
        {
            Debug.LogWarning("Could not flush file stream: " + e.Message);
            return;
        }
    }
    
    /// <summary>
    /// Coroutine to handle TTS streaming with real-time playback
    /// </summary>
    private IEnumerator StreamTTS()
    {
        isPlaying = true;
        
        // Prepare the request data
        var requestData = new TTSRequestData
        {
            text = textToConvert,
            voice = voice,
            rate = rate,
            volume = volume,
            pitch = pitch,
            format = "mp3" // Use MP3 for better streaming support
        };
        
        string jsonData = JsonUtility.ToJson(requestData);
        byte[] postData = System.Text.Encoding.UTF8.GetBytes(jsonData);
        
        string streamUrl = ttsServiceUrl + "/createStream";
        Debug.Log("Requesting TTS audio from URL: " + streamUrl);
        
        // Create a streaming request with our custom DownloadHandler
        downloadHandler = new DownloadHandlerAudioStream(OnAudioDataReceived);
        
        using (UnityWebRequest request = new UnityWebRequest(streamUrl, "POST"))
        {
            currentRequest = request;
            
            request.uploadHandler = new UploadHandlerRaw(postData);
            request.downloadHandler = downloadHandler;
            request.SetRequestHeader("Content-Type", "application/json");
            request.timeout = 300; // 5 minutes timeout
            
#if UNITY_2019_1_OR_NEWER
            // Add custom certificate handler for self-signed certificates
            request.certificateHandler = new CustomCertificateHandler();
#endif
            
            Debug.Log("Starting TTS stream request...");
            
            // Send the request
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();
            
            // Variables for streaming
            string tempFilePath = Path.Combine(Application.temporaryCachePath, "tts_stream.mp3");
            // Create file stream for writing
            FileStream fileStream = new FileStream(tempFilePath, FileMode.Create, FileAccess.Write, FileShare.Read);
            bool startedPlayback = false;
            AudioClip clip = null;
            int previousChunkCount = 0;
            long lastFileSize = 0;
            bool fileStreamValid = true;
            
            Debug.Log("Streaming started. Temp file: " + tempFilePath);
            
            // Process data as it arrives without waiting for completion
            while (!operation.isDone || downloadHandler.GetChunkCount() > previousChunkCount)
            {
                // Check for errors - compatible with Unity 2017
#if UNITY_2017_1_OR_NEWER && !UNITY_2020_1_OR_NEWER
                if (request.isHttpError || request.isNetworkError)
                {
                    Debug.LogError("Error: " + request.error);
                    break;
                }
#elif UNITY_2020_1_OR_NEWER
                if (request.result == UnityWebRequest.Result.ConnectionError || 
                    request.result == UnityWebRequest.Result.ProtocolError)
                {
                    Debug.LogError("Error: " + request.error);
                    break;
                }
#else
                // Fallback for older versions
                if (request.isError)
                {
                    Debug.LogError("Error: " + request.error);
                    break;
                }
#endif
                
                // Process newly received data
                int currentChunkCount = downloadHandler.GetChunkCount();
                if (currentChunkCount > previousChunkCount)
                {
                    // Log data received
                    int newChunksReceived = currentChunkCount - previousChunkCount;
                    int totalBytesReceived = downloadHandler.GetTotalBytesReceived();
                    Debug.Log("Received " + newChunksReceived + " new chunks. Total chunks: " + currentChunkCount + ". Total bytes received: " + totalBytesReceived);
                    
                    // Get all chunks
                    List<byte[]> chunks = downloadHandler.GetAudioChunks();
                    
                    // Write only new chunks to file (not all chunks every time)
                    int bytesWritten = 0;
                    for (int i = previousChunkCount; i < currentChunkCount; i++)
                    {
                        byte[] chunk = chunks[i];
                        if (fileStreamValid)
                        {
                            try
                            {
                                fileStream.Write(chunk, 0, chunk.Length);
                                bytesWritten += chunk.Length;
                            }
                            catch (Exception e)
                            {
                                Debug.LogError("Error writing to file: " + e.Message);
                                fileStreamValid = false;
                            }
                        }
                    }
                    
                    // Force immediate write to disk
                    if (fileStreamValid)
                    {
                        try
                        {
                            ForceFlushToDisk(fileStream); // Force write to device
                        }
                        catch (Exception e)
                        {
                            Debug.LogError("Error flushing file: " + e.Message);
                            fileStreamValid = false;
                        }
                    }
                    
                    // Get file size without accessing disposed stream
                    long fileLength = lastFileSize + bytesWritten;
                    lastFileSize = fileLength;
                    Debug.Log("Wrote " + bytesWritten + " bytes to file. File size: " + fileLength + " bytes");
                    
                    // Try to start playback when we have enough data
                    if (!startedPlayback && totalBytesReceived > 5000) // ~10KB
                    {
                        Debug.Log("Starting initial playback with " + totalBytesReceived + " bytes of data" + " " + UnityTTSExample.GetTimestamp());
                        if (fileStreamValid)
                        {
                            try
                            {
                                ForceFlushToDisk(fileStream); // Ensure all data is written
                                fileStream.Close(); // Close for now to allow Unity to read
                                fileStreamValid = false;
                            }
                            catch (Exception e)
                            {
                                Debug.LogError("Error closing file stream: " + e.Message);
                            }
                        }
                        
                        // Try to load and play partial audio
                        string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                        using (UnityWebRequest audioRequest = UnityWebRequestMultimedia.GetAudioClip(fileUrl, AudioType.MPEG))
                        {
                            yield return audioRequest.SendWebRequest();
                            
                            // Check for errors when loading audio - compatible with Unity 2017
#if UNITY_2017_1_OR_NEWER && !UNITY_2020_1_OR_NEWER
                            if (!audioRequest.isHttpError && !audioRequest.isNetworkError)
#elif UNITY_2020_1_OR_NEWER
                            if (audioRequest.result == UnityWebRequest.Result.Success)
#else
                            if (!audioRequest.isError)
#endif
                            {
                                clip = DownloadHandlerAudioClip.GetContent(audioRequest);
                                if (clip != null && clip.length > 0)
                                {
                                    audioSource.clip = clip;
                                    audioSource.Play();
                                    startedPlayback = true;
                                    Debug.Log("Started playing audio with length: " + clip.length + " seconds. File size: " + fileLength + " bytes");
                                }
                                else
                                {
                                    Debug.LogError("Failed to create AudioClip from file or clip length is 0");
                                }
                            }
                            else
                            {
                                Debug.LogError("Failed to load audio clip: " + audioRequest.error);
                            }
                        }
                        
                        // Reopen file for writing
                        try
                        {
                            fileStream = new FileStream(tempFilePath, FileMode.Append, FileAccess.Write, FileShare.Read);
                            fileStreamValid = true;
                            lastFileSize = fileLength; // Reset last file size tracking
                            Debug.Log("Reopened file for writing. File position: " + fileStream.Position);
                        }
                        catch (Exception e)
                        {
                            Debug.LogError("Error reopening file stream: " + e.Message);
                            fileStreamValid = false;
                        }
                    }
                    // If we've already started playback, update the file with new data
                    else if (startedPlayback)
                    {
                        // For continuous playback, we need to reload the audio clip periodically
                        // This is a limitation of Unity's AudioClip system
                        // We'll check if we have a significant amount of new data
                        Debug.Log("Reloading AudioClip with new data. Total bytes: " + totalBytesReceived + " :" + bytesWritten);
                        if (bytesWritten > 10000) // Check more frequently - every ~5KB increment after initial 10KB
                        {
                            if (fileStreamValid)
                            {
                                try
                                {
                                    ForceFlushToDisk(fileStream); // Ensure all data is written
                                    fileStream.Close();
                                    fileStreamValid = false;
                                }
                                catch (Exception e)
                                {
                                    Debug.LogError("Error closing file stream: " + e.Message);
                                }
                            }

                            // Save current playback time
                            float currentTime = audioSource.time;
                            bool wasPlaying = audioSource.isPlaying;
                            Debug.Log("Saving playback state - Time: " + currentTime + ", Was playing: " + wasPlaying + " " + UnityTTSExample.GetTimestamp());
                            
                            // Reload the audio clip to include new data
                            string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                            using (UnityWebRequest audioRequest = UnityWebRequestMultimedia.GetAudioClip(fileUrl, AudioType.MPEG))
                            {
                                yield return audioRequest.SendWebRequest();
                                
#if UNITY_2017_1_OR_NEWER && !UNITY_2020_1_OR_NEWER
                                if (!audioRequest.isHttpError && !audioRequest.isNetworkError)
#elif UNITY_2020_1_OR_NEWER
                                if (audioRequest.result == UnityWebRequest.Result.Success)
#else
                                if (!audioRequest.isError)
#endif
                                {
                                    AudioClip newClip = DownloadHandlerAudioClip.GetContent(audioRequest);
                                    if (newClip != null && newClip.length > 0)
                                    {
                                        // Apply the new clip
                                        audioSource.clip = newClip;
                                        
                                        // Only restore playback position if it's valid for the new clip
                                        if (currentTime < newClip.length)
                                        {
                                            audioSource.time = currentTime;
                                            Debug.Log("Restored playback position to: " + currentTime + " seconds. New clip length: " + newClip.length + " seconds");
                                        }
                                        else
                                        {
                                            // If the position is beyond the new clip length, start from the beginning
                                            audioSource.time = 0;
                                            Debug.Log("Playback position (" + currentTime + ") beyond new clip length (" + newClip.length + "). Reset to 0.");
                                        }
                                        
                                        // If it was playing, continue playing
                                        if (wasPlaying && !audioSource.isPlaying)
                                        {
                                            audioSource.Play();
                                            Debug.Log("Resumed playback after clip reload");
                                        }
                                        Debug.Log("Reloaded audio clip with additional data. New length: " + newClip.length + " seconds");
                                    }
                                    else
                                    {
                                        Debug.LogError("Failed to create new AudioClip from file during reload or clip length is 0");
                                    }
                                }
                                else
                                {
                                    Debug.LogError("Failed to load audio clip during reload: " + audioRequest.error);
                                }
                            }
                            
                            // Reopen file for writing
                            try
                            {
                                fileStream = new FileStream(tempFilePath, FileMode.Append, FileAccess.Write, FileShare.Read);
                                fileStreamValid = true;
                                lastFileSize = fileLength; // Reset last file size tracking
                                Debug.Log("Reopened file for continued writing. File position: " + fileStream.Position);
                            }
                            catch (Exception e)
                            {
                                Debug.LogError("Error reopening file stream: " + e.Message);
                                fileStreamValid = false;
                            }
                        }
                        else
                        {
                            if (fileStreamValid)
                            {
                                try
                                {
                                    ForceFlushToDisk(fileStream); // Force write to device
                                }
                                catch (Exception e)
                                {
                                    Debug.LogError("Error flushing file: " + e.Message);
                                    fileStreamValid = false;
                                }
                            }
                        }
                    }
                    
                    // Update previous chunk count
                    previousChunkCount = currentChunkCount;
                }
                
                yield return null; // Yield control to allow other operations
            }
            
            // Log final status
            Debug.Log("Streaming completed. Final chunk count: " + downloadHandler.GetChunkCount() + 
                     ". Final bytes received: " + downloadHandler.GetTotalBytesReceived());
            
            // Finalize and clean up
            if (fileStreamValid)
            {
                try
                {
                    ForceFlushToDisk(fileStream); // Ensure all data is written
                    fileStream.Close();
                    fileStreamValid = false;
                }
                catch (Exception e)
                {
                    Debug.LogError("Error closing file stream: " + e.Message);
                }
            }
            Debug.Log("File stream closed");
            
            // Wait for playback to finish if it was started
            if (startedPlayback)
            {
                Debug.Log("Waiting for playback to finish");
                while (audioSource.isPlaying)
                {
                    yield return null;
                }
                Debug.Log("Playback finished");
            }
            else if (!startedPlayback && previousChunkCount > 0)
            {
                // If we have data but never started playback, try one final load
                Debug.Log("Playing remaining audio data");
                string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                using (UnityWebRequest audioRequest = UnityWebRequestMultimedia.GetAudioClip(fileUrl, AudioType.MPEG))
                {
                    yield return audioRequest.SendWebRequest();
                    
                    // Check for errors when loading audio - compatible with Unity 2017
#if UNITY_2017_1_OR_NEWER && !UNITY_2020_1_OR_NEWER
                    if (!audioRequest.isHttpError && !audioRequest.isNetworkError)
#elif UNITY_2020_1_OR_NEWER
                    if (audioRequest.result == UnityWebRequest.Result.Success)
#else
                    if (!audioRequest.isError)
#endif
                    {
                        clip = DownloadHandlerAudioClip.GetContent(audioRequest);
                        if (clip != null && clip.length > 0)
                        {
                            audioSource.clip = clip;
                            audioSource.Play();
                            Debug.Log("Played remaining audio with length: " + clip.length + " seconds");
                            
                            // Wait for playback to finish
                            while (audioSource.isPlaying)
                            {
                                yield return null;
                            }
                            Debug.Log("Remaining audio playback finished");
                        }
                        else
                        {
                            Debug.LogError("Failed to create AudioClip from remaining data or clip length is 0");
                        }
                    }
                    else
                    {
                        Debug.LogError("Failed to load remaining audio clip: " + audioRequest.error);
                    }
                }
            }
            else if (!startedPlayback && previousChunkCount == 0)
            {
                Debug.LogError("No audio data received at all");
            }
            
            // Clean up temporary file
            if (File.Exists(tempFilePath))
            {
                try
                {
                    //File.Delete(tempFilePath);
                    Debug.Log("Temporary file deleted");
                }
                catch (Exception e)
                {
                    Debug.LogWarning("Could not delete temporary file: " + e.Message);
                }
            }
            
            isPlaying = false;
            currentRequest = null;
            Debug.Log("Streaming process completed");
        }
    }
    
    /// <summary>
    /// 测试音频播放功能
    /// </summary>
    public void TestAudioPlayback()
    {
        Debug.Log("Testing audio playback...");
        
        // 确保AudioSource存在
        if (audioSource == null)
        {
            audioSource = gameObject.GetComponent<AudioSource>();
            if (audioSource == null)
            {
                audioSource = gameObject.AddComponent<AudioSource>();
            }
        }
        
        // 创建一个简单的测试音调 (1秒的440Hz正弦波)
        int frequency = 44100;
        float time = 1.0f;
        int samples = (int)(frequency * time);
        AudioClip testClip = AudioClip.Create("TestTone", samples, 1, frequency, false);
        
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            // 生成440Hz的正弦波
            data[i] = Mathf.Sin(2 * Mathf.PI * 440 * i / frequency);
        }
        testClip.SetData(data, 0);
        
        // 尝试播放测试音调
        try
        {
            audioSource.clip = testClip;
            audioSource.Play();
            Debug.Log("Test tone played. isPlaying: " + audioSource.isPlaying);
            
            if (!audioSource.isPlaying)
            {
                Debug.LogError("Test tone failed to play");
            }
        }
        catch (Exception e)
        {
            Debug.LogError("Exception playing test tone: " + e.Message);
        }
    }
    
    /// <summary>
    /// 检查音频系统状态
    /// </summary>
    public void CheckAudioSystemStatus()
    {
        Debug.Log("=== Audio System Status ===");
        Debug.Log("AudioListener volume: " + AudioListener.volume);
        Debug.Log("Audio settings - speaker mode: " + AudioSettings.speakerMode);
        Debug.Log("Audio settings - driver caps: " + AudioSettings.driverCapabilities);
        Debug.Log("Audio settings - output sample rate: " + AudioSettings.outputSampleRate);
        
        AudioListener listener = FindObjectOfType<AudioListener>();
        if (listener != null)
        {
            Debug.Log("AudioListener found: " + listener.gameObject.name + ", enabled: " + listener.enabled);
        }
        else
        {
            Debug.LogWarning("No AudioListener found in scene!");
        }
        
        Debug.Log("==========================");
    }
    
    void OnDisable()
    {
        StopTTSStreaming();
    }
}

/// <summary>
/// Data structure for TTS request
/// </summary>
[Serializable]
public class TTSRequestData
{
    public string text;
    public string voice;
    public string rate;
    public string volume;
    public string pitch;
    public string format; // 添加format字段
    public bool useLLM = false;
}