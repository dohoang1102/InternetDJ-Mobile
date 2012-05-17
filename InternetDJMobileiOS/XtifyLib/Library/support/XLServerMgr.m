/*	
 // XLServerManager.m
 //  RichNotification
 //
 //  Created by Gilad on 3/1/11.
 //  Copyright 2011 Xtify. All rights reserved.
 */ 

#import "XLServerMgr.h"
#import "ASIFormDataRequest.h"
#import "XLutils.h"
#import "XLappMgr.h"
#import "XLLocationMgr.h"
#import "SBJson.h"
#if xMultipleMarkets == TRUE
	#import "XLhmSupport.h"
#endif
#import "AppDetailsMgr.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
static XLServerMgr* mServerMgr = nil;


@implementation XLServerMgr

@synthesize deviceToken, emulatorToken;

@synthesize runAlsoInBackground;
@synthesize timerBadgeUpdate;

+(XLServerMgr *)get
{
	if (nil == mServerMgr)
	{
		mServerMgr = [[XLServerMgr alloc] init];
	}
	return mServerMgr;
}

-(id)init
{
	if (self = [super init])
	{
		self.timerBadgeUpdate=nil;
	}
	return self;
}

- (id)initWithReg:(NSData *)token 
{
	if (self = [super init]) {
		[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];	
		runAlsoInBackground =xRunAlsoInBackground ;//collect location in the background if set to true. can be override in XtifyGlobal.h
		if (token==nil) { //simulator
			NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier]; // 
			emulatorToken = [[NSString alloc]initWithString:deviceId];
            deviceToken = [[NSString alloc]initWithString:deviceId];// set the token as the device id so it would be unique
		}
		else {
			deviceToken=[[NSString alloc]initWithString:[self convertToken:token]];
            emulatorToken=[[NSString alloc]initWithString:[self convertToken:token]];
		}
		[self sendProviderDeviceToken];
        
	}
	return self;	
}

// register with xtify server
- (void)sendProviderDeviceToken 
{
#if xMultipleMarkets == TRUE
	
    XLhmSupport *handm =[XLhmSupport get];
	NSString *appKeyMarket=[handm getAppkey];
    
    if(appKeyMarket == nil)
    {    
        appKeyMarket =[[XLappMgr get] anAppKey];
        [self doXtifyRegistration:appKeyMarket];
    }
    else 
    {
        NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
        NSString *xid = [appDetailsDict valueForKey:@"xid"];
        NSString *locale=[appDetailsDict valueForKey:@"locale"];
        NSString *updateCountry =[appDetailsDict valueForKey:@"country"];
        [[XLappMgr get]setCurLocale:locale];
        [[XLappMgr get]setCurCountry:updateCountry];
        
        NSLog(@"xid=%@, locale=%@",xid,locale);
        if (xid != nil)
        {
            [self updateXtifyRegistration:nil];
            [[XLappMgr get] updateAppKey:[appDetailsDict valueForKey:@"appKey"]];
        }
        [handm setCountryLocaleDict];
    }
#else
	NSString *appKey =[[XLappMgr get] anAppKey];
	NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
	NSString *xid = [appDetailsDict valueForKey:@"xid"];
	NSLog(@"xid=%@",xid);
	if (xid == nil)
	{
		[self doXtifyRegistration:appKey];
	} 
	else {
		[self updateXtifyRegistration:nil];
	}

#endif    
    
}

