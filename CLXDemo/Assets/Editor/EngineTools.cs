using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace CYEngineEditor
{
    public class EngineTools : MonoBehaviour
    {
        [MenuItem("Engine/Tools/把Unity原始Shader转换为CYShaders/一键全部转换")]
        static void HandleShaderConverterAll()
        {
            if (Selection.gameObjects == null || Selection.gameObjects.Length <= 0)
            {
                UnityEditor.EditorUtility.DisplayDialog("Warning", "请选择场景中的对象!", "OK");
                return;
            }
            HandleShaderConverterElseShaderToCYShaders();
        }

        static void HandleShaderConverterElseShaderToCYShaders()
        {
            Debug.Log("开始转换");
            Shader shaderOld = Shader.Find("Legacy Shaders/Transparent/Diffuse");
            Shader shaderNew = Shader.Find("CYShaders/Legacy Shaders/Transparent/Diffuse");

            Shader shaderOld2 = Shader.Find("Legacy Shaders/Transparent/Cutout/Diffuse");
            Shader shaderNew2 = Shader.Find("CYShaders/Legacy Shaders/Transparent/Cutout/Diffuse");

            Shader shaderOld3 = Shader.Find("Legacy Shaders/Transparent/Cutout/Soft Edge Unlit");
            Shader shaderNew3 = Shader.Find("CYShaders/Legacy Shaders/Transparent/Cutout/Soft Edge Unlit");

            Shader shaderOld4 = Shader.Find("Legacy Shaders/Diffuse");
            Shader shaderNew4 = Shader.Find("CYShaders/Legacy Shaders/Diffuse");

            if (Selection.gameObjects == null || Selection.gameObjects.Length<=0)
            {
                UnityEditor.EditorUtility.DisplayDialog("Warning", "请选择场景中的对象!", "OK");
                return;
            }

            foreach (GameObject obj in Selection.gameObjects)
            {
                if (obj != null)
                {
                    foreach (Renderer render in obj.GetComponentsInChildren<Renderer>())
                    {

                        if (render != null)
                        {
                            foreach (Material mat in render.sharedMaterials)
                            {
                                if (mat != null && mat.shader != null)
                                {
                                    if (mat != null && mat.shader != null)
                                    {
                                        if (mat.shader == shaderOld)
                                        {
                                            Debug.Log("转换:" + mat.name);
                                            mat.shader = shaderNew;
                                        }
                                        else if (mat.shader == shaderOld2)
                                        {
                                            Debug.Log("转换:" + mat.name);
                                            mat.shader = shaderNew2;
                                        }
                                        else if (mat.shader == shaderOld3)
                                        {
                                            Debug.Log("转换:" + mat.name);
                                            mat.shader = shaderNew3;
                                        }
                                        else if (mat.shader == shaderOld4)
                                        {
                                            Debug.Log("转换:" + mat.name);
                                            mat.shader = shaderNew4;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Debug.Log("转换完成");
        }

    }
}