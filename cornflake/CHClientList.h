//
//  CHClientList.h
//  cornflake
//
//  Created by Tom York on 21/02/2012.
//  Copyright (c) 2012 Yell Labs. All rights reserved.
//

#import <GameKit/GameKit.h>

NSString* const CHClientListTriggeredNotification;


@interface CHClientList : NSObject <GKSessionDelegate>

@property (nonatomic,retain) NSMutableDictionary* peerTimes;
@property (nonatomic,retain) GKSession* serverSession;
@property (nonatomic) BOOL isCoordinator;
@property (nonatomic) BOOL isConnectedToCoordinator;

- (void)announceMessageReceivedToCoordinator:(NSDate*)receivedTime;   // Does nothing if you're not the coordinator

- (void)triggerPeersInAnnounceTimeOrder:(NSTimeInterval)delay;

@end
