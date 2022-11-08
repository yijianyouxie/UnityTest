using System.Collections;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class CYEnginePainter : EditorWindow
{
    string contolTexName = "";
    GameObject currentSelectObject;

    public bool isPaint;
    private bool ClearMap;

    GameObject goplane;
    Material goplanematerial;
    Projector _projector;


    private Texture2D topSplat;
    //private bool MouseClick = false;
    string selectobjectname = "";
    //int savetime = 10;
    int brushSizeInPourcent;

    private Texture2D[] detailTextures;
    private Texture2D[] brushTextures;

    Texture2D objectMaskTex;
    Texture2D maskTex;

    private string[] paintModeStr = new string[3] { "细节绘制工具", "通道绘制工具", "走向图绘制工具" };
    private string destPainterTexName = "_DetailBlendMap";
    private string[] rgbaChannelName = new string[4] { "R", "G", "B", "A" };
    private PainterMode paintMode = PainterMode.ChannelPaint;

    private string detailTexName = "_DetailMap";
    const int detailMapCount = 3;
    const string painterConfigName = "/CYEnginePainterConfig.asset";
    private Color defaultColor = new Color(1.0f, 1.0f, 1.0f, 1.0f);

    private bool isPainting = false;
    private int currentSelectBrush = 0;
    private int currentSelectChannel = 0;

    private float brushSize = 8.0f;
    private float brushStrength = 0.5f;
    private float brushSoftness = 1.0f;

    const int maskTexSize = 1024;

   

    private CYEnginePainterConfig painterConfig = null;
    private int currentSelectPaintMode = 0;

    [MenuItem("Engine Tool/CY Engine Painter", false, 1)]
    static void OpenObjectPaintEditor()
    {
        var window = GetWindow(typeof(CYEnginePainter), false, "CY Engine Painter") as CYEnginePainter;
        window.InitPainterConfig();
    }

    private void InitPainterConfig()
    {
        if (painterConfig == null)
        {
            var path = GetRootPath() + painterConfigName;
            painterConfig = AssetDatabase.LoadAssetAtPath<CYEnginePainterConfig>(path);
            if (painterConfig == null)
            {
                painterConfig = ScriptableObject.CreateInstance<CYEnginePainterConfig>();
                AssetDatabase.CreateAsset(painterConfig, path);
            }
        }
        InitPainterSetting();
    }

    private void InitPainterSetting()
    {
        paintModeStr = painterConfig.config.Select(x => x.modeName).ToArray();
        var currentConfig = painterConfig.config[currentSelectPaintMode];
        rgbaChannelName = currentConfig.channelConfig.Select(x => x.channelName).ToArray();
        destPainterTexName = currentConfig.paintDestTexName;
        paintMode = currentConfig.paintMode;
    }

    public static string GetRootPath()
    {
        var frame = new System.Diagnostics.StackTrace(true).GetFrame(0);
        var configRootPath = frame.GetFileName();
        configRootPath = Path.GetDirectoryName(configRootPath);
        configRootPath = configRootPath.Replace('\\', '/');
        configRootPath = configRootPath.Remove(0, configRootPath.IndexOf("/Assets") + 1);
        return configRootPath;
    }

    private void OnGUI()
    {
        currentSelectPaintMode = GUILayout.Toolbar(currentSelectPaintMode, paintModeStr);
        if (Check())
        {
            GUI.skin.label.alignment = TextAnchor.MiddleLeft;
            GUI.skin.label.fontSize = 14;
            GUILayout.Label("当前选中物体为  " + currentSelectObject.name, GUILayout.Width(350), GUILayout.Height(20));
            isPaint = GUILayout.Toggle(isPaint, "绘制贴图", GUILayout.Width(100), GUILayout.Height(20));//编辑模式开关
           
            brushSize = (int)EditorGUILayout.Slider("笔刷大小", brushSize, 1f, 15);
            brushSoftness = EditorGUILayout.Slider("笔刷硬度", brushSoftness, 0, 1f);
            brushStrength = EditorGUILayout.Slider("笔刷强度", brushStrength, 0, 1f);
            InitBrush();
            GUILayout.BeginHorizontal("box", GUILayout.Width(318));
            currentSelectBrush = GUILayout.SelectionGrid(currentSelectBrush, brushTextures, 9, "gridlist", GUILayout.Width(340), GUILayout.Height(70));
            GUILayout.EndHorizontal();
            

            switch (paintMode)
            {
                case PainterMode.ChannelPaint:
                    ShowChanelSelectionField();
                    break;
                case PainterMode.DetailPaint:
                    ShowDetailBlendSelectionField();
                    break;
            }
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("自动配置工具", GUILayout.Width(100), GUILayout.Height(40)))
            {
                AutoSetPainter();
            }

            if (GUILayout.Button("清理绘制的数据", GUILayout.Width(100), GUILayout.Height(40)))
            {
                SetTexture();
                var bytes = maskTex.EncodeToPNG();
                var path1 = AssetDatabase.GetAssetPath(objectMaskTex);
                File.WriteAllBytes(path1, bytes);
                AssetDatabase.ImportAsset(path1);//刷新
            }
            /*
            if (GUILayout.Button("使用当前画刷填充贴图", GUILayout.Width(100), GUILayout.Height(40)))
            {

            }
            */

            GUILayout.EndHorizontal();

            PetFurShaderGUI.ShowShaderDebugParam();
        }
    }

    private void OnFocus()
    {
        SceneView.onSceneGUIDelegate -= OnSceneGUI;
        SceneView.onSceneGUIDelegate += OnSceneGUI;
    }

    private void AutoSetPainter()
    {
        //Collider Setting
        var collider = currentSelectObject.GetComponent<MeshCollider>();
        if (collider == null)
        {
            collider = currentSelectObject.AddComponent<MeshCollider>();
        }

        Mesh mesh = null;
        var skin = currentSelectObject.GetComponent<SkinnedMeshRenderer>();
        if (skin != null)
        {
            mesh = skin.sharedMesh;
        }
        else
        {
            var meshFilter = currentSelectObject.GetComponent<MeshFilter>();
            mesh = meshFilter.sharedMesh;
        }
        collider.sharedMesh = mesh;

        //Read Write Enable
        var mat = currentSelectObject.GetComponent<Renderer>().sharedMaterial;
        var texture = mat.GetTexture(destPainterTexName) as Texture2D;
        if (texture != null /*&& texture.isReadable == false*/)
        {
            var path = AssetDatabase.GetAssetPath(texture);
            var textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
            if(!textureIm.isReadable)
            {
                textureIm.isReadable = true;
                textureIm.SaveAndReimport();
                // AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);//刷新
                AssetDatabase.ImportAsset(path);
            }
        }

        //Mesh Refresh
        var modelPath = AssetDatabase.GetAssetPath(mesh);
        var modelIm = AssetImporter.GetAtPath(modelPath) as ModelImporter;
        modelIm.SaveAndReimport();
        AssetDatabase.ImportAsset(modelPath);
    }

    //private void OnInspectorUpdate()
    //{
    //    savetime--;
    //    if (savetime <= 0)
    //    {
    //        savetime = 5;
    //        if (currentSelectObject != null)
    //        {
    //            var renderer = currentSelectObject.GetComponent<Renderer>();
    //            if (renderer != null && renderer.sharedMaterial != null)
    //            {
    //                if (!MouseClick && renderer.sharedMaterial.GetTexture(destPainterTexName).name == "BrushControl")
    //                {
    //                    currentSelectObject.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, objectMaskTex);
    //                }
    //            }
                
    //        }
    //        // SaveTexture();
    //    }
    //}

    void OnSceneGUI(SceneView sceneView)
    {
        if (isPaint)
        {
            CreatBrushPlane();
            Painter();
            Repaint();
        }
        else
        {
            DestroyBrushObject();
        }
    }

    private void SceneViewPickObject()
    {
        var e = Event.current;
        var controlID = GUIUtility.GetControlID(FocusType.Passive);
        if (e.type == EventType.MouseDown)
        {
            HandleUtility.AddDefaultControl(controlID);
        }
    }

    void ShowDetailBlendSelectionField()
    {
        var Select = Selection.activeTransform;
        var mat = Select.gameObject.GetComponent<Renderer>().sharedMaterial;

        topSplat = AssetPreview.GetAssetPreview(mat.GetTexture(destPainterTexName)) as Texture2D;

        detailTextures = new Texture2D[detailMapCount];
        for (int i = 0; i < detailMapCount; i++)
        {
            detailTextures[i] = AssetPreview.GetAssetPreview(mat.GetTexture(detailTexName + (i + 1))) as Texture2D;
        }

        GUILayout.BeginHorizontal("box", GUILayout.Width(160));
        currentSelectChannel = GUILayout.SelectionGrid(currentSelectChannel, detailTextures, detailMapCount, "gridlist", GUILayout.Width(160), GUILayout.Height(75));
        GUILayout.Space(80);

        GUILayout.EndHorizontal();
    }

    void ShowChanelSelectionField()
    {
        currentSelectChannel = GUILayout.SelectionGrid(currentSelectChannel, rgbaChannelName, rgbaChannelName.Length, "gridlist", GUILayout.Width(160), GUILayout.Height(75));
    }

    //获取笔刷  
    void InitBrush()
    {
        var BrushList = new ArrayList();
        var rootPath = GetRootPath();
        Texture2D BrushesTL;
        int BrushNum = 0;
        do
        {
            BrushesTL = (Texture2D)AssetDatabase.LoadAssetAtPath(rootPath + "/Brushes/Brush" + BrushNum + ".png", typeof(Texture2D));

            if (BrushesTL)
            {
                BrushList.Add(BrushesTL);
            }
            BrushNum++;
        } while (BrushesTL);
        brushTextures = BrushList.ToArray(typeof(Texture2D)) as Texture2D[];
        ChangeBrushPlane();
    }

    bool Check()
    {
        var check = false;
        var Select = Selection.activeTransform;

        if (Select == null || Select.name == "object_brush_plane_icon" || Select.name == "Projector" || !Select.gameObject.GetComponent<Renderer>() || !Select.gameObject.GetComponent<Renderer>().sharedMaterial.HasProperty(destPainterTexName))
        {
            ClearAll();
            return false;
        }

        var mat = Select.gameObject.GetComponent<Renderer>().sharedMaterial;
        var basetexture = mat.GetTexture("_MainTex");
        var path = AssetDatabase.GetAssetPath(basetexture);//重新计算路径
        var controlTex = mat.GetTexture(destPainterTexName);

        if (maskTex == null)
        {
            var brushControlPath = GetRootPath() + "/BrushControl.png";
            maskTex = AssetDatabase.LoadAssetAtPath<Texture2D>(brushControlPath);
            if (maskTex == null)
            {
                CheckControlTex(brushControlPath);
            }
        }

        // Texture ControlTex = AssetDatabase.LoadAssetAtPath<Texture>(path);
        //if (true)
        {
            if (controlTex == null)
            {
                GUILayout.BeginVertical();
                EditorGUILayout.HelpBox("当前模型材质球中未找到Control贴图，绘制功能不可用！", MessageType.Error);
                if (GUILayout.Button("创建Control贴图"))
                {
                    CreateDetailMaskTex(path);
                }
                GUILayout.EndVertical();
            }
            else
            {
                check = true;
            }
            if (Select.name != selectobjectname)//换名字
            {
                if (currentSelectObject != null)
                    currentSelectObject.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, objectMaskTex);

                currentSelectObject = Select.gameObject;
                objectMaskTex = (Texture2D)mat.GetTexture(destPainterTexName);
                SetTexture(objectMaskTex);

                //  SaveTexture(ObjcetMaskTex, MaskTex);
                selectobjectname = Select.name;
            }
        }
        //else
        //{
        //    EditorGUILayout.HelpBox("当前模型shader错误！请更换！", MessageType.Error);
        //}
        return check;
    }

    void CheckControlTex(string path1)
    {
        var newMaskTex = new Texture2D(maskTexSize, maskTexSize, TextureFormat.ARGB32, true);
        var colorBase = new Color[maskTexSize * maskTexSize];
        for (int t = 0; t < colorBase.Length; t++)
        {
            colorBase[t] = defaultColor;
        }
        newMaskTex.SetPixels(colorBase);

        var bytes = newMaskTex.EncodeToPNG();
        var rawPath = GetRawAssetpath(path1);
        File.WriteAllBytes(path1, bytes);//保存
        //AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        AssetDatabase.ImportAsset(path1, ImportAssetOptions.ForceUpdate);//导入资源
        //Contol贴图的导入设置
        var textureIm = AssetImporter.GetAtPath(path1) as TextureImporter;
        var newPlatFormSetting = new TextureImporterPlatformSettings();
        newPlatFormSetting.format = TextureImporterFormat.RGBA32;

        textureIm.SetPlatformTextureSettings(newPlatFormSetting);
        textureIm.isReadable = true;
        textureIm.anisoLevel = 4;
        textureIm.mipmapEnabled = false;
        textureIm.wrapMode = TextureWrapMode.Clamp;
        textureIm.textureType = TextureImporterType.Default;
        textureIm.maxTextureSize = maskTexSize;
        textureIm.sRGBTexture = false;
        textureIm.alphaIsTransparency = false;
        textureIm.SaveAndReimport();
        // AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);//刷新
        AssetDatabase.ImportAsset(path1);
    }

    //创建Contol贴图
    void CreateDetailMaskTex(string path1)
    {
        var pathsplit = path1.Split('/');
        var pathlast = pathsplit[pathsplit.Length - 1];
        var pathnew = path1.Substring(0, path1.Length - pathlast.Length);

        var newMaskTex = new Texture2D(maskTexSize, maskTexSize, TextureFormat.ARGB32, true);
        var colorBase = new Color[maskTexSize * maskTexSize];
        for (int t = 0; t < colorBase.Length; t++)
        {
            colorBase[t] = defaultColor;
        }
        newMaskTex.SetPixels(colorBase);

        //判断是否重名
        var exporNameSuccess = true;
        for (int num = 1; exporNameSuccess; num++)
        {
            var Next = Selection.activeTransform.name + "_" + num;
            if (!File.Exists(pathnew + Selection.activeTransform.name + "_Splat.png"))
            {
                contolTexName = Selection.activeTransform.name;
                exporNameSuccess = false;
            }
            else if (!File.Exists(pathnew + Next + "_Splat.png"))
            {
                contolTexName = Next;
                exporNameSuccess = false;
            }
        }

        var path = pathnew + contolTexName + "_Splat.png";
        var bytes = newMaskTex.EncodeToPNG();
        File.WriteAllBytes(path, bytes);//保存

        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);//导入资源
        //Contol贴图的导入设置
        var textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
        textureIm.isReadable = true;
        textureIm.anisoLevel = 4;
        textureIm.mipmapEnabled = false;
        textureIm.wrapMode = TextureWrapMode.Clamp;
        textureIm.textureType = TextureImporterType.Default;
        textureIm.maxTextureSize = maskTexSize;
        textureIm.sRGBTexture = false;
        textureIm.alphaIsTransparency = false;
        textureIm.SaveAndReimport();

        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
        SetDetailMaskTex(path);//设置Contol贴图
    }

    //设置Contol贴图
    void SetDetailMaskTex(string peth)
    {
        var controlTex = (Texture2D)AssetDatabase.LoadAssetAtPath(peth, typeof(Texture2D));
        Selection.activeTransform.gameObject.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, controlTex);
        objectMaskTex = controlTex;
    }

    void Painter()
    {
        var CurrentSelect = Selection.activeTransform;

        if (CurrentSelect == null || CurrentSelect.name == "object_brush_plane_icon" || CurrentSelect.name == "Projector" || !CurrentSelect.gameObject.GetComponent<Renderer>() || !CurrentSelect.gameObject.GetComponent<Renderer>().sharedMaterial.HasProperty(destPainterTexName))
            return;

        var size = 100.0f;
        var meshFilter = CurrentSelect.GetComponent<MeshFilter>();//获取当前模型的MeshFilter
        if (meshFilter == null)
        {
            var skinedMesh = CurrentSelect.GetComponent<SkinnedMeshRenderer>();
            size = skinedMesh.sharedMesh.bounds.size.x;
        }
        else
        {
            size = meshFilter.sharedMesh.bounds.size.x;
        }
        var orthographicSize = (brushSize * CurrentSelect.localScale.x) * (size / 200);//笔刷在模型上的正交大小
        //MouseClick = false;
        brushSizeInPourcent = (int)Mathf.Round((brushSize * maskTex.width) / 100);//笔刷在模型上的大小

        var e = Event.current;//检测输入
        HandleUtility.AddDefaultControl(0);
        var raycastHit = new RaycastHit();
        var terrain = HandleUtility.GUIPointToWorldRay(e.mousePosition);
        if (Physics.Raycast(terrain, out raycastHit, Mathf.Infinity))
        {
            //Handles.color = new Color(0f, 0.7f,1f, 0.4f);//颜色
            //Handles.DrawWireDisc(raycastHit.point, raycastHit.normal, orthographicSize+0.6f);//根据笔刷大小在鼠标位置显示一个圆
            if (goplane != null && _projector != null && raycastHit.transform.GetComponent<MeshCollider>())
            {
                goplane.transform.position = raycastHit.point;
                goplane.transform.up = raycastHit.normal;
                _projector.orthographicSize = orthographicSize * 3f;
            }
            //鼠标点击或按下并拖动进行绘制
            if ((e.type == EventType.MouseDrag && e.alt == false && e.control == false && e.shift == false && e.button == 0) || (e.type == EventType.MouseDown && e.shift == false && e.alt == false && e.control == false && e.button == 0 && isPainting == false))
            {
                //MouseClick = true;
                CurrentSelect.gameObject.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, maskTex);

                var targetColor = GetTargetColor();
                //计算笔刷所覆盖的区域
                var pixelUV = raycastHit.textureCoord2;
                var PuX = Mathf.FloorToInt(pixelUV.x * maskTex.width);
                var PuY = Mathf.FloorToInt(pixelUV.y * maskTex.height);
                var x = Mathf.Clamp(PuX - brushSizeInPourcent / 2, 0, maskTex.width - 1);
                var y = Mathf.Clamp(PuY - brushSizeInPourcent / 2, 0, maskTex.height - 1);
                var width = Mathf.Clamp((PuX + brushSizeInPourcent / 2), 0, maskTex.width) - x;
                var height = Mathf.Clamp((PuY + brushSizeInPourcent / 2), 0, maskTex.height) - y;
                var currentPaintingArea = maskTex.GetPixels(x, y, width, height, 0);//获取Control贴图被笔刷所覆盖的区域的颜色
                var currentPaintingBrush = brushTextures[currentSelectBrush];//获取笔刷性状贴图
                var brushAlpha = new float[brushSizeInPourcent * brushSizeInPourcent];//笔刷透明度

                //根据笔刷贴图计算笔刷的透明度
                for (int i = 0; i < brushSizeInPourcent; i++)
                {
                    for (int j = 0; j < brushSizeInPourcent; j++)
                    {
                        brushAlpha[j * brushSizeInPourcent + i] = currentPaintingBrush.GetPixelBilinear(((float)i) / brushSizeInPourcent, ((float)j) / brushSizeInPourcent).a;
                    }
                }

                //计算绘制后的颜色
                for (int i = 0; i < height; i++)
                {
                    for (int j = 0; j < width; j++)
                    {
                        var index = (i * width) + j;
                        var Stronger = brushAlpha[Mathf.Clamp((y + i) - (PuY - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1) * brushSizeInPourcent + Mathf.Clamp((x + j) - (PuX - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1)] * brushSoftness;
                        if (paintMode == PainterMode.ChannelPaint)
                        {
                            //currentPaintingArea[index] = Color.Lerp(currentPaintingArea[index], targetColor, Stronger);
                            currentPaintingArea[index][currentSelectChannel] = Mathf.Lerp(currentPaintingArea[index][currentSelectChannel], targetColor[currentSelectChannel], Stronger);
                        }
                        else
                        {
                            currentPaintingArea[index] = Color.Lerp(currentPaintingArea[index], targetColor, Stronger);
                        }
                    }
                }
                Undo.RegisterCompleteObjectUndo(maskTex, "meshPaint");//保存历史记录以便撤销

                maskTex.SetPixels(x, y, width, height, currentPaintingArea, 0);//把绘制后的Control贴图保存起来
                maskTex.Apply();
                isPainting = true;
            }
            else if (e.type == EventType.MouseUp && e.alt == false && e.button == 0 && isPainting == true)
            {
                SetTextureCom(maskTex, objectMaskTex);//绘制结束保存Control贴图
                CurrentSelect.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, objectMaskTex);
                isPainting = false;
            }
        }
    }

    private Color GetTargetColor()
    {
        //选择绘制的通道
        Color targetColor = defaultColor;
        switch (currentSelectChannel)
        {
            case 0:
                targetColor = new Color(1f, 0f, 0f, 0f);
                break;
            case 1:
                targetColor = new Color(0f, 1f, 0f, 0f);
                break;
            case 2:
                targetColor = new Color(0f, 0f, 1f, 0f);
                break;
            case 3:
                targetColor = new Color(0f, 0f, 0f, 1f);
                break;
        }

        targetColor *= brushStrength;
        return targetColor;
    }

    private void FillTexture()
    {
        var targetColor = GetTargetColor();
        for(int i = 0; i < maskTex.width; i++)
        {
            for(int j = 0; j < maskTex.height; j++)
            {
                maskTex.SetPixel(i, j, targetColor);
            }
        }
        maskTex.Apply();
    }

    private void SaveTexture()
    {
        if (objectMaskTex == null)
            return;
        var newMaskTex = new Texture2D(maskTexSize, maskTexSize, TextureFormat.ARGB32, true);

        for (int x = 0; x < newMaskTex.width; x++)
        {
            for (int y = 0; y < newMaskTex.height; y++)
            {
                newMaskTex.SetPixel(x, y, objectMaskTex.GetPixel(x, y));
            }
        }
        newMaskTex.Apply();

        var bytes = newMaskTex.EncodeToPNG();
        var path1 = AssetDatabase.GetAssetPath(objectMaskTex);
        File.WriteAllBytes(path1, bytes);
        AssetDatabase.ImportAsset(path1);
    }

    private void SetTextureCom(Texture2D ResTex, Texture2D CombinTex)
    {
        var bytes = ResTex.EncodeToPNG();
        var path1 = AssetDatabase.GetAssetPath(CombinTex);
        File.WriteAllBytes(path1, bytes);
        AssetDatabase.ImportAsset(path1);
    }

    public string GetRawAssetpath(string path)
    {
        var asset = "Asset";
        var head = Application.dataPath.TrimEnd(asset.ToCharArray());
        return head + path;
    }

    private void SetTexture(Texture2D ResTex = null)
    {
        if (maskTex == null)
            return;
        var targetColor = defaultColor;
        if (ResTex == null)
        {
            for (int x = 0; x < maskTex.width; x++)
            {
                for (int y = 0; y < maskTex.height; y++)
                {
                    maskTex.SetPixel(x, y, targetColor);
                }
            }
        }
        else
        {
            for (int x = 0; x < maskTex.width; x++)
            {
                for (int y = 0; y < maskTex.height; y++)
                {
                    maskTex.SetPixel(x, y, ResTex.GetPixel(x, y));
                }
            }
        }
        maskTex.Apply();
    }

    private void CreatBrushPlane()
    {
        if (goplane == null)
        {
            goplane = GameObject.Find("object_brush_plane_icon");
            if (goplane == null)
            {
                goplane = new GameObject();
                goplane.name = "object_brush_plane_icon";
                var child = new GameObject("Projector");
                child.transform.parent = goplane.transform;
                child.transform.localPosition = new Vector3(0, 30, 0);
                child.transform.eulerAngles = new Vector3(90, -90, 0);
                child.AddComponent<Projector>();
                _projector = child.GetComponent<Projector>();
            }
            if (_projector == null)
            {
                _projector = goplane.transform.GetChild(0).GetComponent<Projector>();
            }
            _projector.farClipPlane = 200;
            _projector.nearClipPlane = 0.1f;
            _projector.orthographic = true;

            var _shader = Shader.Find("CYOU/Projectorshader");
            goplanematerial = new Material(_shader);
            _projector.material = goplanematerial;
        }
    }
    public void ChangeBrushPlane()
    {
        if (_projector != null)
        {
            _projector.material.SetTexture("_MainTex", brushTextures[currentSelectBrush]);
        }
    }

    public void DestroyBrushObject()
    {
        if (goplane != null)
        {
            var SceneObject = GameObject.Find("object_brush_plane_icon");
            if (SceneObject != null)
            {
                DestroyImmediate(SceneObject);
            }
            DestroyImmediate(goplane);
            goplane = null;
        }
    }

    private void OnDestroy()
    {
        ClearAll();
    }

    private void ClearAll()
    {
        if (currentSelectObject != null && objectMaskTex != null)
            currentSelectObject.GetComponent<Renderer>().sharedMaterial.SetTexture(destPainterTexName, objectMaskTex);
        isPaint = false;
        currentSelectObject = null;
        objectMaskTex = null;
        maskTex = null;
        selectobjectname = "";
        DestroyBrushObject();
    }
}
