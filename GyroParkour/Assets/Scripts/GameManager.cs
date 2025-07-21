using Games.TLBB.Log;
using Games.TLBB.Util;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameManager : MonoBehaviour {

    public List<GameObject> levelGOList;
    private List<Vector3> cameraLocalRotationList = new List<Vector3>() { new Vector3(20.484f, 0, 0), new Vector3(0,0,0)};
    //当前关卡
    private int currLevel = 1;
    private Camera cam;

    //level1
    public GameObject ballsParent;
    private List<Transform> ballList;
    private int ballListCount = 0;
    public Animation playerAni;
    private Transform playerTr;
    private static Vector3 leftPos = new Vector3(-0.68f, 0, -6.902f);
    private static Vector3 rightPos = new Vector3(0.81f, 0, -6.902f);

    private static Vector3 bornPos = new Vector3(-0.6f, -0.672f, 26.73f);
    private static Vector3 bornPos2 = new Vector3(0.72f, -0.672f, 26.73f);
    private static Vector3 hidePos = new Vector3(0, 0, -7.6f);
    public float ballShowInterval = 3f;
    private float lastBallShowTime = 0;
    public float ballMoveSpeed = 0.5f;
    private float playerMoveSpeed = 0.2f;
    private bool testLeft = false;
    private string str;
    public Text text;
    private static float itemScore = 80;
    private float totalScore;
    private float textShowDuration = 0.5f;
    private float textLastShowTime = 0f;

    //level2
    public Transform chidourenTr;//移动和旋转
    public Transform level2BallParentTr;
    private List<Transform> dropBallList;
    private Vector3 dropHeight = new Vector3(5.1f, 4, -0.729f);
    private Vector3 initEatBallPos;
    private float borderX = 5.48f;
    private float dropFrequency = 4f;
    private int dropBallListCount = 0;
    private bool died = false;

    public Text totalScoreText;
    public GameObject startPanel;
    private bool started = false;

    private static GameManager _instance;
    public static GameManager GetInstance()
    {
        return _instance;
    }

    private void Awake()
    {
        started = false;
        _instance = this;
        cam = GetComponent<Camera>();        

        currLevel = 1;

        if (null != chidourenTr)
        {
            initEatBallPos = chidourenTr.localPosition;
        }
        PrepareLevel();
    }

    private void PrepareLevel()
    {
        if(null == levelGOList)
        {
            LogSystem.Error("====PrepareLevel, levelGOList is null.");
            return;
        }
        var len = levelGOList.Count;
        GameObject go;
        for(int i = 0; i < len; i++)
        {
            go = levelGOList[i];
            if(null != go)
            {
                go.SetActive(currLevel - 1 == i);
            }
        }

        if(null != cam)
        {
            cam.transform.eulerAngles = cameraLocalRotationList[currLevel - 1];
        }

        if(currLevel == 1)
        {
            if (null != playerAni)
            {
                //默认动作是站立
                playerAni.Play("zhanli");

                playerTr = playerAni.transform;
            }
            //隐藏球列表
            if (null != ballsParent)
            {
                var tr = ballsParent.transform;
                Transform chiTr;
                ballListCount = tr.childCount;
                ballList = new List<Transform>(8);
                for (int i = 0; i < ballListCount; i++)
                {
                    chiTr = tr.GetChild(i);
                    chiTr.localPosition = hidePos;
                    chiTr.gameObject.SetActive(false);
                    ballList.Add(chiTr);
                }
            }
        }
        else if(currLevel == 2)
        {
            if (null != chidourenTr)
            {
                var pos = chidourenTr.localPosition;
                chidourenTr.localPosition = initEatBallPos;
            }

            if (null != level2BallParentTr)
            {
                var tr = level2BallParentTr.transform;
                Transform chiTr;
                dropBallListCount = tr.childCount;
                dropBallList = new List<Transform>(8);
                for (int i = 0; i < dropBallListCount; i++)
                {
                    chiTr = tr.GetChild(i);
                    chiTr.localPosition = hidePos;
                    chiTr.gameObject.SetActive(false);
                    chiTr.GetComponent<Rigidbody>().detectCollisions = false;
                    dropBallList.Add(chiTr);
                }
            }
        }
    }

    public void LevelStart()
    {
        if(null != startPanel)
        {
            startPanel.SetActive(false);
        }

        if(currLevel == 1)
        {
            if (null != playerAni)
            {
                //默认动作是站立
                playerAni.Play("paobu");
            }
        }
        else if(currLevel == 2)
        {

        }

        started = true;
        GyroController_Player.ControllGyroPlayer(true);
        GyroController.GetInstance().AddGyroData((int)GyroController.GYROFUNCTYPE.SCENECAMERA);
    }

    public void LevelOver()
    {
        text.text = "";
        totalScore = 0;
        totalScoreText.text = "总分：" + totalScore.ToString();

        started = false;
        currLevel += 1;
        PrepareLevel();

        if (null != startPanel)
        {
            startPanel.SetActive(true);
        }
    }

    private void Update()
    {
        if(!started)
        {
            return;
        }

        UpdateLevel();
    }

    private void UpdateLevel()
    {
        if(currLevel == 1)
        {
            if (null == ballList)
            {
                LogSystem.Error("====ballList is null.");
                return;
            }
            //显示出来的球开始移动
            var time = Time.realtimeSinceStartup;
            Transform tr;
            if (time - lastBallShowTime >= ballShowInterval)
            {
                lastBallShowTime = time;
                for (int i = 0; i < ballListCount; i++)
                {
                    tr = ballList[i];
                    if (tr.localPosition.z <= hidePos.z)
                    {
                        tr.gameObject.SetActive(true);
                        tr.localPosition = Random.Range(0f, 2f) > 1 ? bornPos : bornPos2;
                        break;
                    }
                }
            }

            //移动
            Vector3 localPos;
            for (int i = 0; i < ballListCount; i++)
            {
                tr = ballList[i];
                localPos = tr.localPosition;
                localPos.z -= ballMoveSpeed;
                tr.localPosition = localPos;

                if (Mathf.Abs(localPos.z - playerTr.localPosition.z) <= 1f)
                {
                    //在这期间只检测一次
                    if (time - textLastShowTime > textShowDuration)
                    {
                        textLastShowTime = time;
                        if (Mathf.Abs(localPos.x - playerTr.localPosition.x) <= 0.5f)
                        {
                            totalScore -= itemScore;
                            if (totalScore <= 0)
                            {
                                totalScore = 0;
                            }
                            text.text = "-80";
                            text.color = Color.red;
                        }
                        else
                        {

                            totalScore += itemScore;
                            text.text = "+80";
                            text.color = new Color(0, 159f / 255f, 14f / 255f, 1);
                        }
                    }
                }
            }

            if (time - textLastShowTime > textShowDuration)
            {
                text.text = "";
            }

            totalScoreText.text = "总分：" + totalScore.ToString();

            //if (testLeft)
            //{
            //    OnMove(new Vector2(-1f, 0));
            //}
            //else
            //{
            //    OnMove(new Vector2(1f, 0));
            //}
        }
        else if(currLevel == 2)
        {
            if (null == dropBallList)
            {
                LogSystem.Error("====dropBallList is null.");
                return;
            }
            //显示出来的球开始移动
            var time = Time.realtimeSinceStartup;
            Transform tr;
            if (time - lastBallShowTime >= ballShowInterval)
            {
                lastBallShowTime = time;
                for (int i = 0; i < dropBallListCount; i++)
                {
                    tr = dropBallList[i];
                    if (!tr.gameObject.activeSelf)
                    {
                        tr.gameObject.SetActive(true);
                        tr.localPosition = new Vector3(Random.Range(-dropHeight.x, dropHeight.x), dropHeight.y, dropHeight.z);
                        tr.GetComponent<Rigidbody>().detectCollisions = true;
                        break;
                    }
                }
            }

            for (int i = 0; i < dropBallListCount; i++)
            {
                tr = dropBallList[i];
                if (tr.gameObject.activeSelf)
                {
                    if(tr.localPosition.y < -dropHeight.y)
                    {
                        tr.gameObject.SetActive(false);
                        tr.GetComponent<Rigidbody>().detectCollisions = false;
                    }
                }
            }

            if (time - textLastShowTime > textShowDuration)
            {
                text.text = "";
            }

            totalScoreText.text = "总分：" + totalScore.ToString();
        }
    }

    public void OnMove(Vector2 vec)
    {
        if(!started)
        {
            return;
        }

        if(currLevel == 1)
        {
            if(null == playerTr)
            {
                str = "====PlayerTr is null.";
                LogSystem.Error(str);
                return;
            }
            var pos = playerTr.localPosition;
            var xValue = vec.x;
            str = "====xValue:" + xValue;
            if (xValue > 0)
            {
                pos.x += playerMoveSpeed * Mathf.Abs(xValue);
                if(pos.x >= rightPos.x)
                {
                    pos.x = rightPos.x;
                }
                playerTr.localPosition = pos;
                str += " right:" + pos.x;
            }
            else if(xValue < 0)
            {
                pos.x -= playerMoveSpeed * Mathf.Abs(xValue);
                if (pos.x <= leftPos.x)
                {
                    pos.x = leftPos.x;
                }
                playerTr.localPosition = pos;
                str += " left:" + pos.x + " :" + leftPos.x;
            }
        }
        else if(currLevel == 2)
        {            
            if(null == chidourenTr)
            {
                LogSystem.Error("====Update,chidourenTr is null.");
                return;
            }

            var tr = chidourenTr;

            var pos = tr.localPosition;
            if(died)
            {
                pos.y -= 0.1f;
                tr.localPosition = pos;
                return;
            }
            var xValue = vec.x;
            if (xValue > 0)
            {
                pos.x += playerMoveSpeed * Mathf.Abs(xValue);
                tr.localPosition = pos;
                tr.localScale = Vector3.one;
            }
            else if (xValue < 0)
            {
                pos.x -= playerMoveSpeed * Mathf.Abs(xValue);
                tr.localPosition = pos;
                tr.localScale = new Vector3(-1, 1, 1);
            }

            if(Mathf.Abs(tr.localPosition.x) > borderX)
            {
                Die();
                return;
            }

            //检测是否吃到了
            for (int i = 0; i < dropBallListCount; i++)
            {
                tr = dropBallList[i];
                if (tr.gameObject.activeSelf)
                {
                    if(Mathf.Abs(tr.localPosition.x - chidourenTr.localPosition.x) < 0.5f
                    && Mathf.Abs(tr.localPosition.y - chidourenTr.localPosition.y) < 0.5f)
                    {
                        tr.gameObject.SetActive(false);
                        tr.GetComponent<Rigidbody>().detectCollisions = false;

                        textLastShowTime = Time.realtimeSinceStartup;
                        totalScore += itemScore;
                        text.text = "+80";
                        text.color = new Color(0, 159f / 255f, 14f / 255f, 1);
                    }
                }
            }
        }
    }

    private void Die()
    {
        died = true;

        text.text = "";
        totalScore = 0;
        totalScoreText.text = "总分：" + totalScore.ToString();

        StartCoroutine(Restart());
        
    }
    IEnumerator Restart()
    {
        yield return new WaitForSeconds(1f);
        started = false;
        died = false;
        if (null != startPanel)
        {
            startPanel.SetActive(true);
        }

        PrepareLevel();
    }

    private void OnDestroy()
    {
        
    }

    //private void OnGUI()
    //{
    //    if (GUI.Button(new Rect(0, 0, 100, 80), "TestLeft" + testLeft))
    //    {
    //        testLeft = true;

    //        if (testLeft)
    //        {
    //            OnMove(new Vector2(-1f, 0));
    //        }
    //        else
    //        {
    //            OnMove(new Vector2(1f, 0));
    //        }
    //    }
    //    if (GUI.Button(new Rect(0, 150, 100, 80), "TestRight" + testLeft))
    //    {
    //        testLeft = false;

    //        if (testLeft)
    //        {
    //            OnMove(new Vector2(-1f, 0));
    //        }
    //        else
    //        {
    //            OnMove(new Vector2(1f, 0));
    //        }
    //    }


    //    GUI.TextArea(new Rect(0, 300, 400, 100), str);
    //}
}
