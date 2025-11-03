using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Unity script for streaming TTS from EasyVoice service
/// </summary>
public class UnityTTSStream : MonoBehaviour
{
    [Header("Service Configuration")]
    public string ttsServiceUrl = "http://localhost:3000/api/v1/tts"; // Base URL of EasyVoice service
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
    
    /// <summary>
    /// Start streaming TTS from the service
    /// </summary>
    public void StartTTSStreaming()
    {
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
        if (audioSource.isPlaying)
        {
            audioSource.Stop();
        }
    }
    
    /// <summary>
    /// Coroutine to handle TTS streaming
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
            format = "wav" // 明确指定请求WAV格式
        };
        
        string jsonData = JsonUtility.ToJson(requestData);
        byte[] postData = System.Text.Encoding.UTF8.GetBytes(jsonData);
        
        string streamUrl = ttsServiceUrl + "/createStream";
        Debug.Log("Requesting TTS audio from URL: " + streamUrl);
        
        // First, get the audio data
        using (UnityWebRequest request = new UnityWebRequest(streamUrl, "POST"))
        {
            request.uploadHandler = new UploadHandlerRaw(postData);
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");
            request.timeout = 300; // 5 minutes timeout
            
            Debug.Log("Starting TTS stream request...");
            
            // Send the request
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();
            
            // Wait for the request to complete or for headers to be received
            while (!operation.isDone && request.downloadedBytes < 1024)
            {
                yield return null;
            }
            
            // Log response headers
            Debug.Log("Response headers:");
            Dictionary<string, string> responseHeaders = request.GetResponseHeaders();
            if (responseHeaders != null)
            {
                foreach (var header in responseHeaders.Keys)
                {
                    Debug.Log("  " + header + ": " + request.GetResponseHeader(header));
                }
            }
            else
            {
                Debug.Log("  No response headers available");
            }
            
            // Check for errors
            // 使用兼容性检查方式替代 request.result
#if UNITY_2020_1_OR_NEWER
            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("TTS Stream Error: " + request.error);
                isPlaying = false;
                yield break;
            }
#else
            if (request.isHttpError || request.isNetworkError)
            {
                Debug.LogError("TTS Stream Error: " + request.error);
                isPlaying = false;
                yield break;
            }
#endif
            
            Debug.Log("TTS stream started successfully. Response code: " + request.responseCode);
            
            // Wait for the audio clip to be ready
            while (!operation.isDone)
            {
                yield return null;
            }
            
            // Check if we still have a valid request
            // 使用兼容性检查方式替代 request.result
#if UNITY_2020_1_OR_NEWER
            if (request.result == UnityWebRequest.Result.Success)
#else
            if (!request.isHttpError && !request.isNetworkError)
