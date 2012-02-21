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


NSString* const CHAudioReceiverDidDetectSignal = @"CHAudioReceiverDidDetectSignal";


@interface CHAudioReceiver ()
@property (nonatomic) float* correlatedResult;
@property (nonatomic) AudioBufferList audioSearchBufferList;
@property (nonatomic) vDSP_Length audioSearchBufferLength;
@property (nonatomic) float* capturedAudio;
@property (nonatomic) vDSP_Length capturedAudioLength;
@property (nonatomic) CMTime captureBufferPresentationTime;
@property (nonatomic) CMTime captureStartTime;
@property (nonatomic) Float64 captureBufferDuration;
@end

@implementation CHAudioReceiver

@synthesize captureSession, sampleQueue;
@synthesize audioSearchBufferList, audioSearchBufferLength, capturedAudio, capturedAudioLength, correlatedResult;
@synthesize captureBufferPresentationTime, captureBufferDuration, captureStartTime;

#pragma mark - Lifecycle

- (BOOL)loadAudioDataFromURL:(NSURL*)audioURL {
    // Extract the audio 
    ExtAudioFileRef audioFile;
    OSStatus fileAccessError = ExtAudioFileOpenURL((CFURLRef)audioURL, &audioFile);
    if(fileAccessError != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, fileAccessError);
        return NO;
    }
    
    AudioStreamBasicDescription inputFormat;
    UInt32 inputFormatSize = sizeof(inputFormat);
    ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &inputFormatSize, &inputFormat);
    
    SInt64 numPackets;
    size_t numPacketsPropertySize = sizeof(numPackets);
    const OSStatus lengthStatus = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &numPacketsPropertySize, &numPackets);
    if(lengthStatus != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, lengthStatus);
        return NO;        
    }
    
    AudioStreamBasicDescription format = inputFormat;
    format.mFormatFlags = kAudioFormatFlagIsFloat;
    format.mBitsPerChannel = sizeof(float)*8;
    format.mBytesPerFrame = format.mChannelsPerFrame * sizeof(float);
    format.mBytesPerPacket = format.mFramesPerPacket * format.mBytesPerFrame;
    
    OSStatus fileRetrievalError = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(format), &format);
    if(fileRetrievalError != noErr) {
        NSLog(@"Failed to access asset at URL %@ due to error %ld", audioURL, fileRetrievalError);
        return NO;
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
            return NO;
        }
        totalFramesRead += framesRead;
        if(framesRead == 0) {
            break;
        }
    } while (totalFramesRead < numPackets);
    
    ExtAudioFileDispose(audioFile);
    return YES;
}

- (id)initWithAudioToLookFor:(NSURL*)audioURL {
    NSAssert(audioURL, @"Audio not supplied");
    if(!(self = [super init])) {
        return nil;
    }
    
    if(![self loadAudioDataFromURL:audioURL]) {
        [captureSession release];
        [self release], self = nil;
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
    
    AVCaptureAudioDataOutput* dataOutput = [[[AVCaptureAudioDataOutput alloc] init] autorelease];
    sampleQueue = dispatch_queue_create("com.yell.audio.receive", DISPATCH_QUEUE_SERIAL);
    [dataOutput setSampleBufferDelegate:self queue:sampleQueue];
    if(![captureSession canAddOutput:dataOutput]) {
        [captureSession release];
        NSLog(@"Failed output with error %@ ", micError);
        [self release], self = nil;
        return nil;
    }
    [captureSession addOutput:dataOutput];
    
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
    free(correlatedResult);
    [super dealloc];
}

#pragma mark - Capture control


- (void)startCapturing {
    [self.captureSession startRunning];
}

- (void)stopCapturing {
    [self.captureSession stopRunning];
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {    
    return;
    
	CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
	CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    const Float64 duration = CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer));
    
    const double arrivalTimeToSystemTime = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)) - CACurrentMediaTime();
    
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
    free(readySamples);
    
    if(capturedAudioLength < SAMPLES_PER_CORRELATION) {
        if(capturedAudioLength == 0) {
            self.captureBufferPresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            self.captureBufferDuration = 0;
        }
        bcopy(normedSamples, ((void*)&(capturedAudio[capturedAudioLength])), sizeof(float) * MIN(SAMPLES_PER_CORRELATION, numSamples));
        free(normedSamples);
        capturedAudioLength += numSamples;
        self.captureBufferDuration += duration; 
        return;
    }
    free(normedSamples);
    capturedAudioLength = 0;

    // Prepare space for the correlated result.    
    const vDSP_Length correlatedResultLength = 2*SAMPLES_PER_CORRELATION - 1;
    if(!correlatedResult) {
        correlatedResult = (float*)calloc(correlatedResultLength, sizeof(float));
    }

    // Correlate the two signals
    vDSP_conv(capturedAudio, 1, (float*)(audioSearchBufferList.mBuffers[0].mData), 1, correlatedResult, 1, correlatedResultLength, SAMPLES_PER_CORRELATION);
        
    // Find the maximum and its index
    float maximumValue;
    vDSP_Length indexOfMaximumValue;
    vDSP_maxvi(correlatedResult, 1, &maximumValue, &indexOfMaximumValue, numSamples);

#define kDetectionThreshold 5.0f
    
    const Float64 theTime = self.captureBufferDuration * ((Float64)(indexOfMaximumValue)/(Float64)(SAMPLES_PER_CORRELATION)) + arrivalTimeToSystemTime;
    
    if(maximumValue > kDetectionThreshold) {
        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:theTime];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotification* note = [NSNotification notificationWithName:CHAudioReceiverDidDetectSignal object:date];
            [[NSNotificationCenter defaultCenter] postNotification:note];
        });    
    }    
}

     
@end
