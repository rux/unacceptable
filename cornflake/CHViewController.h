//
//  CHViewController.h
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHAudioReceiver.h"

@interface CHViewController : UIViewController

@property (nonatomic,retain) CHAudioReceiver* receiver;

@property (nonatomic,retain) IBOutlet UIButton* button; 

- (IBAction)didTapButton:(id)sender;

@end
