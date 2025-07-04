#ifndef VOLUME_FOG_INCLUDE  
#define VOLUME_FOG_INCLUDE  	
	
	half _HeightFogStart;
	half _HeightFogEnd;
	half4 _HeightFogColor;

	#define VOLUME_FOG_COLOR(wPos,output) output = CalVolumeFogColor(wPos,output);
	half3 CalVolumeFogColor(float3 worldPos,half3 inputColor)
	{
		//Polybox Calculate heightFog
		half heightFog = saturate((_HeightFogEnd - worldPos.y) / (_HeightFogEnd-_HeightFogStart));
		heightFog = pow(heightFog,2.2);
		
		half4 heightFogColor = _HeightFogColor;
		/*
		half4 heightFogColor = unity_FogColor;
		#ifdef _HEIGHTFOGCOLOR
			heightFogColor = _HeightFogColor;
		#endif
		*/

		inputColor = lerp(inputColor,heightFogColor.rgb,heightFog);
		return inputColor;
	}

#endif 