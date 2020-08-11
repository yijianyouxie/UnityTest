using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CYEngine
{
    [ExecuteInEditMode]
    public class CYFogControl : MonoBehaviour
    {
        [Space(10)]
        [Range(0,1000)]
        public float FogStart = 14.0f;
        [Range(0, 1)]
        public float FogDensity = 1.0f;
        [Range(0.01f, 10000)]
        public float FogHeightRange = 928.0f;
        [Range(0, 1)]
        public float FogBaseHeightCoef = 0.694f;

        [Space(10)]
        public Color FogColor = new Color(0.0f, 0.95f, 0.7f, 0.32f);
 
        public Color FogColor2 = new Color(0.0f, 0.15f, 0.2f, 0.5f);

        public Color FogColor3 = new Color(0.2f, 0.15f, 0.8f, 0.5f);

        [Space(10)]
        [Range(0, 100)]
        public float HeightWeight = 10.6f;
        [Range(0, 10)]
        public float HeightOffset = 1.52f;
        [Range(0, 1)]
        public float FogWeight = 1;
        public bool ShowFogInStartDistance = true;

        private Vector4 VolFogParam;
        private Vector4 VolFogParam2;

        private void OnEnable()
        {
            Shader.EnableKeyword("CY_FOG_ON");
        }
        private void OnDisable()
        {
            Shader.DisableKeyword("CY_FOG_ON");
        }

        // Update is called once per frame
        void Update()
        {
            VolFogParam.x = FogStart; 
            VolFogParam.y = FogDensity;
            VolFogParam.z = 1.0f/FogHeightRange;
            VolFogParam.w = FogBaseHeightCoef;

            VolFogParam2.x = FogWeight;
            VolFogParam2.y = HeightWeight;
            VolFogParam2.z = HeightOffset;
            VolFogParam2.w = ShowFogInStartDistance ? 1 : 0;

            Shader.SetGlobalVector("FogInfo", VolFogParam);
            Shader.SetGlobalVector("FogColor", FogColor);
            Shader.SetGlobalVector("FogColor2", FogColor2);
            Shader.SetGlobalVector("FogColor3", FogColor3);
            Shader.SetGlobalVector("FogInfo2", VolFogParam2);
        }
    }
}