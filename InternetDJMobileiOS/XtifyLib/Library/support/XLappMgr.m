//
//  XLappMgr.m
// Xtify Library App Manager
//
//  Created by Gilad on 3/1/11.
//  Copyright 2011 Xtify. All rights reserved.

#import "XLappMgr.h"
#import "XLInboxMgr.h"
#import "XRInboxVC.h"
#import "XLServerMgr.h"
#import "XLutils.h"
#import "XLLocationMgr.h"
#import "ASIHTTPRequest.h"
#import "XLMetricMgr.h"
#import "SBJson.h"
#import "AppDetailsMgr.h"


static XLappMgr* mXLappMgr = nil;

@implementation XLappMgr

@synthesize anAppKey,prodName, curCountry, curLocale, lastPush;

@synthesize lastLocationUpdateDate,isLocationRequired,timerBulkUpdate, isInGettingMsgLoop;
@synthesize inboxDelegate,didInboxChangeSelector, developerNavigationControllerSelector, developerInboxNavigationControllerSelector,developerCustomActionSelector;
@synthesize activeTagArray = _activeTagArray;

+(XLappMgr*)get
{
	if (nil == mXLappMgr)
	{
		mXLappMgr = [[XLappMgr alloc] init];
	}
	return mXLappMgr;
}

-(id)init
{
	if (self = [super init])
	{
		serverMgr=[XLServerMgr get];
		inboxMgr =[XLInboxMgr get];
		handleNotification=NO;
		anAppKey =nil;
		isLocationRequired =xLocationRequired;
		timerBulkUpdate=nil;
		
		lastLocationUpdateDate = [[NSDate alloc ]initWithTimeIntervalSinceNow:-REGULAR_UPDATE_TIME_INTERVAL_SECONDS];// so loc update fires
		NSBundle *bundle = [NSBundle mainBundle];
		NSDictionary *info = [bundle infoDictionary];
		prodName = [[NSString alloc]initWithString:[info objectForKey:@"CFBundleDisplayName"]];
//		NSLog(@"prodName=%@",prodName);		
		[self setDidInboxChangeSelector:@selector(messageCountChanged:)];
		[self setDeveloperNavigationControllerSelector:@selector(getDeveloperNavigationController:)];
		[self setDeveloperInboxNavigationControllerSelector:@selector(moveTabbarToInboxNavController:)];
		 //update metrics (stats) bulk count after a delay every so many seconds interval
		self.timerBulkUpdate = [NSTimer scheduledTimerWithTimeInterval:25 target:self 
                        selector:@selector(sendActionsToServerBulk:) userInfo:nil repeats:YES]; 
		
		badgeMgrMethod =xBadgeManagerMethod ;
		[self registerForPush ]; 
	}
	return self;
}
-(void)dealloc
{
	[anAppKey release];
	if (timerBulkUpdate) {
		[self.timerBulkUpdate invalidate];
		self.timerBulkUpdate = nil;
	}
	
	[super dealloc];
}
-(void) updateAppKey:(NSString *)appKey 
{
	anAppKey=[[NSString alloc]initWithString:appKey];
}
-(void)registerWithXtify:(NSData *)devToken 
{
	// register with xtify
	[serverMgr initWithReg:devToken ];
}

//App was launch (from off or background posistion), as a result of push notifcation, significant location change
//or the user starts the app
//Initialize inbox view with the main navigation controller
//-(void) launchWithOptions:(UIApplication *)application navController:(UINavigationController *) mainNavC  andOptions:(NSDictionary *)launchOptions
-(void) launchWithOptions:(UIApplication *)application andOptions:(NSDictionary *)launchOptions
{
    
	if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]!=nil)
	{
		
		NSDictionary * pushMessage =[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		NSLog(@"Got a notification when the phone was off: pushMessage=%@",pushMessage);
		lastPush=[[NSDictionary alloc] initWithDictionary:pushMessage];
		if (lastPush !=nil) {
			if ([[XLServerMgr get] deviceToken]==nil) {
				NSLog(@"Device token is nil. Registering is pending");// wait for 2 sec before getting the push
				//ignore notification alert, as alert was alreday displayed
				[self performSelector:@selector(appDisplayNotificationNoAlert:) withObject:pushMessage  afterDelay:2.0];
			}
			else {
				[self appDisplayNotificationNoAlert:pushMessage];
			}
		}
	}
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0
		&& nil != launchOptions
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		&& nil != [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]
#endif		
		)
	{
		// The app was re-launched in order to receive a significant location change update
		
		NSLog(@"launchOptions=%@",launchOptions);
		[[XLLocationMgr get] doOneUpdate:nil];
	}
}
-(void) applicationWillTerminate
{
	NSLog(@"Closeup");
}

