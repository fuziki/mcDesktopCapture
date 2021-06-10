//
//  CmcDesktopCapture.h
//  
//
//  Created by fuziki on 2021/06/10.
//

#ifndef CmcDesktopCapture_h
#define CmcDesktopCapture_h

#ifdef __cplusplus
extern "C" {
#endif

struct FrameEntity {
    long width;
    long height;
    void* texturePtr;
};

#ifdef __cplusplus
}
#endif

#endif /* CmcDesktopCapture_h */
