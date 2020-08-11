using UnityEngine;
using System.Collections;

public class DownloadObbExample : MonoBehaviour {


	private string expPath;
	private string logtxt;
	private bool alreadyLogged = false;
	private string nextScene = "test1";
	private bool downloadStarted;

	void log( string t )
	{
		logtxt += t + "\n";
		Debug.Log(logtxt);
//		GUI.Label(new Rect(10, 300, Screen.width-10, 20),logtxt);

	}
	void OnGUI()
	{
		if (!GooglePlayDownloader.RunningOnAndroid())
		{
			GUI.Label(new Rect(10, 10, Screen.width-10, 20), "Use GooglePlayDownloader only on Android device!");
			return;
		}
		
		expPath = GooglePlayDownloader.GetExpansionFilePath();
		log("expPath:"+expPath);
		if (expPath == null)
		{
				GUI.Label(new Rect(10, 10, Screen.width-10, 20), "External storage is not available!");
		}
		else
		{
			string	mainPath_ = GooglePlayDownloader.GetMainOBBPath(expPath);
			string patchPath = GooglePlayDownloader.GetPatchOBBPath(expPath);
			log("mainpath:"+mainPath_);
			log("patchPath:"+patchPath);
			GUI.Label(new Rect(10, 10, Screen.width-10, 20), "Main = ..."  + ( mainPath_ == null ? " NOT AVAILABLE" :  mainPath_));
			GUI.Label(new Rect(10, 25, Screen.width-10, 20), "Patch = ..." + (patchPath == null ? " NOT AVAILABLE" : patchPath.Substring(expPath.Length)));
			if (mainPath_ == null || patchPath == null)
				if (GUI.Button(new Rect(10, 100, 100, 100), "Fetch OBBs"))
					GooglePlayDownloader.FetchOBB();
					StartCoroutine(loadLevel());
		}

		if(isLoad){
			if (GUI.Button(new Rect(10, 300, 100, 100), "Load Level"))
				Application.LoadLevel(nextScene);
		}
		log("Load Level status: Get main path-"+mainPath);
		log("Load Level status: Loading uri-"+uri);
		log("Load Level status: www err-"+wwwErr);
		log("Load Level status: "+status);
		GUI.Label(new Rect(10,550,Screen.width-10,20),"www err:"+wwwErr);
		GUI.Label(new Rect(10,600,Screen.width-10,20),"uri:"+uri);
		GUI.Label(new Rect(10,650,Screen.width-10,20),"status:"+status);
		if(!www.isDone){
			progress = www.progress;
		}
		GUI.Label(new Rect(10,700,Screen.width-10,20),"progress:"+www.progress);
	}
	float progress;
	bool isLoad = false;
	string uri ;
	string mainPath;
	string wwwErr;
	string status;
	WWW www = null;
	protected IEnumerator loadLevel()
	{


		do
		{
			yield return new WaitForSeconds(0.5f);
			mainPath = GooglePlayDownloader.GetMainOBBPath(expPath);

//			log("waiting mainPath "+mainPath);
		}
		while( mainPath == null);

		if( downloadStarted == false )
		{
			downloadStarted = true;
			
			 uri = "file://" + mainPath;
//			log("downloading " + uri);

			 www = WWW.LoadFromCacheOrDownload(uri , 0);		
			
			// Wait for download to complete
			yield return www;
			status = "www loaded";
			if (www.error != null)
			{
				wwwErr = www.error;

			}
			else
			{
				isLoad = true;
			}
		}
	}

}
