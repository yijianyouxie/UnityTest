using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using UnityEngine.Experimental.Rendering;

namespace Mongoose
{

    public class VolumetricCloud3DTexGenerator 
    {
        [MenuItem("TLStudio/VolumetricCloud/VolumetricCloud3DTexGenerator", priority = 11)]
        private static void Generate3DNoiseTex()
        {

            //List<Texture2D> t_NoiseTexList = new List<Texture2D>();
            List<Color> t_AllColorList = new List<Color>();


            string t_Path = "Assets/GameMain/Temp/Output3DTex/Base";
            for (int index = 0; index < 16; index++)
            {
                string t_FullPath = t_Path + index.ToString() + ".png";
                Texture2D t_tex = AssetDatabase.LoadAssetAtPath<Texture2D>(t_FullPath);
                if (t_tex != null)
                {
                    t_AllColorList.AddRange(t_tex.GetPixels());
                }
            }

            Texture3D t_DensityTex = new Texture3D(256, 256, 16, TextureFormat.RGBA32, false);

            t_DensityTex.SetPixels(t_AllColorList.ToArray());

            t_DensityTex.Apply();

            AssetDatabase.CreateAsset(t_DensityTex, "Assets/GameMain/Temp/DensityTex.asset");
            AssetDatabase.Refresh();

            //t_Path = "Assets/GameMain/Temp/Output3DTex/Detail";
            //t_AllColorList.Clear();
            //for (int index = 0; index < 32; index++)
            //{
            //    string t_FullPath = t_Path + index.ToString() + ".png";
            //    Texture2D t_tex = AssetDatabase.LoadAssetAtPath<Texture2D>(t_FullPath);
            //    if (t_tex != null)
            //    {
            //        t_AllColorList.AddRange(t_tex.GetPixels());
            //    }
            //}


            //Texture3D t_NoiseTex = new Texture3D(32, 32, 32, TextureFormat.RGBA32, false);

            //t_NoiseTex.SetPixels(t_AllColorList.ToArray());

            //t_NoiseTex.Apply();

            //AssetDatabase.CreateAsset(t_NoiseTex, "Assets/GameMain/Temp/NoiseTex.asset");
            //AssetDatabase.Refresh();
        }

        
        

    }

    public class OperateWindow:EditorWindow
    {

        [MenuItem("TLStudio/VolumetricCloud/Split3DTexture", priority = 10)]
        private static void SplitTexture3D()
        {
            OperateWindow.Init();
        }

        string width = "";
        string height = "";
        string count = "";
        static OperateWindow window;
        public static void Init()
        {
            window = EditorWindow.GetWindow<OperateWindow>("拆分Texture3D", true, typeof(EditorWindow));
            //window.position = m_WinPosition;
            window.minSize = new Vector2(400, 300);
            // window.maxSize = m_WinMaxSize;
            window.wantsMouseMove = true;
            //window.Close();
            
            window.Show();
        }

        private void OnGUI()
        {
            Draw();
        }

        private void Draw()
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical();
            //index = EditorGUILayout.Popup(index, layerNames);
            EditorGUILayout.LabelField("宽度：");
            width = EditorGUILayout.TextField(width);

            EditorGUILayout.Space();
            EditorGUILayout.LabelField("高度：");
            height = EditorGUILayout.TextField(height);

            EditorGUILayout.LabelField("个数：");
            count = EditorGUILayout.TextField(count);

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();
            if (GUILayout.Button("  <<拆分GO>>  ", GUILayout.Height(40)))
            {
                Split3DTexture();
            }
            if (GUILayout.Button("  <<合并GO>>  ", GUILayout.Height(40)))
            {
                Generate3DNoiseTex();
            }

            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical();
        }

        private void Split3DTexture()
        {
            //加载3D纹理
            string path = AssetDatabase.GetAssetPath(Selection.activeObject);
            Debug.LogError("=====================Split3DTexture,path:" + path);
            Texture3D t_tex = AssetDatabase.LoadAssetAtPath<Texture3D>(path);
            Color32[] allColors = t_tex.GetPixels32();
            string folder = "Assets/" + Selection.activeObject.name + "Split";
            if (Directory.Exists(folder))
            {
                DirectoryInfo di = new DirectoryInfo(folder);
                di.Delete(true);
            }
            Directory.CreateDirectory(folder);

            int _count = int.Parse(count);
            int _width = int.Parse(width);
            int _height = int.Parse(height);

            for (int i = 0; i < _count; i++)
            {
                Color32[] part = new Color32[_width * _height];
                Array.Copy(allColors, i * _width * _height, part, 0, _width * _height);

                Texture2D Tex2d = new Texture2D(_width, _height, TextureFormat.RGBA32, false);
                Tex2d.SetPixels32(part);
                Tex2d.Apply();

                string texPath = folder + "/" + i + ".png";

                byte[] bytes = Tex2d.EncodeToPNG();
                FileStream file = File.Open(texPath, FileMode.Create);
                BinaryWriter binary = new BinaryWriter(file);
                binary.Write(bytes);
                file.Close();
            }

            AssetDatabase.Refresh();
        }

        private void Generate3DNoiseTex()
        {

            //List<Texture2D> t_NoiseTexList = new List<Texture2D>();
            List<Color> t_AllColorList = new List<Color>();
            int _count = int.Parse(count);
            int _width = int.Parse(width);
            int _height = int.Parse(height);

            string t_Path = "Assets/DensityTexSplit/";
            Debug.LogError("=================t_Path:" + t_Path );
            for (int index = 0; index < _count; index++)
            {
                string t_FullPath = t_Path + index.ToString() + ".png";
                Texture2D t_tex = AssetDatabase.LoadAssetAtPath<Texture2D>(t_FullPath);
                Debug.LogError("=======================t_tex:" + t_tex);
                if (t_tex != null)
                {
                    t_AllColorList.AddRange(t_tex.GetPixels());
                }
            }

            Texture3D t_DensityTex = new Texture3D(_width, _height, _count, TextureFormat.RGBA32, false);

            t_DensityTex.SetPixels(t_AllColorList.ToArray());

            t_DensityTex.Apply();

            AssetDatabase.CreateAsset(t_DensityTex, "Assets/" + "DensityTexSplit" + ".asset");
            AssetDatabase.Refresh();

            //t_Path = "Assets/GameMain/Temp/Output3DTex/Detail";
            //t_AllColorList.Clear();
            //for (int index = 0; index < 32; index++)
            //{
            //    string t_FullPath = t_Path + index.ToString() + ".png";
            //    Texture2D t_tex = AssetDatabase.LoadAssetAtPath<Texture2D>(t_FullPath);
            //    if (t_tex != null)
            //    {
            //        t_AllColorList.AddRange(t_tex.GetPixels());
            //    }
            //}


            //Texture3D t_NoiseTex = new Texture3D(32, 32, 32, TextureFormat.RGBA32, false);

            //t_NoiseTex.SetPixels(t_AllColorList.ToArray());

            //t_NoiseTex.Apply();

            //AssetDatabase.CreateAsset(t_NoiseTex, "Assets/GameMain/Temp/NoiseTex.asset");
            //AssetDatabase.Refresh();
        }
    }


}