-(void) updateLocDate:(NSDate *)updateDate
{
	[lastLocationUpdateDate release];
	lastLocationUpdateDate = [[NSDate alloc ]initWithTimeIntervalSinceNow:0]; //[[NSDate alloc ]initWith =updateDate;
}
-(void) finishHandleNotification
{
	handleNotification=NO;
}
#pragma mark -
#pragma mark received notification
-(void) appReceiveNotification:(NSDictionary *)pushMessage
{	
	BOOL ignoreNotificationAlert=NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	// get state -applicationState is only supported on 4.0 and above
	if (![[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)])
	{
		ignoreNotificationAlert = NO;
	}
	else
	{
		UIApplicationState state = [[UIApplication sharedApplication] applicationState];
		if (state == UIApplicationStateActive) {
			NSLog(@"Got notification and app is running. Need to display an alert (state is UIApplicationStateActive)");
			ignoreNotificationAlert=NO; // display an alert
		}
		else {
			NSLog(@"Got notification while app was in the background; (user selected the Open button");
			// a good place to add stats for app opens because of notification
			ignoreNotificationAlert =TRUE; // don't display another alert
		}
	}
#endif	
	[self appDisplayNotification:pushMessage withAlert:ignoreNotificationAlert];
}
-(void)appDisplayNotificationNoAlert:(NSDictionary *)pushMessage
{
	[self appDisplayNotification:pushMessage withAlert:TRUE];// don't display another alert
}
-(void)appDisplayNotification:(NSDictionary *)pushMessage withAlert:(BOOL) alertFlag
{
	@synchronized(self)
	{
		if (handleNotification) {
			NSLog(@"Handling a notification already");
			return ; //handle one notification at a time
		}
		
		handleNotification=TRUE;
		lastPush=[[NSDictionary alloc] initWithDictionary:pushMessage];
		
		NSLog(@"userInfo= %@", lastPush);
		
		//check the message for msd id or url
		NSString *msgId,*urlLink, *simpleId;
		if ([lastPush objectForKey:@"RN"]!=[NSNull null] && [[lastPush objectForKey:@"RN"] length] > 0 ) {
			msgId= [[[NSString alloc]initWithString:[lastPush objectForKey:@"RN"]]autorelease];
			NSLog(@"lastPush objectForKey=%@",msgId);
            [[XLMetricMgr get]insertMetricAction:xNotifAck andValue:msgId andTimestamp:nil];
			
		}
		else {
			msgId=[[[NSString alloc] initWithString:@""]autorelease];
            simpleId= [[[NSString alloc]initWithString:@""]autorelease];
            if([lastPush objectForKey:@"SN"]!=[NSNull null] && [[lastPush objectForKey:@"SN"] length] > 0 )
            {
                
                simpleId= [lastPush objectForKey:@"SN"];
                NSLog(@"lastPush objectForKey=%@",simpleId);	
                [self setSnid:simpleId];
            }
            [[XLMetricMgr get]insertMetricAction:xNotifAck andValue:simpleId andTimestamp:nil];
		}
		
		if ([lastPush objectForKey:@"URL"]!=[NSNull null] && [[lastPush objectForKey:@"URL"] length] > 0 ) {
			urlLink=[[[NSString alloc]initWithString:[lastPush objectForKey:@"URL"]]autorelease];
			// do the url push directly to safari, no trace to inbox
		}
		else 
			urlLink=[[[NSString alloc] initWithString:@""]autorelease];
		
		NSDictionary *aps=[lastPush objectForKey:@"aps"];
		//	NSString *sound=[aps objectForKey:@"sound"];// don't send sound (when notiffication received) as the app is open
		
		NSDictionary *alert=[aps objectForKey:@"alert"];
		NSString *action=[alert objectForKey:@"action-loc-key"] ==[NSNull null]  ?@"Open" : [alert objectForKey:@"action-loc-key"];
		NSString *body=[alert objectForKey:@"body"] ==[NSNull null] ? @" " : [alert objectForKey:@"body"];
		
        if ([msgId isEqualToString:@""] && [body isEqualToString:@""] )
            alertFlag =true;

		//Check how the notification was opened
		UIAlertView *alertView ;
		if (! alertFlag)  // 
		{// app was active when notification has arrived. Open a dialog with an OK and cancel button
			//	this app handle 2 types of push: rich and url
			if ([msgId isEqualToString:@""] && [urlLink isEqualToString:@""] ) 
				// the message might have a key but if the data is empty there is nothing to do but to display a simple alert ok
				alertView = [[UIAlertView alloc] initWithTitle:prodName message:body
													  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			else { // give the user an option to cancel the push
//				NSLog(@"msgId=%@",msgId);
//				NSLog(@"urlLink=%@",urlLink);
				
				alertView = [[UIAlertView alloc] initWithTitle:prodName message:body
													  delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:action, nil];
			}
			[alertView show];
			[alertView	 release];		
			if([self getSnid]!=nil)
                [[XLMetricMgr get]insertMetricAction:xNotifDisplay andValue:[self getSnid] andTimestamp:nil];// notification is displayed
			
		}	
		else  //user already recived a push when the app was closed, and selectef the open button. 
		{	// no need to have another alert. Check what kind of message it is and push it
			
            if([self getSnid] != nil)
                [[XLMetricMgr get]insertMetricAction:xNotifClick andValue:[self getSnid] andTimestamp:nil];// update stats user clicked on open button
			
			if ([msgId length]>0) { // handle rich push
				//			UINavigationController *devNavController=[self getDeveloperNavigationController ];
				//[inboxMgr pushAndDisplayMessage:devNavController withData:lastPush];
				[inboxMgr pushAndDisplayMessage:lastPush];
				
			} else // can't have both. rich has preference on url
				if ([urlLink length]>0) {
					//NSString *urlLink=[[NSString alloc]initWithString:[lastPush objectForKey:@"URL"]];
					NSURL *url = [NSURL URLWithString:urlLink];
					if (![[UIApplication sharedApplication] openURL:url])
						NSLog(@"Failed to open url:%@",[url description]);
					handleNotification =NO;
				}
            
		}
		
		//		ignoreNotificationAlert=NO;
	}		
}
-(void) registerForPush 
{	
	// apns user request
	NSLog(@"Attempt to register for push notifications...");
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound |UIRemoteNotificationTypeAlert)];
}
//update the server with a single action (when relevant, uses last rich notification id as value)
//{appKey}/{deviceId}/{deviceToken}/{action}/{value}")
-(void) updateStats:(NSString *)action
{
	NSString *appKey=[[XLappMgr get] anAppKey];
    if(appKey == nil || [appKey  caseInsensitiveCompare:@"REPLACE_WITH_YOUR_APP_KEY"]==NSOrderedSame) {
		
		NSLog(@"App key not set yet");
		return;
	}
	
	NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];
    if (xid==nil) {
        NSLog(@"XID is not set. Not updating Stats");
		return;
    }
    
	NSString *value =nil;
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];   
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *isoDate = [dateFormatter stringFromDate:[NSDate date]];

	NSString *urlString =[NSString stringWithFormat:@"%@/%@%@",xBaseUrl,xMetricsUrl,xid]                ; 
    NSString *jsonString;
	if ([action isEqualToString:xAppOpen] || [action isEqualToString:xAppBackground]) {
		jsonString=[NSString stringWithFormat:
                    @" { \"appKey\": \"%@\" , \"events\" : [ { \"action\" : \"%@\", \"value\": \"%@\" , \"timeStamp\" : \"%@\" } ] }",appKey,action,@"",isoDate ];
        
	} else {
		value=[lastPush objectForKey:@"RN"]; // notificationId;
        jsonString=[NSString stringWithFormat:
            @" { \"appKey\": \"%@\" , \"events\" : [ { \"action\" : \"%@\", \"value\": \"%@\" , \"timeStamp\" : \"%@\" } ]  }",appKey,action,value,isoDate ];
	}
	XTLOG(@"Attempt to update Stats with url= %@ and json=%@",urlString,jsonString);
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successStatsMethod:)];
	[request setDidFailSelector: @selector(failureStatsMethod:)];
	[queue addOperation:request];
	
}
- (void)successStatsMethod:(ASIHTTPRequest *) request 
{
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
	XTLOG(@"HTTP statusCode=%d",statusCode);
	if (statusCode >300) {
		XTLOG(@"HTTP responseString=%@",responseString);
	}
}
- (void)failureStatsMethod:(ASIHTTPRequest *)request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	XTLOG(@"***ERROR***: Updating single action Metric. Request result: %@", error);
}