#endif
            {
                // 获取音频数据
                byte[] audioData = request.downloadHandler.data;
                Debug.Log("Received audio data with length: " + (audioData != null ? audioData.Length : 0) + " bytes");
                Debug.Log("Content-Type header: " + request.GetResponseHeader("Content-Type"));
                
                // 检查是否返回了错误信息而不是音频数据
                if (audioData != null && audioData.Length > 0)
                {
                    // 尝试将前100个字节解析为文本，检查是否是错误消息
                    try
                    {
                        int checkLength = Math.Min(100, audioData.Length);
                        string textCheck = System.Text.Encoding.UTF8.GetString(audioData, 0, checkLength);
                        if (textCheck.Contains("error") || textCheck.Contains("Error") || textCheck.Contains("ERROR") ||
                            textCheck.Contains("exception") || textCheck.Contains("Exception") || textCheck.Contains("EXCEPTION") ||
                            textCheck.Contains("<html") || textCheck.Contains("<!DOCTYPE") || textCheck.Contains("404") ||
                            textCheck.Contains("500") || textCheck.Contains("Not Found"))
                        {
                            Debug.LogError("Server may have returned an error page instead of audio data. First 100 chars: " + textCheck);
                            Debug.LogError("Full response headers:");
                            Dictionary<string, string> headers = request.GetResponseHeaders();
                            if (headers != null)
                            {
                                foreach (string key in headers.Keys)
                                {
                                    Debug.LogError("  " + key + ": " + headers[key]);
                                }
                            }
                            isPlaying = false;
                            yield break;
                        }
                    }
                    catch (Exception e)
                    {
                        // 忽略解析错误，继续处理
                        Debug.Log("Could not parse response as text: " + e.Message);
                    }
                }
                
                // 增强的空数据检查：确保数据不为空且长度大于0
                if (audioData == null || audioData.Length == 0)
                {
                    Debug.LogError("Received empty or null audio data from server");
                    isPlaying = false;
                    yield break;
                }
                
                // 显示前几个字节以便识别格式
                string firstBytesString = "";
                string firstBytesHex = "";
                int bytesToShow = Math.Min(32, audioData.Length);
                for (int i = 0; i < bytesToShow; i++)
                {
                    // 只显示可打印字符
                    if (audioData[i] >= 32 && audioData[i] <= 126)
                    {
                        firstBytesString += (char)audioData[i];
                    }
                    else
                    {
                        firstBytesString += ".";
                    }
                    firstBytesHex += audioData[i].ToString("X2") + " ";
                }
                Debug.Log("First " + bytesToShow + " bytes as string: " + firstBytesString);
                Debug.Log("First " + bytesToShow + " bytes as hex: " + firstBytesHex);
                
                // 自动检测音频类型
                AudioType detectedAudioType = DetectAudioType(audioData);
                string fileExtension = detectedAudioType == AudioType.WAV ? ".wav" : ".mp3";
                Debug.Log("Detected audio type: " + detectedAudioType + " with extension: " + fileExtension);
                
                // 如果我们强制使用WAV但检测到的不是WAV，记录警告
                if (forceWavFormat && detectedAudioType != AudioType.WAV) {
                    Debug.LogWarning("Server audio data appears to be " + (detectedAudioType == AudioType.MPEG ? "MP3" : "non-WAV") + 
                                   " format, but forcing WAV processing as configured");
                }
                
                // 尝试多种方法加载音频
                AudioClip clip = null;
                string tempFileName = "temp_tts_audio" + (forceWavFormat ? ".wav" : fileExtension); // 根据配置使用正确的扩展名
                string tempFilePath = Path.Combine(Application.temporaryCachePath, tempFileName);
                File.WriteAllBytes(tempFilePath, audioData);
                
                Debug.Log("Saved audio data to temporary file: " + tempFilePath);
                Debug.Log("File exists: " + File.Exists(tempFilePath) + ", File size: " + 
                         (File.Exists(tempFilePath) ? new FileInfo(tempFilePath).Length : 0) + " bytes");
                
                // 尝试使用不同的音频类型加载
                AudioType[] audioTypesToTry = forceWavFormat ? new AudioType[] { AudioType.WAV } : new AudioType[] { AudioType.WAV, AudioType.MPEG };
                string[] extensionsToTry = forceWavFormat ? new string[] { ".wav" } : new string[] { ".wav", ".mp3" };
                
                for (int i = 0; i < audioTypesToTry.Length; i++)
                {
                    if (clip != null) break; // 如果已经成功加载，跳出循环
                    
                    AudioType typeToTry = audioTypesToTry[i];
                    string extensionToTry = extensionsToTry[i];
                    
                    // 如果不是默认文件名，重命名文件
                    if (extensionToTry != (forceWavFormat ? ".wav" : fileExtension))
                    {
                        string newFilePath = Path.Combine(Application.temporaryCachePath, "temp_tts_audio" + extensionToTry);
                        try
                        {
                            File.Copy(tempFilePath, newFilePath, true);
                            tempFilePath = newFilePath;
                        }
                        catch (Exception e)
                        {
                            Debug.LogWarning("Failed to rename file to " + extensionToTry + ": " + e.Message);
                            continue;
                        }
                    }
                    
                    // 尝试使用UnityWebRequestMultimedia加载
                    using (UnityWebRequest audioRequest = UnityWebRequestMultimedia.GetAudioClip("file:///" + tempFilePath.Replace("\\", "/"), typeToTry))
                    {
                        Debug.Log("Attempting to load audio clip using UnityWebRequestMultimedia with type: " + typeToTry);
                        yield return audioRequest.SendWebRequest();
                        
#if UNITY_2020_1_OR_NEWER
                        if (audioRequest.result == UnityWebRequest.Result.Success)
#else
                        if (!audioRequest.isHttpError && !audioRequest.isNetworkError)
#endif
                        {
                            try
                            {
                                clip = DownloadHandlerAudioClip.GetContent(audioRequest);
                                Debug.Log("UnityWebRequestMultimedia with " + typeToTry + " - AudioClip loaded: " + (clip != null));
                                if (clip != null) {
                                    Debug.Log("Clip length: " + clip.length + " seconds, Samples: " + clip.samples + ", Channels: " + clip.channels + ", Frequency: " + clip.frequency);
                                    if (clip.length <= 0 || clip.samples <= 0)
                                    {
                                        Debug.LogWarning("Loaded clip has invalid properties, trying next format");
                                        clip = null;
                                    }
                                } else {
                                    Debug.LogError("Clip is null after UnityWebRequestMultimedia with " + typeToTry);
                                }
                            }
                            catch (Exception e)
                            {
                                Debug.LogWarning("Exception when getting content with " + typeToTry + ": " + e.Message);
                                clip = null;
                            }
                        }
                        else
                        {
                            Debug.LogWarning("UnityWebRequestMultimedia with " + typeToTry + " failed: " + audioRequest.error);
                        }
                    }
                }
                
                // 如果所有UnityWebRequestMultimedia方法都失败，尝试使用WWW类（兼容性更好）
                if (clip == null)
                {
                    Debug.Log("All UnityWebRequestMultimedia methods failed, trying fallback with different formats");
#if !UNITY_2020_1_OR_NEWER
                    // 重新设置到原始文件
                    tempFilePath = Path.Combine(Application.temporaryCachePath, "temp_tts_audio" + (forceWavFormat ? ".wav" : fileExtension));
                    string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                    
                    // 先尝试WAV格式
                    using (WWW www = new WWW(fileUrl))
                    {
                        yield return www;
                            
                        if (string.IsNullOrEmpty(www.error))
                        {
                            clip = www.GetAudioClip(false, false, AudioType.WAV);
                            Debug.Log("WWW - Attempting WAV format - AudioClip loaded: " + (clip != null));
                            if (clip != null) {
                                Debug.Log("Clip length: " + clip.length + " seconds, Samples: " + clip.samples + ", Channels: " + clip.channels + ", Frequency: " + clip.frequency);
                            } else {
                                Debug.LogError("Clip is null after WWW method with WAV");
                            }
                        }
                        else
                        {
                            Debug.LogWarning("WWW method failed with WAV: " + www.error);
                        }
                    }
                    
                    // 如果WAV失败，尝试MP3格式
                    if (clip == null && !forceWavFormat)
                    {
                        string mp3FilePath = Path.Combine(Application.temporaryCachePath, "temp_tts_audio.mp3");
                        if (File.Exists(mp3FilePath))
                        {
                            string mp3Url = "file:///" + mp3FilePath.Replace("\\", "/");
                            using (WWW www = new WWW(mp3Url))
                            {
                                yield return www;
                                    
                                if (string.IsNullOrEmpty(www.error))
                                {
                                    clip = www.GetAudioClip(false, false, AudioType.MPEG);
                                    Debug.Log("WWW - Attempting MP3 format - AudioClip loaded: " + (clip != null));
                                    if (clip != null) {
                                        Debug.Log("Clip length: " + clip.length + " seconds, Samples: " + clip.samples + ", Channels: " + clip.channels + ", Frequency: " + clip.frequency);
                                    } else {
                                        Debug.LogError("Clip is null after WWW method with MP3");
                                    }
                                }
                                else
                                {
                                    Debug.LogWarning("WWW method failed with MP3: " + www.error);
                                }
                            }
                        }
                    }
#endif
                }
                
                // 不再删除临时文件，保留文件供手动检查
                // 记录文件位置，方便用户检查生成的音频文件
                if (File.Exists(tempFilePath))
                {
                    Debug.Log("Audio file saved for manual inspection at: " + tempFilePath);
                }
                    
                    // 检查是否成功加载音频
                    if (clip != null && clip.samples > 0)
                    {
                        Debug.Log("Audio clip loaded successfully. Duration: " + clip.length + " seconds, Samples: " + clip.samples + ", Channels: " + clip.channels + ", Frequency: " + clip.frequency);
                        
                        // 确保AudioSource存在并且启用
                        if (audioSource == null)
                        {
                            audioSource = gameObject.GetComponent<AudioSource>();
                            if (audioSource == null)
                            {
                                audioSource = gameObject.AddComponent<AudioSource>();
                            }
                        }
                        
                        // 检查GameObject和AudioSource状态
                        Debug.Log("GameObject active in hierarchy: " + gameObject.activeInHierarchy);
                        Debug.Log("AudioSource component: " + (audioSource != null));
                        if (audioSource != null) {
                            Debug.Log("AudioSource enabled: " + audioSource.enabled);
                            Debug.Log("AudioSource mute: " + audioSource.mute);
                            Debug.Log("AudioSource volume: " + audioSource.volume);
                        }
                        
                        // 强制设置AudioSource属性
                        audioSource.playOnAwake = false;
                        audioSource.loop = false;
                        audioSource.mute = false;
                        audioSource.volume = 1.0f;
                        
                        Debug.Log("About to play audio...");
                        
                        // 尝试使用PlayOneShot直接播放（这是最可靠的方法之一）
                        try 
                        {
                            audioSource.PlayOneShot(clip);
                            Debug.Log("AudioSource.PlayOneShot() called. isPlaying: " + audioSource.isPlaying);
                        }
                        catch (Exception e)
                        {
                            Debug.LogError("Exception when calling audioSource.PlayOneShot(): " + e.Message);
                        }
                        
                        // 如果PlayOneShot失败，尝试标准播放方法
                        if (!audioSource.isPlaying)
                        {
                            try
                            {
                                audioSource.clip = clip;
                                audioSource.Play();
                                Debug.Log("AudioSource.Play() called. isPlaying: " + audioSource.isPlaying);
                            }
                            catch (Exception e)
                            {
                                Debug.LogError("Exception when calling audioSource.Play(): " + e.Message);
                            }
                        }
                        
                        // 检查是否开始播放
                        float startTime = Time.time;
                        // 等待一小段时间确保播放状态更新
                        for (int i = 0; i < 10 && !audioSource.isPlaying; i++)
                        {
                            yield return null;
                        }
                        
                        if (audioSource.isPlaying)
                        {
                            Debug.Log("Audio started playing successfully");
                        }
                        else
                        {
                            Debug.LogError("Failed to start audio playback");
                            
                            // 输出更多诊断信息
                            if (audioSource != null && audioSource.clip != null)
                            {
                                Debug.Log("Clip info - length: " + audioSource.clip.length + 
                                         ", samples: " + audioSource.clip.samples + 
                                         ", channels: " + audioSource.clip.channels + 
                                         ", frequency: " + audioSource.clip.frequency);
                            }
                            
                            // 尝试重新创建AudioSource
                            Debug.Log("Recreating AudioSource component...");
                            Destroy(audioSource);
                            audioSource = gameObject.AddComponent<AudioSource>();
                            audioSource.playOnAwake = false;
                            audioSource.volume = 1.0f;
                            
                            try
                            {
                                audioSource.PlayOneShot(clip);
                                Debug.Log("Recreated AudioSource and called PlayOneShot(). isPlaying: " + audioSource.isPlaying);
                            }
                            catch (Exception e)
                            {
                                Debug.LogError("Exception with recreated AudioSource: " + e.Message);
                            }
                        }
                        
                        // Wait for playback to complete
                        if (audioSource.isPlaying)
                        {
                            float timeout = Time.time + clip.length + 1.0f; // 添加1秒的超时时间
                            while (audioSource.isPlaying && isPlaying && Time.time < timeout)
                            {
                                yield return null;
                            }
                            Debug.Log("Audio playback finished or timed out");
                        }
                    }
                    else
                    {
                        Debug.LogError("Failed to create valid audio clip from downloaded data using all available methods");
                    }
            }
            else
            {
                Debug.LogError("TTS Stream Error: " + request.error);
            }
            
            isPlaying = false;
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
    
    
    /// <summary>
    /// 根据文件扩展名和内容自动检测音频类型
    /// </summary>
    /// <param name="audioData">音频数据</param>
    /// <returns>检测到的音频类型</returns>
    private AudioType DetectAudioType(byte[] audioData)
    {
        // 如果强制使用WAV格式，则直接返回WAV
        if (forceWavFormat) {
            Debug.Log("Forcing WAV audio type as per configuration");
            return AudioType.WAV;
        }
        
        if (audioData == null || audioData.Length < 10)
            return AudioType.WAV; // 默认
            
        // 检查WAV文件头
        string header = System.Text.Encoding.UTF8.GetString(audioData, 0, 4);
        if (header == "RIFF")
        {
            string waveHeader = System.Text.Encoding.UTF8.GetString(audioData, 8, 4);
            if (waveHeader == "WAVE")
            {
                Debug.Log("Detected WAV audio type");
                return AudioType.WAV;
            }
            else
            {
                Debug.LogWarning("File has RIFF header but invalid WAVE signature. Actual signature at byte 8: " + waveHeader);
            }
        }
        else
        {
            Debug.LogWarning("File does not have RIFF header. Actual header: " + header);
        }
        
        // 检查MP3文件头
        if (audioData.Length > 3 && audioData[0] == 0x49 && audioData[1] == 0x44 && audioData[2] == 0x33) {
            Debug.Log("Detected MP3 audio type (ID3 tag)");
            return AudioType.MPEG;
        }
        else if (audioData.Length > 2 && audioData[0] == 0xFF && (audioData[1] & 0xE0) == 0xE0) {
            Debug.Log("Detected MP3 audio type (MPEG frame header)");
            return AudioType.MPEG;
        }
        
        // 检查是否是MP3但以其他方式编码
        if (audioData.Length > 2 && audioData[0] == 0xFF && (audioData[1] & 0xF0) == 0xF0) {
            Debug.Log("Detected possible MP3 audio type (alternative MPEG header)");
            return AudioType.MPEG;
        }
        
        // 检查是否是AAC格式
        if (audioData.Length > 8 && audioData[4] == 0x66 && audioData[5] == 0x74 && audioData[6] == 0x79 && audioData[7] == 0x70) {
            Debug.Log("Detected AAC audio type (MP4 container)");
            return AudioType.MPEG; // Unity中AAC使用MPEG类型
        }
        
        // 默认返回设置的类型
        Debug.Log("Could not detect audio type, using configured type: " + AudioType.WAV);
        return AudioType.WAV;
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