/*
 Copyright (c) 2010 OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// We need to mess with core internals

#import "VMUGameCore.h"

#import <OpenEmuBase/OERingBuffer.h>
#import <OpenGL/gl.h>
#import "prototypes.h"

@interface VMUGameCore () <OEVMUSystemResponderClient>
{
    int videoWidth, videoHeight;
    NSString *romPath;
    NSString *overlayFile;
    BOOL overlayIsLoaded;
}
@end

VMUGameCore *g_core;

@implementation VMUGameCore
static union { unsigned char c[32*64/2]; unsigned long l[32*64/8]; } mainimg;

- (id)init
{
    if (self = [super init])
    {
        videoWidth = 48;
        videoHeight = 32;
    }
    overlayIsLoaded = NO;

    g_core = self;
    return self;
}

- (BOOL)loadFileAtPath:(NSString *)path error:(NSError **)error
{
    romPath = path;
    return YES;
}

- (void)executeFrameSkippingFrame:(BOOL)skip
{
    // late init of the overlay

    // check fix, has to be REloaded at each frame, i mean really ?
//    if (![overlayFile isEqualToString:@""] && !overlayIsLoaded)
//    //if (![overlayFile isEqualToString:@""] && !overlayIsLoaded)
//    {
//        load_overlay((char *)[overlayFile UTF8String]);
//        overlayIsLoaded = YES;
//    }

//    vecx_emu ((VECTREX_MHZ / 1000) * EMU_TIMER, 0);
//    glFlush();
}

- (void)executeFrame
{
    [self executeFrameSkippingFrame:NO];
}

- (void)startEmulation
{
    if(!isRunning)
    {
        [super startEmulation];
        do_vmsgame([romPath UTF8String], NULL);
    }
}

- (void)updateSound:(uint8_t *)buff len:(int)len
{
    [[g_core ringBufferAtIndex:0] write:buff maxLength:len];
}

- (void)resetEmulation
{
//    vecx_reset();
}

- (BOOL)saveStateToFileAtPath:(NSString *)fileName
{
//    FILE *saveFile = fopen([fileName UTF8String], "wb");
//    
//    VECXState *state = saveVecxState();
//    
//    long bytesWritten = fwrite(state, sizeof(char), sizeof(VECXState), saveFile);
//    
//    if(bytesWritten != sizeof(VECXState))
//    {
//        NSLog(@"Couldn't write state");
//        return NO;
//    }
//    
//    fclose(saveFile);
//    
//    free(state);
//    
//    return YES;
    return NO;
}

- (BOOL)loadStateFromFileAtPath:(NSString *)fileName
{
//    FILE *saveFile = fopen([fileName UTF8String], "rb");
//    
//    if(saveFile == NULL)
//    {
//        NSLog(@"Could not open state file");
//        return NO;
//    }
//    
//    VECXState *state = malloc(sizeof(VECXState));
//    
//    if(!fread(state, sizeof(char), sizeof(VECXState), saveFile))
//    {
//        NSLog(@"Couldn't read file");
//        return NO;
//    }
//    
//    fclose(saveFile);
//    
//    loadVecxState(state);
//    
//    free(state);
//    
//    return YES;
    return NO;
}

- (OEIntSize)aspectSize
{
    return (OEIntSize){videoWidth, videoHeight};
}

- (OEIntRect)screenRect
{
    return OEIntRectMake(0, 0, videoWidth, videoHeight);
}

- (OEIntSize)bufferSize
{
    return OEIntSizeMake(videoWidth, videoHeight);
}

- (BOOL)rendersToOpenGL
{
    return YES;
}

- (const void *)videoBuffer
{
    NSLog(@"returning video buffer");
    return mainimg.c;
}

- (GLenum)pixelFormat
{
    return GL_BGRA;
}

- (GLenum)pixelType
{
    return GL_UNSIGNED_INT_8_8_8_8;
}

- (GLenum)internalPixelFormat
{
    return GL_RGB8;
}

- (double)audioSampleRate
{
    return 32768;
}

- (NSUInteger)audioBitDepth
{
    return 8;
}

- (NSTimeInterval)frameInterval
{
    return 50;
}

- (NSUInteger)channelCount
{
    return 1;
}


- (oneway void)didPushVMUButton:(OEVMUButton)button forPlayer:(NSUInteger)player
{
    keypress(button);
}

- (oneway void)didReleaseVMUButton:(OEVMUButton)button forPlayer:(NSUInteger)player
{
    keyrelease(button);
}

void error_msg(char *fmt, ...)
{
    va_list va;
    va_start(va, fmt);
    vfprintf(stderr, fmt, va);
    fputc('\n', stderr);
    va_end(va);
}

void vmputpixel(int x, int y, int p)
{
    NSLog(@"pixel: %i at (%i,%i)", p, x, y);
    mainimg.c[x + y*32] = p;
//    if(pixdbl) {
//        x<<=1;
//        y<<=1;
//        XPutPixel(mainimg, x, y, p&1);
//        XPutPixel(mainimg, x+1, y, p&1);
//        XPutPixel(mainimg, x, y+1, p&1);
//        XPutPixel(mainimg, x+1, y+1, p&1);
//    } else
//        XPutPixel(mainimg, x, y, p&1);
}

void redrawlcd()
{
    
}

void checkevents()
{
    
}

void waitforevents(struct timeval *t)
{
    
}

void sound(int freq)
{
//    sound_freq = freq;
}

@end
