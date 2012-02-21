//
//  CHViewController.m
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CHViewController.h"

@implementation CHViewController

@synthesize button, receiver, transmitter, clientList;

- (IBAction)didTapButton:(id)sender {
    self.clientList.isCoordinator = !self.clientList.isCoordinator;

    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef soundFileURLRef;
    soundFileURLRef = CFBundleCopyResourceURL(mainBundle, (CFStringRef)  @"cheer", CFSTR ("mp3"), NULL);
    UInt32 soundID;
    AudioServicesCreateSystemSoundID(soundFileURLRef, &soundID);
    AudioServicesPlaySystemSound(soundID);

    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);

    [UIView animateWithDuration:1
        animations:^{
            if (![self.view.backgroundColor isEqual:[UIColor whiteColor]]) {
            self.view.backgroundColor = [UIColor whiteColor];
            } else {
            self.view.backgroundColor = [UIColor blackColor];
            } 
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:3 animations:^{
                self.view.backgroundColor = [UIColor blackColor];
            }];
        }];
    

}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.button = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.receiver startCapturing];
  //  [self.transmitter startTransmitting];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [self.receiver stopCapturing];
 //   [self.transmitter stopTransmitting];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if(!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        return nil;
    }

    NSURL* audioFileURL =  [[NSBundle mainBundle] URLForResource:@"880-1760-0.1second" withExtension:@"caf"];   
    receiver = [[CHAudioReceiver alloc] initWithAudioToLookFor:audioFileURL];
    transmitter = [[CHAudioTransmitter alloc] initWithAudioFileToSend:audioFileURL];
    clientList = [[CHClientList alloc] init];
    return self;
}

- (void)dealloc {
    [clientList release];
    [transmitter release];
    [receiver release];
    [button release];
    [super dealloc];
}

@end
