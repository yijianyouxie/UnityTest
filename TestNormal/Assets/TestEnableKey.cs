using UnityEngine;
using System.Collections;

public class TestEnableKey : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}
	
	void OnGUI()
	{
		if (GUI.Button(new Rect(0, 0, 100, 50), "ON"))
        {
            Shader.EnableKeyword("ON");
			Shader.DisableKeyword("OFF");
        }
		if (GUI.Button(new Rect(0, 60, 100, 50), "OFF"))
        {
            Shader.EnableKeyword("OFF");
			Shader.DisableKeyword("ON");
        }
	}
}
