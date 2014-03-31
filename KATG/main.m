//
//  main.m
//  KATG
//
//  Created by Doug Russell on 8/26/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGApplication.h"
#import "KATGAppDelegate.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		Class appDelegateClass = [KATGAppDelegate class];
	    return UIApplicationMain(argc, argv, NSStringFromClass([KATGApplication class]), NSStringFromClass(appDelegateClass));
	}
}