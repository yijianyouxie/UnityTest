#ifdef ENABLECLOTHFURCONTROLTEX
float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_ClothFurControlTex, UNITY_PROJ_COORD(IN.projPos)));
//float depth = DecodeFloatRGBA(ct_02);
float partZ = IN.projPos.z;
float fade = step(sceneZ - partZ,0.5);

if(sceneZ>partZ)
{
    //return fixed4(1,0,0,1);
}
else
{
    discard;
    return fixed4(1,1,0,1);
}
//  if(sceneZ-partZ<0.001)
//     {
//         //return fixed4(1,0,0,1);
//         //discard;
//     }
//     else{
//         //return fixed4(1,1,0,1);
//     }
#endif
