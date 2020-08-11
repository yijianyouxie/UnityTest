// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/Details/BillboardWavingDoublePass" {
    Properties {
        _WavingTint ("Fade Color", Color) = (.7,.6,.5, 0)
        _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
        _WaveAndDistance ("Wave and distance", Vector) = (12, 3.6, 1, 1)
        _Cutoff ("Cutoff", float) = 0.5
    }

    SubShader {
        Tags {
            "Queue" = "Geometry+200"
            "IgnoreProjector"="True"
            "RenderType"="GrassBillboard"
            "DisableBatching"="True"
        }
        Cull Off
        LOD 200
        ColorMask RGB

CGPROGRAM
#pragma surface surf Lambert vertex:WavingGrassBillboardVert finalcolor:finalcustomcolor addshadow exclude_path:deferred

#include "UnityCG.cginc"
#include "CYUnityCG.cginc"
#pragma multi_compile __ CY_FOG_ON


sampler2D _MainTex;
fixed _Cutoff;

struct Input {
    float2 uv_MainTex;
    fixed4 color : COLOR;
	CY_FOG_COORDS(1)
};

#include "TerrainEngine.cginc"

void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.color;
    o.Albedo = c.rgb;
    o.Alpha = c.a;
    clip (o.Alpha - _Cutoff);
    o.Alpha *= IN.color.a;
}

void finalcustomcolor(Input IN, SurfaceOutput o, inout fixed4 color)
{
	CY_APPLY_FOG(IN.cyFogCoord, color);
}

ENDCG
    }

    Fallback Off
}
