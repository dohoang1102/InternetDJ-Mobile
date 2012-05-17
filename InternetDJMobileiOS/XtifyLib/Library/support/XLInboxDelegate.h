//
//  XLInboxDelegate.h
//  XtifyLib
//
//  Created by Gilad on 6/15/11.
//  Copyright 2011 Xtify. All rights reserved.
//


@class XLappMgr;

@protocol XLInboxDelegate   <NSObject>

@optional

// These are the default delegate methods 
// You can use different ones by setting didInboxChangeSelector
- (void)messageCountChanged:(XLappMgr *)appMgr;

// get the navigation controller to the inbox for app with push button
- (UINavigationController *)getDeveloperNavigationController:(XLappMgr *)appMgr;

- (void) moveTabbarToInboxNavController:(XLappMgr *)appMgr;
@end
