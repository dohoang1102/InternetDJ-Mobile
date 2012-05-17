//
//  XLLocationMgr.h
//  XtifyLib
//
//  Created by Gilad on 3/22/11.
//  Copyright 2011 Xtify. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum
{
	LMS_COORDINATES_NOT_SET,
	LMS_COORDINATES_DENIED,
	LMS_COORDINATES_SUBMITTED,
	LMS_COORDINATES_FAILED_TO_SUBMIT,
} LM_STATES;

@class ASIHTTPRequest;

@interface XLLocationMgr : NSObject <CLLocationManagerDelegate>
{
	LM_STATES m_nState;
	CLLocationManager* m_coreLocationMan;
	CLLocationCoordinate2D m_currentCoordinate;
	
	NSTimer* timerForegroundUpdate;
	NSDate* newIntervalDate; 
}

@property (nonatomic, retain) CLLocationManager* m_coreLocationMan;
@property (nonatomic, retain) NSTimer* timerForegroundUpdate;
@property (nonatomic, assign) CLLocationCoordinate2D m_currentCoordinate;

+(XLLocationMgr*)get;
-(LM_STATES)getState;
-(void)setState:(LM_STATES)state;
+(NSCondition*)getCondUpdatedFirstTime;
-(void)updateToNet;
-(void)doOneUpdate:(NSTimer*)timer;
-(void)startUpdateForAppStartup ;
-(void)transitionToBackground;
-(void)transitionToForeground;
- (void)successLocationMethod:(ASIHTTPRequest *) request ;
- (void)failureLocationMethod:(ASIHTTPRequest *)request ;
//server
- (void)updateLocationOnServer:(CLLocation *)bestEffortAtLocation;
-(BOOL) isLocationSettingOff ;// return true if 

@end