- (void) doXtifyRegistration: (NSString*) appKey
{
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	
	NSString *urlString = [NSString stringWithFormat:@"%@/%@",xBaseUrl,xRegistrationUrl];
	NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier]; // 
    NSString *deviceModel = [[UIDevice currentDevice] model];
    
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];   
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *myDate = [dateFormatter stringFromDate:[NSDate date]];
    
	if([appKey  caseInsensitiveCompare:@"REPLACE_WITH_YOUR_APP_KEY"]==NSOrderedSame) {
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Xtify app key failure. Please replace with your app key" delegate:self 
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		[alertView show];
		[alertView release];	
		return;
	}
    int tzOffsetinSecs = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSString * cName = [carrier carrierName];
    if(cName == nil)
    {
        cName = @"NIL";
    }
    NSString *jsonString;
    if(carrier == nil)
        jsonString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
                      @"{ \"appKey\" : \"",appKey,@"\",",
                      @" \"installID\" : \"",deviceId,@"\",",
                      @" \"type\" : \"",@"IOS",@"\",",
                      @" \"model\" : \"",deviceModel,@"\",",
                      @" \"vOS\" : \"",osVersion,@"\",",
                      @" \"vSDK\" : \"",xSdkVer,@"\",",
                      @" \"installDate\" : \"",myDate,@"\",",
                      @" \"userKey\" : \"",emulatorToken,@"\",",
                      @" \"offset\" : \"",[NSString stringWithFormat:@"%d",tzOffsetinSecs*1000],@"\",",
                      @" \"deviceToken\" : \"",emulatorToken,@"\" }"];
    else
        jsonString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
                            @"{ \"appKey\" : \"",appKey,@"\",",
                            @" \"installID\" : \"",deviceId,@"\",",
                            @" \"type\" : \"",@"IOS",@"\",",
                            @" \"model\" : \"",deviceModel,@"\",",
                            @" \"carrier\" : \"",cName,@"\",",
                            @" \"vOS\" : \"",osVersion,@"\",",
                            @" \"vSDK\" : \"",xSdkVer,@"\",",
                            @" \"installDate\" : \"",myDate,@"\",",
                            @" \"userKey\" : \"",emulatorToken,@"\",",
                            @" \"offset\" : \"",[NSString stringWithFormat:@"%d",tzOffsetinSecs*1000],@"\",",
                            @" \"deviceToken\" : \"",emulatorToken,@"\" }"];
	//[dateFormatter release];
	NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"Attempt to register  with url= %@ and json=%@",urlString,jsonString);
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successRegistrationMethod:)];
	[request setDidFailSelector: @selector(failureRegistrationMethod:)];
	[queue addOperation:request];

    
}
- (void) updateXtifyRegistration:(NSString *)locAppKey
{
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];

	
	NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier]; 
    NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
    if (xid==nil) {
        NSLog(@"*** ERROR *** XID is not set. Not updateXtifyRegistration");
		return;
    }
    
    NSString *oldAppKey = [appDetailsDict valueForKey:@"appKey"];
    NSString *appKey = locAppKey;
    NSString *jsonString;
    if(appKey != nil)
     jsonString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
                            @"{ \"appKey\" : \"",appKey,@"\",",
                            @" \"installID\" : \"",deviceId,@"\",",
                            @" \"vSDK\" : \"",xSdkVer,@"\",",
                            @" \"type\" : \"",@"IOS",@"\",",
                            @" \"deviceToken\" : \"",emulatorToken, @"\" }"];
    else
        jsonString = [NSString stringWithFormat:@"{ %@%@%@%@%@%@%@%@%@%@%@%@", 
                      @" \"installID\" : \"",deviceId,@"\",",
                      @" \"vSDK\" : \"",xSdkVer,@"\",",
                      @" \"type\" : \"",@"IOS",@"\",",
                      @" \"deviceToken\" : \"",emulatorToken, @"\" }"];
    
	NSString *urlString = [NSString stringWithFormat:@"%@/%@%@/update?appKey=%@",xBaseUrl,xUserUpdateUrl,xid,oldAppKey];
    
	NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"Attempt to update registration with url= %@ and json=%@",urlString,jsonString);
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successRegistrationMethod:)];
	[request setDidFailSelector: @selector(failureRegistrationMethod:)];
	[queue addOperation:request];
    
    
}

