using UnityEngine;
using System.Collections;
using System.IO;

public class TestAndroidProject : MonoBehaviour {

    public GameObject cube;
    private Vector2 scrollPosition;

    // Use this for initialization
    void Start () {
        Texture2D obj = (Texture2D)Resources.Load("NewCommon01_t");
        Debug.LogError("==========================图片资源加载成功。" + obj);
	}
	
	// Update is called once per frame
	void Update () {
	    if( null != cube)
        {
            cube.transform.localEulerAngles = new Vector3( Time.realtimeSinceStartup*20, Time.realtimeSinceStartup*5, Time.realtimeSinceStartup);
        }
	}

    private void OnGUI()
    {
        scrollPosition = GUILayout.BeginScrollView(scrollPosition, GUILayout.Width(Screen.width * 2 / 3), GUILayout.Height(Screen.height));
        string str = Application.dataPath + "!assets/";
        string str2 = Application.streamingAssetsPath + "/";

        string str3 = "";
        //DirectoryInfo dir = new DirectoryInfo(@str2);
        //foreach (FileInfo dChild in dir.GetFiles("*"))
        //{
        //    str3 += dChild.Name;
        //}
        string str4 = "";
        //DirectoryInfo dir4 = new DirectoryInfo(@str);
        //foreach (FileInfo dChild in dir4.GetFiles("*"))
        //{
        //    str4 += dChild.Name;
        //}
        GUILayout.TextArea(str + "\n" + str2 + "\n" + str3 + "\n" + str4);
        GUI.EndScrollView();
    }
}
