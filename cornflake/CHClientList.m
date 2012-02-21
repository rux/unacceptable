//
//  CHClientList.m
//  cornflake
//
//  Created by Tom York on 21/02/2012.
//  Copyright (c) 2012 Yell Labs. All rights reserved.
//

#import "CHClientList.h"

NSString* const CHClientListTriggeredNotification = @"CHClientListTriggeredNotification";

@implementation CHClientList

@synthesize serverSession, isCoordinator, isConnectedToCoordinator, peerTimes;

- (NSArray*)peersInAnnounceTimeOrder {    
    return [self.peerTimes keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSDate*)obj1 compare:(NSDate*)obj2];
    }];
}

- (void)setIsCoordinator:(BOOL)newValue {
    isCoordinator = newValue;
    self.serverSession.available = !isCoordinator;
    
    if(isCoordinator) {
        // Disconnect any stray peers we've already picked up
        [self.serverSession disconnectFromAllPeers];
        [self.peerTimes removeAllObjects];
    }
    else {
        self.isConnectedToCoordinator = NO;
        // Try to connect to a coordinator if one is around
        NSArray* coordinators = [self.serverSession peersWithConnectionState:GKPeerStateAvailable];
        if(coordinators.count == 1) {
            [self.serverSession connectToPeer:[coordinators lastObject] withTimeout:20.0];
        }
    }
}

#pragma mark - Trigger

- (void)announceMessageReceivedToCoordinator:(NSDate*)receivedTime {
    if(self.isCoordinator) {
        return;
    }
    NSData* archivedDate = [NSKeyedArchiver archivedDataWithRootObject:receivedTime];
    [self.serverSession sendDataToAllPeers:archivedDate withDataMode:GKSendDataReliable error:nil];
}

- (void)triggerPeersInAnnounceTimeOrder:(NSTimeInterval)delay {
    if(!self.isCoordinator) {
        return;
    }
    
    NSArray* peers = [self.serverSession peersWithConnectionState:GKPeerStateConnected];
    NSDate* now = [NSDate date];
    __block NSTimeInterval oneDelay = delay;
    [peers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* key = (NSString*)obj;
        NSDate* date = [now dateByAddingTimeInterval:oneDelay];
        NSData* dateArchive = [NSKeyedArchiver archivedDataWithRootObject:date];
        [self.serverSession sendData:dateArchive toPeers:[NSArray arrayWithObject:key] withDataMode:GKSendDataReliable error:nil];
        oneDelay += 0.5;
    }];
        
}

#pragma mark - Lifecycle

- (id)init {
    if(!(self = [super init])) {
        return nil;
    }
    
    peerTimes = [[NSMutableDictionary alloc] initWithCapacity:25];
    
    serverSession = [[GKSession alloc] initWithSessionID:nil displayName:[[UIDevice currentDevice] name] sessionMode:GKSessionModePeer];
    serverSession.disconnectTimeout = 120.0;
    [serverSession setDataReceiveHandler:self withContext:NULL];
    return self;
}


- (void)dealloc {
    [peerTimes release];
    [serverSession release];
    [super dealloc];
}

#pragma mark - Session data handler

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    if(!self.isCoordinator) {
        // This is the go signal
        NSDate* triggerTime = (NSDate*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSDate* now = [NSDate date];
        double delayInSeconds = [triggerTime timeIntervalSinceDate:now];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSNotification* note = [NSNotification notificationWithName:CHClientListTriggeredNotification object:self];
            [[NSNotificationCenter defaultCenter] postNotification:note];                    
        });
    }
    else {
        // This is registration of reception time
        NSDate* receptionTime = [NSDate date];
        [self.peerTimes setObject:receptionTime forKey:peer];        
    }
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    switch (state) {
        case GKPeerStateAvailable:
            // Coordinator doesn't initiate connections
            if(!self.isCoordinator) {
                // Try to connect to the coordinator
                [session connectToPeer:peerID withTimeout:20.0];
            }
            break;
            
        case GKPeerStateConnected:
            if(!self.isCoordinator) {
                // Connected to the coordinator.
                self.isConnectedToCoordinator = YES;
            }
            break;
            
        case GKPeerStateDisconnected:
            [self.peerTimes removeObjectForKey:peerID];
            break;
            
        default:
            break;
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    if(!self.isCoordinator) {
        [session denyConnectionFromPeer:peerID];
        return;
    }

    NSError* error = nil;
    if(![session acceptConnectionFromPeer:peerID error:&error]) {
        NSLog(@"Failed to accept connection from %@ because %@", peerID, error);
        return;
    }    
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    NSLog(@"Failed peer connection with %@: %@", peerID, error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    NSLog(@"Failed session: %@", error);
}

@end
