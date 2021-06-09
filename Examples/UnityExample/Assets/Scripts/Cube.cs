using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Runtime.InteropServices;

public class Cube : MonoBehaviour
{

    [DllImport("mcDesktopCapture")]
    private static extern int mcDesktopCapture_addOne(int src);


    [DllImport("mcDesktopCapture")]
    private static extern void mcDesktopCapture_startCapture();

    [DllImport("mcDesktopCapture")]
    private static extern void mcDesktopCapture_stopCapture();

    [DllImport("mcDesktopCapture")]
    private static extern void mcDesktopCapture_getCurrentFrame(ref int width, ref int height, IntPtr texturePtr);

    [DllImport("mcDesktopCapture")]
    private static extern IntPtr mcDesktopCapture_getCurrentFrame2(ref int width, ref int height);

    [DllImport("mcDesktopCapture")]
    private static extern int mcDesktopCapture_clearFrame(IntPtr texturePtr);

    private IntPtr texturePtr = IntPtr.Zero;
    private bool inited = false;

    // Start is called before the first frame update
    void Start()
    {
        Debug.Log($"add one -> {mcDesktopCapture_addOne(3)}");

        mcDesktopCapture_startCapture();
    }

    // Update is called once per frame
    void Update()
    {
        this.transform.Rotate(-0.2f, -0.3f, 0.4f);

        if (inited) {
            mcDesktopCapture_clearFrame(texturePtr);
        }

        int w = -1;
        int h = -1;

        IntPtr ptr = mcDesktopCapture_getCurrentFrame2(ref w, ref h);

        //Debug.Log($"h: {h}, w: {w}");

        if (w > 0 && h > 0)
        {
            inited = true;
            texturePtr = ptr;

            Texture2D texture = Texture2D.CreateExternalTexture(w, h, TextureFormat.ARGB32, false, false, texturePtr);
            Renderer m_Renderer = GetComponent<Renderer>();

            m_Renderer.material.SetTexture("_MainTex", texture);
        }
    }

    void OnDisable()
    {
        Debug.Log("OnDisable");
        mcDesktopCapture_stopCapture();
    }
}
