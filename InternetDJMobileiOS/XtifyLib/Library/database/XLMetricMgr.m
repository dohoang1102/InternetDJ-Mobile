//
//  XLMetricMgr.h
//  SampleRich
//
//  Created by Gilad on 4/21/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#include "XLMetricMgr.h"
#include "MetricDb.h"
#import "XLDbMgr.h"
#include "XLutils.h"

static XLMetricMgr* mMetricMgr = nil;

@implementation XLMetricMgr

@synthesize localObjectContext, fetchedStats;

+(XLMetricMgr *)get
{
	if (nil == mMetricMgr)
	{
		mMetricMgr = [[XLMetricMgr alloc] init];
	}
	return mMetricMgr;
}
- (id)init
{
	if (self = [super init ]) {
		self.localObjectContext =[[XLDbMgr getDBMgr] managedObjectContext];
	}
	return self;
}

//update actions in local storage to be later send to Xtify server
-(void)insertMetricAction:(NSString *)action andValue:(NSString *)value andTimestamp:(NSString *)ts
{
    if(action == nil)
    {
        return;
    }
	// create a blank entity
	MetricDb *aDbMessage = (MetricDb *)[NSEntityDescription 
										insertNewObjectForEntityForName:@"Metric" 
										inManagedObjectContext:localObjectContext];
	
	aDbMessage.action=action;
	aDbMessage.value=value;
    if(ts == nil)
    {
		double timeInMilliSec=[[NSDate date] timeIntervalSince1970]*1000;
		NSString* timeStamp = [NSString stringWithFormat:@"%.0f" ,timeInMilliSec];
		aDbMessage.timeStamp=timeStamp;
    }
    else
        aDbMessage.timeStamp=ts;
	
	NSError *error;
	if (![localObjectContext save:&error]) { // Commit the change.
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"***Getting database error. Will recreate a new one. Error: %@",[error userInfo]);
		}
		[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database
	}
//	NSLog(@"added record=%@ to Metric entity",aDbMessage);
	
}


/*
 Return the actions in the local storage that need to be sent to the server in json format
 event:, action: value: timeStamp: 
 Return nil if there are no actions 
 */
- (NSString *)getRecentActions
{
	
	NSString *recentActions=[[[NSString alloc]initWithString:@""]autorelease];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init]autorelease];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Metric" 
											  inManagedObjectContext:localObjectContext];
    fetchedStats = [NSMutableDictionary new];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedArrayObjects = [localObjectContext executeFetchRequest:fetchRequest error:&error];
	
	if (fetchedArrayObjects ==nil) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		return recentActions;
	}	
	if ([fetchedArrayObjects count]==0) {
		//XTLOG(@"No Actions to remove");
		return recentActions;
	}	
	
	MetricDb *aMessage; 
	NSString *value;
	XTLOG(@"Send actions to server");
    int n =[fetchedArrayObjects count];
	for (int i=0; i<n;i++) 
	{
        
		aMessage= (MetricDb *)[fetchedArrayObjects objectAtIndex:(NSUInteger)i];
        NSMutableArray *actionValue = [NSMutableArray new];
        [actionValue addObject:[aMessage action]];
        if ([aMessage value] && [[aMessage value]length]>0) {
			[actionValue addObject:[aMessage value]];
        }
        [fetchedStats setValue:actionValue forKey:[aMessage timeStamp]];
		//			NSLog(@"action=%@ value=%@, date=%@",[aMessage action],[aMessage value],[aMessage timeStamp]);
		if ([aMessage value] && [[aMessage value]length]>0) {
		  value=[NSString stringWithFormat:@"%@",[aMessage value]];
		} else {
			value=@"";
		}
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];   
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        //XTLOG(@"ts=%@", [aMessage timeStamp]);        
        double timeInMilliSec= [[aMessage timeStamp] doubleValue]/1000; 
        NSString *isoDate = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeInMilliSec]];
        XTLOG(@"Date is %@", isoDate);

        
        NSString *jsonX=[NSString stringWithFormat:
                              @" { \"action\" : \"%@\", \"value\": \"%@\" , \"timeStamp\" : \"%@\" } ", [aMessage action],value,isoDate];
        
        if ((i+1) <n ) {
            jsonX =[jsonX stringByAppendingString:@","];            
        }
		recentActions =[recentActions stringByAppendingString:jsonX];
        XTLOG(@"recentActions=%@",recentActions);
    }
    [self removeActions];
    
	return recentActions;
}	

-(void)insertFailedStats{
    for (NSString *key in fetchedStats) {
        NSArray *actionVal = [fetchedStats objectForKey:key];
        if([actionVal count] > 1){
            NSLog(@"%@ %@ %@",key,[actionVal objectAtIndex:0],[actionVal objectAtIndex:1]);
            [self insertMetricAction:[actionVal objectAtIndex:0] andValue:[actionVal objectAtIndex:1] andTimestamp:key];
        }
        else{
            NSLog(@"%@ %@ %@",key,[actionVal objectAtIndex:0],nil);
            [self insertMetricAction:[actionVal objectAtIndex:0] andValue:nil andTimestamp:key];
        }
    }
}
-(void)removeActions
{
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init]autorelease];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Metric" 
											  inManagedObjectContext:localObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedArrayObjects = [localObjectContext executeFetchRequest:fetchRequest error:&error];
	
	if (fetchedArrayObjects ==nil) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		return;
	}	
	if ([fetchedArrayObjects count]==0) {
		//XTLOG(@"No Actions to remove");
		return;
	}	
	
	for (int i=0; i<[fetchedArrayObjects count];i++) 
	{
		[localObjectContext deleteObject:
		 [fetchedArrayObjects objectAtIndex:(NSUInteger)i]];
	}
	// Save the context.
	
	if (![localObjectContext save:&error]) {
		XTLOG(@"Unresolved store error %@, %@", error, [error userInfo]);
		[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database
	}
	
}	
@end