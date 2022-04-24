using System.Collections.Generic;
using UnityEngine;

namespace TLStudio
{
    [ExecuteInEditMode]
    public class VolumetricCloud : MonoBehaviour
    {

        Camera m_CurrentCamera;

        public Material m_VolumetricClouMaterial;

        private MeshFilter m_MeshFilter;
        private MeshRenderer m_MeshRenderer;

        private Vector3 m_CloudLightDir;

        private Mesh m_CircleMesh;

        private Mesh m_QuadMesh;
        private Matrix4x4 m_VPosToLastScreenMatrix;
        private Vector2 m_LastCameraPos = new Vector2(0.0f, 0.0f);
        private Vector2 m_AccumulateUVOffset = new Vector2(0f, 0f);


        private Color m_MainLightColor = Color.white;
        private Color m_CloudColor = Color.white;
        private Vector3 m_MainLightDirection = Vector3.one;
        private Vector3 m_BaseTilling = new Vector3(0.08f, 0.2f, 0.08f);
        private float m_Radius = 1000.0f;
        private float m_CloudHeight = 2.0f;
        private float m_MaxTop = 1000.0f;
        private float m_CurrentTop = 100.0f;
        private float m_MaxBottom = -200.0f;
        private float m_CurrentBottom = -100.0f;
        private float m_Speed = 30.0f;
        private float m_Density = 1.0f;
        private float m_MainLightIntensity = 1.0f;
        private float m_GlossIntensity = 1.0f;
        private float m_NoiseTilling = 0.3f;
        private float m_NoiseIntensity = 1.5f;
        private float m_SoftEdge = 1.0f;
        private float m_Border = 0.8f;
        private float m_AtmosphereColorSaturateDistance = 1000.0f;
        private Color m_AtmosphereColor;
        private Vector4 m_VolumetricCloudSpeed = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);
        private float m_VolumetricCloudBaseHeight = 100.0f;

        // Start is called before the first frame update
        void Start()
        {
            transform.localScale = new Vector3(0.0f, 0.0f, 0.0f);
            m_MeshFilter = base.GetComponent<MeshFilter>();
            GenerateCircleMesh(1, 24);
            GenerateQuadMesh();
            m_MeshRenderer = GetComponent<MeshRenderer>();
            m_VPosToLastScreenMatrix = Matrix4x4.identity;
            m_CurrentCamera = Camera.main;
        }

        //public void DoUpdateParameters(Camera cam, )
        private void OnEnable()
        {
            if (m_CurrentCamera == null)
            {
                m_CurrentCamera = Camera.main;
            }




#if UNITY_ANDROID && !UNITY_EDITOR
        Debug.Log("Volumetric Cloud Set Key Word : _ANDROID");
        m_VolumetricClouMaterial.EnableKeyword("_ANDROID");
        if (m_VolumetricClouMaterial.IsKeywordEnabled("_ANDROID"))
        {
            Debug.Log("Volumetric Cloud Set Key Word '_ANDROID' success.");
        }
        else
        {
            Debug.Log("Volumetric Cloud Set Key Word '_ANDROID' failed.");
        }        
#endif
        }

        private void OnDestroy()
        {
#if !UNITY_EDITOR
        if(m_MeshFilter != null)
        {
            UnityEngine.Object.DestroyImmediate(m_MeshFilter.sharedMesh);
        }
#endif
        }

