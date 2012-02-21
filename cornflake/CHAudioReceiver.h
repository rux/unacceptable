//
//  CHAudioReceiver.h
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NSString* const CHAudioReceiverDidDetectSignal;


@interface CHAudioReceiver : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic,retain) AVCaptureSession* captureSession;
@property (nonatomic) dispatch_queue_t sampleQueue;

- (id)initWithAudioToLookFor:(NSURL*)audioToLookFor;

- (void)startCapturing;
- (void)stopCapturing;

@end
