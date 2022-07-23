using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace mcDesktopCapture
{
    [Serializable]
    public class WindowProperty
    {
        [Serializable]
        public class Frame
        {
            public int width;
            public int height;
        }
        [Serializable]
        public class RunningApplication
        {
            public string applicationName;
            public string bundleIdentifier;
        }
        public int windowID;
        public string title;
        public bool isOnScreen;
        public RunningApplication owningApplication;
        public Frame frame;
    }

    [Serializable]
    public class WindowList
    {
        public int count;
        public WindowProperty[] windows;
    }

    [Serializable]
    public class StartCaptureConfig
    {
        public int windowID;
        public int width;
        public int height;
        public bool showsCursor;
    }

    public static class DesktopCapture2
    {
        [DllImport("mcDesktopCapture")]
        private static extern long mcDesktopCapture2_addTwo(long src);

        [DllImport("mcDesktopCapture")]
        private static extern string mcDesktopCapture2_init();

        [DllImport("mcDesktopCapture")]
        private static extern void mcDesktopCapture2_destroy();

        [DllImport("mcDesktopCapture")]
        private static extern string mcDesktopCapture2_windows();

        [DllImport("mcDesktopCapture")]
        private static extern void mcDesktopCapture2_startWithWindowID(string config);

        [DllImport("mcDesktopCapture")]
        private static extern void mcDesktopCapture2_stop();

        [StructLayout(LayoutKind.Sequential)]
        struct FrameEntity
        {
            public long width;
            public long height;
            public IntPtr texturePtr;
        }
        [DllImport("mcDesktopCapture")]
        private static extern FrameEntity mcDesktopCapture2_getTexture();

        private static bool inited = false;
        private static bool isRunning = false;
        private static Texture2D _texture = null;

        /// <summary>
        /// Get the list of windows that can be captured.
        /// This property must be called after Init.
        /// </summary>
        public static WindowProperty[] WindowList
        {
            get
            {
                var str = mcDesktopCapture2_windows();
                var list = JsonUtility.FromJson<WindowList>(str);
                return list.windows;
            }
        }

        /// <summary>
        /// Initialize mcDesktopCapture2.
        /// </summary>
        public static void Init()
        {
            if (inited) return;
            string res = mcDesktopCapture2_init();
            inited = res == "completed";
            if (!inited) Log($"failed to init: {res}");
        }

        /// <summary>
        /// Close mcDesktopCapture2.
        /// This function must be called after Init.
        /// </summary>
        public static void Destroy()
        {
            if (!inited) return;
            mcDesktopCapture2_destroy();
            inited = false;
        }

        /// <summary>
        /// Start capturing the display.
        /// This function must be called after Init.
        /// </summary>
        /// <param name="windowID">Captures only the specified windowID.</param>
        /// <param name="width">The width of the output.</param>
        /// <param name="height">The height of the output.</param>
        /// <param name="showsCursor">A rectangle that specifies the source area to capture.</param>
        public static void StartCaptureWithWindowID(int windowID, int width, int height, bool showsCursor)
        {
            if (!inited || isRunning) return;
            isRunning = true;
            var config = new StartCaptureConfig
            {
                windowID = windowID,
                width = width,
                height = height,
                showsCursor = showsCursor
            };
            var str = JsonUtility.ToJson(config);
            Log($"mcDesktopCapture2: Start Capture: {str}");
            mcDesktopCapture2_startWithWindowID(str);
        }

        /// <summary>
        /// Stop capturing the display.
        /// This function must be called after Init.
        /// </summary>
        public static void StopCapture()
        {
            if (!inited || !isRunning) return;
            _texture = null;
            Log("mcDesktopCapture: Stop Capture");
            mcDesktopCapture2_stop();
            isRunning = false;
        }

        /// <summary>
        /// Get captured video frame.
        /// This function must be called after Init.
        /// </summary>
        /// <returns>If null, there is no frame yet received.</returns>
        public static Texture2D GetTexture2D()
        {
            if (!inited || !isRunning) return null;
            if (_texture != null) return _texture;
            Log("mcDesktopCapture: Get Current Frame");
            FrameEntity frameEntity = mcDesktopCapture2_getTexture();
            if (frameEntity.width > 0 && frameEntity.height > 0 && _texture == null)
            {
                Log("mcDesktopCapture: Create Texture2D");
                _texture = Texture2D.CreateExternalTexture((int)frameEntity.width, (int)frameEntity.height, TextureFormat.ARGB32, false, false, frameEntity.texturePtr);
            }
            return _texture;
        }

        private static void Log(object message)
        {
            Debug.Log(message);
        }
    }
}
