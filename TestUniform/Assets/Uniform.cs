using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Uniform : MonoBehaviour {
    public Vector4 col = new Vector4();
	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        Shader.SetGlobalVector("_Col", col);
    }
}
