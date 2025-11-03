using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Advanced Unity script for true streaming TTS from EasyVoice service
/// This implementation handles real-time streaming by processing chunks of audio data
/// </summary>
public class UnityTTSAdvancedStream : MonoBehaviour
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
    
    private AudioSource audioSource;
    private bool isPlaying = false;
    private AudioClip currentClip;
    private List<float> audioSamples = new List<float>();
    private int sampleRate = 22050; // Default sample rate
    
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
    /// </summary>
    private IEnumerator AdvancedStreamTTS()
    {
        isPlaying = true;
        audioSamples.Clear();
        
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
            
            Debug.Log("Starting advanced TTS stream request...");
            
            // Send the request
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();
            
            // Process data as it comes in
            while (!operation.isDone)
            {
                if (request.downloadHandler.isDone)
                    break;
                
                // Check if we have data to process
                if (request.downloadedBytes > 0)
                {
                    byte[] data = request.downloadHandler.data;
                    if (data != null && data.Length > 0)
                    {
                        // Process the audio data chunk
                        ProcessAudioChunk(data);
                    }
                }
                
                // Check if we should continue playing
                if (!isPlaying)
                {
                    request.Abort();
                    break;
                }
                
                yield return null;
            }
            
            // Process any remaining data
            if (isPlaying && request.downloadHandler.data != null)
            {
                ProcessAudioChunk(request.downloadHandler.data);
            }
            
            // Check for errors
            // 使用兼容性检查方式替代 request.result
#if UNITY_2020_1_OR_NEWER
            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("TTS Stream Error: " + request.error);
            }
#else
            if (request.isHttpError || request.isNetworkError)
            {
                Debug.LogError("TTS Stream Error: " + request.error);
            }
#endif
            else if (isPlaying)
            {
                // Create final audio clip from accumulated samples
                CreateAndPlayAudioClip();
                Debug.Log("TTS streaming completed successfully");
            }
            
            isPlaying = false;
        }
    }
    
    /// <summary>
    /// Process a chunk of audio data
    /// Note: This is a simplified implementation. In a real application,
    /// you would need to decode the audio format (MP3, WAV, etc.) properly.
    /// </summary>
    private void ProcessAudioChunk(byte[] data)
    {
        if (data == null || data.Length == 0)
            return;
        
        Debug.Log("Received audio chunk with " + data.Length + " bytes");
        
        // In a real implementation, you would decode the audio data here
        // For example, using a library like NAudio to decode MP3 to PCM
        // Then convert the PCM data to float samples and add to audioSamples
        
        // This is a placeholder that just adds silence
        // Replace with actual audio decoding
        int samplesToAdd = data.Length / 2; // Simplified calculation
        for (int i = 0; i < samplesToAdd; i++)
        {
            audioSamples.Add(0f); // Add silence instead of actual decoded samples
        }
    }
    
    /// <summary>
    /// Create an AudioClip from accumulated samples and play it
    /// </summary>
    private void CreateAndPlayAudioClip()
    {
        if (audioSamples.Count == 0)
            return;
        
        // Create the audio clip
        currentClip = AudioClip.Create(
            "TTS_Stream", 
            audioSamples.Count, 
            1, 
            sampleRate, 
            false
        );
        
        // Set the data
        currentClip.SetData(audioSamples.ToArray(), 0);
        
        // Play the clip
        audioSource.clip = currentClip;
        audioSource.Play();
        
        Debug.Log("Created audio clip with " + audioSamples.Count + " samples");
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
        public bool useLLM = false;
    }
    
    void OnDisable()
    {
        StopTTSStreaming();
    }
}