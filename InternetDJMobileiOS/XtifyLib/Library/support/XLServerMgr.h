/* Xtify Register Manager
 //
 //  
 //  XLServerMgr.h
 //
 //  Created by Gilad on 3/1/11.
 //  Copyright 2011 Xtify. All rights reserved. 
 */ 

#import <UIKit/UIKit.h>

@class ASIHTTPRequest;

@interface XLServerMgr : NSObject  {
	
	NSString *deviceToken;
	BOOL runAlsoInBackground; //
	NSInteger serverBadgeCount; //updated at start up
	NSTimer* timerBadgeUpdate;
    NSString *emulatorToken;
	
}
+(XLServerMgr*) get;

- (id)initWithReg:(NSData *)token;
- (void)sendProviderDeviceToken ;
- (NSString *)convertToken:(NSData *)token ;
- (void)switchToBackgroundMode:(BOOL)background;
- (void)failureRegistrationMethod:(ASIHTTPRequest *)request ;
- (void)successRegistrationMethod:(ASIHTTPRequest *) request ;
- (void) fireServerBadgeCountService:(NSTimer*)timer; // ascyronis internal process to get the badge count. invoke at startup
- (NSInteger) getServerBadgeCount; // return badge count that was updated last
- (void) successGetBadgeMethod:(ASIHTTPRequest *) request ;
- (void) failureGetBadgeMethod:(ASIHTTPRequest *) request ;

- (void) setServerBadgeCount:(NSString *) countStr; // set the badge count on the server
- (void) successSetBadgeMethod:(ASIHTTPRequest *) request ;
- (void) failureSetBadgeMethod:(ASIHTTPRequest *) request ;

- (void) doXtifyRegistration: (NSString*) appKey;
- (void) updateXtifyRegistration:(NSString *)appKey;

@property(nonatomic, retain) NSString *deviceToken;
@property (nonatomic, assign)	BOOL runAlsoInBackground;
@property (nonatomic, retain) NSTimer* timerBadgeUpdate;
@property(nonatomic, retain) NSString *emulatorToken;
@end

