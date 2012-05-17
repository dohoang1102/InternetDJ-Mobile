//
//  PushNotification.h
//  XtifyPhoneGapPhase2
//
//  Created by Suchi on 3/1/12.
//  Copyright (c) 2012 Xtify.com. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface PushNotification : CDVPlugin {
    
    NSString* callbackID;  
    NSDictionary *notificationMessage;
}

@property (nonatomic, copy) NSString* callbackID;

//Instance Method  
- (void) print:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) printXid:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) printLocation:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
//- (void) retrieveCustomData:()

@end