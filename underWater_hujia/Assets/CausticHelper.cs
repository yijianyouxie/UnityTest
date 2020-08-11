using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CausticHelper : MonoBehaviour
{
    [Range(0.0f, 40.0f)]
    public float causticSpeed = 15.0f;
    [Range(0.00001f, 0.1f)]
    public float causticsSize = 0.003f;
    [Range(0.0f, 3.0f)]
    public float causticsIntinsity = 1.0f;

    public Texture2D causticsTex = null;

    private void OnEnable()
    {
        Shader.EnableKeyword("CausticEffect");
    }

    private void OnDisable()
    {
        Shader.DisableKeyword("CausticEffect");
    }

    private void Update()
    {
        var vector = new Vector4(causticsSize, causticSpeed, causticsIntinsity, 0);
        Shader.SetGlobalVector("_CausticParam", vector);
        Shader.SetGlobalTexture("_CausticsTex", causticsTex);
    }
}
