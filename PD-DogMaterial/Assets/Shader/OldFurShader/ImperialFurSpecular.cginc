		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
 
		sampler2D _FurSpecularMap;
		sampler2D _SpecGlossMap;
		
		#include "IFCommonVariables.cginc"

		fixed3 _FurSpecularColor;
		fixed3 _SpecularColor;

		void surfSkin (Input IN, inout SurfaceOutputStandardSpecular o) {
			if (_SkinMode == 0) {
				fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _FurColor;				
				o.Albedo = c.rgb;
			
				if (_UseFurSecondMap != 0) {
					float4 m = tex2D(_FurSpecularMap, IN.uv_MainTex);
					o.Specular = m.rgb;
					o.Smoothness = m.a; 
				} else {
					o.Specular = _FurSpecularColor;
					o.Smoothness = _FurGlossiness;
				}
			} else {
				fixed4 c = tex2D (_SkinTex, IN.uv_MainTex) * _Color;
				o.Albedo = c.rgb;
			
				if (_UseSkinSecondMap != 0) {
					float4 m = tex2D(_SpecGlossMap, IN.uv_MainTex);
					o.Specular = m.rgb;
					o.Smoothness = m.a; 
				} else {
					o.Specular = _SpecularColor;
					o.Smoothness = _Glossiness;
				}
				
				o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_MainTex)) * _BumpScale;
			}
		}

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {				
			#include "IFCommonSurface.cginc"
			
			if (_UseFurSecondMap != 0) {
				float4 m = tex2D(_FurSpecularMap, IN.uv_MainTex);
				o.Specular = m.rgb;
				o.Smoothness = m.a * n.r; 
			} else {
				o.Specular = _FurSpecularColor;
				o.Smoothness = _FurGlossiness * n.r;
			}          				
		}
		
		//CGINCLUDE
		fixed4 Dissolve( fixed4 c, Input surfIN)
		{
			// fixed ClipTex = tex2D (_DissolveSrc, (surfIN.uv_MainTex+_DissolveInfo.y)/_DissolveInfo.z).r;
			fixed ClipTex2 = tex2D (_DissolveSrc, (surfIN.uv_MainTex1.xy+_DissolveInfo.y)/_DissolveInfo.z).r;
			fixed ClipTex3 = tex2D (_DissolveSrc, (surfIN.uv_MainTex1.yz+_DissolveInfo.y)/_DissolveInfo.z).r;
			// fixed contDis = tex2D(_ControlTex,surfIN.uv_MainTex).g;
			
			fixed ClipTex = ( ClipTex2 + ClipTex3 )* 0.5;//lerp( (ClipTex2 + ClipTex3 )* 0.5, ClipTex, max((contDis)-_ExtraControl.z,0) );
			ClipTex -= surfIN.uv_MainTex1.z * _DissolveInfo.w;
			fixed ClipAmount = max(ClipTex - _DissolveAmount,0);
			ClipAmount = min( ClipAmount, _DissolveInfo.x);
			
			c.xyzw = lerp(c.xyzw, c.xyzw*_DissolveColor*ClipTex, ClipAmount);
			
			return c;
		}
		
		//Bake
		//fixed4 Dissolve2( fixed4 c, Input surfIN, float2 uv2)
		//{
		//	fixed ClipTex = tex2D (_DissolveSrc, uv2).r;
		//	//fixed contDis = tex2D(_ControlTex,surfIN.uv_MainTex).g;
		//	//ClipTex = lerp( 1, ClipTex, contDis );
		//	fixed ClipAmount = max(ClipTex - _DissolveAmount,0);
		//	ClipAmount = min( ClipAmount, _DissolveInfo.x);
		//	c = lerp(c, c*_DissolveColor*ClipTex, ClipAmount);
		//	c.a *= _DissolveInfo.w;
		//	//if(_DissolveInfo.w == 0)
		//	//{
		//	//	clip(-1);
		//	//}
		//	return c;
		//}
		
		//void ColorMaskMudule( Input surfIN, inout SurfaceOutputStandardSpecular o)
		//{
		//	fixed3 cc = tex2D (_DecalColorControlSrc, surfIN.uv_MainTex).xyz;  
		//	//if( cc.r > 0.5 )
		//	//{
		//	//	cc.r = 1.0f;
		//	//	_DecalColor1 = 1.0f;
		//	//}
		//	o.Albedo *= _DecalColor1 * cc.r ;
		//}
		//ENDCG

		#include "IFCommonVert.cginc"
		
