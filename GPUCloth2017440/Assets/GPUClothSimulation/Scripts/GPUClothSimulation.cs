using System;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace GPUClothSimulation
{
    public class GPUClothSimulation : MonoBehaviour
    {
        [Header("Simulation Parameters")]
        // 时间步长（多长时间检测一次）
        public float   TimeStep = 0.01f;
        // 模拟的迭代次数
        [Range(1, 16)]
        public int     VerletIterationNum = 4;
        // 布的分辨率
        public Vector2Int ClothResolution = new Vector2Int(128, 128);
        private int[] ClothResolutionArr = new int[2];
        private float[] totalClothLength = new float[2];
        private float[] CollideSphereParams = new float[4];
        // 布上点的间隔（小弹簧的自然长度）
        public float   RestLength = 0.02f;
        // 决定布伸缩性的常数（弹簧的硬度）
        public float   Stiffness = 10000.0f;
        // 速度衰减常数（阻尼）
        public float   Damp = 0.996f;
        // 质点的质量
        public float   Mass = 1.0f;
        // 重力
        public Vector3 Gravity = new Vector3(0.0f, -9.81f, 0.0f);

        [Header("References")]
        // 参照碰撞用球体的transform
        public Transform CollisionSphereTransform;
        //把脖子物体放到碰撞球里去
        //其实不用将脖子物体放到碰撞球里去，因为computeShader里计算时使用的也是碰撞球的世界坐标
        public Transform NeckBegainTr;
        public Transform NeckEndTr;
        private float[] _NeckPosition = new float[3];

        [Header("Resources")]
        // 用于计算的ComputeShader
        public ComputeShader KernelCS;

        // 布模拟位置数据缓冲
        private RenderTexture[] _posBuff;
        // 布模拟位置数据（前一个时间步）缓冲
        private RenderTexture[] _posPrevBuff;
        // 布模拟法线数据缓冲
        private RenderTexture _normBuff;

        // 布的长度（横，纵）
        private Vector2 _totalClothLength;
        
        [Header("Debug")]
        // 显示模拟缓冲区进行调试
        public bool EnableDebugOnGUI = true;
        // 调试显示时缓冲区的显示比例
        public float _debugOnGUIScale = 1.0f;

        public GameObject Sphere;

        private bool setPosition = true;
        public int maxCount = 3;
        private int count = 0;

        // 是否初始化了模拟资源
        public bool IsInit { private set; get; }

        //private ComputeBuffer speedBuffer;
        //private Vector3[] speedArray;

        //模拟脖子的圆圈
        public Transform PointsRootTr;//项链母体
        private const int neckPointCount = 4;
        private Transform[] neckTrs = new Transform[neckPointCount];
        private Vector4[] neckVectorArray = new Vector4[neckPointCount];

        // 获取位置数据的缓冲区
        public RenderTexture GetPositionBuffer()
        {
            return this.IsInit ? _posBuff[0] : null;
        }
        // 获取法线数据的缓冲区
        public RenderTexture GetNormalBuffer()
        {
            return this.IsInit ? _normBuff : null;
        }
        // 获取布的分辨率
        public Vector2Int GetClothResolution()
        {
            return ClothResolution;
        }
        
        // ComputeShader中x,y线程的数量
        const int numThreadsXY = 32;
        
        void Start()
        {
#if UNITY_EDITOR
            if (Application.isEditor)
            {
                EditorApplication.ExecuteMenuItem("Edit/Graphics Emulation/No Emulation");
            }
#endif
            var w = ClothResolution.x;
            var h = ClothResolution.y;
            var format = RenderTextureFormat.ARGBFloat;
            //新发现，貌似不同的RT格式下，通道中的值并不是1就代表了是红，里边只是存储的这个值。
            //例如ARGBFloat在computeShader中设置了2才代表的是最红；而如果设置为ARGB32，不管设置多大的值都是红的一半。
            //var format = RenderTextureFormat.ARGB32;
            var filter = FilterMode.Point; // 过滤模式为点差值，避免像素之间的插值
            // 创建RT
            CreateRenderTexture(ref _posBuff,     w, h, format, filter);
            CreateRenderTexture(ref _posPrevBuff, w, h, format, filter);
            CreateRenderTexture(ref _normBuff,    w, h, format, filter);

            //InitSpeedBuffer();
            InitNeckPosData();
            // 重置模拟数据
            ResetBuffer();
            // 初始化的标志设置为true
            IsInit = true;

            str += "Init true.\n";
        }

        void Update()
        {
            // 按下r键后，将模拟用的数据复位
            if (Input.GetKeyUp("r"))
                ResetBuffer();

            ////模拟前设定披风根部的位置
            //SetPifengRootPos();

            if(count > maxCount)
            {
                return;
            }
            count++;
            // 进行模拟
            Simulation();
        }

        void OnDestroy()
        {
            // 删除存储模拟数据的RT
            DestroyRenderTexture(ref _posBuff    );
            DestroyRenderTexture(ref _posPrevBuff);
            DestroyRenderTexture(ref _normBuff   );

            str += "OnDestroy.\n";
        }

        void OnGUI()
        {
            // 绘制包含模拟数据的RT以进行调试
            DrawSimulationBufferOnGUI();

            DrawComputeSupport();
        }
        
        //void InitSpeedBuffer()
        //{
        //    speedArray = new Vector3[1];
        //    speedBuffer = new ComputeBuffer(1, 3*4);
        //    speedBuffer.SetData(speedArray);
        //}
        private void InitNeckPosData()
        {
            if(null == PointsRootTr)
            {
                Debug.LogError("====请设置项链。");
                return;
            }

            var chCount = PointsRootTr.childCount;
            if(chCount < neckPointCount)
            {
                Debug.LogError("====脖子基准点数目过少。");
            }
            for(int i = 0;i < chCount;i++)
            {
                var tr = PointsRootTr.GetChild(i);
                neckTrs[i] = tr;
            }
        }
        // 重置模拟用的数据
        void ResetBuffer()
        {
            ComputeShader cs = KernelCS;
            // 获取内核ID
            int kernelId = cs.FindKernel("CSInit");
            // ComputeShader计算内核执行线程组的数量
            int groupThreadsX = 
                Mathf.CeilToInt((float)ClothResolution.x / numThreadsXY);
            int groupThreadsY = 
                Mathf.CeilToInt((float)ClothResolution.y / numThreadsXY);
            // 计算布的长度（横，纵）
            _totalClothLength = new Vector2(
                RestLength * ClothResolution.x, 
                RestLength * ClothResolution.y
            );
            // 设置参数，缓冲区
            ClothResolutionArr[0] = ClothResolution.x;
            ClothResolutionArr[1] = ClothResolution.y;
            cs.SetInts  ("_ClothResolution", ClothResolutionArr);
            totalClothLength[0] = _totalClothLength.x;
            totalClothLength[1] = _totalClothLength.y;
            cs.SetFloats("_TotalClothLength", totalClothLength);
            cs.SetFloat ("_RestLength", RestLength);
            cs.SetTexture(kernelId, "_PositionBufferRW",     _posBuff[0]);
            cs.SetTexture(kernelId, "_PositionPrevBufferRW", _posPrevBuff[0]);
            cs.SetTexture(kernelId, "_NormalBufferRW",       _normBuff);

            //初始化的时候将脖子的位置传递进去，改变buffer里的值
            if (null != NeckBegainTr && null != NeckEndTr)
            {
                cs.SetBool("_SetPosition", setPosition);

                for(int i = 0;i < neckPointCount;i++)
                {
                    neckVectorArray[i].x = neckTrs[i].position.x;
                    neckVectorArray[i].y = neckTrs[i].position.y;
                    neckVectorArray[i].z = neckTrs[i].position.z;
                    neckVectorArray[i].w = 0;
                }
                cs.SetVectorArray("_NeckVectorArray", neckVectorArray);

                var neckPos = NeckBegainTr.position;
                var neckEndPos = NeckEndTr.position;
                _NeckPosition[0] = neckPos.x;
                _NeckPosition[1] = neckPos.y;
                _NeckPosition[2] = neckPos.z;
                cs.SetFloats("_NeckPosition", _NeckPosition);
                _NeckPosition[0] = neckEndPos.x;
                _NeckPosition[1] = neckEndPos.y;
                _NeckPosition[2] = neckEndPos.z;
                cs.SetFloats("_NeckEndPosition", _NeckPosition);
            }
            else
            {
                Debug.LogError("====NeckTr is null.");
            }
            //cs.SetBuffer(kernelId, "_SpeedBuffer", speedBuffer);
            // 运行内核
            cs.Dispatch(kernelId, groupThreadsX, groupThreadsY, 1);

            //注意，获取数据很耗时
            //speedBuffer.GetData(speedArray);

            // 复制缓冲区
            Graphics.Blit(_posBuff[0],     _posBuff[1]);
            Graphics.Blit(_posPrevBuff[0], _posPrevBuff[1]);

            str += "ResetBuffer.\n";
        }

        // 模拟
        void Simulation()
        {
            ComputeShader cs = KernelCS;
            // CSSimulation计算每次时间步的值
            float timestep = (float)TimeStep / VerletIterationNum;
            // 获取内核id
            int kernelId = cs.FindKernel("CSSimulation");
            // ComputeShader计算内核执行线程组的数量
            int groupThreadsX = 
                Mathf.CeilToInt((float)ClothResolution.x / numThreadsXY);
            int groupThreadsY = 
                Mathf.CeilToInt((float)ClothResolution.y / numThreadsXY);

            // 设置参数
            cs.SetVector("_Gravity", Gravity);
            cs.SetFloat ("_Stiffness", Stiffness);
            cs.SetFloat ("_Damp", Damp);
            cs.SetFloat ("_InverseMass", (float)1.0f / Mass);
            cs.SetFloat ("_TimeStep", timestep);
            cs.SetFloat ("_RestLength", RestLength);
            cs.SetInts  ("_ClothResolution", ClothResolutionArr);

            // 设置碰撞球的参数
            if (CollisionSphereTransform != null)
            {
                Vector3 collisionSpherePos = CollisionSphereTransform.position;
                float collisionSphereRad = 
                    CollisionSphereTransform.localScale.x * 0.5f + 0.01f;
                cs.SetBool  ("_EnableCollideSphere", true);
                //这里设定的是世界坐标系里的位置
                CollideSphereParams[0] = collisionSpherePos.x;
                CollideSphereParams[1] = collisionSpherePos.y;
                CollideSphereParams[2] = collisionSpherePos.z;
                CollideSphereParams[3] = collisionSphereRad;
                cs.SetFloats("_CollideSphereParams", CollideSphereParams);
            }
            else
                cs.SetBool("_EnableCollideSphere", false);

            //设置脖子的位置信息
            if (null != NeckBegainTr)
            {
                cs.SetBool("_SetPosition", setPosition);
                for (int i = 0; i < neckPointCount; i++)
                {
                    neckVectorArray[i].x = neckTrs[i].position.x;
                    neckVectorArray[i].y = neckTrs[i].position.y;
                    neckVectorArray[i].z = neckTrs[i].position.z;
                    neckVectorArray[i].w = 0;
                }
                cs.SetVectorArray("_NeckVectorArray", neckVectorArray);

                var neckPos = NeckBegainTr.position;
                var neckEndPos = NeckEndTr.position;
                _NeckPosition[0] = neckPos.x;
                _NeckPosition[1] = neckPos.y;
                _NeckPosition[2] = neckPos.z;
                cs.SetFloats("_NeckPosition", _NeckPosition);
                _NeckPosition[0] = neckEndPos.x;
                _NeckPosition[1] = neckEndPos.y;
                _NeckPosition[2] = neckEndPos.z;
                cs.SetFloats("_NeckEndPosition", _NeckPosition);
            }

            for (var i = 0; i < VerletIterationNum; i++)
            {           
                // 设置缓冲区
                cs.SetTexture(kernelId, "_PositionBufferRO",     _posBuff[0]);
                cs.SetTexture(kernelId, "_PositionPrevBufferRO", _posPrevBuff[0]);
                cs.SetTexture(kernelId, "_PositionBufferRW",     _posBuff[1]);
                cs.SetTexture(kernelId, "_PositionPrevBufferRW", _posPrevBuff[1]);

                cs.SetTexture(kernelId, "_NormalBufferRW",       _normBuff);

                //cs.SetBuffer(kernelId, "_SpeedBuffer", speedBuffer);

                // 执行线程
                cs.Dispatch(kernelId, groupThreadsX, groupThreadsY, 1);

                //speedBuffer.GetData(speedArray);
                //Debug.LogError("====speedArray:" + speedArray[0] + "-len:" + speedArray.Length);

                // 替换读入缓存器和写入缓存器
                SwapBuffer(ref _posBuff[0],     ref _posBuff[1]    );
                SwapBuffer(ref _posPrevBuff[0], ref _posPrevBuff[1]);
            }

            //str += "Simulation.\n";
        }

        // 创建RenderTexture来存储模拟数据
        void CreateRenderTexture(ref RenderTexture buffer, int w, int h, 
            RenderTextureFormat format, FilterMode filter)
        {
            buffer = new RenderTexture(w, h, 0, format)
            {
                filterMode = filter,
                wrapMode   = TextureWrapMode.Clamp,
                hideFlags  = HideFlags.HideAndDontSave,
                enableRandomWrite = true
            };
            buffer.Create();

            str += "CreateRenderTexture.\n";
        }

        // 创建RenderTexture[]来存储模拟数据。
        void CreateRenderTexture(ref RenderTexture[] buffer, int w, int h, 
            RenderTextureFormat format, FilterMode filter)
        {
            buffer = new RenderTexture[2];
            for (var i = 0; i < 2; i++)
            {
                buffer[i] = new RenderTexture(w, h, 0, format)
                {
                    filterMode = filter,
                    wrapMode   = TextureWrapMode.Clamp,
                    hideFlags  = HideFlags.HideAndDontSave,
                    enableRandomWrite = true
                };
                buffer[i].Create();
            }

            str += "CreateRenderTexture2.\n";
        }

        // 删除存储模拟数据的RenderTexture
        void DestroyRenderTexture(ref RenderTexture buffer)
        {
            if (Application.isEditor)
                RenderTexture.DestroyImmediate(buffer);
            else
                RenderTexture.Destroy(buffer);
            buffer = null;

            str += "DestroyRenderTexture.\n";
        }

        // 删除存储模拟数据的RenderTexture[]
        void DestroyRenderTexture(ref RenderTexture[] buffer)
        {
            if (buffer != null)
                for (var i = 0; i < buffer.Length; i++)
                {
                    if (Application.isEditor)
                        RenderTexture.DestroyImmediate(buffer[i]);
                    else
                        RenderTexture.Destroy(buffer[i]);
                    buffer[i] = null;
                }

            str += "DestroyRenderTexture2.\n";
        }

        // 销毁材质
        void DestroyMaterial(ref Material mat)
        {
            if (mat != null)
                if (Application.isEditor)
                    Material.DestroyImmediate(mat);
                else
                    Material.Destroy(mat);
        }

        // 交换缓冲区
        void SwapBuffer(ref RenderTexture ping, ref RenderTexture pong)
        {
            RenderTexture temp = ping;
            ping = pong;
            pong = temp;
        }

        // 在OnGUI函数中绘制用于调试的模拟缓冲器
        void DrawSimulationBufferOnGUI()
        {
            if (!EnableDebugOnGUI)
                return;

            var scl = _debugOnGUIScale;
            int rw = Mathf.RoundToInt((float)ClothResolution.x * scl);
            int rh = Mathf.RoundToInt((float)ClothResolution.y * scl);

            Color storeColor = GUI.color;
            GUI.color = Color.gray;

            if (_posBuff != null)
            {
                Rect r00 = new Rect(rw * 0, rh * 0, rw, rh);
                Rect r01 = new Rect(rw * 0, rh * 1, rw, rh);
                GUI.DrawTexture(r00, _posBuff[0]);
                GUI.DrawTexture(r01, _posBuff[1]);
                GUI.Label(r00, "PositionBuffer[0]");
                GUI.Label(r01, "PositionBuffer[1]");
            }

            if (_posPrevBuff != null)
            {
                Rect r10 = new Rect(rw * 1, rh * 0, rw, rh);
                Rect r11 = new Rect(rw * 1, rh * 1, rw, rh);
                GUI.DrawTexture(r10, _posPrevBuff[0]);
                GUI.DrawTexture(r11, _posPrevBuff[1]);
                GUI.Label(r10, "PositionPrevBuffer[0]");
                GUI.Label(r11, "PositionPrevBuffer[1]");
            }

            if (_normBuff != null)
            {
                Rect r20 = new Rect(rw * 2, rh * 0, rw, rh);
                GUI.DrawTexture(r20, _normBuff);
                GUI.Label(r20, "NormalBuffer");
            }

            GUI.color = storeColor;
        }

        private string computeSupport = "";
        private string str = "";
        private bool hideLog = true;
        void DrawComputeSupport()
        {
            float textAreaWidth = 600f;
            GUIStyle titleStyle2 = new GUIStyle();
            titleStyle2.fontSize = 20;
            titleStyle2.normal.textColor = new Color(256f / 256f, 163f / 256f, 256f / 256f, 256f / 256f);
            //是否支持computeShader
            GUI.Label(new UnityEngine.Rect(textAreaWidth+20, 0, 150, 20), "是否支持ComputeShader：" + SystemInfo.supportsComputeShaders, titleStyle2);
            //当前设备的Graphics API版本
            GUI.Label(new UnityEngine.Rect(textAreaWidth + 20, 30, 150, 20), "GraphicsDeviceType：" + GetGraphicsDeviceType(), titleStyle2);
            //当前设备的GPU型号
            GUI.Label(new UnityEngine.Rect(textAreaWidth + 20, 60, 150, 50), "GPU：" + SystemInfo.graphicsDeviceName, titleStyle2);

            if (GUI.Button(new UnityEngine.Rect(Screen.width - 150, 150, 150, 50), "重置RT"))
            {
                count = 0;
                ResetBuffer();
            }

            if(!hideLog && GUI.Button(new UnityEngine.Rect(Screen.width - 150, 270, 150, 50), "隐藏日志"))
            {
                hideLog = !hideLog;
            }
            if (hideLog && GUI.Button(new UnityEngine.Rect(Screen.width - 150, 270, 150, 50), "显示日志"))
            {
                hideLog = !hideLog;
            }
            if (!hideLog)
            {
                //执行过程
                str = GUI.TextArea(new Rect(0, 0, textAreaWidth, 800), str);
            }
            if(GUI.Button(new UnityEngine.Rect(Screen.width - 150, 330, 150, 50), "控制球体"))
            {
                Sphere.SetActive(!Sphere.activeInHierarchy);
            }
            if (GUI.Button(new UnityEngine.Rect(Screen.width - 150, 210, 150, 50), "清空日志"))
            {
                str = "";
            }

            GUI.Label(new UnityEngine.Rect(Screen.width - 165, 405, 150, 50), VerletIterationNum.ToString());
            VerletIterationNum = (int)GUI.HorizontalSlider(new UnityEngine.Rect(Screen.width - 150, 410, 150, 50), VerletIterationNum, 1, 16);

            //设置位置
            if(GUI.Button(new Rect(Screen.width - 150, 500, 150, 50), "设置位置"+ setPosition))
            {
                setPosition = !setPosition;

            }
        }
        public static string GetGraphicsDeviceType()
        {
            string graphicVersion = SystemInfo.graphicsDeviceType.ToString();
            return graphicVersion;

            string version = "0";
#if (UNITY_ANDROID && !UNITY_EDITOR)
            try
            {
                using (AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                {
                    using (AndroidJavaObject currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
                    {
                        using (AndroidJavaObject curApplication = currentActivity.Call<AndroidJavaObject>("getApplication"))
                        {
                            using (AndroidJavaObject curSystemService = curApplication.Call<AndroidJavaObject>("getSystemService", "activity"))
                            {
                                using (AndroidJavaObject curConfigurationInfo = curSystemService.Call<AndroidJavaObject>("getDeviceConfigurationInfo"))
                                {
                                    int reqGlEsVersion = curConfigurationInfo.Get<int>("reqGlEsVersion");
                                    using (AndroidJavaClass curInteger = new AndroidJavaClass("java.lang.Integer"))
                                    {
                                        version = curInteger.CallStatic<string>("toString",reqGlEsVersion,16);
                                    }
                                }
                            }
                        }
                    } 
                }
            }
            catch (Exception e)
            {
                version = e.ToString();
            }
#elif (UNITY_IOS && !UNITY_EDITOR)
            version = "-1";
#endif
            return version;
        }
    }
}