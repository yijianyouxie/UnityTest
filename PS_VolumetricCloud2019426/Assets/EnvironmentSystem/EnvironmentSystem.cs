using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
namespace TLStudio
{
    [ExecuteInEditMode]
    [DisallowMultipleComponent]
    public class EnvironmentSystem : MonoBehaviour
    {
        public static EnvironmentSystem Instance
        {
            get
            {
                if (m_InstanceList.Count > 0)
                {
                    return m_InstanceList[0];
                }
                return null;
            }
        }

        private static List<EnvironmentSystem> m_InstanceList = new List<EnvironmentSystem>();

        //public WindZone WindZone
        //{
        //    get { return windZone; }
        //    set { windZone = value; }
        //}

        //private WindZone windZone = null;
        //private Transform windTrans = null;

        //[ColorUsage(false, true)]
        //public Color TreeAmbientTop = Color.white;

        //[ColorUsage(false, true)]
        //public Color TreeAmbientMiddle = Color.white;

        //[ColorUsage(false, true)]
        //public Color TreeAmbientDown = Color.white;

        //[ColorUsage(true, true)]
        //public Color FillLightColor = Color.white;

        //public GameObject SkyBox = null;

        //#region SkyCube

        //[Range(-15000f, 15000f)]
        //public float skyHighOffset = 6009;

        //[Range(0f, 1500f)]
        //public float skyHighScale = 761;

        //[ColorUsage(false, true)]
        //public Color SkyTintColor = Color.gray;

        //[Range(0f, 360f)]
        //public float SkyRotation = 0f;

        //[Range(0f, 16f)]
        //public float SkyExposure = 1f;

        //#endregion SkyCube

        //#region Mountains

        //[ColorUsage(true, true)]
        //public Color MountainsBaseLayerColor = Color.white;

        //[ColorUsage(true, true)]
        //public Color Mountains2ndLayerColor = Color.white;

        //[ColorUsage(true, true)]
        //public Color MountainsSideColor = Color.white;

        //[Range(0f, 1f)]
        //public float MountainsFogIntensity = 1;

        //[ColorUsage(true, true)]
        //public Color MountainsSunShaftsColor = Color.black;

        //[Range(0.5f, 0.95f)]
        //public float MountainsSunShaftsSize = 0.8f;

        //#endregion Mountains

        //#region Cloud

        //[ColorUsage(true, true)]
        //public Color cloudColor = Color.white;

        //[ColorUsage(true, true)]
        //public Color cloudCentColor = Color.white;

        //[Range(0f, 2f)]
        //public float cloudDensity = 1f;

        //[Range(0f, 2f)]
        //public float cloudSize = 0.5f;

        //[Range(0f, 1f)]
        //public float cloudBreak = 0.5f;

        //[Range(0f, 1f)]
        //public float cloudCener = 0.5f;

        //[Range(0f, 10f)]
        //public float cloudConcentration = 0.5f;

        //public Vector4 cloudSpeedNSide = Vector4.zero;
        //private Vector4 cloudSpeed = Vector4.zero;

        //#endregion Cloud

        //#region SeaOfCloud

        //public Material SeaCloudMaterial;

        //[ColorUsage(true, true)]
        //public Color SeaCloudColor = Color.white;

        //[ColorUsage(true, false)]
        //public Color SeaCloudDownColor = Color.white;

        //[Range(0f, 2f)]
        //public float SeaCloudTiling = 0.2f;

        //[Range(0f, 2f)]
        //public float SeaCloudDensity = 0.84f;

        //[Range(0f, 2f)]
        //public float SeaCloudPower = 1.2f;

        //[Range(0f, 1f)]
        //public float SeaCloudFogIntensity = 1.0f;

        //#endregion SeaOfCloud

        #region VolumetricCloud

        /*外部接口不要调用,使用SetVolumetricCloudVisiable()函数统一调用*/
        public bool enableVolumetricCloud = false;

        public GameObject VolumetricCloudGO = null;

        public GameObject VolumetricCloudGOLow = null;

        //[ColorUsage(true, true)]
        public Color CloudMainLightColor = new Color(1.0f, 1.0f, 1.0f, 1.0f);
        //[ColorUsage(true, true)]
        public Color CloudColor = new Color(1.0f, 1.0f, 1.0f, 1.0f);

        public Vector3 CloudMainLightDirection = Vector3.one;
        [Range(0, 45)]
        public int SampleCount = 40;

        public Vector3 CloudTilling = new Vector3(0.15f, 0.2f, 0.15f);

        public float Radius = 1000.0f;


        [Range(-1000.0f, 2000.0f)]
        public float CloudHeight = 2.0f;

        [Range(0.0f, 2000.0f)]
        public float MaxTop = 1000.0f;

        [Range(0.0f, 200.0f)]
        public float CurrentTop = 100.0f;

        [Range(-1000, 0)]
        public float MaxBottom = -200.0f;

        [Range(-200.0f, 0)]
        public float CurrentBottom = -100.0f;

        public float Speed = 30.0f;


        [Range(0f, 20.0f)]
        public float Density = 1.0f;

        [Range(0f, 1.0f)]
        public float MainLightIntensity = 1.0f;

        [Range(0, 20.0f)]
        public float glossyIntensity = 1.0f;

        [Range(0f, 1.0f)]
        public float NoiseTilling = 0.3f;

        [Range(0f, 10.0f)]
        public float NoiseIntensity = 1.5f;


        [Range(0.1f, 1.0f)]
        public float SoftEdge = 1.0f;


        [Range(0.0f, 1.0f)]
        public float Border;

        [Range(-2000, 2000)]
        public float VolumetricCloudBaseHeight = 0.0f;

        [Range(100, 10000)]
        public float AtmosphereColorSaturateDistance = 1200.0f;

        //[ColorUsage(true, true)]
        public Color AtmosphereColor = new Color(1.0f,1.0f,1.0f,1.0f);

        private VolumetricCloud m_VolumetricCloudComponent = null;

        private bool m_VolumetricCloudQuality = true;
        #endregion

        //#region CelestialBody

        //[ColorUsage(true, true)]
        //public Color sunColor = Color.white;

        //[Range(0f, 20f)]
        //public float sunSize = 1;

        //public Vector3 sunDirection = Vector3.one;

        //public GameObject Shafts;
        //public Vector3 shaftsDirection = Vector3.one;

        //[ColorUsage(true, true)]
        //public Color moonColor = Color.white;

        //[Range(0f, 10f)]
        //public float moonSize = 1;

        //public Vector3 moonDirection = Vector3.one;

        //[Range(0, 1)]
        //public float starsStrength = 1;

        //[ColorUsage(true, true)]
        //public Color milkywayColor = Color.white;

        //[Range(0f, 10f)]
        //public float milkywaySize = 1;

        //public Vector3 milkywayDirection = Vector3.one;

        //[Range(0f, 3f)]
        //public float rainbowIntensity = 0f;

        //#endregion CelestialBody

        [Range(0f, 2f)]
        public float emissionIntensity = 0;

        [Range(0.0f, 10f)]
        public float globalAOScale = 1f;

        [Range(0.1f, 10f)]
        public float globalAOIntensity = 1f;

        [Range(0f, 1f)]
        public float mainLightSpecularIntensity = 1f;

        [Range(0f, 360f)]
        public float mainLightSpecularDirection = 0f;

        [Range(0f, 360f)]
        public float mainLightSpecularDirectionY = 0f;

        private Vector3 mainLightRotation = Vector3.zero;
        private GameObject Mainlight;

        [Range(1f, 5f)]
        public float mainLightDiffuseAO = 5f;

        //[Range(0.0f, 10f)]
        //public float sceneFillLightGlobalIntensity = 1f;

        public Cubemap globalCubemap = null;

        [Range(-1.0f, 20f)]
        public float exposureFX = 0f;

        public Color GlobalLightColor = Color.white;

        [Range(-1f, 1f)]
        public float GlobalLeafAOIntensity = 0f;

        [Range(0.0f, 4.0f)]
        public float GlobalHLODLightIntensity = 1.0f;

        public bool snowDay = false;
        public float snowHeight = -10;//不同场景,雪高低不同.

        [Range(0.0f, 0.5f)]
        public float snowCoverage = 0;
        public Color snowColor = new Color(0.3f, 0.3f, 0.3f, 1.0f);