- (NSString *)convertToken:(NSData *)token {
	NSMutableString *strToken = [NSMutableString string];
	// iterate through the bytes and convert to hex
	unsigned char *ptr = (unsigned char *)[token bytes];
	NSInteger i=0;
	for (i=0; i < 32; ++i) {
		[strToken appendString:[NSString stringWithFormat:@"%02x", ptr[i]]];
	}
	return strToken;
}
// Regardless if a 1st time registration or an updated registration 
- (void)successRegistrationMethod:(ASIHTTPRequest *) request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
	
    //	NSLog(@"Succeeded registering on Xtify server");
    if ((statusCode != 200) && (statusCode != 204) ) {
            XTLOG(@"*** ERROR *** HTTP statusCode=%d, %@",statusCode,responseString);
            return ; // failed to registrer or to update registratio, no point to update badge, stat or location
    }
    // response ok.
    NSString *jsonXid;
    if( statusCode == 200) // first time registration, get the xid
    {
        XTLOG(@"HTTP responseString=%@",responseString);
        if ([responseString length]>0 ) 
        {
            NSString *kParentJson=[[[NSString alloc]initWithString:@"xid"]autorelease];
            NSDictionary *responseDictionary = [responseString JSONValue];
            if ([responseDictionary valueForKeyPath:kParentJson]!=[NSNull null]) 
            {
                jsonXid = [responseDictionary valueForKeyPath:kParentJson];
            }
        }
    }

    if(statusCode == 204) // updated registration
    {
        NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
        jsonXid = [appDetailsDict valueForKey:@"xid"];
        if([appDetailsDict valueForKey:@"locale"] != nil)
        {
            NSString *curLoc = [appDetailsDict valueForKey:@"locale"];
            [[XLappMgr get] untagLocale:curLoc];
        }
        [[AppDetailsMgr get] removeAppDetails];
    }

    // Update AppDetail
    NSString *appKey = [[XLappMgr get] anAppKey];
#if xMultipleMarkets == TRUE		
    NSString *loc = [[XLappMgr get]curLocale];
    NSString *country = [[XLappMgr get]curCountry];
    
    if(jsonXid!=nil && loc!=nil && country!=nil)
    {
        [[AppDetailsMgr get] insertAppDetail:jsonXid:loc:appKey andValue:country];
        [[XLappMgr get] addLocale: loc]; // add local to appMgr and update server
    }
#else
    if(jsonXid!=nil )
    {
        [[AppDetailsMgr get] insertAppDetail:jsonXid:nil:appKey andValue:nil];
    }
#endif        
    
    // Create the locaton manager object with default setting
	NSString *xid = [[[AppDetailsMgr get] getAppDetails] valueForKey:@"xid"];
    if(appKey == nil || [appKey  caseInsensitiveCompare:@"REPLACE_WITH_YOUR_APP_KEY"]==NSOrderedSame || xid==nil) {
		
		XTLOG(@"Appkey or xid is not set");
		return;
	}
	
    if ([[XLappMgr get] getLocationRequiredFlag]) {
        [[XLLocationMgr get] startUpdateForAppStartup];
        NSLog(@"Starting Xtify SDK location services");
    } else {
        NSLog(@"Xtify SDK with no location services");
    }
    
    [[XLappMgr get] updateStats:xAppOpen]; // update stats with app open

    // get the badge count from the server and sync w/ client
    self.timerBadgeUpdate = [NSTimer scheduledTimerWithTimeInterval:15 target:self  
                                        selector:@selector(fireServerBadgeCountService:) userInfo:nil repeats:NO];
}

// app is switched to background or foreground
- (void)switchToBackgroundMode:(BOOL)background
{ 
    if (background) // app is switching to background
    {
		NSLog(@"Entering background and...");
        if (self.runAlsoInBackground) //start the signigicant location tracking
		{
			NSLog(@"...and updating significant location changes");
		}
		else // stop collecting location information
        {
			NSLog(@"...and Stopping to collect location changes");
        }
    } 
    else // app is switching to foreground
    {
		//need to switch locaion on again, regardless if location was collected in the background or not
		NSLog(@"Entering foreground; Start to collect location updates");
        
    }
}


- (void)dealloc {
	if (timerBadgeUpdate) {
		[self.timerBadgeUpdate invalidate];
		self.timerBadgeUpdate = nil;
	}
    
	[super dealloc];
}

//failure in request for registration or location webservice
- (void)failureRegistrationMethod:(ASIHTTPRequest *)request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	NSLog(@"***ERROR***: HTTPRequest request result: %@", error);
}

