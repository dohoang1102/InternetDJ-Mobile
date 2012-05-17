//
//  XLLocationMgr.m
//  XtifyLib
//
//  Created by Gilad on 3/22/11.
//  Copyright 2011 Xtify. All rights reserved.
//

//

#import <UIKit/UIKit.h>
#import "XLLocationMgr.h"
#import "XLappMgr.h"
#import "XLutils.h"
#import "XLServerMgr.h"
#import "ASIHTTPRequest.h"
#import "AppDetailsMgr.h"

#define TIME_INTERVAL_GIVE_UP  20
#define LOCATION_UPDATE_FRESHNESS_THRESHOLD_SECONDS  60
#define DESIRED_ACCURACY  kCLLocationAccuracyKilometer
#define RETRY_COUNT_MM_SERVER_LOC_UPDATE  3

XLLocationMgr* mLocationMan = nil;
NSCondition* condUpdatedFirstTime = nil;

@implementation XLLocationMgr

@synthesize m_coreLocationMan , m_currentCoordinate;
@synthesize timerForegroundUpdate;

+(XLLocationMgr*)get
{
	@synchronized(self) {
		if (nil == mLocationMan)
		{
			mLocationMan = [[XLLocationMgr alloc] init];
		}
		
		return mLocationMan;
	}
}

-(id)init
{
	if (self = [super init])
	{
		[self setState:LMS_COORDINATES_NOT_SET];
		m_currentCoordinate.latitude = 0;
		m_currentCoordinate.longitude = 0;
		self.m_coreLocationMan = [[[CLLocationManager alloc] init] autorelease];
		m_coreLocationMan.delegate = self;
		m_coreLocationMan.desiredAccuracy = DESIRED_ACCURACY;
		self.timerForegroundUpdate = nil;
		newIntervalDate =[[NSDate alloc ]initWithTimeIntervalSinceNow:0];
	}
	return self;
}

- (void)writeLastLocationUpdateDateToDB:(NSDate*)updateDate
{
		
	XTLOG(@"writeLastLocationUpdate Date=%@",updateDate);
	[[XLappMgr get] updateLocDate:updateDate];

}

- (NSDate*)getLastLocationUpdateDateFromDB
{
	
	NSDate *last = [[XLappMgr get] lastLocationUpdateDate];
	XTLOG(@"getLastLocationUpdate Date FromDB=%@",last);
	return last;
	
}

-(void)broadcastUpdate
{
	NSCondition* lock = [XLLocationMgr getCondUpdatedFirstTime];
	[lock lock];
	[lock broadcast];
	[lock unlock];
	XTLOG(@"XLLocationMgr: unlocked");
}

-(void)failWithError:(NSString*)errorMessage
{
	NSLog(@"%@",errorMessage);
	[self broadcastUpdate];
}

-(void)doOneUpdate:(NSTimer*)timer
{
	[newIntervalDate release];
	newIntervalDate = [[NSDate alloc ]initWithTimeIntervalSinceNow:0]; 
	NSTimeInterval secondsSinceIntervalStarts = [newIntervalDate timeIntervalSinceNow] *-1;

	XTLOG(@"STARING location service, secondsSinceIntervalStarts=%f",secondsSinceIntervalStarts);
	[m_coreLocationMan stopUpdatingLocation];
	[m_coreLocationMan startUpdatingLocation];
}

-(void)startUpdateForAppStartup
{
	self.timerForegroundUpdate = [NSTimer scheduledTimerWithTimeInterval:REGULAR_UPDATE_TIME_INTERVAL_SECONDS
									target:self selector:@selector(doOneUpdate:)userInfo:nil repeats:YES];
	
	NSDate* dateLastUpdate = [self getLastLocationUpdateDateFromDB];
	NSTimeInterval secondsSinceLastUpdate = [dateLastUpdate timeIntervalSinceNow] * -1.0;
	XTLOG(@"Last update was at %f seconds ago", secondsSinceLastUpdate);
	if (secondsSinceLastUpdate > REGULAR_UPDATE_TIME_INTERVAL_SECONDS)
	{
		XTLOG(@"Updating Location");
		[self setState:LMS_COORDINATES_NOT_SET];
		[self.timerForegroundUpdate fire];
	}
	else
	{
		XTLOG(@"Not Updating Location, secondsSinceLastUpdate=%f", secondsSinceLastUpdate);
	}
}

-(LM_STATES)getState
{
	return m_nState;
}

