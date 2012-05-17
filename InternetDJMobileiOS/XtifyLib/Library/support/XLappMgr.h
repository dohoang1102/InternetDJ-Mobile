//
//  XLappMgr.h
//
//  Created by Gilad on 3/1/11.
//  Copyright 2011 Xtify. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XtifyGlobal.h"
#import "XLInboxDelegate.h"

@class XLServerMgr,XLInboxMgr;
@class UIApplication ;
@class ASIHTTPRequest;

typedef enum _XLBadgeManagedType {
	XLInboxManagedMethod = 0,
    XLDeveloperManagedMethod = 1
} XLBadgeManagedType ;


@interface XLappMgr : NSObject <UIAlertViewDelegate> 
{

	XLServerMgr *serverMgr;
	XLInboxMgr *inboxMgr;
	BOOL handleNotification;
	NSDictionary *lastPush ;//Apple last push notification dictionary
	NSString *anAppKey ; // xtify application key
	NSDate * lastLocationUpdateDate ;
	NSString *prodName ; // product name from info plist
	// Badge
	XLBadgeManagedType badgeMgrMethod;
	// The delegate, developer needs to manage setting and talking to delegate in subclasses
	id <XLInboxDelegate> inboxDelegate;
	// Called on the delegate (if implemented) when a message read in the Inbox. Default is messageCountChanged:
	SEL didInboxChangeSelector;
	SEL developerNavigationControllerSelector ;
	SEL developerInboxNavigationControllerSelector ;
	SEL developerCustomActionSelector ;
	BOOL isLocationRequired ; //
    NSString * snId;
	NSTimer* timerBulkUpdate;
    NSMutableArray *activeTagArray;

	BOOL isInGettingMsgLoop ;// set to yes by the inboxMgr, when getting few messages from the server to prevent multiple updates
    NSString *curCountry;
    NSString *curLocale;
}

+(XLappMgr*)get;
-(void) registerForPush ;
-(void) launchWithOptions:(UIApplication *)application andOptions:(NSDictionary *)launchOptions;
-(void) registerWithXtify:(NSData *)devToken ;
-(void) updateAppKey:(NSString *)appKey ;
-(void) appEnterBackground;
-(void) appEnterActive;
-(void) appEnterForeground;
-(void) appReceiveNotification:(NSDictionary *)userInfo;
-(void) displayInboxTable;
-(void) displayGenericAlert:(NSString *) messageContent ;
-(void) updateLocDate:(NSDate *)updateDate;
-(void) finishHandleNotification;
-(void) applicationWillTerminate;
-(void) updateStats:(NSString *)type;
- (void)successStatsMethod:(ASIHTTPRequest *) request ;
- (void)failureStatsMethod:(ASIHTTPRequest *)request ;
- (void) sendActionsToServerBulk:(NSTimer*)timer;
- (void)successSendActionsToServerBulk:(ASIHTTPRequest *) request ;
- (void)failureSendActionsToServerBulk:(ASIHTTPRequest *)request;
- (void) updateBackgroundLocationFlag:(BOOL )value; // set it to False to disable location tracking in the BG
- (BOOL) getBackgroundLocationFlag; // get the BG location tracking flag
- (void) updateLocationRequiredFlag:(BOOL )value;
- (BOOL) getLocationRequiredFlag ;
-(BOOL) isLocationSettingOff ;// return true if location setting is turned off for the app running
-(void)appDisplayNotificationNoAlert:(NSDictionary *)pushMessage;
-(void) appDisplayNotification:(NSDictionary *)pushMessage withAlert:(BOOL) alertFlag;
-(void) getPenddingNotifications;
- (UIViewController *)getInboxViewController ; // allow developer hook the inbox VC
// badge management
-(NSInteger) getSpringBoardBadgeCount ;
-(void)		 setSpringBoardBadgeCount:(NSInteger) count;
-(NSInteger) getServerBadgeCount;
-(void)		setServerBadgeCount:(NSInteger) count;
-(void)		setBadgeCountSpringBoardAndServer:(NSInteger) count;
-(void) updateBadgeCount:(NSInteger) value andOperator:(char ) op;//‘op’ is either ‘+’ or ‘-’ or nil
-(NSInteger) getInboxUnreadMessageCount ;
-(void) inboxChangedInternal:(NSInteger) count; // used by the Inbox to notify when rich message was read/reveived

// Called when inbox message count changed, lets the delegate know via didInboxChangeSelector
- (void)messageCountChanged;
// Called when inbox displays a rich details dialog
- (UINavigationController *)getDeveloperNavigationController;
//called when a rich push arrive and the app uses Tabbar
- (void) moveTabbarToInboxNavController ;
// called when action in rich message is set to CST; informs delegate via developerCustomActionSelector
- (void) performDeveloperCustomAction:(NSString *)actionData ;

//to manage the badge flag
- (XLBadgeManagedType) getBadgeMethod;
- (void) updateBadgeFlag:(BOOL )value;
-(void) setSnid:(NSString * )value;
- (NSString *) getSnid;
// Tags
- (void)addTag:(NSMutableArray *)tags;
- (NSString *) getTagString:(NSMutableArray *) tags;
- (void)failureTagMethod:(ASIHTTPRequest *)request;
- (void)successTagMethod:(ASIHTTPRequest *)request;
-(void)doTagRequest:(NSString *) tagUrlString;
- (void)unTag:(NSMutableArray *)tags;
- (void)setTag:(NSMutableArray *)tags;
- (void) getActiveTags;
- (void)successActiveTagMethod:(ASIHTTPRequest *) request;
-(void)doActiveTagsRequest:(NSString *) tagString;
-(NSString *)getXid;

// Locale
- (void)addLocale:(NSString*)locale; // initilazie and updated when first starts, in settings page and register update 
- (void)untagLocale:(NSString*)locale; // in register update

@property (nonatomic, retain) NSString *anAppKey;
@property (nonatomic, retain) 	NSDate * lastLocationUpdateDate ;
@property (nonatomic, retain) NSString *prodName;
@property (nonatomic, assign)	BOOL isLocationRequired, isInGettingMsgLoop;
@property (nonatomic, retain) NSTimer* timerBulkUpdate;

@property (nonatomic, retain) NSDictionary *lastPush;

//badge management
@property (assign, nonatomic) id inboxDelegate;
@property (assign) SEL didInboxChangeSelector, developerCustomActionSelector;
@property (assign) SEL developerNavigationControllerSelector, developerInboxNavigationControllerSelector;

//Locale
@property (nonatomic, retain) NSString *curCountry;
@property (nonatomic, retain) NSString *curLocale;
@property (nonatomic, retain) NSMutableArray *activeTagArray;

@end