        public void DoUpdateParameters(
            Color mainlightColor,
            Color cloudColor,
            Vector3 mainLightDirection,
            Vector3 BaseTilling,
            float radius,
            float cloudHeight,
            float maxTop,
            float currentTop,
            float maxBottom,
            float currentBottom,
            float speed,
            float density,
            float mainLightIntensity,
            float glossIntensity,
            float noiseTilling,
            float noiseIntensity,
            float softEdge,
            float border,
            float VolumetricCloudBaseHeight,
            float AtmosphereColorSaturateDistance,
            Color AtmosphereColor
            )
        {
            m_MainLightColor = mainlightColor;
            m_CloudColor = cloudColor;
            m_MainLightDirection = mainLightDirection;
            m_BaseTilling = BaseTilling;
            m_CloudHeight = cloudHeight;
            m_MaxTop = maxTop;
            m_CurrentTop = currentTop;
            m_MaxBottom = maxBottom;
            m_CurrentBottom = currentBottom;
            m_Speed = speed;
            m_Density = density;
            m_MainLightIntensity = mainLightIntensity;
            m_GlossIntensity = glossIntensity;
            m_NoiseTilling = noiseTilling;
            m_NoiseIntensity = noiseIntensity;
            m_SoftEdge = softEdge;
            m_Border = border;
            m_VolumetricCloudBaseHeight = VolumetricCloudBaseHeight;
            m_AtmosphereColorSaturateDistance = AtmosphereColorSaturateDistance;
            m_AtmosphereColor = AtmosphereColor;

        }


        public void SetRenderingState(bool enable)
        {
            if (m_MeshRenderer)
            {
                if (m_MeshRenderer.enabled != enable)
                    m_MeshRenderer.enabled = enable;
            }
        }

        public bool GetRenderingState()
        {
            if (m_MeshRenderer)
            {
                return m_MeshRenderer.enabled;
            }

            return false;
        }