//update server with multiple actions from local store
-(void) sendActionsToServerBulk:(NSTimer*)timer
{
    NSString *appKey=[[XLappMgr get] anAppKey];
    static BOOL firsttime=TRUE;

    if(appKey == nil || [appKey  caseInsensitiveCompare:@"REPLACE_WITH_YOUR_APP_KEY"]==NSOrderedSame) {
            if (firsttime ) {
                NSLog(@"*** ERROR *** App key not set yet");
                firsttime =FALSE;
            }
		return;
	}
	NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];
    if (xid==nil) {
        if (firsttime ) {
            NSLog(@"*** ERROR *** XID is not set. Not updating metrix");
            firsttime =FALSE;
        }
		return;
    }
	
	NSString *jsonStringPartII=[[XLMetricMgr get] getRecentActions ];
	
	if ([jsonStringPartII length]==0) {//isEqualToString
        return; // no action was recorded recently
	}
	
	NSString *urlString =[NSString stringWithFormat:@"%@/%@%@",xBaseUrl,xMetricsUrl,xid]                ; 
	NSString *jsonString=[NSString stringWithFormat:
					  @" { \"appKey\": \"%@\" , \"events\" : [ %@ ]   }",appKey,jsonStringPartII];
	
	XTLOG(@"Attempt to update Stats with url= %@ and json=%@",urlString,jsonString);

	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successSendActionsToServerBulk:)];
	[request setDidFailSelector: @selector(failureSendActionsToServerBulk:)];
	[queue addOperation:request];
	
}

