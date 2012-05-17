//
//  AppDetailsMgr.h
//  XtifyLib
//
//  Created by Sucharita Gaat on 11/2/11.
//  Copyright (c) 2011 Xtify. All rights reserved.
//

#import <CoreData/CoreData.h>



@interface AppDetailsMgr : NSObject 
{
	NSManagedObjectContext *localObjectContext;	 
    
}

+(AppDetailsMgr *) get;
-(void)insertAppDetail:(NSString*)xid:(NSString *)locale:(NSString *)appKey andValue:(NSString *)country;
- (NSMutableDictionary *)getAppDetails ;
-(void)removeAppDetails;

@property (nonatomic, retain) NSManagedObjectContext *localObjectContext;
@end

