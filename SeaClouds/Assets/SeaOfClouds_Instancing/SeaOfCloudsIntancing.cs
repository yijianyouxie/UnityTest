using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class SeaOfCloudsIntancing : MonoBehaviour
{
    [Range(0f, 20f)]
    public int instanceCount = 20;
    public Mesh instanceMesh;
    public Material instanceMaterial;
    [Range(0f, 3f)]
    private float pow = 2f;
    [Range(0f, 10f)]
    public float High = 3.2f;

    private Matrix4x4[] m_atrix4x4s = new Matrix4x4[45];
    private Vector4[] color = new Vector4[45];
    private float[] offset = new float[45];
    private float[] clip = new float[45];
    private MaterialPropertyBlock prop ;

    private bool IsGPUInstanceSupported = true;

    void Start()
    {
        prop = new MaterialPropertyBlock();

        IsGPUInstanceSupported = SystemInfo.supportsInstancing;
        if(!IsGPUInstanceSupported)
        {
            Debug.LogError("ERROR: SeaOfCloudsIntancing.Start : IsGPUInstanceSupported False!");
        }
    }

    

    void Update()
    {
        if(!IsGPUInstanceSupported)
        {
            return;
        }
        if(prop == null)
        {
            prop = new MaterialPropertyBlock();
        }

        for (int i = 0; i < instanceCount; i++)
        {
            float Count = instanceCount;
            color[i] = Color.white * i / Count;
            offset[i] = i * High / Count;
            clip[i] = Mathf.Pow(i / Count * 2 - 1, pow);
            //clip[i] = Mathf.Sin(((i / Count)+Mathf.PI*2.0f)*Mathf.PI*2.0f) *0.5f+0.5f;
            m_atrix4x4s[i] = transform.localToWorldMatrix;
        }
        //MaterialPropertyBlock prop = new MaterialPropertyBlock();
        prop.SetFloatArray("_offset", offset);
        prop.SetVectorArray("_color", color);
        prop.SetFloatArray("_clip", clip);
        
        if(instanceMesh != null && instanceMaterial != null)
        {
            Graphics.DrawMeshInstanced(instanceMesh, 0, instanceMaterial, m_atrix4x4s, instanceCount, prop, ShadowCastingMode.Off, false);
        }
    }
}
