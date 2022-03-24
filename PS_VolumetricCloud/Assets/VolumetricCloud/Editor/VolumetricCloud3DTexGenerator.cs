using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;



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


}

