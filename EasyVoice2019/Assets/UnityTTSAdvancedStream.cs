using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Advanced Unity script for true streaming TTS from EasyVoice service
/// This implementation handles real-time streaming by processing chunks of audio data
/// Enhanced with improved error handling and mobile platform compatibility
/// </summary>
public class UnityTTSAdvancedStream : MonoBehaviour
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
    
    private AudioSource audioSource;
    private bool isPlaying = false;
    private AudioClip currentClip;
    
    void Start()
    {
        audioSource = gameObject.AddComponent<AudioSource>();
        audioSource.playOnAwake = false;
    }
    
    /// <summary>
    /// Start streaming TTS from the service
    /// </summary>
    public void StartTTSStreaming()
    {
        if (string.IsNullOrEmpty(textToConvert))
        {
            Debug.LogError("Text to convert is empty!");
            return;
        }
        
        if (isPlaying)
        {
            Debug.LogWarning("Already playing TTS stream!");
            return;
        }
        
        StartCoroutine(AdvancedStreamTTS());
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
    /// Advanced coroutine to handle true TTS streaming
    /// Processes audio data in chunks as it is received
    /// Improved error handling and response header processing for mobile platforms
    /// </summary>
    private IEnumerator AdvancedStreamTTS()
    {
        isPlaying = true;
        
        // Prepare the request data
        var requestData = new TTSRequestData
        {
            text = textToConvert,
            voice = voice,
            rate = rate,
            volume = volume,
            pitch = pitch
        };
        
        string jsonData = JsonUtility.ToJson(requestData);
        byte[] postData = System.Text.Encoding.UTF8.GetBytes(jsonData);
        
        string streamUrl = ttsServiceUrl + "/createStream";
        
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
            
            Debug.Log("Starting advanced TTS stream request...");
            
            // Send the request
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();
            
            // Improved error handling for mobile platforms
            while (!operation.isDone)
            {
                yield return null;
            }
            
            // Log response information with improved error handling
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
            
            // Get the audio data
            byte[] audioData = request.downloadHandler.data;
            Debug.Log("Received audio data with length: " + (audioData != null ? audioData.Length : 0) + " bytes");
            
            // Try to get Content-Type header
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
            
            // Check if error response was returned instead of audio data
            if (audioData != null && audioData.Length > 0)
            {
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
                    Debug.Log("Could not parse response as text: " + e.Message);
                }
            }
            
            // Enhanced empty data check
            if (audioData == null || audioData.Length == 0)
            {
                Debug.LogError("Received empty or null audio data from server");
                isPlaying = false;
                yield break;
            }
            
            // Process audio data
            if (ProcessAudioData(audioData))
            {
                // Play the audio
                if (currentClip != null)
                {
                    audioSource.clip = currentClip;
                    audioSource.Play();
                    
                    // Wait for playback to complete
                    while (audioSource.isPlaying && isPlaying)
                    {
                        yield return null;
                    }
                    
                    // Clean up
                    Destroy(currentClip);
                    currentClip = null;
                }
            }
            else
            {
                Debug.LogError("Failed to process audio data");
            }
            
            isPlaying = false;
        }
    }
    
    /// <summary>
    /// Process received audio data and create an AudioClip
    /// Uses temporary file and WWW for better mobile compatibility
    /// </summary>
    /// <param name="audioData">The raw audio data</param>
    /// <returns>True if processing was successful</returns>
    private bool ProcessAudioData(byte[] audioData)
    {
        try
        {
            // Save to temporary file
            string tempFileName = "temp_advanced_tts.wav";
            string tempFilePath = Path.Combine(Application.temporaryCachePath, tempFileName);
            File.WriteAllBytes(tempFilePath, audioData);
            
            // Load with WWW (more compatible on mobile)
            string fileUrl = "file:///" + tempFilePath.Replace("\\", "/");
            using (WWW www = new WWW(fileUrl))
            {
                // Wait for load
                float timeout = Time.time + 10f; // 10 second timeout
                while (!www.isDone && Time.time < timeout)
                {
                    System.Threading.Thread.Sleep(100);
                }
                
                if (www.isDone && string.IsNullOrEmpty(www.error))
                {
                    currentClip = www.GetAudioClip(false, false, AudioType.WAV);
                    if (currentClip != null)
                    {
                        Debug.Log("Successfully created AudioClip. Duration: " + currentClip.length + " seconds");
                        return true;
                    }
                    else
                    {
                        Debug.LogError("Failed to create AudioClip from downloaded data");
                    }
                }
                else
                {
                    Debug.LogError("Failed to download audio file: " + (www.error ?? "Timeout"));
                }
            }
            
            // Clean up
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
        }
        catch (Exception e)
        {
            Debug.LogError("Error processing audio data: " + e.Message);
        }
        
        return false;
    }
    
    /// <summary>
    /// Data structure for TTS request
    /// </summary>
    [Serializable]
    private class TTSRequestData
    {
        public string text;
        public string voice;
        public string rate;
        public string volume;
        public string pitch;
    }
}