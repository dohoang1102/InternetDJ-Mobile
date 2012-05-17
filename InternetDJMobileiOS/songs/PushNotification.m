//
//  PushNotification.m
//  XtifyPhoneGapPhase2
//
//  Created by Suchi on 3/1/12.
//  Copyright (c) 2012 Xtify.com. All rights reserved.
//

#import "PushNotification.h" 
#import "XLappMgr.h"
#import <CoreLocation/CoreLocation.h>
#import "XLLocationMgr.h"

@implementation PushNotification 

@synthesize callbackID;

-(void)print:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options  
{
    NSLog(@"Reached here");
    
    //The first argument in the arguments parameter is the callbackID.
    //We use this to send data back to the successCallback or failureCallback
    //through PluginResult.   
    self.callbackID = [arguments pop];
    
    //Get the string that javascript sent us 
    //NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];      
    NSDictionary *pushDic = [[XLappMgr get] lastPush];
    NSString *customData = [pushDic objectForKey:@"customKey"];
    
    //Create the Message that we wish to send to the Javascript
    NSString *stringToReturn;
    if (customData != nil)
        stringToReturn = customData;
    else
        stringToReturn = @"No data item called customKey";
    //Append the received string to the string we plan to send out        
    //[stringToReturn appendString: stringObtainedFromJavascript];
    //Create Plugin Result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:                        [stringToReturn stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //Checking if the string received is HelloWorld or not
    if(customData != nil)
    {
        //Call  the Success Javascript function
        [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackID]];
        
    }else
    {    
        //Call  the Failure Javascript function
        [self writeJavascript: [pluginResult toErrorCallbackString:self.callbackID]];
        
    }
    
}
-(void)printXid:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options  
{
    NSLog(@"Reached xid here");
    
    //The first argument in the arguments parameter is the callbackID.
    //We use this to send data back to the successCallback or failureCallback
    //through PluginResult.   
    self.callbackID = [arguments pop];
    
    //Get the string that javascript sent us 
    //NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];      
    
    NSString *xid = [[XLappMgr get] getXid];
    
    //Create the Message that we wish to send to the Javascript
    NSString *stringToReturn;
    if (xid != nil)
        stringToReturn = xid;
    else
        stringToReturn = @"No xid";
    //Append the received string to the string we plan to send out        
    //[stringToReturn appendString: stringObtainedFromJavascript];
    //Create Plugin Result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:                        [stringToReturn stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //Checking if the string received is HelloWorld or not
    if(xid != nil)
    {
        //Call  the Success Javascript function
        [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackID]];
        
    }else
    {    
        //Call  the Failure Javascript function
        [self writeJavascript: [pluginResult toErrorCallbackString:self.callbackID]];
        
    }
    
}


-(void)printLocation:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options  
{
    NSLog(@"Reached location here");
    
    //The first argument in the arguments parameter is the callbackID.
    //We use this to send data back to the successCallback or failureCallback
    //through PluginResult.   
    self.callbackID = [arguments pop];
    
    
    CLLocationCoordinate2D lastLnownLocation = [[XLLocationMgr get] m_currentCoordinate];
    
    NSString* latString = [NSString stringWithFormat:@"%f", lastLnownLocation.latitude];
	NSString* lonString = [NSString stringWithFormat:@"%f", lastLnownLocation.longitude];
    
    NSString *locationString;
    
    if(lastLnownLocation.latitude == 0 && lastLnownLocation.longitude == 0)
    {
        locationString = @"Nil";
    }
    else
    {
        locationString = [NSString stringWithFormat:@"%@%@%@%@" , @"Latitude:", latString, @",Longitude:" , lonString]; 
    }
    
        //Append the received string to the string we plan to send out        
    //[stringToReturn appendString: stringObtainedFromJavascript];
    //Create Plugin Result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:                        [locationString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //Checking if the string received is HelloWorld or not
    if(locationString != nil)
    {
        //Call  the Success Javascript function
        [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackID]];
        
    }else
    {    
        //Call  the Failure Javascript function
        [self writeJavascript: [pluginResult toErrorCallbackString:self.callbackID]];
        
    }
    
}



@end