//
//  CHViewController.m
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CHViewController.h"

@implementation CHViewController

@synthesize receiver, transmitter, clientList, status, role, masterSwitch, sensitivitySlider, sensitivityLabel;

- (IBAction)didChangeSensitivity:(UISlider*)sender {
    const float sensitivity = 1.0f + (1.0f - sender.value) * 9.0f;
    self.receiver.detectionThreshold = sensitivity;
}

- (IBAction)didTapButton:(id)sender {
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef soundFileURLRef;
    soundFileURLRef = CFBundleCopyResourceURL(mainBundle, (CFStringRef)  @"cheer", CFSTR ("mp3"), NULL);
    UInt32 soundID;
    AudioServicesCreateSystemSoundID(soundFileURLRef, &soundID);
    AudioServicesPlaySystemSound(soundID);
    AudioServicesDisposeSystemSoundID(soundID);

    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);

    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
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
        }
    ];
}


- (IBAction)masterSwitch:(id)sender {
    if (masterSwitch.on) {
        self.clientList.isCoordinator = YES;
        self.view.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:219.0/255.0 blue:52.0/255.0 alpha:1.0];
    } else {
        self.clientList.isCoordinator = NO;
        self.view.backgroundColor = [UIColor blackColor];
    }
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.sensitivitySlider = nil;
    self.status = nil;
    self.role = nil;
    self.sensitivityLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.clientList.isCoordinator = NO;
    self.sensitivitySlider.value = MAX(MIN(1.0f - (self.receiver.detectionThreshold - 1.0f) / 9.0f, 1.0f), 0.0f);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(object != clientList) return;
    
    if (clientList.isCoordinator) {
        self.status.text = @"Sending waves";
        self.status.textColor = [UIColor blackColor];
        self.sensitivityLabel.hidden = YES;
        self.sensitivitySlider.hidden = YES;
        self.role.text =  @"Waver";
        self.role.textColor = [UIColor blackColor];
        [self.receiver stopCapturing];
        [self.transmitter startTransmitting];
    } else {
        self.status.text = clientList.isConnectedToCoordinator ? @"Talking to waver" : @"Listening for waver";
        self.status.textColor = [UIColor whiteColor];
        self.sensitivityLabel.hidden = NO;
        self.sensitivitySlider.hidden = NO;
        self.role.text =  @"Wavee";
        self.role.textColor = [UIColor whiteColor];
        [self.transmitter stopTransmitting];
        [self.receiver startCapturing];
    }

}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if(!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        return nil;
    }

    NSURL* audioFileURL =  [[NSBundle mainBundle] URLForResource:@"880-1760-0.1second" withExtension:@"caf"];   
    receiver = [[CHAudioReceiver alloc] initWithAudioToLookFor:audioFileURL];
    transmitter = [[CHAudioTransmitter alloc] initWithAudioFileToSend:audioFileURL];
    clientList = [[CHClientList alloc] init];
    [clientList addObserver:self forKeyPath:@"isCoordinator" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [clientList addObserver:self forKeyPath:@"isConnectedToCoordinator" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapButton:) name:CHAudioReceiverDidDetectSignal object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [clientList removeObserver:self forKeyPath:@"isCoordinator"];
    [clientList removeObserver:self forKeyPath:@"isConnectedToCoordinator"];
    [clientList release];
    [transmitter release];
    [receiver release];
    [sensitivitySlider release];
    [sensitivityLabel release];
    [super dealloc];
}

@end
