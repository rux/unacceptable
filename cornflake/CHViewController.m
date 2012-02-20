//
//  CHViewController.m
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CHViewController.h"

@implementation CHViewController

@synthesize button, receiver;

- (IBAction)didTapButton:(id)sender {
    UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Hello" message:@"Totally" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [self.receiver stopCapturing];
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
    
    receiver = [[CHAudioReceiver alloc] initWithAudioToLookFor:nil];
    return self;
}

- (void)dealloc {
    [receiver release];
    [button release];
    [super dealloc];
}

@end
