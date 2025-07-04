Shader "TLStudio/Effect/EffectUber"
{
	Properties
	{
		[Header(Blend Mode xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _SrcBlend("    源混合因子SrcBlend", Float) = 5
		[MaterialEnum(UnityEngine.Rendering.BlendMode)] _DstBlend("    目标混合因子DestBlend", Int) = 10
		[MaterialEnum(UnityEngine.Rendering.CullMode)] _Cull("    裁剪模式", Int) = 0
		[MaterialEnum(Off, 0, On, 1)]_ZWrite("    Z写入模式", Int) = 0

		[Space(20)]
		[NoScaleOffset]_MainTex ("    主贴图 重复偏移使用CustomData1", 2D) = "white" {}
		[Toggle]_MainUWrapMode("    主贴图U WrapMode 0:Repeat 1:Clmap", int) = 0
		[Toggle]_MainVWrapMode("    主贴图V WrapMode 0:Repeat 1:Clmap", int) = 0
		_MainTexMaskChannel("    主贴图透明使用的通道rgba(值是0或1)", vector) = (0, 0, 0 ,1)
		_MainCol("_MainCol", Color) = (1,1,1,1)
		/*_MainColIntensity("MainColIntensity", float) = 1*/
		_RepeateUV("    xy重复 zw偏移(可预览)", vector) = (1,1,0,0)
		_MainFlowSpeed("    主贴图uv流动速度", vector) = (0,0,0,0)
		[Toggle]_UseCustomData("    是否使用粒子Custom", int) = 0
		[Header(ColorMode xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Brightness("    亮度 正常值为1", float) = 1	//直接倍数rgb
		_Saturation("    饱和度 正常值为1", Range(0,10)) = 1	//饱和度
		_Contrast("    对比度 正常值为1", Range(-1,5)) = 1		//对比度
		_Lightness("    明度 正常值为1",float) = 1	//明度
		[Space]
		[Header(Bloom xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		[Toggle]_BloomSwitch("    Bloom开关 0关闭 1开启", int) = 0
		_BloomColor("    BloomColor", Color) = (1,1,1,1)
		_BloomStrength("    Bloom力度 值越小越亮", Range(-2, 20)) = 0.5

		[Space]
		[Header(Alpha xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Alpha("    Alpha调节", float) = 1
		_Range("    范围调节", float) = 0

		[Space]
		[Header(Polar xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		[Toggle]_Polar("    是否使用极坐标.如果使用极坐标，请去掉贴图的GenerateMipMaps", int) = 0

		[Space]
		[Header(Rotate xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_Rotate("    贴图旋转角度", Range(0, 360)) = 0

		[Space]
		[Header(Multiply xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_GlossTex("    相乘GlossTex", 2D) = "white" {}
		_GlossCol("    _GlossCol", Color) = (1,1,1,1)
		_GlossSpeedx("    相乘贴图u速度", float) = 0
		_GlossSpeedy("    相乘贴图v速度", float) = 0

		[Space]
		[Header(Add xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_AdjustTex("    相加AdjustTex", 2D) = "black" {}
		_AdjustCol("    _AdjustCol", Color) = (1,1,1,1)
		_AdjustSpeedx("    相加贴图u速度", float) = 0
		_AdjustSpeedy("    相加贴图v速度", float) = 0

		[Space]
		[Header(Distortion xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_OffsetTexture("    扭曲贴图NoiseTexture", 2D) = "white" {}
		_DistabilizationMask("    扭曲Mask(黑白图)", 2D) = "white" {}

		_NoisePower("    扭曲强度", Range(-1,1)) = 0
		/*_Intensity("    u扭曲强度", Range(-1, 1)) = 0
		_IntensityVertical("    v扭曲强度", Range(-1, 1)) = 0*/
		_HorizontalSpeed("    u速度",float) = 0
		_VerticalSpeed("    v速度",float) = 0
		_Utiling("    u tiling", Range(0, 5)) = 1
		_Vtiling("    V tiling", Range(0, 5)) = 1
		[Space]
		_MaskTex("    偏移遮罩，uv重复使用custom2.xy", 2D) = "white" {}
		[Toggle]_MaskUWrapMode("    偏移遮罩U WrapMode 0:Repeat 1:Clmap", int) = 0
		[Toggle]_MaskVWrapMode("    偏移遮罩V WrapMode 0:Repeat 1:Clmap", int) = 0
		_MaskUVOffset("    偏移遮罩uv偏移使用xy值 |custom2.z", vector) = (0,0,0,0)
		_MaskOffsetTexture("    偏移遮罩的扭曲贴图", 2D) = "white" {}
		_IntensityMask("    偏移遮罩贴图水平扭曲强度", Range(-1, 1)) = 0
		_IntensityMaskVertical("    偏移遮罩贴图垂直扭曲强度", Range(-1, 1)) = 0
		_MaskHorizontalSpeed("    遮罩的扭曲u速度",float) = 0
		_MaskVerticalSpeed("    遮罩的扭曲v速度",float) = 0

		[Space]
		[Header(Dissove xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_DissoveTex("    溶解DissoveTex", 2D) = "white" {}
		_AlphaCutoff("    溶解变化custom2.w", Range(0,1)) = 0
		_DissoveWidth("    溶解硬度",Range(0.001,1)) = 1
		_DissoveOffsetTexture("    溶解扭曲贴图NoiseTexture", 2D) = "white" {}
		_DissoveIntensity("    溶解水平扭曲强度", Range(-1, 1)) = 0
		_DissoveIntensityVertical("    溶解垂直扭曲强度", Range(-1, 1)) = 0
		_DissoveHorizontalSpeed("    溶解u速度HorizontalSpeed",float) = 0
		_DissoveVerticalSpeed("    溶解v速度VerticalSpeed",float) = 0
		_DissoveDirectionTex("    定向溶解数据图", 2D) = "white" {}
		_DissoveDirEdgeRange("    定向溶解羽化宽度", Range(0.001, 1)) = 0.5
		_DissoveDirAngle("    定向溶解uv旋转角度", Range(0, 360)) = 0

		[Space]
		[Header(CircleMask xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_CircleMaskCenter("    圆形遮罩中心", vector) = (0.5, 0.5, 0, 0)
		_CircleMaskRadius("    圆形遮罩半径", Range(0.001,1)) = 0
		_CircleFeatherWidth("    圆形遮罩羽化宽度", Range(0.0001,10)) = 0

		[Space]
		[Header(ScanMask xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_ScanMaskCenter("    扫描遮罩中心", vector) = (0.5, 0.5, 0, 0)
		_ScanRotateAngle("    扫描遮罩旋转", Range(0,6.28)) = 0
		_ScanRangeAngle("    扫描遮罩范围", Range(0,6.28)) = 6.28
		_ScanFeatherWidth("    扫描遮罩羽化宽度", Range(0,5)) = 0

		[Space]
		[Header(Fresnel xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		[Toggle]_ApplyFresnel("    是否应用菲涅尔", int) = 1
		_FresnelColor("    菲涅尔颜色", Color) = (1,1,1,1)
		_FresnelRimColor("    菲涅尔边缘光颜色", Color) = (0,0,0,1)
		_FresnelRimPower("    菲涅尔边缘光强度", Range(0, 3)) = 0.5

		/*[Space]
		[Header(EdgeFeather xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_EdgeFeatherRange("    羽化范围", Range(0, 5)) = 5*/

		[Space]
		[Header(TexScale xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_TexScale("    贴图中心缩放clamp", Range(0.01, 10)) = 1
		[Toggle]_ApplyPolar("    缩放是否应用极坐标", int) = 0

		[Space]
		[Header(FinalControlTex xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_FinalControlTex("    最终控制图", 2D) = "white" {}
		[Space]
		[Header(_FinalGradientTex xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_FinalGradientTex("    渐变控制图", 2D) = "white" {}
		[Toggle]_FinalGradientUWrapMode("    渐变控制图U WrapMode 0:Repeat 1:Clmap", int) = 0
		[Toggle]_FinalGradientVWrapMode("    渐变控制图V WrapMode 0:Repeat 1:Clmap", int) = 0

		[Space]
		[Header(FinalMaskTex xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)]
		_FinalMaskTex("总遮罩MaskTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "IgnoreProjector" = "True"
				"Queue" = "Transparent"
				"RenderType" = "Transparent" }

		LOD 100

		Pass
		{
			Blend[_SrcBlend][_DstBlend]
			Cull [_Cull]
			Lighting Off
			ZWrite [_ZWrite]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "EffectUber.cginc"
			#pragma exclude_renderers xbox360 ps3 flash d3d11_9x

			//Custom Vertex Streams里有的属性，这里也有要有，并且要被实际的使用到
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				float4 uv1 : TEXCOORD1;//CustomData1
				float4 uv2 : TEXCOORD2;//CustomData2
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
				float4 customUV2 : TEXCOORD3;
				fixed4 color : COLOR;
				float4 posWorld : TEXCOORD4;
				float3 normalDir : TEXCOORD5;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				//o.uv1 = v.uv * v.uv1.xy + v.uv1.zw;//uv的变化要放到顶点着色器中，如果放到像素着色器中是，当没有开启Custom Vextex Streams时，uv显示不正确
				o.uv1 = v.uv1;
				o.uv2 = v.uv * v.uv2.xy + v.uv2.zw;
				o.customUV2 = v.uv2;
				o.color = v.color;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = ProcessUVColor(_MainTex, i.uv, i.uv1, i.uv2, i.customUV2, i.posWorld, i.normalDir, i.color);

				return fixed4(col.rgb, col.a);
			}
			ENDCG
		}
	}
}