        public Vector3 SnowCameraSet = Vector3.zero;
        [HideInInspector]
        public float SnowTexConfig;
        public Texture2D SnowNoise = null;
        public Texture2D SnowDepthTex = null;
        public Vector4 SnowTerrainConfigA = Vector4.zero;
        public Vector4 SnowTerrainConfigB = Vector4.zero;

        public bool stormDay = false;

        [Range(0.0f, 1.0f)]
        public float rainIntensity = 0;

        [Range(0.0f, 1.0f)]
        public float rainSmoothness = 0;

        [Range(0.0f, 0.4f)]
        public float charRainSmoothness = 0.2f;

        [Range(-20f, 20f)]
        public float rainflowRate = 1;

        public Cubemap rainCubemap = null;

        //public Texture2D rainNormal = null;

        //public Texture2D rainCharNormal = null;

        public Texture2D rainRipple = null;

        public Vector4 rippleConfig = Vector4.zero;

        [Range(0.1f, 5.0f)]
        public float rainTiling = 1;

        public GameObject MainLight2CharLight = null;
        private Vector3 MainLight2CharFillLight = new Vector3(0, 90, 0);
        public Texture2D charSkinProfile = null;

        public Vector3 charMainLightDir = new Vector3(20, 0, 0);
        public float charMainLightSpecularDirection = 0f;
        private Vector3 charMainLightSpecularRotation = Vector3.zero;
        public Vector3 charFillLightDir = new Vector3(20, 180, 0);
        public Color charMainLightColor = Color.white;

        [Range(0.0f, 4f)]
        public float charMainLightIntensity = 1f;

        [Range(0.0f, 4f)]
        public float charMainLightIntensityAdditional = 0f;

        public Color charFillLightColor;

        [Range(0.0f, 4f)]
        public float charFillLightIntensity = 1f;

        [Range(0.0f, 4f)]
        public float charFillLightIntensityAdditional = 0f;

        [Range(0.0f, 1.0f)]
        public float lightAdditionalRate = 0.0f;

        //[ColorUsage(false, true)]
        public Color charAmbientTop = Color.white;

        //[ColorUsage(false, true)]
        public Color charAmbientDown = Color.white;

        //[ColorUsage(false, true)]
        public Color charUIAmbientTop = Color.white;

        //[ColorUsage(false, true)]
        public Color charUIAmbientDown = Color.white;

        [Range(0.0f, 1f)]
        public float charToneMapping = 0.9f;
        /// /////////////////////UICharLit//////////////////////////////////////////
        //public bool UiCharacter = false;
        public Vector3 charUIMainLightDir = new Vector3(20, 0, 0);

        public Vector3 charUIFillLightDir = new Vector3(20, 180, 0);
        public Color charUIMainLightColor = Color.white;

        [Range(0.0f, 4f)]
        public float charUIMainLightIntensity = 1f;

        public Color charUIFillLightColor;

        [Range(0.0f, 4f)]
        public float charUIFillLightIntensity = 1f;

        [Range(0.0f, 4f)]
        public float charGlobalEnvIntensity = 1f;

        [Range(0.0f, 1f)]
        public float charShadowAtten = 0f;

        public Color charShadowColor = Color.white;

        //public Color charHairLightColor = Color.white;

        [HideInInspector]
        public Color actualCharMainLightColor, actualCharFillLightColor;

        [HideInInspector]
        public Color actualCharUIMainLightColor, actualCharUIFillLightColor;

        [HideInInspector]
        public Vector4 actualCharMainLightDir, actualCharFillLightDir;

        [HideInInspector]
        public Vector4 actualCharUIMainLightDir, actualCharUIFillLightDir;

        //#region Water

        //[ColorUsage(false, true)]
        //public Color waterEnvColor = Color.white;

        //[ColorUsage(false, true)]
        //public Color waterSpecColor = Color.white;

        //[Range(0.2f, 1f)]
        //public float waterDepthFactor = 1;

        //#endregion Water

//        #region Light Atten 临时用于导出前的草

////#if UNITY_EDITOR
//        public Texture2D LightAttenTex = null;
//        public Vector3 LightAttenParams = Vector3.zero;
//        //public bool IsShowLightAtten = false;

//        public Texture2D LightMapTex = null;
//        //public bool IsShowLightMap = false;
////#endif

//        #endregion Light Atten 临时用于导出前的草

//        #region Gpu Instance Grass

//        public List<Mesh> GPUInstanceMeshList = new List<Mesh>();

//        //public List<GpuInstanceQualitySettings> GPUInstanceQualityList = new List<GpuInstanceQualitySettings>()
//        //{
//        //    new GpuInstanceQualitySettings(),
//        //    new GpuInstanceQualitySettings(),
//        //    new GpuInstanceQualitySettings(),
//        //    new GpuInstanceQualitySettings(),
//        //};

//        public List<Material> GPUInstanceMaterialList = new List<Material>();
//        public List<Mesh> GPUInstanceLod1MeshList = new List<Mesh>();
//        public List<Material> GPUInstanceLod1MaterialList = new List<Material>();
//        public string InstanceDataFileName = string.Empty;

//        [Range(0.0f, 5f)]
//        public float grassShadowAtten = 0f;

//        /*草的全局噪声图*/
//        public Texture2D grassNoise = null;

//        /*草的全局风控制参数 X分量表示在X轴上自身摆动的速度，Y分量没有使用， Z分量表示在Z轴方向上摆动的速度， W表示摆动的强度*/
//        public Vector4 grassWindControl = new Vector4(1.0f, 1.0f, 1.0f, 0.5f);

//        public Color grassSnowColor = Color.white;
//        [ColorUsage(false, true)]
//        public Color grassSnowDarkFaceColor = Color.white;
//        ///*草的波形控制参数 X轴上风浪的速度，Y分量没有使用， Z分量表示在Z轴上风浪的速度，w表示地图的大小，用于噪点图的坐标寻址*/
//        //public Vector4 grassWaveControl = new Vector4(1.0f, 0.0f, 1.0f, 1.0f);

//#if UNITY_EDITOR
//        public bool IsDrawGizmo = true;
//#endif

//        //[SerializeField]
//        //public GrassQualityLevelType GrassQualityLevelType = GrassQualityLevelType.Low;

//        //private const string m_SceneQualityName = "SceneQuality";

//        //private void OnQualitySettingChanged(object sender, GameFramework.Event.GameEventArgs e)
//        //{
//        //    ProjectS.QualitySettingChangedEventArgs ne = (ProjectS.QualitySettingChangedEventArgs)e;
//        //    if (ne.QualitySettingName != m_SceneQualityName)
//        //    {
//        //        return;
//        //    }

//        //    switch (ProjectS.SceneExtension.SceneQuality)
//        //    {
//        //        case ProjectS.SceneQualityLevel.Base:
//        //        case ProjectS.SceneQualityLevel.Low:
//        //            GrassQualityLevelType = GrassQualityLevelType.Low;
//        //            break;

//        //        case ProjectS.SceneQualityLevel.Medium:
//        //            GrassQualityLevelType = GrassQualityLevelType.Medium;
//        //            break;

//        //        case ProjectS.SceneQualityLevel.High:
//        //            GrassQualityLevelType = GrassQualityLevelType.High;
//        //            break;

//        //        case ProjectS.SceneQualityLevel.Ultra:
//        //            GrassQualityLevelType = GrassQualityLevelType.Ultra;
//        //            break;

//        //        default:
//        //            break;
//        //    }
//        //}

//        #endregion Gpu Instance Grass

        //#region Terrain Sound

        //public Texture2D TerrainAlpha0 = null;
        //public Texture2D TerrainAlpha1 = null;
        //public Vector4 TerrainParams = Vector4.zero;
        ////public List<ProjectS.MaterialType> MaterialTypeList = new List<ProjectS.MaterialType>();

        //public ProjectS.MaterialType CheckTerrainMaterialType(Vector2 targetPos)
        //{
        //    if (TerrainParams == Vector4.zero)
        //    {
        //        return ProjectS.MaterialType.Other;
        //    }

        //    if (TerrainAlpha0 == null)
        //    {
        //        return ProjectS.MaterialType.Other;
        //    }

        //    Vector2 photoUV = new Vector2((targetPos.x - TerrainParams.x) / TerrainParams.z,
        //(targetPos.y - TerrainParams.y) / TerrainParams.w);

        //    Color alpha0Color = TerrainAlpha0.GetPixelBilinear(photoUV.x, photoUV.y);

