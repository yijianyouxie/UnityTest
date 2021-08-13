using UnityEngine;
using System.Collections;

public class VectorAdd : MonoBehaviour {

    public ComputeShader calcMeshShader;

    private ComputeBuffer preBuffer;
    private ComputeBuffer nextBuffer;
    private ComputeBuffer resultBuffer;

    public Vector3[] array1;
    public Vector3[] array2;
    public Vector3[] resultArr;

    public int length = 16;
    private int kernel;

	// Use this for initialization
	void Start ()
    {
        bool su = SystemInfo.supportsComputeShaders;
        if (!su)
        {
            Debug.LogError("====not supports.");
            return;
        }
        if (null == calcMeshShader)
        {
            Debug.LogError("====ComputeShader is null.");
            return;
        }
        array1 = new Vector3[length];
        array2 = new Vector3[length];
        for(int i = 0;i<length;i++)
        {
            array1[i] = Vector3.one;
            array2[i] = Vector3.one * 2;
        }

        resultArr = new Vector3[length];

        InitBuffers();

        kernel = calcMeshShader.FindKernel("CSMain");
        calcMeshShader.SetBuffer(kernel, "preVertices", preBuffer);
        calcMeshShader.SetBuffer(kernel, "nextVertices", nextBuffer);
        calcMeshShader.SetBuffer(kernel, "Result", resultBuffer);
	}

    private void InitBuffers()
    {
        preBuffer = new ComputeBuffer(array1.Length, 3 * 4);
        preBuffer.SetData(array1);

        nextBuffer = new ComputeBuffer(array2.Length, 3 * 4);
        nextBuffer.SetData(array2);

        resultBuffer = new ComputeBuffer(resultArr.Length, 3*4);
        resultBuffer.SetData(resultArr);
    }

	// Update is called once per frame
	void Update () {
        bool su = SystemInfo.supportsComputeShaders;
        if (!su)
        {
            Debug.LogError("====not supports.");
            return;
        }
        if (null == calcMeshShader)
        {
            Debug.LogError("====ComputeShader is null.");
            return;
        }
        //if (Input.GetKeyDown(KeyCode.P))
        //{
            calcMeshShader.Dispatch(kernel, 2, 2, 1);
            resultBuffer.GetData(resultArr);
            Debug.LogError("====" + resultArr[0]);

            //resultBuffer.Release();
        //}

	}

    private string str = "";
    private void OnGUI()
    {
        str = GUI.TextField(new Rect(0, 0, 100, 30), resultArr[0].ToString());
    }

    private void OnDestroy()
    {
        preBuffer.Release();
        nextBuffer.Release();
        resultBuffer.Release();
    }
}
