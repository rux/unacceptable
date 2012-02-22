//
//  CHViewController.h
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHAudioReceiver.h"
#import "CHAudioTransmitter.h"
#import "CHClientList.h"

#import <AudioToolbox/AudioToolbox.h>

@interface CHViewController : UIViewController

@property (nonatomic,retain) CHAudioReceiver* receiver;
@property (nonatomic,retain) CHAudioTransmitter* transmitter;
@property (nonatomic,retain) CHClientList* clientList;

- (IBAction)didTapButton:(id)sender;

- (IBAction)didChangeSensitivity:(UISlider*)sender;

@property (nonatomic,retain) IBOutlet UISlider* sensitivitySlider;
@property (nonatomic,retain) IBOutlet UILabel* status; 
@property (nonatomic,retain) IBOutlet UILabel* role; 
@property (nonatomic,retain) IBOutlet UISwitch* masterSwitch; 
@property (nonatomic,retain) IBOutlet UILabel* sensitivityLabel;
@property (nonatomic,retain) IBOutlet UIButton* initiateWave;


@end

