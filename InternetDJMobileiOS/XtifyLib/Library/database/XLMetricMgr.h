//
//  XLMetricMgr.h
//  SampleRich
//
//  Created by Gilad on 4/21/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#import <CoreData/CoreData.h>



@interface XLMetricMgr : NSObject 
{
	NSManagedObjectContext *localObjectContext;	 

}

+(XLMetricMgr *) get;
-(void)insertMetricAction:(NSString *)action andValue:(NSString *)value andTimestamp:(NSString *)ts;
- (NSString *)getRecentActions ;
-(void)removeActions;
-(void)insertFailedStats;

@property (nonatomic, retain) NSManagedObjectContext *localObjectContext;
@property (nonatomic, assign) NSMutableDictionary *fetchedStats; 
@end

