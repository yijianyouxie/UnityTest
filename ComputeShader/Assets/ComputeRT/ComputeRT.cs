using UnityEngine;
using System.Collections;

public class ComputeRT : MonoBehaviour {

    public ComputeShader computeShader;
    public Material panelMat;

    private RenderTexture rt;
    private int kernel;

    public Color color;

    public Color[] colors;
    private Vector4[] colorVectors;

	// Use this for initialization
	void Start () {

        bool su = SystemInfo.supportsComputeShaders;
        if (!su)
        {
            Debug.LogError("====not supports.");
            return;
        }
        if (null == computeShader)
        {
            Debug.LogError("====ComputeShader is null.");
            return;
        }

        if(null == panelMat)
        {
            Debug.LogError("====panelMat is null.");
            return;
        }
        kernel = computeShader.FindKernel("CSMain");

        //rt = RenderTexture.GetTemporary(512, 512, 24);
        rt = new RenderTexture(512, 512, 24);
        rt.enableRandomWrite = true;
        rt.Create();
        //computeShader.SetTexture(kernel, "Result", rt);
        //computeShader.Dispatch(kernel, 32, 32, 1);

        //panelMat.mainTexture = rt;
        //转换color2vector
        int len = colors.Length;
        colorVectors = new Vector4[len];
        for(int i = 0;i<len;i++)
        {
            colorVectors[i] = new Vector4(colors[i].r, colors[i].g, colors[i].b, colors[i].a);
        }
	}
	
	// Update is called once per frame
	void Update () {

        bool su = SystemInfo.supportsComputeShaders;
        if (!su)
        {
            Debug.LogError("====not supports.");
            return;
        }
        computeShader.SetVector("color", color);
        computeShader.SetFloat("time", Time.time);
        computeShader.SetVectorArray("colors", colorVectors);
        computeShader.SetTexture(kernel, "Result", rt);
        computeShader.Dispatch(kernel, 32, 32, 1);

        panelMat.mainTexture = rt;
    }

    private void OnDestroy()
    {
        if(null != panelMat)
        {
            panelMat.mainTexture = null;
        }
        if( null != rt)
        {
            DestroyImmediate(rt);
        }
    }
}
