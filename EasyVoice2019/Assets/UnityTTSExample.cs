using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Example script showing how to use the TTS streaming in a Unity scene
/// </summary>
public class UnityTTSExample : MonoBehaviour
{
    [Header("UI References")]
    public InputField textInput;
    public Button playButton;
    public Button stopButton;
    public Text statusText;
    public Dropdown voiceDropdown;
    public Slider rateSlider;
    public Slider pitchSlider;
    public Slider volumeSlider;

    public Button localRemoteBtn;
    public Text localRemoteText;
    
    [Header("TTS Components")]
    public UnityTTSStream ttsStream;
    public UnityTTSAdvancedStream ttsAdvancedStream;
    
    private string[] availableVoices = {
        "zh-CN-XiaoxiaoNeural",
        "zh-CN-XiaoyiNeural",
        "zh-CN-YunjianNeural",
        "zh-CN-YunxiNeural",
        "zh-CN-YunxiaNeural",
        "zh-CN-YunyangNeural",
        "zh-CN-liaoning-XiaobeiNeural",
        "zh-CN-shaanxi-XiaoniNeural",
        "zh-HK-HiuGaaiNeural",
        "zh-HK-WanLungNeural",
        "zh-TW-HsiaoChenNeural",
        "zh-TW-YunJheNeural",
    };

    private static bool isLocalURL = true;
    private static string localURL = "http://localhost:3000/api/v1/tts";
    private static string remoteURL = "https://8.131.145.224/api/v1/tts";

    void Start()
    {
        SetupUI();
        UpdateStatus("Ready to convert text to speech");

        UpdateURL();
        
        Debug.Log("TTS Example initialized. Platform: " + Application.platform);
    }

    public static string GetTargetUrl()
    {
        if(isLocalURL)
        {
            return localURL;
        }
        else
        {
            return remoteURL;
        }
    }

    private void UpdateURL()
    {
        if(isLocalURL)
        {
            localRemoteText.text = "Local";
        }
        else
        {
            localRemoteText.text = "Remote";
        }
        // 确保在移动平台上设置正确的URL
#if UNITY_ANDROID || UNITY_IOS
        if (ttsStream != null)
        {
            // 在移动设备上使用HTTPS URL
            ttsStream.ttsServiceUrl = GetTargetUrl();
        }

        if (ttsAdvancedStream != null)
        {
            // 在移动设备上使用HTTPS URL
            ttsAdvancedStream.ttsServiceUrl = GetTargetUrl();
        }
#else
        // 在编辑器中可以使用本地URL进行测试
        if (ttsStream != null && string.IsNullOrEmpty(ttsStream.ttsServiceUrl))
        {
            ttsStream.ttsServiceUrl = GetTargetUrl();
        }
        
        if (ttsAdvancedStream != null && string.IsNullOrEmpty(ttsAdvancedStream.ttsServiceUrl))
        {
            ttsAdvancedStream.ttsServiceUrl = GetTargetUrl();
        }
#endif
    }

    private void SetupUI()
    {
        // Setup button listeners
        playButton.onClick.AddListener(OnPlayButtonClicked);
        stopButton.onClick.AddListener(OnStopButtonClicked);
        localRemoteBtn.onClick.AddListener(OnLocalRemoteBtnClicked);

        // Setup voice dropdown
        List<string> voiceOptions = new List<string>(availableVoices);
        voiceDropdown.ClearOptions();
        voiceDropdown.AddOptions(voiceOptions);
        voiceDropdown.onValueChanged.AddListener(OnVoiceChanged);
        
        // Setup sliders
        rateSlider.onValueChanged.AddListener(OnRateChanged);
        pitchSlider.onValueChanged.AddListener(OnPitchChanged);
        volumeSlider.onValueChanged.AddListener(OnVolumeChanged);
        
        // Set default values
        rateSlider.value = 0f;
        pitchSlider.value = 0f;
        volumeSlider.value = 0f;
    }
    
    private void OnPlayButtonClicked()
    {
        if (string.IsNullOrEmpty(textInput.text))
        {
            UpdateStatus("Please enter some text to convert");
            return;
        }
        
        // Update the TTS component with current settings
        ttsStream.textToConvert = textInput.text;
        UpdateStatus("Converting text to speech...");
        
        // Start streaming
        ttsStream.StartTTSStreaming(UpdateStatus);
    }
    private void OnLocalRemoteBtnClicked()
    {
        isLocalURL = !isLocalURL;
        UpdateURL();
        UpdateStatus("OnLocalRemoteBtnClicked, isLocalURL:" + isLocalURL);
    }


    private void OnStopButtonClicked()
    {
        ttsStream.StopTTSStreaming();
        UpdateStatus("Stopped streaming");
    }
    
    private void OnVoiceChanged(int index)
    {
        ttsStream.voice = availableVoices[index];
        UpdateStatus("Voice changed to: " + availableVoices[index]);
    }
    
    private void OnRateChanged(float value)
    {
        // Convert slider value (-50 to 50) to percentage string
        int percent = Mathf.RoundToInt(value);
        ttsStream.rate = (percent >= 0 ? "+" : "") + percent + "%";
        UpdateStatus("Rate set to: " + ttsStream.rate);
    }
    
    private void OnPitchChanged(float value)
    {
        // Convert slider value (-100 to 100) to Hz string
        int hz = Mathf.RoundToInt(value);
        ttsStream.pitch = (hz >= 0 ? "+" : "") + hz + "Hz";
        UpdateStatus("Pitch set to: " + ttsStream.pitch);
    }
    
    private void OnVolumeChanged(float value)
    {
        // Convert slider value (-50 to 50) to percentage string
        int percent = Mathf.RoundToInt(value);
        ttsStream.volume = (percent >= 0 ? "+" : "") + percent + "%";
        UpdateStatus("Volume set to: " + ttsStream.volume);
    }
    
    private void UpdateStatus(string message)
    {
        if (statusText != null)
        {
            statusText.text += "\n" + message;
        }
    }
    
    // Example of how to use the advanced streaming (true streaming)
    public void StartAdvancedStreaming()
    {
        if (string.IsNullOrEmpty(textInput.text))
        {
            UpdateStatus("Please enter some text to convert");
            return;
        }
        
        // Update the advanced TTS component with current settings
        ttsAdvancedStream.textToConvert = textInput.text;
        UpdateStatus("Converting text to speech with advanced streaming...");
        
        // Start advanced streaming
        ttsAdvancedStream.StartTTSStreaming();
    }
}