- (void)successSendActionsToServerBulk:(ASIHTTPRequest *) request 
{
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
	XTLOG(@"HTTP statusCode=%d",statusCode);
	if (statusCode >300) {
		XTLOG(@"HTTP responseString=%@",responseString);
        [[XLMetricMgr get] insertFailedStats];
  		return ; 
	}
	//[[XLMetricMgr get] removeActions];	// remove actions from local storage	
}
- (void)failureSendActionsToServerBulk:(ASIHTTPRequest *)request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	XTLOG(@"***ERROR***: Updating Actions Metric. Request result: %@", error);
	[[XLMetricMgr get] insertFailedStats];
}

-(void) displayInboxTable
{
	[[XLMetricMgr get]insertMetricAction:xRichInboxClick andValue:nil andTimestamp:nil];
	[inboxMgr displayInboxTable];
}

-(void) appEnterActive
{
	//	ignoreNotificationAlert=NO;
}
-(void) appEnterForeground
{
	//user might have open the app because of push notification
	//	ignoreNotificationAlert=TRUE; //set flag to ignore notification alert
	[self finishHandleNotification];
	if ([[XLappMgr get] getLocationRequiredFlag] && [[XLappMgr get] getXid] != nil) {
		[[XLLocationMgr get] transitionToForeground];
	}
	[[XLMetricMgr get]insertMetricAction:xAppOpen andValue:nil andTimestamp:nil];
	
	//	[self getPenddingNotifications];
}
-(void) appEnterBackground
{
    NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
	[self finishHandleNotification];
	if ([[XLappMgr get] getLocationRequiredFlag] && xid != nil) {
		[[XLLocationMgr get] transitionToBackground];
	}
	[[XLMetricMgr get]insertMetricAction:xAppBackground andValue:nil andTimestamp:nil];
}	
-(void) getPenddingNotifications
{
	[[XLInboxMgr get]getPenddingNotifications:nil];
}
-(void) displayGenericAlert:(NSString *) messageContent
{
	UIAlertView *alert =[[[UIAlertView alloc] initWithTitle:prodName 
													message:messageContent delegate:nil cancelButtonTitle:@"Cancel" 
										  otherButtonTitles:nil] autorelease];
	[alert show];
}

