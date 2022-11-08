using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum PainterMode
{
    DetailPaint,
    ChannelPaint,
    FlowMapPaint,
}

public class CYEnginePainterConfig : ScriptableObject
{
    [System.Serializable]
    public class PainterModeConfig
    {
        public string modeName;
        public ChannelConfig[] channelConfig;
        public string paintDestTexName;
        public int paintTexSize = 512;
        public int maxChannelCount = 4;
        public PainterMode paintMode = PainterMode.ChannelPaint;
    }

    [System.Serializable]
    public class ChannelConfig
    {
        public string channelName;
        public string channelMinName;
        public string channelMaxName;
    }

    


    public PainterModeConfig[] config;

}
