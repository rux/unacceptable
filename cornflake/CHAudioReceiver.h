//
//  CHAudioReceiver.h
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface CHAudioReceiver : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic,retain) AVCaptureSession* captureSession;
@property (nonatomic,retain) NSData* audioToLookFor;
@property (nonatomic) dispatch_queue_t sampleQueue;

- (id)initWithAudioToLookFor:(NSData*)audioToLookFor;

- (void)startCapturing;
- (void)stopCapturing;

@end
