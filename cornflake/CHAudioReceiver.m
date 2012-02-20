//
//  CHAudioReceiver.m
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "CHAudioReceiver.h"

@implementation CHAudioReceiver

@synthesize captureSession, audioToLookFor, sampleQueue;

- (id)initWithAudioToLookFor:(NSData*)aAudioToLookFor {
    if(!(self = [super init])) {
        return nil;
    }
    audioToLookFor = [aAudioToLookFor retain];
    
    captureSession = [[AVCaptureSession alloc] init];
    
    NSArray* mics = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    AVCaptureDevice* preferredMic = [mics lastObject];

    NSError* micError = nil;
    AVCaptureDeviceInput* micInput = [AVCaptureDeviceInput deviceInputWithDevice:preferredMic error:&micError];
    if(!micInput) {
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
    
    return self;
}

- (void)dealloc {
    dispatch_release(sampleQueue);
    [audioToLookFor release];
    [captureSession release];
    [super dealloc];
}


- (void)startCapturing {
    [self.captureSession startRunning];
}

- (void)stopCapturing {
    [self.captureSession stopRunning];
}

#pragma mark - Process audio

- (SInt16)maxValueInArray:(SInt16*)array ofSize:(NSUInteger)size {
    SInt16 biggestSample = 0;
    for(NSUInteger sampleIndex=0; sampleIndex<size; sampleIndex++) {
        if(abs(array[sampleIndex]) > biggestSample) {
            biggestSample = abs(array[sampleIndex]);
        }
    }
    return biggestSample;
}

- (float)calculateAudioLevel:(CMSampleBufferRef)sampleBuffer {
	float currentAudioLevel = 0.0f;
    
	CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
	NSUInteger channelIndex = 0;
	
	CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
	size_t audioBlockBufferOffset = (channelIndex * numSamples * sizeof(SInt16));
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	SInt16 *samples = NULL;
	CMBlockBufferGetDataPointer(audioBlockBuffer, audioBlockBufferOffset, &lengthAtOffset, &totalLength, (char **)(&samples));
	
	int numSamplesToRead = 1;
    
	for (int i = 0; i < numSamplesToRead; i++) {
		
		SInt16 subSet[numSamples / numSamplesToRead];
		for (int j = 0; j < numSamples / numSamplesToRead; j++)
			subSet[j] = samples[(i * (numSamples / numSamplesToRead)) + j];
		
		const SInt16 lastAudioSample = [self maxValueInArray:subSet ofSize:(numSamples / numSamplesToRead)];
		currentAudioLevel = (float)(lastAudioSample) / 32767.0;
	}
	return currentAudioLevel;
}

#pragma mark - 

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    const float maxValue = [self calculateAudioLevel:sampleBuffer];
    if(maxValue > 0.2f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Sound level %f", maxValue);
        });    
    }
}

     
@end
