/*
 * XLInboxMgr.m
Copyright Xtify Inc. All rights reserved.

*/
#import <UIKit/UIKit.h>
#import "XLInboxMgr.h"
#import "XRInboxVC.h"
#import "XRDetailsVC.h"
#import "XLRichJsonMessage.h"
#import "XLInboxJsonParser.h"
#import "RichDbMessage.h"
#import "ASIHTTPRequest.h"
#import "XLutils.h"
#import "XLappMgr.h"
#import "XLServerMgr.h"
#import "XLDbMgr.h"
#import "XLMetricMgr.h"
#import "AppDetailsMgr.h"

static XLInboxMgr* mInboxMgr = nil;

@implementation XLInboxMgr

+(XLInboxMgr *)get
{
	if (nil == mInboxMgr)
	{
		mInboxMgr = [[XLInboxMgr alloc] init];
	}
	return mInboxMgr;
}

-(id)init
{
	if (self = [super init])
	{
		lastStatusCode=0;
		isRetrieving=0;	
		lastMid=nil;
		
	}
	return self;
}

-(void) displayInboxTable  
{
	XRInboxVC *inboxVC=[XRInboxVC get ];
	NSString *missingMids= [inboxVC iterateOverFectch ];
	NSLog(@"missingMids=%@",missingMids);
	[self getPenddingNotifications:missingMids];//upload all the pending messages
	UINavigationController *devNavController=[[XLappMgr get]getDeveloperNavigationController ];
	
	[devNavController pushViewController:inboxVC animated:YES];
	[devNavController setNavigationBarHidden:NO];
}
// get all pending messages
// the link has the format /api/1.2/rn/details?appKey=APIKEY&includePending=TRUE&deviceToken=DEVICETOKEN
-(void) getPenddingNotifications:(NSString *)missingMids
{
	NSString *appKey=[[XLappMgr get] anAppKey];
	NSString *urlString;
    NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];

	if (missingMids==nil) {
        urlString =[NSString stringWithFormat:@"%@/%@%@/pending?appKey=%@",xBaseUrl,xRichUrl,xid,appKey];      
	}
	else {
        urlString =[NSString stringWithFormat:@"%@/%@%@/details?appKey=%@&mid=%@",xBaseUrl,xRichUrl,xid,appKey,missingMids];      
	}
	[self getRichMessage:urlString];//
}

// Display a rich message (only for mid)
//Get all pending messages, place them in the inbox messages and display the one in the notification
-(void) pushAndDisplayMessage:(NSDictionary *)pushMessage
{
	// get the push	
	lastMid=[[NSString alloc]initWithString:[pushMessage objectForKey:@"RN"]];

	//make sure we're at the top level as it's unknow what the app is doing
	[[XLappMgr get]moveTabbarToInboxNavController];
	
	 // the ui
	 XRInboxVC *inboxVC	=[XRInboxVC get ];
	 if ((inboxVC.detailsController)==nil)
		inboxVC.detailsController= [[XRDetailsVC alloc] init ];
		
	
	NSString *appKey=[[XLappMgr get] anAppKey];
    NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];
	if (xid ==nil) {
		NSLog(@"XID is nil. Not displaying Rich message %@",lastMid);
		return;
	}
	[self addEmptyMid:lastMid];
    
    NSString *urlString =[NSString stringWithFormat:@"%@/%@%@/details?appKey=%@&mid=%@",xBaseUrl,xRichUrl,xid,appKey,lastMid];      

		[self getRichMessage:urlString];//
    [[XLMetricMgr get]insertMetricAction:xRichDisplay andValue:lastMid andTimestamp:nil];
    [[XLMetricMgr get]insertMetricAction:xNotifClick andValue:lastMid andTimestamp:nil];
}	

// get rich message from xtify serer Using GET 
// Getting the pending messages as well
- (void)getRichMessage:(NSString *)urlString 
{
    if([[[XLappMgr get] anAppKey] caseInsensitiveCompare:@"REPLACE_WITH_YOUR_APP_KEY"]==NSOrderedSame) {
		NSLog(@"App key not set yet");	
		return;
	}

    NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];
    if (xid==nil) {
        NSLog(@"*** ERROR *** XID is not set. Not getRichMessage");
		return;
    }

    // notify message is about to load, start spin indicator
	NSLog(@"Attempt to GET rich message with url= %@",urlString);
	NSURL *url = [NSURL URLWithString:urlString];
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setNumberOfTimesToRetryOnTimeout:2]; // Make requests retry of 2 times if they encounter a timeout:
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setResponseEncoding:NSUnicodeStringEncoding];
	//request.requestMethod = @"GET";
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successGetMessageMethod:)];
	[request setDidFailSelector: @selector(failureGetMessageMethod:)];
	
    [request startAsynchronous];
    isRetrieving++;
}