-(NSString *) getXid
{
    NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
    return xid;
}

#pragma mark -
#pragma mark - UIAlertViewDelegate
//User clicks the 'Open' after a push when the app is open.
// this is the application which puts the message
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) { // user select open
		//		[[XLMetricMgr get]insertMetricAction:xNotifAck andValue:[self getSnid]];// user clicked on open button
		//		[[XLMetricMgr get]insertMetricAction:xNotifClick andValue:[self getSnid]];// update stats, notification was opened 
		if([self getSnid]!=nil)
        {
            [[XLMetricMgr get]insertMetricAction:xNotifClick andValue:[self getSnid] andTimestamp:nil];
        }		
		if ([lastPush objectForKey:@"RN"] !=[NSNull null]  && [[lastPush objectForKey:@"RN"] length] > 0 ) {
			NSLog(@"About to Open Rich notification");
			//			UINavigationController *devNavController=[[XLappMgr get]getDeveloperNavigationController ];
			[inboxMgr pushAndDisplayMessage:lastPush];
		}
		if ([lastPush objectForKey:@"URL"] !=[NSNull null]  && [[lastPush objectForKey:@"URL"] length] > 0  ) {
			NSLog(@"About to Open Safari");
			NSString *urlLink=[[[NSString alloc]initWithString:[lastPush objectForKey:@"URL"]]autorelease];
			NSURL *url = [NSURL URLWithString:urlLink];
			if (![[UIApplication sharedApplication] openURL:url])
				NSLog(@"Failed to open url:%@",[url description]);
		}
		
	}
	else // user selected cancel
	{
		NSLog(@"Canceled notification while the app is running");
		[[XLMetricMgr get]insertMetricAction:xNotifClear andValue:[self getSnid] andTimestamp:nil];// notification was canceled 
		
	}
	handleNotification=NO;
}
#pragma mark -
#pragma mark - Location method

-(void) updateBackgroundLocationFlag:(BOOL )value
{
	[XLServerMgr get].runAlsoInBackground=value;
}

// get the BG location tracking flag
- (BOOL) getBackgroundLocationFlag
{
	return [XLServerMgr get].runAlsoInBackground;
}

-(void) updateLocationRequiredFlag:(BOOL )value
{
	isLocationRequired=value;
}
- (BOOL) getLocationRequiredFlag
{
	return isLocationRequired;
}

-(void) setSnid:(NSString * )value
{
	snId=value;
}
- (NSString *) getSnid
{
	return snId;
}

// Get the app location setting 
- (BOOL) isLocationSettingOff
{
	return [[XLLocationMgr get] isLocationSettingOff];
}
#pragma mark -
#pragma mark - Badge Management
- (void)setInboxDelegate:(id)newDelegate
{
	inboxDelegate = newDelegate;
}
-(void) setSpringBoardBadgeCount:(NSInteger) count
{
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}
// called internally whenever message arrived, read or deleteed w/o read
-(void) inboxChangedInternal:(NSInteger) count
{ 
	if (isInGettingMsgLoop) {
		return; // wait for the end of the loop
	}
	
	
	// developer manage method vs. inbox
	if (badgeMgrMethod ==XLInboxManagedMethod) {
		[self setBadgeCountSpringBoardAndServer:count];
	}	
	
	//for developer
	if (badgeMgrMethod ==XLDeveloperManagedMethod) {
		[self messageCountChanged] ;
	}
}

