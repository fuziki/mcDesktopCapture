# mcDesktopCapture

Unity native plugin to capture the macOS desktop as Texture2D

![unity_example](docs/videos/unity_example.gif)  

# Environment
* macOS 11.3.1
* Unity 2020.3.5

# Installation
* Copy mcDesktopCapture.bundle to your project.

# Usage
## Start capture

```c#
mcDesktopCapture_startCapture();
```

## Get current frame

* If w and h are not updated, the frame acquisition has failed.

```c#
int w = -1;
int h = -1;

IntPtr ptr = mcDesktopCapture_getCurrentFrame2(ref w, ref h);
```

* Create Texture2D from IntPtr

```c#
Texture2D texture = Texture2D.CreateExternalTexture(w, h, TextureFormat.ARGB32, false, false, texturePtr);
```

## Clear frame if need

```c#
mcDesktopCapture_clearFrame(texturePtr);
```

## Stop capture

```c#
mcDesktopCapture_stopCapture();
```