        //    int maxIndex = 0;
        //    if (TerrainAlpha1 == null)
        //    {
        //        float maxValue = alpha0Color.r;
        //        if (alpha0Color.g > maxValue)
        //        {
        //            maxIndex = 1;
        //            maxValue = alpha0Color.g;
        //        }
        //        if (alpha0Color.b > maxValue)
        //        {
        //            maxIndex = 2;
        //            maxValue = alpha0Color.b;
        //        }
        //        if (alpha0Color.a > maxValue)
        //        {
        //            maxIndex = 3;
        //        }
        //    }
        //    else
        //    {
        //        Color alpha1Color = TerrainAlpha1.GetPixelBilinear(photoUV.x, photoUV.y);
        //        float maxValue = alpha0Color.r;
        //        if (alpha0Color.g > maxValue)
        //        {
        //            maxIndex = 1;
        //            maxValue = alpha0Color.g;
        //        }
        //        if (alpha0Color.b > maxValue)
        //        {
        //            maxIndex = 2;
        //            maxValue = alpha0Color.b;
        //        }
        //        if (alpha0Color.a > maxValue)
        //        {
        //            maxIndex = 3;
        //        }
        //        if (alpha1Color.r > maxValue)
        //        {
        //            maxIndex = 4;
        //            maxValue = alpha0Color.g;
        //        }
        //        if (alpha1Color.g > maxValue)
        //        {
        //            maxIndex = 5;
        //            maxValue = alpha0Color.g;
        //        }
        //        if (alpha1Color.b > maxValue)
        //        {
        //            maxIndex = 6;
        //            maxValue = alpha0Color.b;
        //        }
        //        if (alpha1Color.a > maxValue)
        //        {
        //            maxIndex = 7;
        //        }
        //    }

        //    if (MaterialTypeList.Count > maxIndex)
        //    {
        //        return MaterialTypeList[maxIndex];
        //    }
        //    else
        //    {
        //        return ProjectS.MaterialType.Other;
        //    }
        //}

        //#endregion Terrain Sound

        #region Dynamic Point Light

        [Range(0.0f, 2f)]
        public float GlobalDynamicPointLightIntensity = 1.0f;

        #endregion Dynamic Point Light

        //获取到的本地材质
        private Material SkyMaterialBase;

        private Material MilkywayMaterialBase;
        private Material RainbowMaterialBase;
        private Material SunMaterialBase;
        private Material MoonMaterialBase;
        private Material CloudMaterialBase;
        private Material MountainsMaterialBase;

        //运行时实例的材质
        private Material SkyMaterialInstance;

        private Material MilkywayMaterialInstance;
        private Material RainbowMaterialInstance;
        private Material SunMaterialInstance;
        private Material MoonMaterialInstance;
        private Material CloudMaterialInstance;
        private Material MountainsMaterialInstance;

        //老罗的水用
        [HideInInspector]
        public Renderer SkyMaterialRenderer;

        [HideInInspector]
        public Renderer SunMaterialRenderer;

        [HideInInspector]
        public Renderer MoonMaterialRenderer;

        [HideInInspector]
        public Renderer MilkywayMaterialRenderer;

        [HideInInspector]
        public Renderer RainbowMaterialRenderer;

        [HideInInspector]
        public Renderer CloudMaterialRenderer;

        [HideInInspector]
        public Renderer MountainsMaterialRenderer;

        private float treespeed = 0f;
        // Use this for initialization
        //private System.EventHandler<GameFramework.Event.GameEventArgs> m_OnQualitySettingChanged = null;
        public Color GetLinearColor(Color color, float intensity)
        {
            Color gammaColor = color * intensity;
            return new Vector4(Mathf.GammaToLinearSpace(gammaColor.r),
            Mathf.GammaToLinearSpace(gammaColor.g),
            Mathf.GammaToLinearSpace(gammaColor.b),
            intensity);
        }

        //获取Sky下的所有材质信息，运行时用实例材质，避免因修改本地文件引起svn更新冲突
        //public void GetAllMaterialsEditor()//editor变更skybox时需要获取skybox已有参数设置
        //{
        //    Transform[] all = SkyBox.GetComponentsInChildren<Transform>(true);
        //    foreach (var one in all)
        //    {
        //        if (one.name == "Sky")
        //        {
        //            SkyMaterialRenderer = one.GetComponent<Renderer>();
        //            SkyMaterialBase = SkyMaterialRenderer.sharedMaterial;
        //            if (SkyMaterialBase != null && SkyMaterialBase.shader.name == "TLStudio/SceneSkyCubemap")
        //            {
        //                skyHighOffset = SkyMaterialBase.GetFloat(ShaderPropertyToID._HighOffset_ID);
        //                skyHighScale = SkyMaterialBase.GetFloat(ShaderPropertyToID._HighScale_ID);
        //                SkyTintColor = SkyMaterialBase.GetColor(ShaderPropertyToID._TintColor_ID);
        //                SkyRotation = SkyMaterialBase.GetFloat(ShaderPropertyToID._Rotation_ID);
        //                SkyExposure = SkyMaterialBase.GetFloat(ShaderPropertyToID._Exposure_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Sky的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Sun")
        //        {
        //            SunMaterialRenderer = one.GetComponent<Renderer>();
        //            SunMaterialBase = SunMaterialRenderer.sharedMaterial;
        //            if (SunMaterialBase != null)
        //            {
        //                sunColor = SunMaterialBase.GetColor(ShaderPropertyToID._Tint_ID);
        //                sunSize = SunMaterialBase.GetFloat(ShaderPropertyToID._Size_ID);
        //                sunDirection = SunMaterialBase.GetVector(ShaderPropertyToID._WorldLightDir_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Sun的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Moon")
        //        {
        //            MoonMaterialRenderer = one.GetComponent<Renderer>();
        //            MoonMaterialBase = MoonMaterialRenderer.sharedMaterial;
        //            if (MoonMaterialBase != null)
        //            {
        //                moonColor = MoonMaterialBase.GetColor(ShaderPropertyToID._Tint_ID);
        //                moonSize = MoonMaterialBase.GetFloat(ShaderPropertyToID._Size_ID);
        //                moonDirection = MoonMaterialBase.GetVector(ShaderPropertyToID._WorldLightDir_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Moon的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "MilkyWay")
        //        {
        //            MilkywayMaterialRenderer = one.GetComponent<Renderer>();
        //            MilkywayMaterialBase = MilkywayMaterialRenderer.sharedMaterial;
        //            if (MilkywayMaterialBase != null)
        //            {
        //                milkywayColor = MilkywayMaterialBase.GetColor(ShaderPropertyToID._Tint_ID);
        //                milkywaySize = MilkywayMaterialBase.GetFloat(ShaderPropertyToID._Size_ID);
        //                milkywayDirection = MilkywayMaterialBase.GetVector(ShaderPropertyToID._WorldLightDir_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("MilkyWay的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Rainbow")
        //        {
        //            RainbowMaterialRenderer = one.GetComponent<Renderer>();
        //            RainbowMaterialBase = RainbowMaterialRenderer.sharedMaterial;
        //            if (RainbowMaterialBase != null)
        //            {
        //                rainbowIntensity = RainbowMaterialBase.GetFloat(ShaderPropertyToID._ColorLight_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Rainbow的材质丢失" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Cloud")
        //        {
        //            CloudMaterialRenderer = one.GetComponent<Renderer>();
        //            CloudMaterialBase = CloudMaterialRenderer.sharedMaterial;
        //            if (CloudMaterialBase != null)
        //            {
        //                cloudColor = CloudMaterialBase.GetColor(ShaderPropertyToID._CloudColor_ID);
        //                cloudCentColor = CloudMaterialBase.GetColor(ShaderPropertyToID._CenterColor_ID);
        //                cloudDensity = CloudMaterialBase.GetFloat(ShaderPropertyToID._Density_ID);
        //                cloudSize = CloudMaterialBase.GetFloat(ShaderPropertyToID._Size_ID);
        //                cloudBreak = CloudMaterialBase.GetFloat(ShaderPropertyToID._Break_ID);
        //                cloudCener = CloudMaterialBase.GetFloat(ShaderPropertyToID._Center_ID);
        //                cloudConcentration = CloudMaterialBase.GetFloat(ShaderPropertyToID._Concentration_ID);
        //                cloudSpeed = CloudMaterialBase.GetVector(ShaderPropertyToID._Speed_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Cloud的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Mountains")
        //        {
        //            MountainsMaterialRenderer = one.GetComponent<Renderer>();
        //            MountainsMaterialBase = MountainsMaterialRenderer.sharedMaterial;
        //            if (MountainsMaterialBase != null)
        //            {
        //                MountainsBaseLayerColor = MountainsMaterialBase.GetColor(ShaderPropertyToID._BaseLayerTint_ID);
        //                Mountains2ndLayerColor = MountainsMaterialBase.GetColor(ShaderPropertyToID._2ndLayerTint_ID);
        //                MountainsSideColor = MountainsMaterialBase.GetColor(ShaderPropertyToID._SkySideColor_ID);
        //                MountainsFogIntensity = MountainsMaterialBase.GetFloat(ShaderPropertyToID._FogIntensity_ID);
        //                MountainsSunShaftsColor = MountainsMaterialBase.GetColor(ShaderPropertyToID._MountainsSunShaftsColor_ID);
        //                MountainsSunShaftsSize = MountainsMaterialBase.GetFloat(ShaderPropertyToID._MountainsSunShaftsSize_ID);
        //            }
        //            else
        //            {
        //                Debug.LogError("Mountains的材质丢失！"+ SceneManager.GetActiveScene().name);
        //            }
        //        }
        //    }
        //    if (SeaCloudMaterial != null)
        //    {
        //        SeaCloudColor = SeaCloudMaterial.GetColor(ShaderPropertyToID._Color_ID);
        //        SeaCloudDownColor = SeaCloudMaterial.GetColor(ShaderPropertyToID._DownColor_ID);
        //        SeaCloudTiling = SeaCloudMaterial.GetFloat(ShaderPropertyToID._tiling_ID);
        //        SeaCloudDensity = SeaCloudMaterial.GetFloat(ShaderPropertyToID._CloudDensity_ID);
        //        SeaCloudPower = SeaCloudMaterial.GetFloat(ShaderPropertyToID._CloudPower_ID);
        //        SeaCloudFogIntensity = SeaCloudMaterial.GetFloat(ShaderPropertyToID._FogIntensity_ID);
        //    }
        //}