- (void) messageCountChanged
{
	if (inboxDelegate && [inboxDelegate respondsToSelector:didInboxChangeSelector]) {
		[inboxDelegate performSelector:didInboxChangeSelector withObject:self];
	}
	else {
		NSLog(@"**Warning**");
		NSLog(@"xBadgeManagerMethod is set to XLDeveloperManagedMethod but selector is not set. Use [appMgr setDidInboxChangeSelector:@selector(doMyUpdate:)]; to set it up");
	}
}
- (UINavigationController *) getDeveloperNavigationController
{
	if (inboxDelegate && [inboxDelegate respondsToSelector:developerNavigationControllerSelector]) {
		return (UINavigationController *)[inboxDelegate performSelector:developerNavigationControllerSelector withObject:self];
	}
	NSLog(@"*** Error ***");
	NSLog(@"Use [appMgr setDeveloperNavigationControllerSelector:@selector(developerNavigationController:)]; to set it up");
	return nil;
}

- (void) moveTabbarToInboxNavController
{
	if (inboxDelegate && [inboxDelegate respondsToSelector:developerInboxNavigationControllerSelector]) {
		NSLog(@"performing developerInboxNavigationControllerSelector");
		[inboxDelegate performSelector:developerInboxNavigationControllerSelector withObject:self];
	}
}

-(void) performDeveloperCustomAction:(NSString *)actionData
{
	
	if (inboxDelegate && [inboxDelegate respondsToSelector:developerCustomActionSelector]) {
		[inboxDelegate performSelector:developerCustomActionSelector withObject:actionData];
	}
	else {
		NSLog(@"*** Error ***. Custom Rich is set but no method was provided. Use [appMgr setDeveloperCustomActionSelector:@selector(developerCustomActionMethod:)]; to set it up");
	}
}

- (UIViewController *)getInboxViewController 
{
	return (UIViewController *)[XRInboxVC get];
}
-(NSInteger) getInboxUnreadMessageCount 
{
	return [[XLInboxMgr get] getInboxUnreadMessageCount] ;
}

-(NSInteger)  getSpringBoardBadgeCount
{
	return [[UIApplication sharedApplication] applicationIconBadgeNumber];
}

-(NSInteger) getServerBadgeCount
{
	return [[XLServerMgr get] getServerBadgeCount];
}
-(void)		setServerBadgeCount:(NSInteger) count
{
	NSString *countStr=[NSString stringWithFormat:@"%d", count ];
	return [[XLServerMgr get] setServerBadgeCount:countStr];
}

-(void)	setBadgeCountSpringBoardAndServer:(NSInteger) count
{
	[self setServerBadgeCount:count];
	[self setSpringBoardBadgeCount:count];
}

//‘op’ is either ‘+’ or ‘-’ or nil
-(void) updateBadgeCount:(NSInteger) value andOperator:(char ) op
{
	NSString *countStr;
	switch (op) {
		case '+':
			countStr=[NSString stringWithFormat:@"+%d",value];
			break;
		case '-':
			countStr=[NSString stringWithFormat:@"-%d",value];
			break;
		default:
			countStr=[NSString stringWithFormat:@"%d",value];
			break;
	}
	[[XLServerMgr get] setServerBadgeCount:countStr];
}
-(XLBadgeManagedType) getBadgeMethod
{
	return badgeMgrMethod;
}

-(void) updateBadgeFlag:(BOOL )value
{
    
    badgeMgrMethod = value;
    
    if (value == NO) {
        NSLog(@"The badge is now managed by Inbox");
    } else {
        NSLog(@"The badge is now managed by Developer");
    }
}

#pragma mark -
#pragma mark - Tags Management
- (void)addTag:(NSMutableArray *)tags 
{
    
    NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
		NSString *tagString = [NSString stringWithFormat:@"%@/%@%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],
							   @"/addtag?appKey=",[[XLappMgr get] anAppKey],
							   [self getTagString:tags]];
		[self doTagRequest:tagString];
    }
    else
        NSLog(@"XID not present");
}

- (void)setTag:(NSMutableArray *)tags
{

    NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
        NSString *tagString;
        if (tags!=nil)
        { 
            tagString = [NSString stringWithFormat:@"%@/%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],
							   @"/settag?appKey=",[[XLappMgr get] anAppKey],
							   [self getTagString:tags]];
        }
        else
        {
            tagString = [NSString stringWithFormat:@"%@/%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],
                                   @"/settag?appKey=",[[XLappMgr get] anAppKey]];
        }
		NSLog(@"The tagging url is %@", tagString);
		[self doTagRequest:tagString];
    }
    else
        NSLog(@"XID not present");
}

