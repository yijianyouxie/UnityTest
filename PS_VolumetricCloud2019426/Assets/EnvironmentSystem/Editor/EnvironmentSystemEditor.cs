using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace TLStudio
{
    [CustomEditor(typeof(EnvironmentSystem)), CanEditMultipleObjects]
    public class EnvironmentSystemEditor:Editor
    {
        #region NGUI
        //来自NGUI
        public bool DrawHeader(string text, bool isTrue, float offset)
        {
            return DrawHeader(text, text, offset, false, isTrue);
        }
        public bool DrawHeader(string text, string key, float offset, bool forceOn, bool minimalistic)
        {
            bool state = EditorPrefs.GetBool(key, false);

            if (!minimalistic) GUILayout.Space(3f);
            if (!forceOn && !state) GUI.backgroundColor = new Color(0.8f, 0.8f, 0.8f);
            GUILayout.BeginHorizontal();
            GUI.changed = false;

            if (minimalistic)
            {
                if (state) text = "\u25BC" + (char)0x200a + text;
                else text = "\u25BA" + (char)0x200a + text;

                GUILayout.BeginHorizontal();
                GUI.contentColor = EditorGUIUtility.isProSkin ? new Color(1f, 1f, 1f, 0.7f) : new Color(0f, 0f, 0f, 0.7f);
                GUILayout.Label("", GUILayout.Width(offset));
                if (!GUILayout.Toggle(true, text, "PreToolbar2", GUILayout.MinWidth(20f))) state = !state;
                GUI.contentColor = Color.white;
                GUILayout.EndHorizontal();
            }
            else
            {
                text = "<b><size=11>" + text + "</size></b>";
                if (state) text = "\u25BC " + text;
                else text = "\u25BA " + text;
                if (!GUILayout.Toggle(true, text, "dragtab", GUILayout.MinWidth(20f))) state = !state;
            }

            if (GUI.changed) EditorPrefs.SetBool(key, state);

            if (!minimalistic) GUILayout.Space(2f);
            GUILayout.EndHorizontal();
            GUI.backgroundColor = Color.white;
            if (!forceOn && !state) GUILayout.Space(3f);
            return state;
        }

        #endregion

        //https://docs.unity3d.com/Manual/editor-CustomEditors.html
        //支持动画自动K帧
        SerializedProperty FillLightColor, 
            starsStrength, skyHighOffset, skyHighScale,SkyTintColor, SkyRotation, SkyExposure,
            sunColor, sunSize, sunDirection, moonColor, moonSize, moonDirection, shafts, milkywayColor, milkywaySize, milkywayDirection, rainbowIntensity,
            cloudmainlightColor,cloudColor, CloudMainLightDirection, cloudCentColor, cloudDensity, cloudSize, cloudBreak, cloudCener, cloudConcentration, cloudSpeedNSide,
            MountainsBaseLayerColor, Mountains2ndLayerColor, MountainsSideColor, MountainsFogIntensity, MountainsSunShaftsColor, MountainsSunShaftsSize,
            SeaCloudColor, SeaCloudDownColor, SeaCloudTiling, SeaCloudDensity, SeaCloudPower, SeaCloudFogIntensity,
            enableVolumetricCloud,VolumetricCloudGO, VolumetricCloudGOLow, CloudColor, SampleCount, CloudTilling, Radius, CloudHeight, MaxTop, CurrentTop, MaxBottom, CurrentBottom, Speed, Density, MainLightIntensity, glossyIntensity, NoiseTilling, NoiseIntensity, SoftEdge, Border, VolumetricCloudBaseHeight,AtmosphereColorSaturateDistance, AtmosphereColor,
            stormDay, rainIntensity, rainSmoothness, charRainSmoothness, rainflowRate, /*rainNormal,*/ /*rainCharNormal,*/ rainTiling,rainCubemap, rainRipple, rippleConfig,
            snowDay, snowCoverage, snowColor, SnowCameraSet, SnowNoise, SnowDepthTex, SnowTerrainConfigA, SnowTerrainConfigB, SnowHeight,
            globalCubemap,exposureFX, emissionIntensity, mainLightSpecularIntensity, mainLightSpecularDirection, mainLightDiffuseAO, GlobalLightColor, GlobalLeafAOIntensity,GlobalHLODLightIntensity, TreeAmbientTop, TreeAmbientMiddle, TreeAmbientDown,
            waterEnvColor, waterSpecColor, waterDepthFactor,
            springBoneWindMain, springBoneWindPluseMagnitude, springBoneWindPluseFrequency,
            charSkinProfile, MainLight2CharLight,charMainLightDir, charMainLightSpecularDirection,charFillLightDir, charMainLightColor, lightAdditionalRate, charMainLightIntensity, charMainLightIntensityAdditional, charFillLightColor, charFillLightIntensity, charFillLightIntensityAdditional, charAmbientTop, charAmbientDown, charUIAmbientTop, charUIAmbientDown,
            charUIMainLightDir, charUIFillLightDir, charUIMainLightColor, charUIMainLightIntensity, charUIFillLightColor, charUIFillLightIntensity, charToneMapping,
            charGlobalEnvIntensity, charShadowAtten, charShadowColor, LightAttenTex, LightAttenParams, LightMapTex, /*IsShowLightAtten,IsShowLightMap,*/
            grassShadowAtten,GPUInstanceMeshList, GPUInstanceMaterialList, GPUInstanceLod1MeshList, GPUInstanceLod1MaterialList,grassNoise, grassWindControl, grassSnowColor, grassSnowDarkFaceColor,// grassWaveControl,
            InstanceDataFileName, IsDrawGizmo, TerrainAlpha0, TerrainAlpha1, TerrainParams, MaterialTypes, GlobalDynamicPointLightIntensity;

        private void OnEnable()
        {
            FillLightColor               = serializedObject.FindProperty("FillLightColor");
            skyHighOffset                = serializedObject.FindProperty("skyHighOffset");
            skyHighScale                 = serializedObject.FindProperty("skyHighScale");
            SkyTintColor                 = serializedObject.FindProperty("SkyTintColor");
            SkyRotation                  = serializedObject.FindProperty("SkyRotation");
            SkyExposure                  = serializedObject.FindProperty("SkyExposure");
            starsStrength                = serializedObject.FindProperty("starsStrength");
            sunColor                     = serializedObject.FindProperty("sunColor");
            sunSize                      = serializedObject.FindProperty("sunSize");
            sunDirection                 = serializedObject.FindProperty("sunDirection");
            moonColor                    = serializedObject.FindProperty("moonColor");
            moonSize                     = serializedObject.FindProperty("moonSize");
            moonDirection                = serializedObject.FindProperty("moonDirection");
            milkywayColor                = serializedObject.FindProperty("milkywayColor");
            milkywaySize                 = serializedObject.FindProperty("milkywaySize");
            milkywayDirection            = serializedObject.FindProperty("milkywayDirection");
            rainbowIntensity             = serializedObject.FindProperty("rainbowIntensity");
            shafts                       = serializedObject.FindProperty("Shafts");
            cloudColor                   = serializedObject.FindProperty("cloudColor");
            cloudCentColor               = serializedObject.FindProperty("cloudCentColor");
            cloudDensity                 = serializedObject.FindProperty("cloudDensity");
            cloudSize                    = serializedObject.FindProperty("cloudSize");
            cloudBreak                   = serializedObject.FindProperty("cloudBreak");
            cloudCener                   = serializedObject.FindProperty("cloudCener");
            cloudConcentration           = serializedObject.FindProperty("cloudConcentration");
            cloudSpeedNSide              = serializedObject.FindProperty("cloudSpeedNSide");
            MountainsBaseLayerColor      = serializedObject.FindProperty("MountainsBaseLayerColor");
            Mountains2ndLayerColor       = serializedObject.FindProperty("Mountains2ndLayerColor");
            MountainsSideColor           = serializedObject.FindProperty("MountainsSideColor");
            MountainsFogIntensity        = serializedObject.FindProperty("MountainsFogIntensity");
            MountainsSunShaftsColor      = serializedObject.FindProperty("MountainsSunShaftsColor");
            MountainsSunShaftsSize       = serializedObject.FindProperty("MountainsSunShaftsSize");
            SeaCloudColor                = serializedObject.FindProperty("SeaCloudColor");
            SeaCloudDownColor            = serializedObject.FindProperty("SeaCloudDownColor");
            SeaCloudTiling               = serializedObject.FindProperty("SeaCloudTiling");
            SeaCloudDensity              = serializedObject.FindProperty("SeaCloudDensity");
            SeaCloudPower                = serializedObject.FindProperty("SeaCloudPower");
            SeaCloudFogIntensity         = serializedObject.FindProperty("SeaCloudFogIntensity");
            enableVolumetricCloud        = serializedObject.FindProperty("enableVolumetricCloud");
            VolumetricCloudGO            = serializedObject.FindProperty("VolumetricCloudGO");
            VolumetricCloudGOLow         = serializedObject.FindProperty("VolumetricCloudGOLow");
            cloudmainlightColor          = serializedObject.FindProperty("CloudMainLightColor");
            CloudColor                   = serializedObject.FindProperty("CloudColor");
            CloudMainLightDirection      = serializedObject.FindProperty("CloudMainLightDirection");
            SampleCount                  = serializedObject.FindProperty("SampleCount");
            CloudTilling                 = serializedObject.FindProperty("CloudTilling");
            Radius                       = serializedObject.FindProperty("Radius");
            CloudHeight                  = serializedObject.FindProperty("CloudHeight");
            MaxTop                       = serializedObject.FindProperty("MaxTop");
            CurrentTop                   = serializedObject.FindProperty("CurrentTop");
            MaxBottom                    = serializedObject.FindProperty("MaxBottom");
            CurrentBottom                = serializedObject.FindProperty("CurrentBottom");
            Speed                        = serializedObject.FindProperty("Speed");
            Density                      = serializedObject.FindProperty("Density");
            MainLightIntensity           = serializedObject.FindProperty("MainLightIntensity");
            glossyIntensity            = serializedObject.FindProperty("glossyIntensity");
            NoiseTilling                 = serializedObject.FindProperty("NoiseTilling");
            NoiseIntensity               = serializedObject.FindProperty("NoiseIntensity");
            SoftEdge                     = serializedObject.FindProperty("SoftEdge");
            Border                       = serializedObject.FindProperty("Border");
            VolumetricCloudBaseHeight    = serializedObject.FindProperty("VolumetricCloudBaseHeight");
            AtmosphereColorSaturateDistance = serializedObject.FindProperty("AtmosphereColorSaturateDistance");
            AtmosphereColor = serializedObject.FindProperty("AtmosphereColor");
            stormDay                     = serializedObject.FindProperty("stormDay");
            rainIntensity                = serializedObject.FindProperty("rainIntensity");
            rainSmoothness               = serializedObject.FindProperty("rainSmoothness");
            charRainSmoothness           = serializedObject.FindProperty("charRainSmoothness");
            rainflowRate                 = serializedObject.FindProperty("rainflowRate");
            rainRipple                   = serializedObject.FindProperty("rainRipple");
            rippleConfig                 = serializedObject.FindProperty("rippleConfig");
            //rainNormal                   = serializedObject.FindProperty("rainNormal");
            //rainCharNormal               = serializedObject.FindProperty("rainCharNormal");
            rainTiling                   = serializedObject.FindProperty("rainTiling");
            rainCubemap                  = serializedObject.FindProperty("rainCubemap");
            snowDay                      = serializedObject.FindProperty("snowDay");
            snowCoverage                 = serializedObject.FindProperty("snowCoverage");
            snowColor                    = serializedObject.FindProperty("snowColor");
            SnowCameraSet                = serializedObject.FindProperty("SnowCameraSet");
            SnowNoise                    = serializedObject.FindProperty("SnowNoise");
            SnowHeight                      = serializedObject.FindProperty("snowHeight"); 
             SnowDepthTex                 = serializedObject.FindProperty("SnowDepthTex");
            SnowTerrainConfigA           = serializedObject.FindProperty("SnowTerrainConfigA");
            SnowTerrainConfigB           = serializedObject.FindProperty("SnowTerrainConfigB");
            globalCubemap                = serializedObject.FindProperty("globalCubemap");
            exposureFX                   = serializedObject.FindProperty("exposureFX");
            emissionIntensity            = serializedObject.FindProperty("emissionIntensity");
            mainLightSpecularIntensity   = serializedObject.FindProperty("mainLightSpecularIntensity");
            mainLightSpecularDirection   = serializedObject.FindProperty("mainLightSpecularDirection");
            mainLightDiffuseAO           = serializedObject.FindProperty("mainLightDiffuseAO");
            GlobalLightColor             = serializedObject.FindProperty("GlobalLightColor");
            GlobalLeafAOIntensity        = serializedObject.FindProperty("GlobalLeafAOIntensity");
            GlobalHLODLightIntensity     = serializedObject.FindProperty("GlobalHLODLightIntensity");
            TreeAmbientTop               = serializedObject.FindProperty("TreeAmbientTop");
            TreeAmbientMiddle            = serializedObject.FindProperty("TreeAmbientMiddle");
            TreeAmbientDown              = serializedObject.FindProperty("TreeAmbientDown");
            waterEnvColor                = serializedObject.FindProperty("waterEnvColor");
            waterSpecColor               = serializedObject.FindProperty("waterSpecColor");
            waterDepthFactor             = serializedObject.FindProperty("waterDepthFactor");
            charSkinProfile              = serializedObject.FindProperty("charSkinProfile");
            MainLight2CharLight          = serializedObject.FindProperty("MainLight2CharLight");
            charMainLightDir             = serializedObject.FindProperty("charMainLightDir");
            charMainLightSpecularDirection=serializedObject.FindProperty("charMainLightSpecularDirection");
            charFillLightDir             = serializedObject.FindProperty("charFillLightDir");
            charMainLightColor           = serializedObject.FindProperty("charMainLightColor");
            lightAdditionalRate          = serializedObject.FindProperty("lightAdditionalRate");
            charMainLightIntensity       = serializedObject.FindProperty("charMainLightIntensity");
            charMainLightIntensityAdditional = serializedObject.FindProperty("charMainLightIntensityAdditional");
            charFillLightColor           = serializedObject.FindProperty("charFillLightColor");
            charFillLightIntensity       = serializedObject.FindProperty("charFillLightIntensity");
            charFillLightIntensityAdditional = serializedObject.FindProperty("charFillLightIntensityAdditional");
            charAmbientTop               = serializedObject.FindProperty("charAmbientTop");
            charAmbientDown              = serializedObject.FindProperty("charAmbientDown");
            charUIAmbientTop = serializedObject.FindProperty("charUIAmbientTop");
            charUIAmbientDown = serializedObject.FindProperty("charUIAmbientDown");
            charUIMainLightDir           = serializedObject.FindProperty("charUIMainLightDir");
            charUIFillLightDir           = serializedObject.FindProperty("charUIFillLightDir");
            charUIMainLightColor         = serializedObject.FindProperty("charUIMainLightColor");
            charUIMainLightIntensity     = serializedObject.FindProperty("charUIMainLightIntensity");
            charUIFillLightColor         = serializedObject.FindProperty("charUIFillLightColor");
            charUIFillLightIntensity     = serializedObject.FindProperty("charUIFillLightIntensity");
            charToneMapping            	 = serializedObject.FindProperty("charToneMapping");
            charGlobalEnvIntensity       = serializedObject.FindProperty("charGlobalEnvIntensity");
            charShadowAtten              = serializedObject.FindProperty("charShadowAtten");
            charShadowColor              = serializedObject.FindProperty("charShadowColor");
            LightAttenTex                = serializedObject.FindProperty("LightAttenTex");
            //IsShowLightAtten             = serializedObject.FindProperty("IsShowLightAtten");
            LightAttenParams             = serializedObject.FindProperty("LightAttenParams");
            LightMapTex                  = serializedObject.FindProperty("LightMapTex");
            //IsShowLightMap               = serializedObject.FindProperty("IsShowLightMap");
            grassShadowAtten             = serializedObject.FindProperty("grassShadowAtten");
            GPUInstanceMeshList          = serializedObject.FindProperty("GPUInstanceMeshList");
            GPUInstanceMaterialList      = serializedObject.FindProperty("GPUInstanceMaterialList");
            GPUInstanceLod1MeshList      = serializedObject.FindProperty("GPUInstanceLod1MeshList");
            GPUInstanceLod1MaterialList  = serializedObject.FindProperty("GPUInstanceLod1MaterialList");
            InstanceDataFileName         = serializedObject.FindProperty("InstanceDataFileName");
            grassNoise                   = serializedObject.FindProperty("grassNoise");
            grassWindControl             = serializedObject.FindProperty("grassWindControl");
            grassSnowColor               = serializedObject.FindProperty("grassSnowColor");
            grassSnowDarkFaceColor       = serializedObject.FindProperty("grassSnowDarkFaceColor");
            //grassWaveControl             = serializedObject.FindProperty("grassWaveControl");
            IsDrawGizmo                  = serializedObject.FindProperty("IsDrawGizmo");
            TerrainAlpha0                = serializedObject.FindProperty("TerrainAlpha0");
            TerrainAlpha1                = serializedObject.FindProperty("TerrainAlpha1");
            TerrainParams                = serializedObject.FindProperty("TerrainParams");
            MaterialTypes                = serializedObject.FindProperty("MaterialTypeList");
            GlobalDynamicPointLightIntensity = serializedObject.FindProperty("GlobalDynamicPointLightIntensity");

            springBoneWindMain = serializedObject.FindProperty("springBoneWindMain");
            springBoneWindPluseMagnitude = serializedObject.FindProperty("springBoneWindPluseMagnitude");
            springBoneWindPluseFrequency = serializedObject.FindProperty("springBoneWindPluseFrequency");
        }

        public override void OnInspectorGUI()
        {
            //base.OnInspectorGUI();
            EnvironmentSystem t = (target as EnvironmentSystem);
            //EditorGUI.BeginChangeCheck();
            PrefabUtility.RecordPrefabInstancePropertyModifications(target);
            serializedObject.Update();
            
            EditorGUILayout.Space();

            //从此引出的属性不支持动画自动K帧，但可以用来判断属性是否为空来控制面板的显示和隐藏
            EnvironmentSystem environmentSystem = (EnvironmentSystem)target;

            GUI.color = new Color(0.9f, 0.9f, 0.95f);
            //EditorGUILayout.PropertyField(FillLightColor);
            EditorGUILayout.BeginVertical();
            if(DrawHeader("Sky Box", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();

                //如果发生变更，重新获取材质属性
                EditorGUI.BeginChangeCheck();
                //environmentSystem.SkyBox = (GameObject)EditorGUILayout.ObjectField(environmentSystem.SkyBox, typeof(GameObject), true);
                //if(EditorGUI.EndChangeCheck())
                //{
                //    environmentSystem.GetAllMaterialsEditor();
                //}

                //if (environmentSystem.SkyBox == null || environmentSystem.SkyBox.name != "SkyBox")
                //{
                //    EditorGUILayout.HelpBox("把SkyBox拖进来。", MessageType.Error);
                //}
                //else
                //{
                    
                //    EditorGUILayout.HelpBox("SkyBox自己和子物体都不可以改名字！不可以增加或删除子物体！只允许替换每个子物体的材质。", MessageType.Info);
                //    EditorGUILayout.BeginVertical("box");
                //    if (DrawHeader("SkyCube", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(skyHighOffset   ,new GUIContent("SkyHigh Offset"));
                //        EditorGUILayout.PropertyField(skyHighScale    ,new GUIContent("SkyHigh Scale"));
                //        EditorGUILayout.PropertyField(SkyTintColor    ,new GUIContent("Sky TintColor"));
                //        EditorGUILayout.PropertyField(SkyRotation     ,new GUIContent("Rotation"));
                //        EditorGUILayout.PropertyField(SkyExposure     ,new GUIContent("Exposure"));
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("Star", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        EditorGUILayout.PropertyField(starsStrength);
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("Sun", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(sunColor, new GUIContent("Color"));
                //        EditorGUILayout.PropertyField(sunSize, new GUIContent("Size"));
                //        EditorGUILayout.PropertyField(sunDirection, new GUIContent("Direction"));
                //        sunDirection.vector3Value = new Vector3(Mathf.Clamp(sunDirection.vector3Value.x, 0, 180), Mathf.Clamp(sunDirection.vector3Value.y, 0, 360), Mathf.Clamp(sunDirection.vector3Value.z, 0, 1));
                //        EditorGUILayout.PropertyField(shafts, new GUIContent("Shafts"));
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("Moon", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(moonColor, new GUIContent("Color"));
                //        EditorGUILayout.PropertyField(moonSize, new GUIContent("Size"));
                //        EditorGUILayout.PropertyField(moonDirection, new GUIContent("Direction"));
                //        moonDirection.vector3Value = new Vector3(Mathf.Clamp(moonDirection.vector3Value.x, 0, 180), sunDirection.vector3Value.y, Mathf.Clamp(moonDirection.vector3Value.z, 0, 1));
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("MilkyWay", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(milkywayColor, new GUIContent("Color"));
                //        EditorGUILayout.PropertyField(milkywaySize, new GUIContent("Size"));
                //        EditorGUILayout.PropertyField(milkywayDirection, new GUIContent("Direction"));
                //        EditorGUILayout.PropertyField(rainbowIntensity, new GUIContent("Rainbow Intensity"));
                //        milkywayDirection.vector3Value = new Vector3(Mathf.Clamp(milkywayDirection.vector3Value.x, -20, 200), Mathf.Clamp(milkywayDirection.vector3Value.y, -20, 200), Mathf.Clamp(milkywayDirection.vector3Value.z, 0, 1));
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("Cloud", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(cloudColor, new GUIContent("Color"));
                //        EditorGUILayout.PropertyField(cloudCentColor, new GUIContent("CenterColor"));
                //        EditorGUILayout.PropertyField(cloudCener, new GUIContent("CenterColor Intensity"));
                //        EditorGUILayout.PropertyField(cloudDensity, new GUIContent("Density"));
                //        EditorGUILayout.PropertyField(cloudSize, new GUIContent("Size"));
                //        EditorGUILayout.PropertyField(cloudBreak, new GUIContent("Break"));
                //        EditorGUILayout.PropertyField(cloudConcentration, new GUIContent("Concentration"));
                //        EditorGUILayout.PropertyField(cloudSpeedNSide, new GUIContent("Speed And SideFadeOut"),true);
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    if (DrawHeader("Mountains", false, 10))
                //    {
                //        GUILayout.BeginHorizontal();
                //        GUILayout.Label("", GUILayout.Width(10));
                //        GUILayout.BeginVertical();
                //        EditorGUILayout.PropertyField(MountainsBaseLayerColor, new GUIContent("BaseLayer Color"));
                //        EditorGUILayout.PropertyField(Mountains2ndLayerColor, new GUIContent("2ndLayer Color"));
                //        EditorGUILayout.PropertyField(MountainsSideColor, new GUIContent("Side Color"));
                //        EditorGUILayout.PropertyField(MountainsFogIntensity, new GUIContent("Fog Intensity"));
                //        EditorGUILayout.PropertyField(MountainsSunShaftsColor, new GUIContent("SunShafts Color"));
                //        EditorGUILayout.PropertyField(MountainsSunShaftsSize, new GUIContent("SunShafts Size"));
                //        GUILayout.EndVertical();
                //        GUILayout.EndHorizontal();
                //    }
                //    EditorGUILayout.EndVertical();
                //}
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
                
            }

            //if(DrawHeader("Sea Of Clouds", true, 0))
            //{
            //    GUILayout.BeginHorizontal();
            //    GUILayout.Label("", GUILayout.Width(10));
            //    GUILayout.BeginVertical();
            //    EditorGUILayout.BeginVertical("box");

            //    //如果发生变更，重新获取材质属性
            //    EditorGUI.BeginChangeCheck();
            //    environmentSystem.SeaCloudMaterial = (Material)EditorGUILayout.ObjectField(environmentSystem.SeaCloudMaterial, typeof(Material), false);
            //    if (EditorGUI.EndChangeCheck())
            //    {
            //        environmentSystem.GetAllMaterialsEditor();
            //    }

            //    if (environmentSystem.SeaCloudMaterial == null)
            //    {
            //        EditorGUILayout.HelpBox("如果需要env控制新版云海，就把材质拖进来。", MessageType.Warning);
            //    }
            //    else
            //    {
                    
            //        EditorGUILayout.PropertyField(SeaCloudColor, new GUIContent("Cloud Color"));
            //        EditorGUILayout.PropertyField(SeaCloudDownColor, new GUIContent("Cloud Down Color"));
            //        EditorGUILayout.PropertyField(SeaCloudTiling, new GUIContent("Cloud Tiling"));
            //        EditorGUILayout.PropertyField(SeaCloudDensity, new GUIContent("Cloud Density"));
            //        EditorGUILayout.PropertyField(SeaCloudPower, new GUIContent("Cloud Power"));
            //        EditorGUILayout.PropertyField(SeaCloudFogIntensity, new GUIContent("Fog Intensity"));
                    
            //    }
            //    EditorGUILayout.EndVertical();
            //    GUILayout.EndVertical();
            //    GUILayout.EndHorizontal();
            //}


            if(DrawHeader("Volumetric Cloud", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");

                EditorGUILayout.PropertyField(enableVolumetricCloud, new GUIContent("Volumetric Cloud"));
                if (enableVolumetricCloud.boolValue == true)
                {
                    EditorGUILayout.PropertyField(VolumetricCloudGO, new GUIContent("VolumetricCloud GameObject"));
                    EditorGUILayout.PropertyField(VolumetricCloudGOLow, new GUIContent("Low VolumetricCloudGO GameObject"));
                    EditorGUILayout.PropertyField(cloudmainlightColor, new GUIContent("Cloud MainLight Color"));
                    EditorGUILayout.PropertyField(CloudColor, new GUIContent("Volumetric Cloud Color"));
                    EditorGUILayout.PropertyField(CloudMainLightDirection, new GUIContent("Cloud MainLight Direction"));
                    EditorGUILayout.PropertyField(SampleCount, new GUIContent("Sample Count "));
                    EditorGUILayout.PropertyField(CloudTilling, new GUIContent("Cloud Tiling"));
                    EditorGUILayout.PropertyField(Radius, new GUIContent("Cloud Radius"));
                    EditorGUILayout.PropertyField(CloudHeight, new GUIContent("Cloud Height"));
                    EditorGUILayout.PropertyField(MaxTop, new GUIContent("Max Top"));
                    EditorGUILayout.PropertyField(CurrentTop, new GUIContent("Current Top"));
                    EditorGUILayout.PropertyField(MaxBottom, new GUIContent("Max Bottom"));
                    EditorGUILayout.PropertyField(CurrentBottom, new GUIContent("Current Bottom"));
                    EditorGUILayout.PropertyField(Speed, new GUIContent("Cloud Speed"));
                    EditorGUILayout.PropertyField(Density, new GUIContent("Cloud Density"));
                    EditorGUILayout.PropertyField(MainLightIntensity, new GUIContent("Main Light Intensity"));
                    EditorGUILayout.PropertyField(glossyIntensity, new GUIContent("Glossy Intensity"));
                    EditorGUILayout.PropertyField(NoiseTilling, new GUIContent("Noise BaseTilling"));
                    EditorGUILayout.PropertyField(NoiseIntensity, new GUIContent("Noise Intensity"));                    
                    EditorGUILayout.PropertyField(SoftEdge, new GUIContent("Soft Edge"));
                    EditorGUILayout.PropertyField(Border, new GUIContent("Cloud Border"));
                    EditorGUILayout.PropertyField(VolumetricCloudBaseHeight, new GUIContent("VolumetricCloudBaseHeight"));
                    EditorGUILayout.PropertyField(AtmosphereColorSaturateDistance, new GUIContent("AtmosphereColorSaturateDistance"));
                    EditorGUILayout.PropertyField(AtmosphereColor, new GUIContent("AtmosphereColor"));
                }


                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if (DrawHeader("Storm And Snow", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                if (DrawHeader("Storm", false, 10))
                {
                    EditorGUILayout.PropertyField(stormDay, new GUIContent("Storm Day"));
                    if (stormDay.boolValue == false)
                    {
                        
                    }
                    else
                    {
                        EditorGUILayout.PropertyField(rainIntensity, new GUIContent("Intensity"));
                        EditorGUILayout.PropertyField(rainSmoothness, new GUIContent("Smoothness"));
                        EditorGUILayout.PropertyField(charRainSmoothness, new GUIContent("Char Smoothness"));
                        EditorGUILayout.PropertyField(rainflowRate, new GUIContent("Rainflow Rate"));
                        EditorGUILayout.PropertyField(rainTiling, new GUIContent("Rain Tiling"));
                        EditorGUILayout.PropertyField(rainCubemap, new GUIContent("Rain Cubemap"));
                        EditorGUILayout.PropertyField(rainRipple, new GUIContent("Rain Ripple"));
                        EditorGUILayout.PropertyField(rippleConfig, new GUIContent("Ripple Config"));
                        EditorGUILayout.PropertyField(SnowCameraSet, new GUIContent("Coverage Settings"));
                        EditorGUILayout.PropertyField(SnowDepthTex, new GUIContent("Snow Depth"));
                        //EditorGUILayout.PropertyField(rainNormal, new GUIContent("Rain Normal"));
                        //EditorGUILayout.PropertyField(rainCharNormal, new GUIContent("Rain Char Normal"));
                    }
                }
                if (DrawHeader("Snow", false, 10))
                {
                    EditorGUILayout.PropertyField(snowDay, new GUIContent("Snowy Day"));
                    if(snowDay.boolValue == false)
                    {

                    }
                    else
                    {
                        EditorGUILayout.PropertyField(SnowHeight, new GUIContent("SnowHeight"));
                        EditorGUILayout.PropertyField(snowCoverage, new GUIContent("Coverage"));
                        EditorGUILayout.PropertyField(snowColor, new GUIContent("Snow Color"));
                        EditorGUILayout.PropertyField(SnowCameraSet, new GUIContent("Coverage Settings"));
                        EditorGUILayout.PropertyField(SnowNoise, new GUIContent("Snow Noise"));
                        EditorGUILayout.PropertyField(SnowDepthTex, new GUIContent("Snow Depth"));
                        EditorGUILayout.PropertyField(SnowTerrainConfigA, new GUIContent("SnowTerrainConfigA"));
                        EditorGUILayout.PropertyField(SnowTerrainConfigB, new GUIContent("SnowTerrainConfigB"));
                    }
                }
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
                
            }

            if (DrawHeader("Water", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(waterEnvColor, new GUIContent("Env Color"));
                EditorGUILayout.PropertyField(waterSpecColor, new GUIContent("Spec Color"));
                EditorGUILayout.PropertyField(waterDepthFactor, new GUIContent("Depth Factor"));
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if (DrawHeader("Global Setting", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(globalCubemap, new GUIContent("GlobalCubemap"));
                EditorGUILayout.PropertyField(exposureFX, new GUIContent("Exposure FX"));

                EditorGUILayout.PropertyField(emissionIntensity, new GUIContent("Emission Intensity"));
                EditorGUILayout.PropertyField(mainLightSpecularIntensity, new GUIContent("MainLight Specular Intensity"));
                Vector2 mainLightSpecularDirectionVector = new Vector2(t.mainLightSpecularDirection, t.mainLightSpecularDirectionY);
                mainLightSpecularDirectionVector = EditorGUILayout.Vector2Field("MainLight Specular Direction", mainLightSpecularDirectionVector);
                mainLightSpecularDirectionVector = new Vector2(Mathf.Clamp(mainLightSpecularDirectionVector.x,0,360), Mathf.Clamp(mainLightSpecularDirectionVector.y, 0, 360));
                t.mainLightSpecularDirection = mainLightSpecularDirectionVector.x;
                t.mainLightSpecularDirectionY = mainLightSpecularDirectionVector.y;
               // EditorGUILayout.PropertyField(mainLightSpecularDirection, new GUIContent("MainLight Specular Direction"));
                EditorGUILayout.PropertyField(mainLightDiffuseAO, new GUIContent("MainLight Diffuse AO"));
                EditorGUILayout.PropertyField(GlobalLightColor, new GUIContent("Unlit Global Light Color"));
                EditorGUILayout.PropertyField(GlobalLeafAOIntensity, new GUIContent("Global Leaf AOIntensity"));
                EditorGUILayout.PropertyField(GlobalHLODLightIntensity, new GUIContent("Global HLOD Light Intensity"));
                EditorGUILayout.PropertyField(TreeAmbientTop);
                EditorGUILayout.PropertyField(TreeAmbientMiddle);
                EditorGUILayout.PropertyField(TreeAmbientDown);
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if (DrawHeader("Char Setting", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(charGlobalEnvIntensity, new GUIContent("Global Env Intensity"));
                EditorGUILayout.PropertyField(charShadowAtten, new GUIContent("Shadow Atten"));
                EditorGUILayout.PropertyField(charShadowColor, new GUIContent("Shadow Color"));

                if (DrawHeader("Char", false, 10))
                {
                    EditorGUILayout.PropertyField(charSkinProfile, new GUIContent("Skin Profile"));
                    EditorGUILayout.PropertyField(MainLight2CharLight, new GUIContent("MainLight2Char"));
                    EditorGUILayout.PropertyField(charMainLightDir, new GUIContent("Main LightDir"));
                    EditorGUILayout.PropertyField(charMainLightSpecularDirection, new GUIContent("SpecularDirection"));
                    EditorGUILayout.PropertyField(charFillLightDir, new GUIContent("Fill LightDir"));
                    EditorGUILayout.PropertyField(charMainLightColor, new GUIContent("Main LightColor"));
                    EditorGUILayout.PropertyField(lightAdditionalRate, new GUIContent("Light Additional Rate"));
                    EditorGUILayout.PropertyField(charMainLightIntensity, new GUIContent("Main LightIntensity"));
                    EditorGUILayout.PropertyField(charMainLightIntensityAdditional, new GUIContent("Main LightIntensity Additional"));
                    EditorGUILayout.PropertyField(charFillLightColor, new GUIContent("Fill LightColor"));
                    EditorGUILayout.PropertyField(charFillLightIntensity, new GUIContent("Fill LightIntensity"));
                    EditorGUILayout.PropertyField(charFillLightIntensityAdditional, new GUIContent("Fill LightIntensity Additional"));
                    EditorGUILayout.PropertyField(charAmbientTop, new GUIContent("Ambient Top"));
                    EditorGUILayout.PropertyField(charAmbientDown, new GUIContent("Ambient Down"));
                }
                if (DrawHeader("Char UI", false, 10))
                {
                    EditorGUILayout.PropertyField(charUIMainLightDir, new GUIContent("Main LightDir"));
                    EditorGUILayout.PropertyField(charUIFillLightDir, new GUIContent("Fill LightDir"));
                    EditorGUILayout.PropertyField(charUIMainLightColor, new GUIContent("Main LightColor"));
                    EditorGUILayout.PropertyField(charUIMainLightIntensity, new GUIContent("Main LightIntensity"));
                    EditorGUILayout.PropertyField(charUIFillLightColor, new GUIContent("Fill LightColor"));
                    EditorGUILayout.PropertyField(charUIFillLightIntensity, new GUIContent("Fill LightIntensity"));
                    EditorGUILayout.PropertyField(charToneMapping, new GUIContent("ToneMapping Intensity"));
                    EditorGUILayout.PropertyField(charUIAmbientTop, new GUIContent("Ambient Top"));
                    EditorGUILayout.PropertyField(charUIAmbientDown, new GUIContent("Ambient Down"));
                }
                
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if (DrawHeader("Light Atten", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(LightAttenTex, new GUIContent("Light Atten Tex"));
                EditorGUILayout.PropertyField(LightAttenParams, new GUIContent("Light Atten Params"));
                //EditorGUILayout.PropertyField(IsShowLightAtten, new GUIContent("Show Light Atten"));
                EditorGUILayout.PropertyField(LightMapTex, new GUIContent("Light Map Tex"));
                //EditorGUILayout.PropertyField(IsShowLightMap, new GUIContent("Show Lightmap"));
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }
            
            if (DrawHeader("GPU Instance", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(GPUInstanceMeshList, new GUIContent("Mesh List"), true);
                EditorGUILayout.PropertyField(GPUInstanceMaterialList, new GUIContent("Material List"), true);
                EditorGUILayout.PropertyField(GPUInstanceLod1MeshList, new GUIContent("Mesh LOD1 List"), true);
                EditorGUILayout.PropertyField(GPUInstanceLod1MaterialList, new GUIContent("Material LOD1 List"), true);
                EditorGUILayout.PropertyField(InstanceDataFileName, new GUIContent("File Name"), true);
                EditorGUILayout.PropertyField(grassNoise, new GUIContent("Grass Noise Tex"), true);
                EditorGUILayout.PropertyField(grassWindControl, new GUIContent("Grass Wind Control 草的全局风控制参数 X分量表示在X轴上自身摆动的速度，Y分量地图的大小(不要设置成0)， Z分量表示在Z轴方向上摆动的速度， W表示摆动的强度"), true);
                EditorGUILayout.PropertyField(grassSnowColor, new GUIContent("grass snow color"));
                EditorGUILayout.PropertyField(grassSnowDarkFaceColor, new GUIContent("grass dark face color"));
                //EditorGUILayout.PropertyField(grassWaveControl, new GUIContent("Grass Wave Control"), true);

                EditorGUILayout.PropertyField(IsDrawGizmo, new GUIContent("Draw Gizmo"));
                EditorGUILayout.PropertyField(grassShadowAtten, new GUIContent("Grass Shadow Atten"));
                //environmentSystem.GrassQualityLevelType = (GrassQualityLevelType)EditorGUILayout.EnumPopup("Quality Level", environmentSystem.GrassQualityLevelType);

                //List<GpuInstanceQualitySettings> settingsList = environmentSystem.GPUInstanceQualityList;
                //GpuInstanceQualitySettings curSettings = null;
                //if (settingsList.Count > (int)environmentSystem.GrassQualityLevelType)
                //{
                //    curSettings = settingsList[(int)environmentSystem.GrassQualityLevelType];
                //}
                //if (curSettings != null)
                //{
                //    int numDiff = curSettings.EnableList.Count - environmentSystem.GPUInstanceMeshList.Count;
                //    if (numDiff > 0)
                //    {
                //        for (int j = 0; j < numDiff; j++)
                //        {
                //            curSettings.EnableList.RemoveAt(curSettings.EnableList.Count - 1);
                //        }
                //    }
                //    else if (numDiff < 0)
                //    {
                //        for (int j = 0; j < -numDiff; j++)
                //        {
                //            curSettings.EnableList.Add(true);
                //        }
                //    }
                //    curSettings.LOD0Distance = EditorGUILayout.FloatField("Lod0 Distance", curSettings.LOD0Distance);
                //    curSettings.LOD1Distance = EditorGUILayout.FloatField("Lod1 Distance", curSettings.LOD1Distance);
                //    if (curSettings.LOD1Distance < curSettings.LOD0Distance)
                //    {
                //        curSettings.LOD1Distance = curSettings.LOD0Distance;
                //    }
                //    for (int i = 0; i < curSettings.EnableList.Count; i++)
                //    {
                //        curSettings.EnableList[i] = EditorGUILayout.Toggle(i.ToString(), curSettings.EnableList[i]);
                //    }
                //}
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if (DrawHeader("地形声音", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(TerrainAlpha0, new GUIContent("第一张混合图"));
                EditorGUILayout.PropertyField(TerrainAlpha1, new GUIContent("第二张混合图"));
                EditorGUILayout.PropertyField(TerrainParams, new GUIContent("地形参数"));
                EditorGUILayout.PropertyField(MaterialTypes, new GUIContent("材质类型"), true);
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            if(DrawHeader("DynamicPointLight", true, 0))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("", GUILayout.Width(10));
                GUILayout.BeginVertical();
                EditorGUILayout.BeginVertical("box");
                EditorGUILayout.PropertyField(GlobalDynamicPointLightIntensity, new GUIContent("GlobalDynamicPointLightIntensity"));      
                EditorGUILayout.EndVertical();
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
            }

            //if (DrawHeader("布料风力参数", true, 0))
            //{
            //    GUILayout.BeginHorizontal();
            //    GUILayout.Label("", GUILayout.Width(10));
            //    GUILayout.BeginVertical();
            //    EditorGUILayout.BeginVertical("box");
            //    EditorGUILayout.PropertyField(springBoneWindMain, new GUIContent("springBoneWindMain"));
            //    EditorGUILayout.PropertyField(springBoneWindPluseMagnitude, new GUIContent("springBoneWindPluseMagnitude"));
            //    EditorGUILayout.PropertyField(springBoneWindPluseFrequency, new GUIContent("springBoneWindPluseFrequency"));
            //    EditorGUILayout.EndVertical();
            //    GUILayout.EndVertical();
            //    GUILayout.EndHorizontal();
            //}
            EditorGUILayout.EndVertical();

            serializedObject.ApplyModifiedProperties();
            //当Inspector 面板发生变化时保存数据
            if (GUI.changed)
            {
                EditorUtility.SetDirty(target);
                UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(environmentSystem.gameObject.scene);
            }
        }
    }
}