        //private void GetAllMaterials()
        //{
        //    Transform[] all = SkyBox.GetComponentsInChildren<Transform>(true);
        //    foreach (var one in all)
        //    {
        //        if (one.name == "Sky")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            SkyMaterialRenderer = one.GetComponent<Renderer>();
        //            SkyMaterialBase = SkyMaterialRenderer.sharedMaterial;
        //            if (SkyMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(SkyMaterialBase);
        //                    SkyMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Sky的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Sun")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            SunMaterialRenderer = one.GetComponent<Renderer>();
        //            SunMaterialBase = SunMaterialRenderer.sharedMaterial;
        //            if (SunMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(SunMaterialBase);
        //                    SunMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Sun的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Moon")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            MoonMaterialRenderer = one.GetComponent<Renderer>();
        //            MoonMaterialBase = MoonMaterialRenderer.sharedMaterial;
        //            if (MoonMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(MoonMaterialBase);
        //                    MoonMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Moon的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "MilkyWay")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            MilkywayMaterialRenderer = one.GetComponent<Renderer>();
        //            MilkywayMaterialBase = MilkywayMaterialRenderer.sharedMaterial;
        //            if (MilkywayMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(MilkywayMaterialBase);
        //                    MilkywayMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("MilkyWay的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Rainbow")
        //        {
        //            RainbowMaterialRenderer = one.GetComponent<Renderer>();
        //            RainbowMaterialBase = RainbowMaterialRenderer.sharedMaterial;
        //            if (RainbowMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(RainbowMaterialBase);
        //                    RainbowMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Rainbow的材质丢失" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Cloud")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            CloudMaterialRenderer = one.GetComponent<Renderer>();
        //            CloudMaterialBase = CloudMaterialRenderer.sharedMaterial;
        //            if (CloudMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(CloudMaterialBase);
        //                    CloudMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Cloud的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //        if (one.name == "Mountains")
        //        {
        //            one.transform.SetLocalScaleX(50000.0f);
        //            one.transform.SetLocalScaleY(50000.0f);
        //            one.transform.SetLocalScaleZ(50000.0f);
        //            MountainsMaterialRenderer = one.GetComponent<Renderer>();
        //            MountainsMaterialBase = MountainsMaterialRenderer.sharedMaterial;
        //            if (MountainsMaterialBase != null)
        //            {
        //                if (Application.IsPlaying(gameObject))
        //                {
        //                    one.GetComponent<Renderer>().material = new Material(MountainsMaterialBase);
        //                    MountainsMaterialInstance = one.GetComponent<Renderer>().material;
        //                }
        //            }
        //            else
        //            {
        //                Debug.LogError("Mountains的材质丢失！" + SceneManager.GetActiveScene().name);
        //            }
        //        }
        //    }
        //    if (RenderSettings.defaultReflectionMode == DefaultReflectionMode.Custom && RenderSettings.customReflection != null && !stormDay && globalCubemap == null)
        //    {
        //        globalCubemap = RenderSettings.customReflection;
        //    }
            
        //}

        //天空控制
        //private void ChangeSkyMaterial(Material Mat)
        //{
        //    if (Mat != null)
        //    {
        //        Mat.SetFloat(ShaderPropertyToID._HighOffset_ID, skyHighOffset);
        //        Mat.SetFloat(ShaderPropertyToID._HighScale_ID, skyHighScale);
        //        Mat.SetColor(ShaderPropertyToID._TintColor_ID, SkyTintColor);
        //        //Mat.SetVector("_SkyParameter", SkyParameter);
        //        //Mat.SetFloat("_WhichTime", SkyWhichTime);
        //        //Mat.SetFloat("_WhichWeather", SkyWhichWeather);
        //        //Mat.SetFloat("_TimeOrWeather", SkyTimeOrWeather);
        //        Mat.SetFloat(ShaderPropertyToID._Exposure_ID, SkyExposure);
        //        Mat.SetFloat(ShaderPropertyToID._Rotation_ID, SkyRotation);
        //    }
        //}

        ////太阳月亮控制
        //private void ChangeSunMoonMaterial(Material Mat, Color color, float size, Vector3 direction)
        //{
        //    if (Mat != null)
        //    {
        //        Mat.SetColor(ShaderPropertyToID._Tint_ID, color);
        //        Mat.SetFloat(ShaderPropertyToID._Size_ID, size);
        //        Mat.SetVector(ShaderPropertyToID._WorldLightDir_ID, direction);
        //        Mat.SetFloat(ShaderPropertyToID._SkyRotation_ID, SkyRotation);
        //    }
        //}

        ////彩虹控制
        //private void ChangeRainbowMaterial(Material Mat, float intensity)
        //{
        //    if (Mat != null)
        //    {
        //        Mat.SetFloat(ShaderPropertyToID._ColorLight_ID, intensity);
        //        if (RainbowMaterialRenderer != null && RainbowMaterialRenderer.gameObject != null)
        //        {
        //            RainbowMaterialRenderer.gameObject.SetActive(intensity > 0);
        //        }
        //    }
        //}

        ////云控制
        //private void ChangeCloudMaterial(Material Mat)
        //{
        //    if (Mat != null)
        //    {
        //        Mat.SetColor(ShaderPropertyToID._CloudColor_ID, cloudColor);
        //        Mat.SetColor(ShaderPropertyToID._CenterColor_ID, cloudCentColor);
        //        Mat.SetFloat(ShaderPropertyToID._Density_ID, cloudDensity);
        //        Mat.SetFloat(ShaderPropertyToID._Size_ID, cloudSize);
        //        Mat.SetFloat(ShaderPropertyToID._Break_ID, cloudBreak);
        //        Mat.SetFloat(ShaderPropertyToID._Center_ID, cloudCener);
        //        Mat.SetFloat(ShaderPropertyToID._Concentration_ID, cloudConcentration);
        //        cloudSpeed.x += cloudSpeedNSide.x * Time.deltaTime;
        //        cloudSpeed.y += cloudSpeedNSide.y * Time.deltaTime;
        //        cloudSpeed.z = cloudSpeedNSide.z;
        //        cloudSpeed.w = cloudSpeedNSide.w;
        //        Mat.SetVector(ShaderPropertyToID._Speed_ID, cloudSpeed);
        //    }
        //}

