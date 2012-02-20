//
//  CHAppDelegate.h
//  cornflake
//
//  Created by Russ Anderson on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CHViewController;

@interface CHAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CHViewController *viewController;

@end
