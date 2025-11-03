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
    
    [Header("TTS Components")]
    public UnityTTSStream ttsStream;
    public UnityTTSAdvancedStream ttsAdvancedStream;
    
    private string[] availableVoices = {
        "zh-CN-XiaoxiaoNeural",
        "zh-CN-YunxiNeural",
        "en-US-JennyNeural",
        "en-US-GuyNeural",
        "ja-JP-NanamiNeural",
        "ko-KR-SunHiNeural"
    };
    
    void Start()
    {
        SetupUI();
        UpdateStatus("Ready to convert text to speech");
    }
    
    private void SetupUI()
    {
        // Setup button listeners
        playButton.onClick.AddListener(OnPlayButtonClicked);
        stopButton.onClick.AddListener(OnStopButtonClicked);
        
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
        ttsStream.StartTTSStreaming();
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
            statusText.text = message;
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