// private function
-(void)setState:(LM_STATES)state
{
	@synchronized(self)
	{
		m_nState = state;
	}
}

+(NSCondition*)getCondUpdatedFirstTime
{
	@synchronized(self)
	{
		if (nil == condUpdatedFirstTime)
		{
			XTLOG(@"XLLocationMgr: creating new condUpdatedFirstTime");
			condUpdatedFirstTime = [[NSCondition alloc] init];
		}
		
		return condUpdatedFirstTime;
	}
}

// BG Thread
- (void)updateToNet
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	BOOL success = NO;
	
	for (int i = 0; !success && i < RETRY_COUNT_MM_SERVER_LOC_UPDATE; ++i)
	{
		XTLOG(@"update server...");
	}
	
	if (success)
	{
		[self setState:LMS_COORDINATES_SUBMITTED];
		[self broadcastUpdate];
	}
	else
	{
		[self setState:LMS_COORDINATES_FAILED_TO_SUBMIT];
		[self failWithError:@"There was an error updating your location. Internet may be unavailable, or Location Setting is off."];
	}
	
	[pool release];
}
// Background (significant) and foreground entry point for location changes
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	@synchronized(self)
	{
		// update to server should not happen too often, but should give it up if accuracy is not achived after so many seconds
		NSDate* dateLastUpdate = [self getLastLocationUpdateDateFromDB];
		NSTimeInterval secondsSinceLastUpdate = [dateLastUpdate timeIntervalSinceNow] *-1;
		NSTimeInterval secondsSinceIntervalStarts = [newIntervalDate timeIntervalSinceNow] *-1;
		
		XTLOG(@"Location update; accuracy: %f, secondsSinceLastUpdate=%f, secondsSinceIntervalStarts: %f",
			  newLocation.horizontalAccuracy, secondsSinceLastUpdate,secondsSinceIntervalStarts);

		if (secondsSinceLastUpdate < LOCATION_UPDATE_FRESHNESS_THRESHOLD_SECONDS)
		{
			XTLOG(@"Stopping and Discarding location update. Already did an update %f seconds ago.",secondsSinceLastUpdate);
			[m_coreLocationMan stopUpdatingLocation];
            [m_coreLocationMan stopUpdatingHeading];
			[self setState:LMS_COORDINATES_NOT_SET];
			return;
		}
		
		if (TARGET_IPHONE_SIMULATOR) {
			[m_coreLocationMan stopUpdatingLocation];
			[self writeLastLocationUpdateDateToDB:[NSDate date]];
			m_currentCoordinate = newLocation.coordinate;
			[self updateLocationOnServer:newLocation ];
			return;		
		}
		
		if (secondsSinceIntervalStarts > TIME_INTERVAL_GIVE_UP ) {
			[m_coreLocationMan stopUpdatingLocation];
			[self writeLastLocationUpdateDateToDB:[NSDate date]];
			m_currentCoordinate = newLocation.coordinate;
			XTLOG(@"Stopping standard location updates because of TIME_INTERVAL_GIVE_UP: Coordinates set: lat:%f lon:%f", m_currentCoordinate.latitude, m_currentCoordinate.longitude);
			[self updateLocationOnServer:newLocation ];
		}
		else // met accuracy 
		{
				XTLOG(@"Stopping location update. Received desired location updates after secondsSinceIntervalStarts=%f.",secondsSinceIntervalStarts);
				// Turn off standard updates. Significant location updates will continue
				[m_coreLocationMan stopUpdatingLocation];
				[self writeLastLocationUpdateDateToDB:[NSDate date]];
				m_currentCoordinate = newLocation.coordinate;
				CLLocation *bestEffortAtLocation=newLocation;
				XTLOG(@"XLLocationMgr: Coordinates set: lat:%f lon:%f", m_currentCoordinate.latitude, m_currentCoordinate.longitude);
				[self updateLocationOnServer:bestEffortAtLocation ];
		}
      
//        [m_coreLocationMan stopMonitoringForRegion:<#(CLRegion *)#>
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	switch (error.code)
	{
		case kCLErrorLocationUnknown:
			// docs say that operation will continue. so do nothing.
			XTLOG(@"XLLocationMgr: kCLErrorLocationUnknown code:%i : %@. CL will try again.", error.code, [error localizedDescription]);
			break;
			
		case kCLErrorDenied:
			if (LMS_COORDINATES_DENIED != m_nState)
			{
				[self setState:LMS_COORDINATES_DENIED];
				[self failWithError:@"Is the Location Setting off?"];
			}
			break;
			
		case kCLErrorNetwork:
			XTLOG(@"XLLocationMgr: kCLErrorNetwork: code %i, description %@. Not doing anything.", error.code, [error localizedDescription]);
			break;
			
		default:
			XTLOG(@"XLLocationMgr: unhandled error: code: %i, description: %@. Not doing anything.", error.code, [error localizedDescription]);
			break;
	}
}
 
