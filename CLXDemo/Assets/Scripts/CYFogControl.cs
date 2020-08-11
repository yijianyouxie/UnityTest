using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CYEngine
{
    [System.Serializable]
    public class FogParams
    {
        [Space(10)]
        [Range(0, 1000)]
        public float FogStart = 10.0f;
        [Range(0, 1)]
        public float FogDensity = 0.05058f;
        //[Range(0.01f, 10000)]
        public float FogHeightRange = -485;
        [Range(0, 1)]
        public float FogBaseHeightCoef = 0.5559446f;

        [Space(10)]
        [ColorUsage(true, true, 0, 5, 0, 5)]
        public Color FogColor = new Color(0.13f, 0.26f, 0.48f, 0.6462353f);
        [ColorUsage(true, true, 0, 5, 0, 5)]
        public Color FogColor2 = new Color(0.0f, 0.15f, 0.15f, 0.7165445f);
        [ColorUsage(true, true, 0, 5, 0, 5)]
        public Color FogColor3 = new Color(0.51f, 0.69f, 0.96f, 1.0f);

        [Space(10)]
        [Range(0, 100)]
        public float HeightWeight = 5;
        [Range(0, 10)]
        public float HeightOffset = 1;
        [Range(0, 1)]
        public float FogWeight = 1;
    }

    [ExecuteInEditMode]
    public class CYFogControl : MonoBehaviour
    {
        public FogParams _FogParams;

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

        public void SetFogParams(FogParams fogParams)
        {
            _FogParams = fogParams;
        }

        // Use this for initialization
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            VolFogParam.x = _FogParams.FogStart; 
            VolFogParam.y = _FogParams.FogDensity;
            if (Mathf.Abs(_FogParams.FogHeightRange) < 0.0001f)
            {
                VolFogParam.z = 10000.0f;
            }
            else
            {
                VolFogParam.z = 1.0f / _FogParams.FogHeightRange;
            }
            VolFogParam.w = _FogParams.FogBaseHeightCoef;

            VolFogParam2.x = _FogParams.FogWeight;
            VolFogParam2.y = _FogParams.HeightWeight;
            VolFogParam2.z = _FogParams.HeightOffset;
            VolFogParam2.w = ShowFogInStartDistance ? 1 : 0;

            Shader.SetGlobalVector("FogInfo", VolFogParam);
            Shader.SetGlobalVector("FogColor", _FogParams.FogColor);
            Shader.SetGlobalVector("FogColor2", _FogParams.FogColor2);
            Shader.SetGlobalVector("FogColor3", _FogParams.FogColor3);
            Shader.SetGlobalVector("FogInfo2", VolFogParam2);
        }
    }
}