        private void LateUpdate()
        {
            if (m_CurrentCamera == null)
            {
                m_CurrentCamera = Camera.main;
                if (m_CurrentCamera == null)
                {
                    return;
                }
            }

            if(m_VolumetricClouMaterial == null)
            {
                return;
            }

            UnityEngine.Profiling.Profiler.BeginSample("Volumetric Cloud parameter update");

            Vector3 t_CamPos = m_CurrentCamera.transform.position;
            Vector3 forward = m_CurrentCamera.transform.forward;
            float t_density = m_Density * 0.001f;                                     // num1
            float t_height = m_CloudHeight + m_VolumetricCloudBaseHeight;                                           // num2

            if (t_density <= 0.0f)
            {
                m_MeshRenderer.enabled = false;
            }
            else
            {
                float t_Tilling_y = 1.0f / m_BaseTilling.y * 100.0f;                 // t_Tilling_y
                float t_Relative_Height_Down = t_CamPos.y - t_height - t_Tilling_y;          // nun4
                float t_Relative_Height_Up = t_Relative_Height_Down + t_Tilling_y * 2.0f;                  // t_CamPos.y - t_height + t_Tilling_y;
                float t_Hg = 0.9f;

                bool t_bReverse;
                float t_Height_Middle_Value;

                if (t_Relative_Height_Down >= m_MaxTop)
                {
                    t_bReverse = false;
                    t_Height_Middle_Value = m_CurrentTop;
					Debug.LogError("======================01t_Height_Middle_Value:"+t_Height_Middle_Value + " :"+t_Relative_Height_Down);
                }
                else if (t_Relative_Height_Down >= 0.0f)
                {
                    t_bReverse = false;
                    float t_Height_Down_Percentage = t_Relative_Height_Down / m_MaxTop;
                    t_Height_Middle_Value = m_CurrentTop * t_Height_Down_Percentage;
					Debug.LogError("======================02t_Relative_Height_Down:"+t_Relative_Height_Down + " :"+t_Relative_Height_Down);
                }
                else if (t_Relative_Height_Down >= -t_Tilling_y)
                {
                    t_bReverse = false;
                    t_Height_Middle_Value = t_Relative_Height_Down;
                    float t = 1f + t_Relative_Height_Down / t_Tilling_y;
                    t_Hg = Mathf.Lerp(0.3f, 0.9f, t);
					Debug.LogError("======================03t_Height_Middle_Value:"+t_Height_Middle_Value + " :"+t_Relative_Height_Down);
                }
                else if (t_Relative_Height_Up >= 0.0f)
                {
                    t_bReverse = true;
                    t_Height_Middle_Value = t_Relative_Height_Down + t_Tilling_y;
                    float t2 = 1f - t_Relative_Height_Up / t_Tilling_y;
                    t_Hg = Mathf.Lerp(0.3f, 0.9f, t2);
					Debug.LogError("======================04t_Relative_Height_Up:"+t_Relative_Height_Up + " :"+t_Relative_Height_Down);
                }
                else if (t_Relative_Height_Up >= m_MaxBottom)
                {
                    t_bReverse = true;
                    float t_Height_Up_percentage = t_Relative_Height_Up / m_MaxBottom;
                    t_Height_Middle_Value = m_CurrentBottom * t_Height_Up_percentage - t_Tilling_y;
					Debug.LogError("======================05t_Relative_Height_Up:"+t_Relative_Height_Up + " :"+t_Relative_Height_Down);
                }
                else
                {
                    t_bReverse = true;
                    t_Height_Middle_Value = m_CurrentBottom - t_Tilling_y;
					Debug.LogError("======================06t_Relative_Height_Up:"+t_Relative_Height_Up + " :"+t_Relative_Height_Down);
                }


                float t_Height_Final_Value = t_Height_Middle_Value + t_Tilling_y;
				
                float t_DeltaDistance = Time.deltaTime * m_Speed;
                float t_RaidusFallOff = CalcVolumeCloudFalloff(t_CamPos.y, m_CurrentCamera.farClipPlane, t_Tilling_y, t_height, m_Radius);
                Vector2 rhs = new Vector2(t_CamPos.x - m_LastCameraPos.x, t_CamPos.y - m_LastCameraPos.y);
                m_LastCameraPos = t_CamPos;
                Vector2 vector = new Vector2(forward.y, -forward.x);
                vector.Normalize();
                Vector2 vector2 = Vector2.Dot(vector, rhs) * vector * t_Height_Middle_Value / t_Relative_Height_Down;
                m_AccumulateUVOffset.x = m_AccumulateUVOffset.x + vector2.x;
                m_AccumulateUVOffset.y = m_AccumulateUVOffset.y + vector2.y;
                m_AccumulateUVOffset.x = m_AccumulateUVOffset.x - t_DeltaDistance;
                m_AccumulateUVOffset.y = m_AccumulateUVOffset.y - t_DeltaDistance;
                //Vector4 value;
                m_VolumetricCloudSpeed.x = m_AccumulateUVOffset.x;
                m_VolumetricCloudSpeed.y = m_AccumulateUVOffset.y;
                m_VolumetricCloudSpeed.z = m_VolumetricCloudSpeed.x * 0.5f;
                m_VolumetricCloudSpeed.w = m_VolumetricCloudSpeed.y * 0.5f;



                //Vector3 t_CamPos = m_CurrentCamera.transform.position;
                Matrix4x4 t_InvViewProjection = GL.GetGPUProjectionMatrix(m_CurrentCamera.projectionMatrix, m_CurrentCamera.allowHDR) * m_CurrentCamera.worldToCameraMatrix * Matrix4x4.Translate(t_CamPos);
                m_VolumetricClouMaterial.SetMatrix(ShaderPropertyToID.InvVPMatrix_ViewDir_ID, t_InvViewProjection.inverse);

                m_VPosToLastScreenMatrix[0, 0] = 1.0f / (float)Screen.width;
                m_VPosToLastScreenMatrix[1, 1] = 1.0f / (float)Screen.height;

                m_VolumetricClouMaterial.SetMatrix(ShaderPropertyToID.VPosToLastScreenMatrix_ID, m_VPosToLastScreenMatrix);
                m_VolumetricClouMaterial.SetInt(ShaderPropertyToID.SampleCount_ID, 40);
                m_VolumetricClouMaterial.SetColor(ShaderPropertyToID.MainLightColor_ID, m_MainLightColor);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.MainLightDirection_ID, Vector3.Normalize(m_MainLightDirection));
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.BaseTilling_ID, m_BaseTilling * 0.01f);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.Density_ID, new Vector2(t_density, 1f));
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.SoftEdge_ID, m_SoftEdge * 0.01f);
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.mainLightIntensity_ID, m_MainLightIntensity);
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.glossIntensity_ID, m_GlossIntensity);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.HGParameter_ID, new Vector3((1f - t_Hg * t_Hg) / 12.566371f, 1f + t_Hg * t_Hg, 2f * t_Hg));
                m_VolumetricClouMaterial.SetColor(ShaderPropertyToID.CloudColor_ID, m_CloudColor);
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.NoiseTilling_ID, m_NoiseTilling * 0.01f);
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.NoiseIntensity_ID, m_NoiseIntensity * 10f);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.Speed_ID, m_VolumetricCloudSpeed);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.Radius_ID, new Vector2(m_Radius, t_RaidusFallOff));
                m_VolumetricClouMaterial.SetColor(ShaderPropertyToID.AtmosphereColor_ID, m_AtmosphereColor);
                m_VolumetricClouMaterial.SetFloat(ShaderPropertyToID.AtmosphereColorSaturateDistance_ID, m_AtmosphereColorSaturateDistance);
                if (t_bReverse)
                {
                    m_VolumetricClouMaterial.EnableKeyword("_REVERSE_V");
                }
                else
                {
                    m_VolumetricClouMaterial.DisableKeyword("_REVERSE_V");
                }
                float t_InCloudDensityFactor = Mathf.Abs(t_CamPos.y - t_height) / t_Tilling_y;
                t_InCloudDensityFactor = (1f - t_InCloudDensityFactor) * 1.5f;
                t_InCloudDensityFactor = Mathf.Clamp(t_InCloudDensityFactor, 0f, 1f);
                t_InCloudDensityFactor = Mathf.Pow(t_InCloudDensityFactor, 4f);
                Vector4 t_Condition = new Vector4(-t_Height_Final_Value, -t_Height_Middle_Value + m_Border * m_NoiseIntensity * 7.5f, t_InCloudDensityFactor, t_Height_Middle_Value - t_Relative_Height_Down);
                m_VolumetricClouMaterial.SetVector(ShaderPropertyToID.Condition_ID, t_Condition);
				
                float y = t_Condition.y;
                float x = t_Condition.x;
                float w = t_Condition.w;

                //default in cloud, 
                m_VolumetricClouMaterial.EnableKeyword("_RENDER_STATE_1");
                m_VolumetricClouMaterial.DisableKeyword("_RENDER_STATE_2");
                if (y >= 0f)
                {
                    if (x > 0f)
                    {
                        m_VolumetricClouMaterial.EnableKeyword("_RENDER_STATE_2");
                        m_VolumetricClouMaterial.DisableKeyword("_RENDER_STATE_1");
                    }
                    else
                    {
                        m_VolumetricClouMaterial.EnableKeyword("_RENDER_STATE_1");
                        m_VolumetricClouMaterial.DisableKeyword("_RENDER_STATE_2");
                    }
                }
                else
                {
                    m_VolumetricClouMaterial.DisableKeyword("_RENDER_STATE_1");
                    m_VolumetricClouMaterial.DisableKeyword("_RENDER_STATE_2");
                }
                float t_NearValue = m_CurrentCamera.nearClipPlane * 1.5f;
                bool flag2 = -y > t_NearValue;
                bool flag3 = x > t_NearValue;
                if (!flag2 && !flag3)
                {
                    SetVolumetricCloudMesh(m_QuadMesh);
                    base.gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
                    base.gameObject.transform.position = t_CamPos + forward * 100f;
                    m_VolumetricClouMaterial.DisableKeyword("_OPTIMIZATION_VERSION");
					Debug.LogError("====================================================================001");
                }
                else
                {
					Debug.LogError("====================================================================002");
                    SetVolumetricCloudMesh(m_CircleMesh);
                    m_VolumetricClouMaterial.EnableKeyword("_OPTIMIZATION_VERSION");
                    float t_ScaleFactor;
                    float t_RadiusScale;
                    if (flag2)
                    {
                        t_ScaleFactor = y + w;
                        t_RadiusScale = t_RaidusFallOff * t_ScaleFactor / y;
                    }
                    else
                    {
                        t_ScaleFactor = x + w;
                        t_RadiusScale = t_RaidusFallOff * t_ScaleFactor / x;
                    }
                    float t_AdditionalHeight = t_ScaleFactor;
                    if (t_RadiusScale > m_CurrentCamera.farClipPlane)
                    {
                        t_AdditionalHeight -= (t_RadiusScale - m_CurrentCamera.farClipPlane) * t_AdditionalHeight / t_RadiusScale;
                    }
                    t_RadiusScale = Mathf.Sqrt(t_RadiusScale * t_RadiusScale - t_ScaleFactor * t_ScaleFactor);
                    t_RadiusScale = Mathf.Min(t_RadiusScale, 100000f);
                    base.gameObject.transform.localScale = new Vector3(t_RadiusScale, 1f, t_RadiusScale);
                    base.gameObject.transform.position = new Vector3(t_CamPos.x, t_CamPos.y + t_AdditionalHeight, t_CamPos.z);
                }


                UnityEngine.Profiling.Profiler.EndSample();
            }
        }
        private void GenerateCircleMesh(float radius, int segNum)
        {
            List<Vector3> list = new List<Vector3>();
            List<Vector2> list2 = new List<Vector2>();
            List<int> list3 = new List<int>();
            for (int i = 0; i < segNum; i++)
            {
                list3.Add(0);
                list3.Add(i + 1);
                list3.Add(i + 2);
            }
            list.Add(Vector3.zero);
            list2.Add(new Vector2(0.5f, 0.5f));
            float num = 6.2831855f / (float)segNum;
            for (int j = 0; j <= segNum; j++)
            {
                float f = (float)j * num;
                float num2 = Mathf.Cos(f);
                float y = 0f;
                float t_Tilling_y = Mathf.Sin(f);
                list.Add(new Vector3(num2, y, t_Tilling_y) * radius);
                list2.Add(new Vector2(num2 + 1f, t_Tilling_y + 1f) * 0.5f);
            }
            Vector3[] vertices = list.ToArray();
            Vector2[] uv = list2.ToArray();
            Mesh mesh = new Mesh();
            mesh.name = "VolumeCloudMesh";
            mesh.vertices = vertices;
            mesh.uv = uv;
            mesh.triangles = list3.ToArray();
            //if (null != m_MeshFilter.sharedMesh)
            //{
            //    UnityEngine.Object.DestroyImmediate(m_MeshFilter.sharedMesh);
            //}
            mesh.UploadMeshData(true);
            m_CircleMesh = mesh;
        }


        private void GenerateQuadMesh()
        {
            Vector3[] array = new Vector3[4];
            Vector2[] array2 = new Vector2[4];
            int[] array3 = new int[6];
            Mesh mesh = new Mesh();
            array[0] = new Vector3(-1f, -1f, 0f);
            array[1] = new Vector3(1f, -1f, 0f);
            array[2] = new Vector3(-1f, 1f, 0f);
            array[3] = new Vector3(1f, 1f, 0f);
            mesh.vertices = array;
            array3[0] = 0;
            array3[1] = 2;
            array3[2] = 1;
            array3[3] = 2;
            array3[4] = 3;
            array3[5] = 1;
            mesh.triangles = array3;
            array2[0] = new Vector2(0f, 0f);
            array2[1] = new Vector2(1f, 0f);
            array2[2] = new Vector2(0f, 1f);
            array2[3] = new Vector2(1f, 1f);
            mesh.uv = array2;
            mesh.name = "VolumeCloudMesh";
            mesh.UploadMeshData(true);
            m_QuadMesh = mesh;
        }


        private float CalcVolumeCloudFalloff(float camy, float farPlane, float yThickness, float fheight, float mRadius)
        {
            float num = Mathf.Abs(camy - fheight);
            float num2 = yThickness / mRadius;
            float a = num / num2 * 0.75f;
            float a2 = Mathf.Min(a, farPlane);
            return Mathf.Min(a2, mRadius);
        }

        private void SetVolumetricCloudMesh(Mesh mesh)
        {
            if (mesh != null)
            {
                m_MeshFilter.sharedMesh = mesh;
            }
        }
    }

}