#pragma mark -
#pragma mark Badge
// get rich message from xtify serer Using GET 
// Getting the pending messages as well
- (NSInteger)getServerBadgeCount
{
	return serverBadgeCount;
}
- (void) fireServerBadgeCountService:(NSTimer*)timer
{
	[self.timerBadgeUpdate invalidate];
	self.timerBadgeUpdate = nil;
    
	
	
	NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
    
    if(xid != nil)
    {
		NSString *urlString = [[NSString alloc ] initWithFormat:@"%@/%@%@/badge",xBaseUrl,xUserUpdateUrl,xid];
		
		NSURL *url = [NSURL URLWithString:urlString];
		XTLOG(@"Attempt to GET badge count from server with url=%@",urlString);
		ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
		request.requestMethod = @"GET";
		[request setDelegate:self];
		[request setDidFinishSelector: @selector(successGetBadgeMethod:)];
		[request setDidFailSelector: @selector(failureGetBadgeMethod:)];
		[request startAsynchronous];
		
    }
    else  {
        serverBadgeCount = 0;
        NSLog(@"*** ERROR *** XID is not set. Not fireServerBadgeCountService");
    }
    
        
}

- (void)successGetBadgeMethod:(ASIHTTPRequest *) request 
{
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
	if (statusCode !=200) {
		XTLOG(@"*** ERROR HTTP statusCode=%d, responseString=%@",statusCode,responseString);
		serverBadgeCount =0; // initlize the count
		return ; 
	}
 
    XTLOG(@"Got successGetBadgeMethod with responseString=%@",responseString);
	// get the badge count
    NSDictionary *responseDictionary = [responseString JSONValue];
    
    if  ([responseDictionary valueForKeyPath:@"badge"] == [NSNull null] ) {
        
        XTLOG(@"Initilizing badge count to zero. statusCode=%d, responseString=[%@]",statusCode,responseString);
        serverBadgeCount=0; // init, badge not set yet
        return;
    }
    
    NSString *badgeValue=[responseDictionary valueForKeyPath:@"badge"] ;
    if (badgeValue !=nil) {
         serverBadgeCount=[badgeValue intValue];
    }
    else {
            serverBadgeCount=0;
    }

}
- (void)failureGetBadgeMethod:(ASIHTTPRequest *)request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	int statusCode = [request responseStatusCode];
	XTLOG(@"***ERROR***: failure to get message count. HTTPRequest request result: [%@] and code=%d", error,statusCode);
    
	serverBadgeCount =0; // initilize it.
	
}

- (void) setServerBadgeCount:(NSString *) countStr // set the badge count on the server
{
   
    NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
	NSString *appKey=[[XLappMgr get] anAppKey];
    
    if (xid==nil || appKey==nil) {
        NSLog(@"*** ERROR *** XID or appKey is not set. Not updating setServerBadgeCount");
		return;
    }
    

    NSString *urlString = [[NSString alloc ] initWithFormat:@"%@/%@%@/update?appKey=%@",
                           xBaseUrl,xUserUpdateUrl,xid,appKey];
    	
    NSString *jsonString = [NSString stringWithFormat:@"%@%@%@",
                            @"{\"badge\" : \"",countStr,@"\" }"];
    
    XTLOG(@"Attempt to POST badge count with url= %@ and json=%@",urlString,jsonString);	

    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
	request.requestMethod = @"POST";
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successSetBadgeMethod:)];
	[request setDidFailSelector: @selector(failureSetBadgeMethod:)];
    [request startAsynchronous];
}

- (void)successSetBadgeMethod:(ASIHTTPRequest *) request 
{
	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];// Use when fetching text data
	
	if (statusCode !=200 && statusCode !=204) {
		XTLOG(@"HTTP statusCode=%d, responseString=%@",statusCode,responseString);
		return ; 
	}
	
	
}
- (void)failureSetBadgeMethod:(ASIHTTPRequest *)request {
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	int statusCode = [request responseStatusCode];
	NSLog(@"***ERROR***: failure to get message count. HTTPRequest request result: [%@] and code=%d", error,statusCode);
	
	serverBadgeCount =-1; // error
	
}


@end
