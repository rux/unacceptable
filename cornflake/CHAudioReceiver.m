//
//  CHAudioReceiver.m
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import "CHAudioReceiver.h"

#define SAMPLES_PER_CORRELATION 4096


static AudioBufferList audioSearchBufferList;
static vDSP_Length audioSearchBufferLength;
static float* capturedAudio;
static vDSP_Length capturedAudioLength;

@implementation CHAudioReceiver

@synthesize captureSession, sampleQueue;

- (id)initWithAudioToLookFor:(NSURL*)audioURL {
    NSAssert(audioURL, @"Audio not supplied");
    if(!(self = [super init])) {
        return nil;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    
    NSArray* mics = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    AVCaptureDevice* preferredMic = [mics lastObject];

    NSError* micError = nil;
    AVCaptureDeviceInput* micInput = [AVCaptureDeviceInput deviceInputWithDevice:preferredMic error:&micError];
    if(!micInput || ![captureSession canAddInput:micInput]) {
        [captureSession release];
        NSLog(@"Failed mic with error %@ ", micError);
        [self release], self = nil;
        return nil;
    }
    [captureSession addInput:micInput];
    
    AVCaptureAudioDataOutput* dataOutput = [[AVCaptureAudioDataOutput alloc] init];
    sampleQueue = dispatch_queue_create("com.yell.audio.receive", DISPATCH_QUEUE_SERIAL);
    [dataOutput setSampleBufferDelegate:self queue:sampleQueue];
    [captureSession addOutput:dataOutput];
    [dataOutput release];
    
    // Extract the audio 
    ExtAudioFileRef audioFile;
    OSStatus fileAccessError = ExtAudioFileOpenURL((CFURLRef)audioURL, &audioFile);
    if(fileAccessError != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, fileAccessError);
        [captureSession release];
        [self release], self = nil;
        return nil;
    }
        
    AudioStreamBasicDescription inputFormat;
    UInt32 inputFormatSize = sizeof(inputFormat);
    ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &inputFormatSize, &inputFormat);
    
    SInt64 numPackets;
    size_t numPacketsPropertySize = sizeof(numPackets);
    const OSStatus lengthStatus = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &numPacketsPropertySize, &numPackets);
    if(lengthStatus != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, lengthStatus);
        [captureSession release];
        [self release], self = nil;
        return nil;        
    }

    
    AudioStreamBasicDescription format = inputFormat;
    format.mFormatFlags = kAudioFormatFlagIsFloat;
    format.mBitsPerChannel = sizeof(float)*8;
    format.mBytesPerFrame = format.mChannelsPerFrame * sizeof(float);
    format.mBytesPerPacket = format.mFramesPerPacket * format.mBytesPerFrame;

    OSStatus fileRetrievalError = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(format), &format);
    if(fileRetrievalError != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, fileRetrievalError);
        [captureSession release];
        [self release], self = nil;
        return nil;        
    }
    
    float* audioSearchBuffer = (float*)calloc(numPackets, sizeof(float));
    
    audioSearchBufferLength = numPackets;
    audioSearchBufferList.mNumberBuffers = 1;
    audioSearchBufferList.mBuffers[0].mNumberChannels = 1; 
    audioSearchBufferList.mBuffers[0].mDataByteSize = numPackets * format.mBytesPerPacket;
    audioSearchBufferList.mBuffers[0].mData = audioSearchBuffer;
    
    ExtAudioFileSeek(audioFile, 0);
    UInt32 totalFramesRead = 0;
    do {
        UInt32 framesRead = numPackets - totalFramesRead;
        audioSearchBufferList.mBuffers[0].mData = audioSearchBuffer + (totalFramesRead * (sizeof(float)));
        OSStatus readError = ExtAudioFileRead(audioFile, &framesRead, &audioSearchBufferList);
        if(readError != noErr) {
            NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, readError);
            ExtAudioFileDispose(audioFile);
            [captureSession release];
            [self release], self = nil;
            return nil;        
        }
        totalFramesRead += framesRead;
        if(framesRead == 0) {
            break;
        }
    } while (totalFramesRead < numPackets);
    
    ExtAudioFileDispose(audioFile);

    return self;
}

- (id)init {
    return [self initWithAudioToLookFor:nil];
}

- (void)dealloc {
    if(sampleQueue) {
        dispatch_release(sampleQueue);
    }
    [captureSession release];
    free(capturedAudio);
    [super dealloc];
}


- (void)startCapturing {
    [self.captureSession startRunning];
}

- (void)stopCapturing {
    [self.captureSession stopRunning];
}

#pragma mark - Process audio

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {    
	CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
	CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

    if(numSamples != 1024) {
        return;
    }
    
    if(!capturedAudio) {
        capturedAudio = (float*)calloc(SAMPLES_PER_CORRELATION, sizeof(float));
    }

    // Obtain the raw sample data as a float array, readySamples.
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	SInt16* rawSamples = NULL;
	CMBlockBufferGetDataPointer(audioBlockBuffer, 0, &lengthAtOffset, &totalLength, (char**)(&rawSamples));
    float* readySamples = calloc(numSamples, sizeof(float));
    vDSP_vflt16(rawSamples, 1, readySamples, 1, numSamples);
    float* normedSamples = calloc(numSamples, sizeof(float));
    float divisor = 32767.f;
    vDSP_vsdiv(readySamples, 1, &divisor, normedSamples, 1, numSamples);
    
    if(capturedAudioLength < SAMPLES_PER_CORRELATION) {
        bcopy(normedSamples, ((void*)&(capturedAudio[capturedAudioLength])), sizeof(float) * MIN(SAMPLES_PER_CORRELATION, numSamples));
        capturedAudioLength += numSamples;
        return;
    }
    capturedAudioLength = 0;

    // Prepare space for the correlated result.    
    const vDSP_Length correlatedResultLength = 2*SAMPLES_PER_CORRELATION - 1;
    float* correlatedResult = (float*)calloc(correlatedResultLength, sizeof(float));

    // Correlate the two signals
    vDSP_conv(capturedAudio, 1, (float*)(audioSearchBufferList.mBuffers[0].mData), 1, correlatedResult, 1, correlatedResultLength, SAMPLES_PER_CORRELATION);
        
    // Find the maximum and its index
    float maximumValue;
    vDSP_Length indexOfMaximumValue;
    vDSP_maxvi(correlatedResult, 1, &maximumValue, &indexOfMaximumValue, numSamples);

    dispatch_async(dispatch_get_main_queue(), ^{
       NSLog(@"Matched %f at index %lu", maximumValue, indexOfMaximumValue);
    });    

    free(correlatedResult);
    free(readySamples);
    free(normedSamples);
}

     
@end
