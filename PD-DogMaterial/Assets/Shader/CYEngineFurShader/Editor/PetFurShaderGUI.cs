using UnityEngine;
using UnityEditor;

public class PetFurShaderGUI : ShaderGUI
{

    protected MaterialEditor currentMaterialEditor = null;
    protected Material currentMaterial = null;
    protected Shader currentShader = null;
    protected MaterialProperty[] currentProps = null;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        currentMaterial = materialEditor.target as Material;
        currentMaterialEditor = materialEditor;
        currentProps = props;
        currentShader = currentMaterial.shader;

        for (int i = 0; i < ShaderUtil.GetPropertyCount(currentShader); i++)
        {
            var description = ShaderUtil.GetPropertyDescription(currentShader, i);
            var name = ShaderUtil.GetPropertyName(currentShader, i);
            var property = FindProperty(name, props);
            HandleProperty(name, description, property);
        }
        ShowShaderDebugParam();
        materialEditor.RenderQueueField();
    }

    public void HandleProperty(string name, string description, MaterialProperty property)
    {
        currentMaterialEditor.ShaderProperty(property, description);

    }

    enum FurDebug
    {
        None = 0,
        FurLength,
        FurDensity,
        FurFlowMap,
    }

    public static void ShowShaderDebugParam()
    {
        var debugModes = System.Enum.GetValues(typeof(FurDebug));

        GUILayout.BeginHorizontal();
        DrawDebugButton(FurDebug.None);

        for (int i = 1; i < debugModes.Length; i++)
        {
            var debug = debugModes.GetValue(i);
            if ((int)debug % 3 == 1)
            {
                GUILayout.EndHorizontal();
                GUILayout.BeginHorizontal();
            }
            DrawDebugButton(debug);

        }
        GUILayout.EndHorizontal();
    }

    private static string debugControlKeyGlobal = "_Debug_Fur_Control";
    private static string debugKeyWord = "DEBUG_FUR";

    private static void DrawDebugButton(object debug)
    {
        var col = GUI.color;
        if ((int)Shader.GetGlobalFloat(debugControlKeyGlobal) == (int)debug)
            GUI.color = Color.red;
        if (GUILayout.Button(debug.ToString()))
        {
            Shader.SetGlobalFloat(debugControlKeyGlobal, (int)debug);
            if ((int)debug == 0)
                Shader.DisableKeyword(debugKeyWord);
            else
                Shader.EnableKeyword(debugKeyWord);
#if UNITY_EDITOR
            UnityEditor.SceneView.lastActiveSceneView.Repaint();
#endif
        }
        GUI.color = col;
    }
}

