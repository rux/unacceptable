//
//  CHAudioTransmitter.m
//  cornflake
//
//  Created by Tom York on 20/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "CHAudioTransmitter.h"



@implementation CHAudioTransmitter

@synthesize player, playerStartTime;

- (id)initWithAudioFileToSend:(NSURL*)audioURL {
    if(!(self = [super init])) {
        return nil;
    }
    
    NSAssert(audioURL, @"You specified nothing to be sent!");
    
    NSError* error = nil;
    player = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfURL:audioURL] error:&error];
    if(!player) {
        NSLog(@"Failed to init player with error %@", error);
        [self release], self = nil;
        return nil;
    }
    player.numberOfLoops = -1; // Loop the sound until stopped.
    
    return self;
}

- (id)init {
    return [self initWithAudioFileToSend:nil];
}

- (void)dealloc {
    [playerStartTime release];
    [player release];
    [super dealloc];
}

- (void)startTransmitting {
    [self.player prepareToPlay];
    [playerStartTime release];
    playerStartTime = [[NSDate date] retain];
    [self.player play];
}

- (void)stopTransmitting {
    [self.player stop];
}

@end
