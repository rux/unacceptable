//
//  CHAudioTransmitter.h
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface CHAudioTransmitter : NSObject

@property (nonatomic,retain,readonly) NSDate* playerStartTime;
@property (nonatomic,retain) AVAudioPlayer* player;

- (id)initWithAudioFileToSend:(NSURL*)audioURL;

- (void)startTransmitting;
- (void)stopTransmitting;

@end
