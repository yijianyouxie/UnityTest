/********************************************************************************
 *	创建人：	 李彬
 *	创建时间：   2015-06-11
 *
 *	功能说明：  DF拉过来
 *	
 *	修改记录：
*********************************************************************************/

using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using UnityEngine;

namespace Games.TLBB.Log
{

    public class LogSystem:BaseLogSystem
    {
        [Conditional("GAMEDEBUG")]
        public static void Debug(string format, params object[] args)
        {
            BaseLogSystem.internal_Debug(format, args);
        }
        [Conditional("GAMEDEBUG")]
        public static void Info(string format, params object[] args)
        {
            BaseLogSystem.internal_Info(format, args);
        }
        [Conditional("GAMEDEBUG")]
        public static void Warn(string format, params object[] args)
        {
            BaseLogSystem.internal_Warn(format, args);
        }
        [Conditional("GAMEDEBUG")]
        public static void Error(string format, params object[] args)
        {
            BaseLogSystem.internal_Error(format, args);
        }
        [Conditional("GAMEDEBUG")]
        public static void Error(string format, System.Exception ex, params object[] args)
        {
            BaseLogSystem.internal_Error(format, ex, args);
        }
        [Conditional("GAMEDEBUG")]
        public static void Assert(bool check, string format, params object[] args)
        {
            BaseLogSystem.internal_Assert(check, format, args);
        }
    }
}