-(void)transitionToBackground
{
	XTLOG(@"XLLocationMgr: transitionToBackground");
	if ([[XLServerMgr get]runAlsoInBackground]) {
		NSLog(@"about to monitor significant location changes");

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	
		[m_coreLocationMan startMonitoringSignificantLocationChanges];
#endif
	}

	[m_coreLocationMan stopUpdatingLocation];
	[self.timerForegroundUpdate invalidate];
	self.timerForegroundUpdate = nil;
	[self broadcastUpdate];
}

-(void)transitionToForeground
{
	XTLOG(@"XLLocationMgr: transitionToForeground");
	if ([[XLServerMgr get]runAlsoInBackground]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		
		[m_coreLocationMan stopMonitoringSignificantLocationChanges];
#endif
	}
	[self startUpdateForAppStartup]; // send an update when app goes to foreground
}

-(void)dealloc
{
	XTLOG(@"XLLocationMgr: dealloc");
	self.m_coreLocationMan = nil;
	[self.timerForegroundUpdate invalidate];
	self.timerForegroundUpdate = nil;
	[super dealloc];
}


- (void)updateLocationOnServer:(CLLocation *)bestEffortAtLocation
{
	XTLOG(@"UPDATING server with cordinates=%@",bestEffortAtLocation);
	
    NSMutableDictionary *appDetailsDict = [[AppDetailsMgr get] getAppDetails];
    
    NSString *appKey =[appDetailsDict valueForKey:@"appKey"];
 
    NSString *xid = [appDetailsDict valueForKey:@"xid"];
    if (xid==nil) {
        NSLog(@"*** ERROR *** XID is not set. Not updateLocationOnServer");
		return;
    }
    
	NSString *urlString = [NSString stringWithFormat:@"%@/%@%@%@",xBaseUrl,xLocationUrl, xid, @"/update"];
	
	NSString* latString = [NSString stringWithFormat:@"%f", bestEffortAtLocation.coordinate.latitude];
	NSString* lonString = [NSString stringWithFormat:@"%f", bestEffortAtLocation.coordinate.longitude];
	NSString* altString = [NSString stringWithFormat:@"%f", bestEffortAtLocation.altitude];
	NSString* horzString = [NSString stringWithFormat:@"%f", bestEffortAtLocation.horizontalAccuracy];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];   
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *myDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *jsonString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
                            @"{ \"appKey\" : \"",appKey,@"\",",
                            @" \"lat\" : \"",latString,@"\",",
                            @" \"lng\" : \"",lonString,@"\",",
                            @" \"alt\" : \"",altString,@"\",",
                            @" \"accuracy\" : \"",horzString,@"\",",
                            @" \"ts\" : \"",myDate,@"\" }"];
	
	
	NSString *logX=[NSString stringWithFormat:@"Attempt to update location with url= %@ and json=%@",urlString,jsonString];
	XTLOG(@"==>%@",logX);
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	[request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	[request setTimeOutSeconds:30];
	[request setNumberOfTimesToRetryOnTimeout:2]; // Make requests retry of 2 times 
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successLocationMethod:)];
	[request setDidFailSelector: @selector(failureLocationMethod:)];
	[queue addOperation:request];
	
}	
- (void)successLocationMethod:(ASIHTTPRequest *) request 
{
	[self setState:LMS_COORDINATES_NOT_SET];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	int statusCode = [request responseStatusCode];
	NSString *responseString = [request responseString];//
    
	if (statusCode !=200 && statusCode !=204) {
		XTLOG(@"*** ERROR *** HTTP error in successLocationMethod statusCode=%d, response=%@",statusCode,responseString);
		return ; 
	}

	XTLOG(@"Got response from Location update=%@",[request responseString]);
	
}
- (void)failureLocationMethod:(ASIHTTPRequest *)request {
	
	[self setState:LMS_COORDINATES_FAILED_TO_SUBMIT];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	XTLOG(@"***ERROR***: location update failure. HTTPRequest request result: %@", error);
}

-(BOOL) isLocationSettingOff 
{
	return (m_nState==LMS_COORDINATES_DENIED);
}

@end