        ////远山控制
        //private void ChangeMountainsMaterial(Material Mat)
        //{
        //    if (Mat != null)
        //    {
        //        Mat.SetColor(ShaderPropertyToID._BaseLayerTint_ID, MountainsBaseLayerColor);
        //        Mat.SetColor(ShaderPropertyToID._2ndLayerTint_ID, Mountains2ndLayerColor);
        //        Mat.SetColor(ShaderPropertyToID._SkySideColor_ID, MountainsSideColor);
        //        Mat.SetFloat(ShaderPropertyToID._FogIntensity_ID, MountainsFogIntensity);
        //        Mat.SetColor(ShaderPropertyToID._MountainsSunShaftsColor_ID, MountainsSunShaftsColor);
        //        Mat.SetFloat(ShaderPropertyToID._MountainsSunShaftsSize_ID, MountainsSunShaftsSize);
        //    }
        //}

        //public Vector4 GetCharLightDir(Vector3 dir)
        //{
        //    Quaternion quat = Quaternion.Euler(dir.x, dir.y, dir.z);
        //    return quat * new Vector4(0.0f, 0.0f, -1.0f, 0.0f);
        //}

        #region VolumetricCloud

        public void SetVolumetricCloudQuality(bool HighQuality)
        {
            m_VolumetricCloudQuality = HighQuality;


            //如果当前有云在显示，则刷新一下
            if (enableVolumetricCloud)
            {
                SetVolumetricCloudVisiable(true);
            }
            else if (VolumetricCloudGOLow != null)
            {
                if (VolumetricCloudGOLow.activeSelf)
                {
                    SetVolumetricCloudVisiable(true);
                }
            }
        }


        public void SetVolumetricCloudVisiable(bool bVisiable)
        {
            if (m_VolumetricCloudQuality)
            {
                if (VolumetricCloudGO != null)
                {

                    if (m_VolumetricCloudComponent != null)
                    {
                        enableVolumetricCloud = bVisiable;
                        m_VolumetricCloudComponent.SetRenderingState(enableVolumetricCloud);

                    }

                }

                if (VolumetricCloudGOLow != null && VolumetricCloudGOLow.activeSelf == true)
                {
                    VolumetricCloudGOLow.SetActive(false);
                }
            }
            else
            {
                if (VolumetricCloudGO != null)
                {

                    if (m_VolumetricCloudComponent != null)
                    {
                        enableVolumetricCloud = false;
                        m_VolumetricCloudComponent.SetRenderingState(enableVolumetricCloud);
                    }

                }

                if (VolumetricCloudGOLow != null)
                {
                    VolumetricCloudGOLow.SetActive(bVisiable);
                }
            }
        }
        #endregion

        private void Awake()
        {
            //if (SkyBox != null)
            //{
            //    GetAllMaterials();
            //}

            //windZone = gameObject.GetComponent<WindZone>();

            //if (windZone == null)
            //{
            //    windZone = gameObject.AddComponent<WindZone>();
            //}

            //windTrans = gameObject.transform;

            Mainlight = GameObject.Find("Directional Light");
            if (Mainlight != null)
            {
                float originLightDirX = Mainlight.transform.rotation.eulerAngles.x;
                float originLightDirY = Mainlight.transform.rotation.eulerAngles.y;

                if (mainLightSpecularDirection == 0)
                {
                    mainLightSpecularDirection = originLightDirX;
                }

                if (mainLightSpecularDirectionY == 0)
                {
                    mainLightSpecularDirectionY = originLightDirY;
                }

            }

            if (VolumetricCloudGOLow != null)
            {
                VolumetricCloudGOLow.SetActive(false);
            }
        }

        private void OnEnable()
        {
            //Shader.DisableKeyword("_UICHAR");
            //_UpdateCharLightInfo();
//#if UNITY_EDITOR
            //if (/*IsShowLightAtten && */LightAttenTex != null)
            //{
            //    Shader.SetGlobalTexture(ShaderPropertyToID._LightAttenPhoto_ID, LightAttenTex);
            //    Shader.SetGlobalVector(ShaderPropertyToID._LightAttenParams_ID, LightAttenParams);
            //    //Shader.EnableKeyword("_LIGHT_ATTEN_ON");
            //}
            //else
            //{
            //    //Shader.DisableKeyword("_LIGHT_ATTEN_ON");
            //}

            //if (/*IsShowLightMap &&*/ LightMapTex != null)
            //{
            //    Shader.SetGlobalTexture(ShaderPropertyToID._LightMapPhoto_ID, LightMapTex);
            //    Shader.SetGlobalVector(ShaderPropertyToID._LightAttenParams_ID, LightAttenParams);
            //    //Shader.EnableKeyword("_LIGHTMAP_TEX_ON");
            //}
            //else
            //{
            //    //Shader.DisableKeyword("_LIGHTMAP_TEX_ON");
            //}
//#endif
            //if (GPUInstanceMeshList.Count > 0 && GPUInstanceMaterialList.Count > 0)
            //{
            //    GPUInstanceManager.LoadGPUInstanceByteDatas(InstanceDataFileName, GPUInstanceMeshList, GPUInstanceMaterialList,
            //        GPUInstanceLod1MeshList, GPUInstanceLod1MaterialList);
            //}

            //if (ProjectS.GameEntry.Event != null)
            //{
            //    if (m_OnQualitySettingChanged == null)
            //    {
            //        m_OnQualitySettingChanged = OnQualitySettingChanged;
            //    }
            //    ProjectS.GameEntry.Event.Subscribe(ProjectS.QualitySettingChangedEventArgs.EventId, m_OnQualitySettingChanged);
            //}
            m_InstanceList.Insert(0, this);


            if (m_VolumetricCloudComponent == null)
            {
                if(VolumetricCloudGO != null)
                {
                    m_VolumetricCloudComponent = VolumetricCloudGO.GetComponent<VolumetricCloud>();
                }
            }
        }

        private void OnDisable()
        {
            // 清零各种输入
            Shader.SetGlobalVector(ShaderPropertyToID._WindParam_ID, Vector4.zero);
            Shader.SetGlobalVector(ShaderPropertyToID.fillLightColor_ID, Vector4.zero);
            //Shader.SetGlobalVector("fillLightColor1", Vector4.zero);
            //Shader.SetGlobalFloat("_GIDiffuseScale", 0);
            Shader.SetGlobalFloat(ShaderPropertyToID._ExposureFX_ID, 0);
            Shader.SetGlobalVector(ShaderPropertyToID._CharLightColor_ID, Vector4.zero);
            Shader.SetGlobalVector(ShaderPropertyToID._CharFillLightColor_ID, Vector4.zero);
            Shader.SetGlobalVector(ShaderPropertyToID._UICharLightColor_ID, Vector4.zero);
            Shader.SetGlobalVector(ShaderPropertyToID._UICharFillLightColor_ID, Vector4.zero);
            Shader.SetGlobalFloat(ShaderPropertyToID._GlobalEnvIntensity_ID, 1f);
            Shader.SetGlobalTexture(ShaderPropertyToID._SkinProfile_ID, null);
            Shader.SetGlobalTexture(ShaderPropertyToID._GrassNoise_ID, null);
            Shader.SetGlobalVector(ShaderPropertyToID._GrassWindControl_ID, Vector4.zero);
            //Shader.SetGlobalVector("_GrassWaveControl", Vector4.zero);
            Shader.SetGlobalFloat(ShaderPropertyToID._ShadowAttenFactor_ID, 0f);
            Shader.SetGlobalFloat(ShaderPropertyToID._GrassShadowAttenFactor_ID, 0f);
            Shader.SetGlobalVector(ShaderPropertyToID._CharHairLightColor_ID, Vector4.zero);
            Shader.SetGlobalFloat(ShaderPropertyToID._rainIntensity_ID, 0f);
            Shader.SetGlobalFloat(ShaderPropertyToID._rainSmoothness_ID, 0f);
            Shader.SetGlobalFloat(ShaderPropertyToID._EmissionIntensityMax_ID, 0);
            Shader.SetGlobalColor(ShaderPropertyToID._AmbientTop_ID, Vector4.zero);
            Shader.SetGlobalColor(ShaderPropertyToID._AmbinetDown_ID, Vector4.zero);

            //GPUInstanceManager.UnloadGPUInstanceData();
            ////if (m_OnQualitySettingChanged == null)
            ////{
            ////    m_OnQualitySettingChanged = OnQualitySettingChanged;
            ////}
            ////if (ProjectS.GameEntry.Event != null && ProjectS.GameEntry.Event.Check(ProjectS.QualitySettingChangedEventArgs.EventId, m_OnQualitySettingChanged))
            ////{
            ////    ProjectS.GameEntry.Event.Unsubscribe(ProjectS.QualitySettingChangedEventArgs.EventId, m_OnQualitySettingChanged);
            ////}
            //for (int i = 0; i < m_InstanceList.Count; i++)
            //{
            //    if (m_InstanceList[i] == this)
            //    {
            //        m_InstanceList.RemoveAt(i);
            //        break;
            //    }
            //}
        }
        //public float springBoneWindMain = 1f;
        ////public float springBoneWindTurb = 1f;
        //public float springBoneWindPluseMagnitude = 0.5f;
        //public float springBoneWindPluseFrequency = 0.5f;
        //private void SpringManagerWind()
        //{
        //    Vector3 forward = windTrans.forward;
        //    forward.y = 0;
        //    //forward *= Mathf.PerlinNoise(Time.time, 0.0f) * windZone.windMain * 0.005f;
        //    Vector3 windForce = forward;

