using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace TLStudio
{
    public static class ShaderPropertyToID 
    {
        public static int _Color_ID = Shader.PropertyToID("_Color");

        public static int _DownColor_ID = Shader.PropertyToID("_DownColor");

        public static int _tiling_ID = Shader.PropertyToID("_tiling");

        public static int _CloudDensity_ID = Shader.PropertyToID("_CloudDensity");

        public static int _CloudPower_ID = Shader.PropertyToID("_CloudPower");

        public static int _FogIntensity_ID = Shader.PropertyToID("_FogIntensity");

        public static int _HighOffset_ID = Shader.PropertyToID("_HighOffset");

        public static int _HighScale_ID = Shader.PropertyToID("_HighScale");

        public static int _TintColor_ID = Shader.PropertyToID("_TintColor");

        public static int _Rotation_ID = Shader.PropertyToID("_Rotation");

        public static int _SkyRotation_ID = Shader.PropertyToID("_SkyRotation");

        public static int _Exposure_ID = Shader.PropertyToID("_Exposure");

        public static int _Tint_ID = Shader.PropertyToID("_Tint");

        public static int _Size_ID = Shader.PropertyToID("_Size");

        public static int _WorldLightDir_ID = Shader.PropertyToID("_WorldLightDir");

        public static int _ColorLight_ID = Shader.PropertyToID("_ColorLight");

        public static int _CloudColor_ID = Shader.PropertyToID("_CloudColor");

        public static int _CenterColor_ID = Shader.PropertyToID("_CenterColor");

        public static int _Density_ID = Shader.PropertyToID("_Density");

        public static int _Break_ID = Shader.PropertyToID("_Break");

        public static int _Center_ID = Shader.PropertyToID("_Center");

        public static int _Concentration_ID = Shader.PropertyToID("_Concentration");

        public static int _Speed_ID = Shader.PropertyToID("_Speed");

        public static int _BaseLayerTint_ID = Shader.PropertyToID("_BaseLayerTint");

        public static int _2ndLayerTint_ID = Shader.PropertyToID("_2ndLayerTint");

        public static int _SkySideColor_ID = Shader.PropertyToID("_SkySideColor");

        public static int _MountainsSunShaftsColor_ID = Shader.PropertyToID("_MountainsSunShaftsColor");

        public static int _MountainsSunShaftsSize_ID = Shader.PropertyToID("_MountainsSunShaftsSize");

        public static int _WindParam_ID = Shader.PropertyToID("_WindParam");

        public static int _WindZoneParams_ID = Shader.PropertyToID("_WindZoneParams");

        public static int _WindZoneDir_ID = Shader.PropertyToID("_WindZoneDir");

        public static int _StarStrength_ID = Shader.PropertyToID("_StarStrength");

        public static int fillLightColor_ID = Shader.PropertyToID("fillLightColor");

        public static int TreeAmbientTop_ID = Shader.PropertyToID("TreeAmbientTop");

        public static int TreeAmbientMiddle_ID = Shader.PropertyToID("TreeAmbientMiddle");

        public static int TreeAmbientDown_ID = Shader.PropertyToID("TreeAmbientDown");




        public static int _AOParam_ID = Shader.PropertyToID("_AOParam");

        public static int _ExposureFX_ID = Shader.PropertyToID("_ExposureFX");

        public static int _CharMainLightSpecularDirection_ID = Shader.PropertyToID("_CharMainLightSpecularDirection");

        public static int _AmbientTop_ID = Shader.PropertyToID("_AmbientTop");

        public static int _AmbinetDown_ID = Shader.PropertyToID("_AmbinetDown");

        public static int _CharLightColor_ID = Shader.PropertyToID("_CharLightColor");

        public static int _CharLightDir_ID = Shader.PropertyToID("_CharLightDir");

        public static int _UICharLightColor_ID = Shader.PropertyToID("_UICharLightColor");

        public static int _UICharLightDir_ID = Shader.PropertyToID("_UICharLightDir");

        public static int _CharHairLightColor_ID = Shader.PropertyToID("_CharHairLightColor");

        public static int _UICharHairLightColor_ID = Shader.PropertyToID("_UICharHairLightColor");

        public static int _UICharAmbientTop_ID = Shader.PropertyToID("_UICharAmbientTop");

        public static int _UICharAmbinetDown_ID = Shader.PropertyToID("_UICharAmbinetDown");

        public static int _CharToneMapping_ID = Shader.PropertyToID("_CharToneMapping");

        public static int _CharFillLightColor_ID = Shader.PropertyToID("_CharFillLightColor");

        public static int _CharFillLightDir_ID = Shader.PropertyToID("_CharFillLightDir");

        public static int _UICharFillLightColor_ID = Shader.PropertyToID("_UICharFillLightColor");

        public static int _UICharFillLightDir_ID = Shader.PropertyToID("_UICharFillLightDir");

        public static int _WaterEnvColor_ID = Shader.PropertyToID("_WaterEnvColor");

        public static int _WaterSpecColor_ID = Shader.PropertyToID("_WaterSpecColor");

        public static int _DepthFactor_ID = Shader.PropertyToID("_DepthFactor");

        public static int _GlobalEnvIntensity_ID = Shader.PropertyToID("_GlobalEnvIntensity");

        public static int _SkinProfile_ID = Shader.PropertyToID("_SkinProfile");

        public static int _ShadowAttenFactor_ID = Shader.PropertyToID("_ShadowAttenFactor");

        public static int _SkinShadowColor_ID = Shader.PropertyToID("_SkinShadowColor");

        public static int _GrassShadowAttenFactor_ID = Shader.PropertyToID("_GrassShadowAttenFactor");

        public static int _rainIntensity_ID = Shader.PropertyToID("_rainIntensity");

        public static int _rainSmoothness_ID = Shader.PropertyToID("_rainSmoothness");

        public static int _CharRainSmoothness_ID = Shader.PropertyToID("_CharRainSmoothness");

        public static int _flowRate_ID = Shader.PropertyToID("_flowRate");

        public static int _rainTiling_ID = Shader.PropertyToID("_rainTiling");

        public static int _rainRipple_ID = Shader.PropertyToID("_rainRipple");

        public static int _rippleConfig_ID = Shader.PropertyToID("_rippleConfig");

        public static int _snowCameraSet_ID = Shader.PropertyToID("_snowCameraSet");      

        public static int _SnowTexConfig_ID = Shader.PropertyToID("_SnowTexConfig");

        public static int _SnowDepth_ID = Shader.PropertyToID("_SnowDepth");

        public static int _SkinRaindrop_ID = Shader.PropertyToID("_SkinRaindrop");

        public static int _SnowColor_ID = Shader.PropertyToID("_SnowColor"); 

        public static int _SnowHeight_ID = Shader.PropertyToID("_SnowHeight"); 

        public static int _snowCoverage_ID = Shader.PropertyToID("_snowCoverage");

        public static int _SnowNoise_ID = Shader.PropertyToID("_SnowNoise");

        public static int _SnowTerrainConfigA_ID = Shader.PropertyToID("_SnowTerrainConfigA");

        public static int _SnowTerrainConfigB_ID = Shader.PropertyToID("_SnowTerrainConfigB");

        public static int _GrassSnowColor_ID = Shader.PropertyToID("_GrassSnowColor");

        public static int _GrassSnowDarkFaceColor_ID = Shader.PropertyToID("_GrassSnowDarkFaceColor");

        public static int _LightAttenPhoto_ID = Shader.PropertyToID("_LightAttenPhoto");

        public static int _LightAttenParams_ID = Shader.PropertyToID("_LightAttenParams");

        public static int _LightMapPhoto_ID = Shader.PropertyToID("_LightMapPhoto");

        public static int _EmissionIntensityMax_ID = Shader.PropertyToID("_EmissionIntensityMax");

        public static int _UnlitGlobalLightColor_ID = Shader.PropertyToID("_UnlitGlobalLightColor");

        public static int _GlobalLeafAOIntensity_ID = Shader.PropertyToID("_GlobalLeafAOIntensity");

        public static int _HLODlightIntensity_ID = Shader.PropertyToID("_HLODlightIntensity");

        public static int _MainLightSpecularIntensity_ID = Shader.PropertyToID("_MainLightSpecularIntensity");

        public static int _MainLightDiffuseAO_ID = Shader.PropertyToID("_MainLightDiffuseAO");

        public static int _MainLightSpecularDirection_ID = Shader.PropertyToID("_MainLightSpecularDirection");

        public static int _GrassNoise_ID = Shader.PropertyToID("_GrassNoise");

        public static int _GrassWindControl_ID = Shader.PropertyToID("_GrassWindControl");

        public static int InvVPMatrix_ViewDir_ID = Shader.PropertyToID("InvVPMatrix_ViewDir");

        public static int VPosToLastScreenMatrix_ID = Shader.PropertyToID("VPosToLastScreenMatrix");

        public static int SampleCount_ID = Shader.PropertyToID("SampleCount");

        public static int MainLightColor_ID = Shader.PropertyToID("MainLightColor");

        public static int MainLightDirection_ID = Shader.PropertyToID("MainLightDirection");

        public static int BaseTilling_ID = Shader.PropertyToID("BaseTilling");

        public static int Density_ID = Shader.PropertyToID("Density");

        public static int SoftEdge_ID = Shader.PropertyToID("SoftEdge");

        public static int mainLightIntensity_ID = Shader.PropertyToID("mainLightIntensity");

        public static int glossIntensity_ID = Shader.PropertyToID("glossIntensity");

        public static int HGParameter_ID = Shader.PropertyToID("HGParameter");

        public static int CloudColor_ID = Shader.PropertyToID("CloudColor");

        public static int NoiseTilling_ID = Shader.PropertyToID("NoiseTilling");

        public static int NoiseIntensity_ID = Shader.PropertyToID("NoiseIntensity");

        public static int Speed_ID = Shader.PropertyToID("Speed");

        public static int Radius_ID = Shader.PropertyToID("Radius");

        public static int AtmosphereColor_ID = Shader.PropertyToID("AtmosphereColor");

        public static int AtmosphereColorSaturateDistance_ID = Shader.PropertyToID("AtmosphereColorSaturateDistance");

        public static int Condition_ID = Shader.PropertyToID("Condition");
    }

}