- (void)successGetMessageMethod:(ASIHTTPRequest *) request 
{
	
    isRetrieving--;
	[[XLappMgr get] finishHandleNotification];

	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data

	lastStatusCode=statusCode;
	if (statusCode !=200) {
		XTLOG(@"*** ERROR *** HTTP statusCode=%d, [%@]",statusCode,responseString);
		return ; 
	}
    NSData *response = [request responseData];
    NSString *strData = [[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding];

    XTLOG(@"responseString=%@",strData );
	XLInboxJsonParser *inboxJsonParser = [[XLInboxJsonParser alloc] init];
	BOOL success = [inboxJsonParser  parseResponse:strData];

    if(success ) {
		// either the most recent push or display the inbox list
		int jsonMessageCount=[inboxJsonParser getMessageCount] ;
		if (jsonMessageCount==0) {
			NSLog(@"No pending messages" );
			[XLappMgr get].isInGettingMsgLoop=NO;
			return ;
		}
		else {
			[XLappMgr get].isInGettingMsgLoop=YES;
			XTLOG(@"Getting %d message(s)",jsonMessageCount);
		}
		// get all pending messages and add them to the local store
		XLRichJsonMessage *axMessage;
		// start a batch flag
		for (int i=0; i<jsonMessageCount; i++) {
			axMessage =(XLRichJsonMessage *)[inboxJsonParser getMessageAtIndex:i];
			if (axMessage==nil) {
				NSLog(@"No valid Json message reveived for element i=%d",i );
				continue;
			}
			if (i==(jsonMessageCount-1)) {
				[XLappMgr get].isInGettingMsgLoop=NO; //the last db update will also update badge count 
			}
			[self loadNotificationsToDb:(XLRichJsonlMessage *)axMessage];
		}
		if (lastMid !=nil)  //get lastMid message and display it
		{
			XTLOG(@"Display the rich message %@, as it came as a push",lastMid);
			// at this point the view controller got notified that its table was changed
			XRInboxVC *inboxVC	=[XRInboxVC get ];
			RichDbMessage *dbMessage =(RichDbMessage *)[inboxVC getDbMessageByMid:lastMid]; 
			if (dbMessage !=nil)  {
				inboxVC.detailsController.dbMessage =dbMessage  ;
				[dbMessage updateMessage:TRUE]; //message is updaged as read

				UINavigationController *devNavController=[[XLappMgr get]getDeveloperNavigationController ];
                NSArray *viewCntrlArray=[devNavController popToRootViewControllerAnimated:NO];

                BOOL isVcDetailsDisplaying =false;  //
                if(viewCntrlArray != nil && [viewCntrlArray count] > 0) {
                    for(UIViewController* viewC in viewCntrlArray) {
                        if ([viewC isMemberOfClass:[XRDetailsVC class]]) {
                            isVcDetailsDisplaying=true; // force refresh if details view was visiable when push arrived
                        }
                    }
                }
				// decrement the total count as the message displayed is being read
				int unreadMessages=[inboxVC getInboxUnreadMessageCount];
				[inboxVC setInboxUnreadMessageCount:--unreadMessages];
				[[XLappMgr get] inboxChangedInternal:unreadMessages];

 				if (inboxVC.navigationController==nil) {
                    [devNavController pushViewController:inboxVC animated:NO];
					[devNavController pushViewController:inboxVC.detailsController animated:YES];
				} else {
					[inboxVC.navigationController pushViewController:inboxVC.detailsController animated:YES]; 
				}
				if (isVcDetailsDisplaying) {
                    [inboxVC.detailsController viewWillAppear:TRUE];
                }
			}
				
			[lastMid release];
			lastMid =nil;
		}

	} 
	else {
		XTLOG(@"Error reading/ parsing Json, or bad version number%@",responseString);
	} 
}

-(void) addEmptyMid:(NSString *)pushMid
{
	XRInboxVC *inboxVC=[XRInboxVC get ];
	// create a blank entity
	RichDbMessage *aDbMessage = (RichDbMessage *)[NSEntityDescription 
												  insertNewObjectForEntityForName:@"Inbox" inManagedObjectContext:inboxVC.managedObjectContext];
	aDbMessage.mid=pushMid;
	NSError *error;
	if (![inboxVC.managedObjectContext save:&error]) { // Commit the change.
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"***Getting database error.%@",[error userInfo]);
		}
		[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database

	}
	NSLog(@"Added Empty record=%@ to Inbox entity",[aDbMessage mid]);
	
}
//update Inbox entity with new notifications
//update view controller with new entries
-(void) loadNotificationsToDb:(XLRichJsonMessage *)axMessage
{
	XRInboxVC *inboxVC=[XRInboxVC get ];
    
	RichDbMessage *aDbMessage =(RichDbMessage *)[inboxVC getDbMessageByMid:axMessage.mid]; 
	if (aDbMessage ==nil)  {
		// create a blank entity
		aDbMessage = (RichDbMessage *)[NSEntityDescription 
					insertNewObjectForEntityForName:@"Inbox" inManagedObjectContext:inboxVC.managedObjectContext];
	}
	else {
        
		NSLog(@"mid %@ exist. Just populate it",axMessage.mid);
	}
    // subjet
    NSString *rnSubject = axMessage.subject;
    [rnSubject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(rnSubject == nil || [rnSubject length] == 0)
    {
        axMessage.subject = @" ";
    }
	// content
    NSString *rnContent = axMessage.content;
    [rnContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(rnContent == nil || [rnContent length] == 0)
    {
        axMessage.content = @" ";
    }

    NSString *expirationDate = axMessage.expirationDate;
    if(expirationDate == nil || [expirationDate length] == 0)
    {
        axMessage.expirationDate = @" ";
    }

	[aDbMessage setFromJson:axMessage]; // set the entity from the json

	
	NSError *error;
	if (![inboxVC.managedObjectContext save:&error]) { // Commit the change.
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"***Getting database error.%@",[error userInfo]);
		}
		[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database
	}
//	NSLog(@"added record=%@ to Inbox entity",[aDbMessage mid]);
}	
- (void)failureGetMessageMethod:(ASIHTTPRequest *)request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[[XLappMgr get] finishHandleNotification];
	NSError *error = [request error];
	NSLog(@"***ERROR***: failureGetMessageMethod request failure. HTTPRequest request result: %@", error);
	int statusCode = [request responseStatusCode];
	lastStatusCode=statusCode;
}
- (int) getLastHttpStatusCode
{
	return lastStatusCode;
}

- (NSInteger) getInboxUnreadMessageCount
{
	return [[XRInboxVC get] getInboxUnreadMessageCount];
}
@end
