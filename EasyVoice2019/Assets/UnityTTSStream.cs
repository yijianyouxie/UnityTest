using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
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
        if(null != updateStatusHandler)
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
            
#if UNITY_2019_1_OR_NEWER
            // Add custom certificate handler for self-signed certificates
            request.certificateHandler = new CustomCertificateHandler();
#endif
            
            Debug.Log("Starting TTS stream request...");
            
            // Send the request
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();

            // Wait for the request to complete or for headers to be received
            while (!operation.isDone && request.downloadedBytes < 1024)
            {
                yield return null;
            }
            
            // Log response headers with improved error handling
            Debug.Log("Response code: " + request.responseCode);
            try 
            {
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
                    Debug.LogWarning("  No response headers available (this may be normal on mobile platforms)");
                }
            }
            catch (Exception e)
            {
                UpdateStatus("Could not retrieve response headers: " + e.Message + " (this may be normal on mobile platforms)");
                Debug.LogWarning("Could not retrieve response headers: " + e.Message + " (this may be normal on mobile platforms)");
            }
            
            // Check for errors with improved mobile compatibility
            bool hasError = false;
            string errorMessage = "";
            
#if UNITY_2020_1_OR_NEWER
            if (request.result != UnityWebRequest.Result.Success)
            {
                hasError = true;
                errorMessage = "TTS Stream Error: " + request.error + " Result:" + request.result;
            }
#else
            if (request.isHttpError || request.isNetworkError)
            {
                hasError = true;
                errorMessage = "TTS Stream Error: " + request.error + " isHttpError:" + request.isHttpError + " isNetworkError:" + request.isNetworkError + " ResponseCode:" + request.responseCode;
            }
#endif
            
            // Additional error checking for mobile platforms
            if (request.responseCode >= 400) 
            {
                hasError = true;
                errorMessage = "HTTP Error " + request.responseCode + ": " + request.error;
            }
            
            // Log detailed error information
            if (hasError) 
            {
                Debug.LogError(errorMessage);
                UpdateStatus(errorMessage);
                Debug.LogError("Request URL: " + streamUrl);
                Debug.LogError("Request timeout: " + request.timeout);
                Debug.LogError("Downloaded bytes: " + request.downloadedBytes);
                
                // Log certificate handler information
#if UNITY_2019_1_OR_NEWER
                if (request.certificateHandler != null) 
                {
                    Debug.LogError("Certificate handler: " + request.certificateHandler.GetType().Name);
                } 
                else 
                {
                    Debug.LogError("No certificate handler");
                }
#else
                Debug.LogError("Certificate handler not supported in this Unity version");
#endif
                
                // Log redirect chain
//#if UNITY_2019_1_OR_NEWER
//                Debug.LogError("Redirect count: " + request.redirectChain.Length);
//#endif
                
                isPlaying = false;
                yield break;
            }

            Debug.Log("TTS stream started successfully. Response code: " + request.responseCode);
            
            // Wait for the audio clip to be ready
            while (!operation.isDone)
            {
                yield return null;
            }
            
            // Final error check
            hasError = false;
#if UNITY_2020_1_OR_NEWER
            if (request.result != UnityWebRequest.Result.Success)
            {
                hasError = true;
                errorMessage = "TTS Stream Error: " + request.error;
            }
#else
            if (request.isHttpError || request.isNetworkError)
            {
                hasError = true;
                errorMessage = "TTS Stream Error: " + request.error;
            }
#endif
            
            if (request.responseCode >= 400) 
            {
                hasError = true;
                errorMessage = "HTTP Error " + request.responseCode + ": " + request.error;
            }
            
            if (hasError)
            {
                Debug.LogError(errorMessage);
                isPlaying = false;
                yield break;
            }
            
            // 获取音频数据
            byte[] audioData = request.downloadHandler.data;
            Debug.Log("Received audio data with length: " + (audioData != null ? audioData.Length : 0) + " bytes");
            
            // 尝试获取Content-Type头部
            string contentType = "";
            try 
            {
                contentType = request.GetResponseHeader("Content-Type");
                Debug.Log("Content-Type header: " + contentType);
            }
            catch (Exception e)
            {
                Debug.LogWarning("Could not get Content-Type header: " + e.Message);
            }
            
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
                        if (File.Exists(newFilePath)) File.Delete(newFilePath);
                        File.Copy(tempFilePath, newFilePath);
                        tempFilePath = newFilePath;
                    }
                    catch (Exception e)
                    {
                        Debug.LogWarning("Could not rename temporary file: " + e.Message);
                        continue;
                    }
                }
                
                // 使用WWW加载音频（在某些平台上更稳定）
                string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                using (WWW www = new WWW(fileUrl))
                {
                    yield return www;
                    
                    if (string.IsNullOrEmpty(www.error))
                    {
                        clip = www.GetAudioClip(false, false, typeToTry);
                        if (clip != null)
                        {
                            Debug.Log("Successfully loaded audio clip with WWW loader, type: " + typeToTry);
                        }
                        else
                        {
                            Debug.LogWarning("WWW loader returned null clip for type: " + typeToTry);
                        }
                    }
                    else
                    {
                        Debug.LogWarning("WWW loader error for type " + typeToTry + ": " + www.error);
                    }
                }
            }
            
            // 如果WWW加载失败，尝试使用UnityWebRequest加载
            if (clip == null)
            {
                Debug.Log("Trying UnityWebRequest to load audio clip...");
                string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
                using (UnityWebRequest audioRequest = UnityWebRequestMultimedia.GetAudioClip(fileUrl, forceWavFormat ? AudioType.WAV : AudioType.MPEG))
                {
                    yield return audioRequest.SendWebRequest();
                    
                    bool requestSuccess = false;
#if UNITY_2020_1_OR_NEWER
                    requestSuccess = (audioRequest.result == UnityWebRequest.Result.Success);
#else
                    requestSuccess = (!audioRequest.isHttpError && !audioRequest.isNetworkError);
#endif
                    
                    if (requestSuccess)
                    {
                        clip = DownloadHandlerAudioClip.GetContent(audioRequest);
                        if (clip != null)
                        {
                            Debug.Log("Successfully loaded audio clip with UnityWebRequest");
                        }
                        else
                        {
                            Debug.LogWarning("UnityWebRequest loader returned null clip");
                        }
                    }
                    else
                    {
                        Debug.LogError("UnityWebRequest loader error: " + audioRequest.error);
                    }
                }
            }

            // 清理临时文件
            try
            {
                if (File.Exists(tempFilePath))
                {
                    File.Delete(tempFilePath);
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning("Could not delete temporary file: " + e.Message);
            }
            
            // 检查是否成功加载音频
            if (clip != null)
            {
                Debug.Log("Audio clip loaded successfully. Duration: " + clip.length + " seconds, Samples: " + clip.samples);
                UpdateStatus("Audio clip loaded successfully. Duration: " + clip.length + " seconds, Samples: " + clip.samples);
                audioSource.clip = clip;
                audioSource.Play();
                
                // Wait for playback to complete
                while (audioSource.isPlaying && isPlaying)
                {
                    yield return null;
                }
                
                // 释放音频资源
                Destroy(clip);
            }
            else
            {
                Debug.LogError("Failed to load audio clip from response data");
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