- (void)unTag:(NSMutableArray *)tags
{

    NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    NSString *tagStt = [self getTagString:tags];
    NSLog(@"The tagStr is=%@",tagStt);
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
        NSString *tagString = [NSString stringWithFormat:@"%@/%@%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],
                               @"/untag?appKey=",[[XLappMgr get] anAppKey],
                               [self getTagString:tags]];
		[self doTagRequest:tagString];
    }
    else
        NSLog(@"XID not present");
}

- (void) getActiveTags 
{
	NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
		NSString *tagString = [NSString stringWithFormat:@"%@/%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"], @"/tags?appKey=",[[XLappMgr get] anAppKey]];
		NSLog(@"the url is %@",tagString);
		[self doActiveTagsRequest:tagString];
    }
    else
        NSLog(@"XID not present");
}


- (NSString *) getTagString:(NSMutableArray *) tags
{
    return [NSString stringWithFormat:@"%@%@",@"&tag=",[tags componentsJoinedByString: @"&tag="]];
}
- (void)successTagMethod:(ASIHTTPRequest *) request 
{
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
    XTLOG(@"Got successTagMethod  statusCode=%d, responseString=%@",statusCode,responseString);
	if (statusCode !=204 && statusCode !=200) {
        XTLOG(@"***ERROR***: failure to tag. HTTPRequest code=%d, error=%@", statusCode,responseString);
		return ; 
	}
}
- (void)failureTagMethod:(ASIHTTPRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	int statusCode = [request responseStatusCode];
	XTLOG(@"***ERROR***: failure to tag. HTTPRequest result: [%@] and code=%d", error,statusCode);
	
}
- (void)successActiveTagMethod:(ASIHTTPRequest *) request 
{
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
    NSLog(@"%@",responseString);
	NSDictionary *responseDictionary = [responseString JSONValue];
    
	if (statusCode !=200) {
		XTLOG(@"HTTP statusCode=%d, responseString=%@",statusCode,responseString);
		return ; 
	}
    if ([responseDictionary valueForKeyPath:@"tags"]!=[NSNull null] ) {
		NSMutableArray * anArray = [responseDictionary valueForKeyPath:@"tags"];
		NSLog(@"The array length is=%d",[anArray count]);
        
        [self setActiveTagArray:anArray];
        
	}
}


-(void)doTagRequest:(NSString *) tagString{
    NSURL *url = [NSURL URLWithString:tagString];
    XTLOG(@"Attempt to POST tag to server with url=%@",tagString);
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successTagMethod:)];
	[request setDidFailSelector: @selector(failureTagMethod:)];
    [request startAsynchronous];
}

-(void)doActiveTagsRequest:(NSString *) tagString{
    NSURL *url = [NSURL URLWithString:tagString];
    XTLOG(@"Attempt to GET tags from server with url=%@",tagString);
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"GET";
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successActiveTagMethod:)];
	[request setDidFailSelector: @selector(failureTagMethod:)];
    [request startAsynchronous];
    
}

#pragma mark -
#pragma mark - Locale
- (void)addLocale:(NSString*)locale 
{
    NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
        NSString *tagString = [NSString stringWithFormat:@"%@/%@%@%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],@"/addtag?appKey=",[[XLappMgr get] anAppKey],@"&tag=.",locale];
        NSLog(@"Attempting to connect with url = %@", tagString);
        [self doTagRequest:tagString];
    }
    else
		
        NSLog(@"XID not present");
}
- (void)untagLocale:(NSString*)locale 
{
    NSMutableDictionary *dic = [[AppDetailsMgr get]getAppDetails];
    if([dic valueForKey:@"xid"]!=[NSNull null] && [[dic valueForKey:@"xid"]length] > 0)
    {
        NSString *tagString = [NSString stringWithFormat:@"%@/%@%@%@%@%@%@",xBaseUrl,xTaggingUrl,[dic valueForKey:@"xid"],@"/untag?appKey=",[[XLappMgr get] anAppKey],@"&tag=.",locale];
        NSLog(@"Attempting to connect with url = %@", tagString);
        [self doTagRequest:tagString];
        
    }
    else
        
        NSLog(@"XID not present");
}

@end