        //    float time = Time.timeSinceLevelLoad;
        //    //SetGlobalShaderParam();
        //    float windPhase = time * 3.14f * springBoneWindPluseFrequency * 3;
        //    float pulse = (Mathf.Cos(windPhase) + Mathf.Cos(windPhase * 0.375f) + Mathf.Cos(windPhase * 0.05f)) * 0.333f;
        //    pulse = 1.0f + (pulse * springBoneWindPluseMagnitude * 2);
        //    SpringManager.SpringManager.windForce = forward * springBoneWindMain * pulse * 0.126f;
        //    SpringManager.SpringManager.selfWindForce = GetUISpringManagerWind();
        //}
        //private Vector3 GetUISpringManagerWind()
        //{
        //    Vector3 forward = new Vector3(0,-90f,0);
        //    forward.y = 0;
        //    //forward *= Mathf.PerlinNoise(Time.time, 0.0f) * windZone.windMain * 0.005f;
        //    Vector3 windForce = forward;

        //    float time = Time.timeSinceLevelLoad;
        //    //SetGlobalShaderParam();
        //    float windPhase = time * 3.14f * 1.5f;
        //    float pulse = (Mathf.Cos(windPhase) + Mathf.Cos(windPhase * 0.375f) + Mathf.Cos(windPhase * 0.05f)) * 0.333f;
        //    pulse = 1.0f + pulse;
        //    return forward * pulse * 0.126f;
        //}
        // Update is called once per frame
        private void Update()
        {
            //SpringManagerWind();
            //float time = Time.timeSinceLevelLoad;
            ////SetGlobalShaderParam();
            //float windPhase = time * 3.14f * windZone.windPulseFrequency;
            //float pulse = (Mathf.Cos(windPhase) + Mathf.Cos(windPhase * 0.375f) + Mathf.Cos(windPhase * 0.05f)) * 0.333f;
            //pulse = 1.0f + (pulse * windZone.windPulseMagnitude);
            //float power = pulse;

            //Vector3 forward = windTrans.forward;
            //Vector4 wind = new Vector4(forward.x, forward.z, windZone.windMain * power, windZone.windTurbulence * power);
            //Shader.SetGlobalVector(ShaderPropertyToID._WindParam_ID, wind);
            //treespeed += windZone.windPulseFrequency * Time.deltaTime;//树的抖动频率不能直接乘在time上，在拖动频率值或者lerp插值频率值时会出现树抖动
            ////wind = new Vector4(forward.x * windZone.windMain * power, forward.y * windZone.windMain * power,
            ////    forward.z * windZone.windMain * power, windZone.windTurbulence * power);
            ////Shader.SetGlobalVector("_WindParamImproved", wind);
            //Vector4 _WindZoneParams = new Vector4(windZone.windMain, windZone.windTurbulence,
            //    windZone.windPulseMagnitude, treespeed);
            //Shader.SetGlobalVector(ShaderPropertyToID._WindZoneParams_ID, _WindZoneParams);
            //Shader.SetGlobalVector(ShaderPropertyToID._WindZoneDir_ID, forward);

            //Color color, linearColor;

            //天空盒控制
            //if (SkyBox != null)
            //{
            //    if (Application.IsPlaying(gameObject))
            //    {
            //        ChangeSkyMaterial(SkyMaterialInstance);
            //        ChangeSunMoonMaterial(SunMaterialInstance, sunColor, sunSize, sunDirection);
            //        ChangeSunMoonMaterial(MoonMaterialInstance, moonColor, moonSize, moonDirection);
            //        ChangeSunMoonMaterial(MilkywayMaterialInstance, milkywayColor, milkywaySize, milkywayDirection);
            //        ChangeRainbowMaterial(RainbowMaterialInstance, rainbowIntensity);
            //        ChangeCloudMaterial(CloudMaterialInstance);
            //        ChangeMountainsMaterial(MountainsMaterialInstance);
            //    }
            //    else
            //    {
            //        ChangeSkyMaterial(SkyMaterialBase);
            //        ChangeSunMoonMaterial(SunMaterialBase, sunColor, sunSize, sunDirection);
            //        ChangeSunMoonMaterial(MoonMaterialBase, moonColor, moonSize, moonDirection);
            //        ChangeSunMoonMaterial(MilkywayMaterialBase, milkywayColor, milkywaySize, milkywayDirection);
            //        ChangeRainbowMaterial(RainbowMaterialBase, rainbowIntensity);
            //        ChangeCloudMaterial(CloudMaterialBase);
            //        ChangeMountainsMaterial(MountainsMaterialBase);
            //    }
            //    Shader.SetGlobalFloat(ShaderPropertyToID._StarStrength_ID, starsStrength);
            //}

            //if (SeaCloudMaterial != null)
            //{
            //    SeaCloudMaterial.SetColor(ShaderPropertyToID._Color_ID, SeaCloudColor);
            //    SeaCloudMaterial.SetColor(ShaderPropertyToID._DownColor_ID, SeaCloudDownColor);
            //    SeaCloudMaterial.SetFloat(ShaderPropertyToID._tiling_ID, SeaCloudTiling);
            //    SeaCloudMaterial.SetFloat(ShaderPropertyToID._CloudDensity_ID, SeaCloudDensity);
            //    SeaCloudMaterial.SetFloat(ShaderPropertyToID._CloudPower_ID, SeaCloudPower);
            //    SeaCloudMaterial.SetFloat(ShaderPropertyToID._FogIntensity_ID, SeaCloudFogIntensity);
            //}


            if(VolumetricCloudGO != null)
            {
                //if(enableVolumetricCloud != VolumetricCloudGO.activeSelf)
                //{
                //    VolumetricCloudGO.SetActive(enableVolumetricCloud);
                //}

                if(m_VolumetricCloudComponent != null)
                {
                    if(enableVolumetricCloud)
                    {
                        m_VolumetricCloudComponent.DoUpdateParameters(CloudMainLightColor, CloudColor, CloudMainLightDirection, CloudTilling, Radius, CloudHeight, MaxTop, CurrentTop, MaxBottom, CurrentBottom, Speed, Density, MainLightIntensity, glossyIntensity, NoiseTilling, NoiseIntensity, SoftEdge, Border, VolumetricCloudBaseHeight, AtmosphereColorSaturateDistance, AtmosphereColor);
                    }

                    m_VolumetricCloudComponent.SetRenderingState(enableVolumetricCloud);
                }

            }

            //if (Shafts != null)
            //{
            //    //太阳不可见时跟月亮，其他全部跟太阳
            //    if (sunColor.a == 0)
            //    {
            //        Vector3 shaftsDirectionMoon = moonDirection;
            //        shaftsDirectionMoon.y -= SkyRotation;
            //        Shafts.transform.rotation = Quaternion.Euler(shaftsDirectionMoon);
            //        shaftsDirection = shaftsDirectionMoon;
            //    }
            //    else
            //    {
            //        Vector3 shaftsDirectionSun = sunDirection;
            //        shaftsDirectionSun.y -= SkyRotation;
            //        Shafts.transform.rotation = Quaternion.Euler(shaftsDirectionSun);
            //        shaftsDirection = shaftsDirectionSun;
            //    }
            //}
            //if (sceneFillLight != null)
            //{
            //color = FillLightColor;
            //linearColor = new Vector4(Mathf.GammaToLinearSpace(color.r),
            //Mathf.GammaToLinearSpace(color.g),
            //Mathf.GammaToLinearSpace(color.b),
            //color.a);

            //Shader.SetGlobalVector(ShaderPropertyToID.fillLightColor_ID, linearColor);
            //Shader.SetGlobalColor(ShaderPropertyToID.TreeAmbientTop_ID, TreeAmbientTop);
            //Shader.SetGlobalColor(ShaderPropertyToID.TreeAmbientMiddle_ID, TreeAmbientMiddle);
            //Shader.SetGlobalColor(ShaderPropertyToID.TreeAmbientDown_ID, TreeAmbientDown);
            //Shader.SetGlobalVector("fillLightDir", -sceneFillLight.transform.forward);
            //}
            //else
            //{
            //    Shader.SetGlobalVector("fillLightColor", Vector4.zero);
            //}

            //if (sceneFillLight1 != null)
            //{
            //    color = sceneFillLight1.color * sceneFillLight1.intensity * sceneFillLightGlobalIntensity;
            //    linearColor = new Vector4(Mathf.GammaToLinearSpace(color.r),
            //    Mathf.GammaToLinearSpace(color.g),
            //    Mathf.GammaToLinearSpace(color.b),
            //    sceneFillLight1.intensity);

            //    Shader.SetGlobalVector("fillLightColor1", linearColor);
            //    Shader.SetGlobalVector("fillLightDir1", -sceneFillLight1.transform.forward);
            //}
            //else
            //{
            //    Shader.SetGlobalVector("fillLightColor1", Vector4.zero);
            //}
            //FillLightScale = 1.0f;
            //Shader.SetGlobalFloat("_GIDiffuseScale", FillLightScale);

            Shader.SetGlobalVector(ShaderPropertyToID._AOParam_ID, new Vector4(globalAOScale, globalAOIntensity, 0, 0));

            Shader.SetGlobalFloat(ShaderPropertyToID._ExposureFX_ID, exposureFX);

            // 20181015 由于在游戏中UI角色需要不同的光照条件，所以这里不做全局设置，在游戏里直接设置到material中，在编辑器里通过OnValidate进行设置
            //Quaternion quat = Quaternion.Euler(charMainLightDir.x, charMainLightDir.y, charMainLightDir.z);
            //Vector4 dir = quat * new Vector4(0.0f, 0.0f, -1.0f, 0.0f);

            //color = charMainLightColor * charMainLightIntensity;
            //linearColor = new Vector4(Mathf.GammaToLinearSpace(color.r),
            //Mathf.GammaToLinearSpace(color.g),
            //Mathf.GammaToLinearSpace(color.b),
            //charMainLightIntensity);

            //Shader.SetGlobalVector("_CharLightColor", linearColor);
            //Shader.SetGlobalVector("_CharLightDir", dir);

            //quat = Quaternion.Euler(charFillLightDir.x, charFillLightDir.y, charFillLightDir.z);
            //dir = quat * new Vector4(0.0f, 0.0f, -1.0f, 0.0f);

            //Shader.SetGlobalVector("_CharFillLightDir", dir);

            //color = charFillLightColor * charFillLightIntensity;
            //linearColor = new Vector4(Mathf.GammaToLinearSpace(color.r),
            //Mathf.GammaToLinearSpace(color.g),
            //Mathf.GammaToLinearSpace(color.b),
            //charFillLightIntensity);

            //Shader.SetGlobalColor("_CharFillLightColor", linearColor);
            //_UpdateCharLightInfo();
            Shader.SetGlobalFloat(ShaderPropertyToID._GlobalEnvIntensity_ID, charGlobalEnvIntensity);
            Shader.SetGlobalTexture(ShaderPropertyToID._SkinProfile_ID, charSkinProfile);
            Shader.SetGlobalFloat(ShaderPropertyToID._ShadowAttenFactor_ID, charShadowAtten);
            Shader.SetGlobalColor(ShaderPropertyToID._SkinShadowColor_ID, charShadowColor);

            //Shader.SetGlobalFloat(ShaderPropertyToID._GrassShadowAttenFactor_ID, grassShadowAtten);
            if (stormDay)
            {
                //雨的代码在代码里通过lod控制
                Shader.SetGlobalFloat(ShaderPropertyToID._rainIntensity_ID, rainIntensity);
                Shader.SetGlobalFloat(ShaderPropertyToID._rainSmoothness_ID, rainSmoothness);
                Shader.SetGlobalFloat(ShaderPropertyToID._CharRainSmoothness_ID, charRainSmoothness);
                Shader.SetGlobalFloat(ShaderPropertyToID._flowRate_ID, rainflowRate);
                Shader.SetGlobalFloat(ShaderPropertyToID._rainTiling_ID, rainTiling);
                Shader.SetGlobalTexture(ShaderPropertyToID._rainRipple_ID, rainRipple);
                Shader.SetGlobalVector(ShaderPropertyToID._rippleConfig_ID, rippleConfig);
                if (rainCubemap != null && RenderSettings.defaultReflectionMode == DefaultReflectionMode.Custom)
                {
                    RenderSettings.customReflection = rainCubemap;
                }
                Shader.SetGlobalVector(ShaderPropertyToID._snowCameraSet_ID, SnowCameraSet);
                Shader.SetGlobalFloat(ShaderPropertyToID._SnowTexConfig_ID, SnowTexConfig);
                if (SnowDepthTex == null) SnowDepthTex = Texture2D.blackTexture;//没深度图的时候保证有雪
                Shader.SetGlobalTexture(ShaderPropertyToID._SnowDepth_ID, SnowDepthTex); 
                Shader.SetGlobalInt(ShaderPropertyToID._SkinRaindrop_ID, 1);
                //Shader.SetGlobalTexture("_RainNormal", rainNormal);
                //Shader.SetGlobalTexture("_RainCharNormal", rainCharNormal);
            }
            else
            {

                Shader.SetGlobalFloat(ShaderPropertyToID._rainIntensity_ID, 0);
                Shader.SetGlobalFloat(ShaderPropertyToID._rainSmoothness_ID, 0f);
                Shader.SetGlobalInt(ShaderPropertyToID._SkinRaindrop_ID, 0);
                if (globalCubemap != null && RenderSettings.defaultReflectionMode == DefaultReflectionMode.Custom)
                {
                    RenderSettings.customReflection = globalCubemap;
                }
            }
            //if (snowDay)
            //{
            //    if (Shader.globalMaximumLOD >= 300)//雪的代码因为控制的东西很多,有的没有lod,所以通过参数控制
            //    {
            //         Shader.SetGlobalFloat(ShaderPropertyToID._snowCoverage_ID, snowCoverage);

            //        Shader.SetGlobalColor(ShaderPropertyToID._SnowColor_ID, snowColor);
            //        Shader.SetGlobalVector(ShaderPropertyToID._snowCameraSet_ID, SnowCameraSet);
            //        Shader.SetGlobalFloat(ShaderPropertyToID._SnowTexConfig_ID, SnowTexConfig);
            //        if (SnowDepthTex == null) SnowDepthTex = Texture2D.blackTexture;//没深度图的时候保证有雪
            //        Shader.SetGlobalTexture(ShaderPropertyToID._SnowDepth_ID, SnowDepthTex);
            //        Shader.SetGlobalTexture(ShaderPropertyToID._SnowNoise_ID, SnowNoise);
            //        Shader.SetGlobalVector(ShaderPropertyToID._SnowTerrainConfigA_ID, SnowTerrainConfigA);
            //        Shader.SetGlobalVector(ShaderPropertyToID._SnowTerrainConfigB_ID, SnowTerrainConfigB);

            //    }
            //    else
            //    {
            //        Shader.SetGlobalFloat(ShaderPropertyToID._snowCoverage_ID, 0);
            //    }

            //}
            //else
            //{
            //    Shader.SetGlobalFloat(ShaderPropertyToID._snowCoverage_ID, 0);
            //}
            Shader.SetGlobalFloat(ShaderPropertyToID._SnowHeight_ID, snowHeight);//常驻的雪高度,这样缥缈峰的脚印就有参数了

//            Shader.SetGlobalColor(ShaderPropertyToID._GrassSnowColor_ID, grassSnowColor);
//            Shader.SetGlobalColor(ShaderPropertyToID._GrassSnowDarkFaceColor_ID, grassSnowDarkFaceColor);
////#if UNITY_EDITOR
//            if (/*IsShowLightAtten &&*/ LightAttenTex != null)
//            {
//                Shader.SetGlobalTexture(ShaderPropertyToID._LightAttenPhoto_ID, LightAttenTex);
//                Shader.SetGlobalVector(ShaderPropertyToID._LightAttenParams_ID, LightAttenParams);
//                //Shader.EnableKeyword("_LIGHT_ATTEN_ON");
//            }
//            else
//            {
//                //Shader.DisableKeyword("_LIGHT_ATTEN_ON");
//            }


//            if(/*IsShowLightMap &&*/ LightMapTex != null)
//            {
//                Shader.SetGlobalTexture(ShaderPropertyToID._LightMapPhoto_ID, LightMapTex);
//                Shader.SetGlobalVector(ShaderPropertyToID._LightAttenParams_ID, LightAttenParams);
//                //Shader.EnableKeyword("_LIGHTMAP_TEX_ON");
//            }
//            else
//            {
//                //Shader.DisableKeyword("_LIGHTMAP_TEX_ON");
//            }
//#endif

            Shader.SetGlobalFloat(ShaderPropertyToID._EmissionIntensityMax_ID, emissionIntensity);
            Shader.SetGlobalColor(ShaderPropertyToID._UnlitGlobalLightColor_ID, GlobalLightColor);
            Shader.SetGlobalFloat(ShaderPropertyToID._GlobalLeafAOIntensity_ID, GlobalLeafAOIntensity);
            Shader.SetGlobalFloat(ShaderPropertyToID._HLODlightIntensity_ID, GlobalHLODLightIntensity);
            Shader.SetGlobalFloat(ShaderPropertyToID._MainLightSpecularIntensity_ID, mainLightSpecularIntensity);
            Shader.SetGlobalFloat(ShaderPropertyToID._MainLightDiffuseAO_ID, mainLightDiffuseAO);

            //if (Mainlight != null)
            //{
            //    mainLightRotation.x = mainLightSpecularDirection;
            //    mainLightRotation.y = mainLightSpecularDirectionY;
            //    mainLightRotation.z = Mainlight.transform.rotation.eulerAngles.z;
            //    Shader.SetGlobalVector(ShaderPropertyToID._MainLightSpecularDirection_ID, GetCharLightDir(mainLightRotation));
            //}
            
            ////UpdateWater();

            //Shader.SetGlobalTexture(ShaderPropertyToID._GrassNoise_ID, grassNoise);
            //Shader.SetGlobalVector(ShaderPropertyToID._GrassWindControl_ID, grassWindControl);
            //Shader.SetGlobalVector("_GrassWaveControl", grassWaveControl);
            //if (GPUInstanceQualityList.Count > (int)GrassQualityLevelType)
            //{
            //    GPUInstanceManager.QualitySettings = GPUInstanceQualityList[(int)GrassQualityLevelType];
            //    GPUInstanceManager.UpdateGPUInstance();
            //}

//#if UNITY_EDITOR
//            GPUInstanceManager.IsDrawGizmo = IsDrawGizmo;
//            Shader.EnableKeyword("_PLAYER");
//#endif

//            if (DynamicPointLightManager.Self.DynamicPointLight && DynamicPointLightManager.s_InitialInternalData)
//            {
//                if (this == Instance && DynamicPointLightManager.Self.GlobalLightIntensity != GlobalDynamicPointLightIntensity)
//                { 
//                    DynamicPointLightManager.Self.GlobalLightIntensity = GlobalDynamicPointLightIntensity;
//                    DynamicPointLightManager.Self.UpdateDynamicPointLightData();
//                }
//            }
        }

//        private void UpdateWater()
//        {
//#if UNITY_IOS || UNITY_ANDROID
//            Shader.SetGlobalColor(ShaderPropertyToID._WaterEnvColor_ID, waterEnvColor * 5.657f);//如果是移动平台,因为是hdr图,所以手动修亮图片.系数是2的2.5次方,满足效果
//#else
//            Shader.SetGlobalColor(ShaderPropertyToID._WaterEnvColor_ID, waterEnvColor);
//#endif
//            Shader.SetGlobalColor(ShaderPropertyToID._WaterSpecColor_ID, waterSpecColor);

//            Shader.SetGlobalFloat(ShaderPropertyToID._DepthFactor_ID, waterDepthFactor);
//        }

//        private void OnValidate()
//        {
//            _UpdateCharLightInfo();
//        }

//        private void _UpdateCharLightInfo()
//        {

//#if UNITY_EDITOR
//            float tempcharMainLightIntensity = charMainLightIntensity;
//            if (!Application.isPlaying)
//            {
//                tempcharMainLightIntensity = charMainLightIntensity + lightAdditionalRate * charMainLightIntensityAdditional;
//            }

//            actualCharMainLightColor = GetLinearColor(charMainLightColor, tempcharMainLightIntensity);
//#else
//            actualCharMainLightColor = GetLinearColor(charMainLightColor, charMainLightIntensity);
//#endif

//            if (MainLight2CharLight != null)
//            {
//                charMainLightDir = MainLight2CharLight.transform.rotation.eulerAngles;
//                charFillLightDir = MainLight2CharLight.transform.rotation.eulerAngles + MainLight2CharFillLight;
//            }
//            actualCharMainLightDir = GetCharLightDir(charMainLightDir);
//            actualCharUIMainLightColor = GetLinearColor(charUIMainLightColor, charUIMainLightIntensity);
//            actualCharUIMainLightDir = GetCharLightDir(charUIMainLightDir);

//            charMainLightSpecularRotation.x = charMainLightSpecularDirection;
//            charMainLightSpecularRotation.y = charMainLightDir.y;
//            charMainLightSpecularRotation.z = charMainLightDir.z;
//            Shader.SetGlobalVector(ShaderPropertyToID._CharMainLightSpecularDirection_ID, GetCharLightDir(charMainLightSpecularRotation));

//            Shader.SetGlobalColor(ShaderPropertyToID._AmbientTop_ID, charAmbientTop);
//            Shader.SetGlobalColor(ShaderPropertyToID._AmbinetDown_ID, charAmbientDown);

//            Shader.SetGlobalVector(ShaderPropertyToID._CharLightColor_ID, actualCharMainLightColor);
//            Shader.SetGlobalVector(ShaderPropertyToID._CharLightDir_ID, actualCharMainLightDir);
//            Shader.SetGlobalVector(ShaderPropertyToID._UICharLightColor_ID, actualCharUIMainLightColor);
//            Shader.SetGlobalVector(ShaderPropertyToID._UICharLightDir_ID, actualCharUIMainLightDir);
//            Shader.SetGlobalVector(ShaderPropertyToID._CharHairLightColor_ID, actualCharMainLightColor);
//            Shader.SetGlobalVector(ShaderPropertyToID._UICharHairLightColor_ID, actualCharUIMainLightColor);

//            Shader.SetGlobalColor(ShaderPropertyToID._UICharAmbientTop_ID,  charUIAmbientTop);
//            Shader.SetGlobalColor(ShaderPropertyToID._UICharAmbinetDown_ID, charUIAmbientDown);

//            Shader.SetGlobalFloat(ShaderPropertyToID._CharToneMapping_ID, charToneMapping);
//#if UNITY_EDITOR
//            float tempcharFillLightIntensity = charFillLightIntensity;
//            if (!Application.isPlaying)
//            {
//                tempcharFillLightIntensity = charFillLightIntensity + lightAdditionalRate * charFillLightIntensityAdditional;
//            }

//            actualCharFillLightColor = GetLinearColor(charFillLightColor, tempcharFillLightIntensity);
//#else
//            actualCharFillLightColor = GetLinearColor(charFillLightColor, charFillLightIntensity);
//#endif

//            actualCharFillLightDir = GetCharLightDir(charFillLightDir);
//            actualCharUIFillLightColor = GetLinearColor(charUIFillLightColor, charUIFillLightIntensity);
//            actualCharUIFillLightDir = GetCharLightDir(charUIFillLightDir);

//            Shader.SetGlobalVector(ShaderPropertyToID._CharFillLightColor_ID, actualCharFillLightColor);
//            Shader.SetGlobalVector(ShaderPropertyToID._CharFillLightDir_ID, actualCharFillLightDir);
//            Shader.SetGlobalVector(ShaderPropertyToID._UICharFillLightColor_ID, actualCharUIFillLightColor);
//            Shader.SetGlobalVector(ShaderPropertyToID._UICharFillLightDir_ID, actualCharUIFillLightDir);
//        }
    }
}
