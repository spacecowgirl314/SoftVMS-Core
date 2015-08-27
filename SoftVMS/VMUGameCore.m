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
    int bpp;
    uint16_t *videoBuffer;
    char *audioStream;
    int audioLength;
    int videoWidth, videoHeight;
    NSString *romPath;
}
@end

VMUGameCore *current;

@implementation VMUGameCore

- (id)init
{
    if (self = [super init])
    {
        audioLength = 5512; //256*2*2*2*2; 4096
        videoWidth = 48;
        videoHeight = 32;
        bpp = 3;
        
        if(videoBuffer)
            free(videoBuffer);
        if(audioStream)
            free(audioStream);
        videoBuffer = malloc(videoWidth*videoHeight*bpp);
        audioStream = malloc(audioLength);
        memset(videoBuffer, 0, videoWidth*videoHeight*bpp);
        memset(audioStream, 0, audioLength);
    }
    
    current = self;
    
    return self;
}

- (void)dealloc
{
    free(audioStream);
    free(videoBuffer);
}

#pragma mark - Execution

- (BOOL)loadFileAtPath:(NSString *)path error:(NSError **)error
{
    romPath = path;
    return YES;
}

- (void)executeFrameSkippingFrame:(BOOL)skip
{

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
        [self.renderDelegate willRenderOnAlternateThread];
        [NSThread detachNewThreadSelector:@selector(runVMUEmuThread) toTarget:self withObject:nil];
    }
}

- (void)runVMUEmuThread
{
    @autoreleasepool
    {
        [self.renderDelegate startRenderingOnAlternateThread];
        do_vmsgame((char*)[romPath UTF8String], NULL);
        [super stopEmulation];
    }
}

- (void)resetEmulation
{
    
}

#pragma mark - Save State

- (BOOL)saveStateToFileAtPath:(NSString *)fileName
{
    return savestate([fileName UTF8String]) ? YES : NO;
}

- (BOOL)loadStateFromFileAtPath:(NSString *)fileName
{
    return loadstate([fileName UTF8String]) ? YES : NO;
}

#pragma mark - Input

- (oneway void)didPushVMUButton:(OEVMUButton)button forPlayer:(NSUInteger)player
{
    keypress(button);
}

- (oneway void)didReleaseVMUButton:(OEVMUButton)button forPlayer:(NSUInteger)player
{
    keyrelease(button);
}

#pragma mark - Video

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

- (const void *)videoBuffer
{
    return videoBuffer;
}

- (GLenum)pixelFormat
{
    return GL_BGRA;
}

- (GLenum)pixelType
{
    return GL_UNSIGNED_SHORT_4_4_4_4_REV;
}

- (GLenum)internalPixelFormat
{
    return GL_RGB5;
}

#pragma mark - Audio

- (double)audioSampleRate
{
    return 48000; //32768;
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

#pragma mark - Callbacks

void error_msg(char *fmt, ...)
{
    va_list va;
    va_start(va, fmt);
    vfprintf(stderr, fmt, va);
    fputc('\n', stderr);
    va_end(va);
}

void putpixel(int x, int y, int p)
{
    uint16_t *pixels = current->videoBuffer + y * current->videoWidth + x;
    if (p&1)
    {
        // 8, 16, 82 (0x08, 0x10, 0x52) Foreground
        pixels[0] = 8;
        pixels[1] = 16;
        pixels[2] = 82;
    }
    else
    {
        // 170, 213, 195 (0xaa, 0xd5, 0xc3) Background
        pixels[0] = 170;
        pixels[1] = 213;
        pixels[2] = 230;
    }
}

void vmputpixel(int x, int y, int p)
{
    if (y <= 32) {
        putpixel(x, y, p);
    }
}

void redrawlcd()
{
    
}

void checkevents()
{
    // do nothing, this is handled already
}

void waitforevents(struct timeval *t)
{
    if(t != NULL)
    {
        useconds_t millis = t->tv_sec*1000 + t->tv_usec;
        usleep(millis);
    }
}

void sound(int freq)
{
    char *stream = current->audioStream;
    int length = current->audioLength;
    if(freq <= 0)
        memset(stream, 0, length);
    else
    {
        int i;
        static char v = 0x7f;
        static int f = 0;
        for(i=0; i<length; i++)
        {
            f += freq;
            while(f >= 32768)
            {
                v ^= 0xffff;
                f -= 32768;
            }
            *stream++ = v;
        }
        [[current ringBufferAtIndex:0] write:stream maxLength:sizeof(char) * length];
    }
}

@end
