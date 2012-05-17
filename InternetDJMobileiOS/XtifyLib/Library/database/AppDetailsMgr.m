//
//  AppDetailsMgr.m
//  XtifyLib
//
//  Created by Sucharita Gaat on 11/2/11.
//  Copyright (c) 2011 Xtify. All rights reserved.
//

#import "AppDetailsMgr.h"

#include "AppDetail.h"
#import "XLDbMgr.h"
#include "XLutils.h"

static AppDetailsMgr* appDetailsMgr = nil;

@implementation AppDetailsMgr

@synthesize localObjectContext;

+(AppDetailsMgr *)get
{
	if (nil == appDetailsMgr)
	{
		appDetailsMgr = [[AppDetailsMgr alloc] init];
	}
	return appDetailsMgr;
}
- (id)init
{
	if (self = [super init ]) {
		self.localObjectContext =[[XLDbMgr getDBMgr] managedObjectContext];
	}
	return self;
}

//update actions in local storage to be later send to Xtify server
-(void)insertAppDetail:(NSString*)xid:(NSString *)locale:(NSString *)appKey andValue:(NSString *)country{
	// create a blank entity
	AppDetail *aDbMessage = (AppDetail *)[NSEntityDescription 
                                        insertNewObjectForEntityForName:@"AppDetail" 
										inManagedObjectContext:localObjectContext];
	
    aDbMessage.country = country;
	aDbMessage.locale=locale;
    aDbMessage.xid = xid;
    aDbMessage.appKey = appKey;
	
	NSError *error;
	if (![localObjectContext save:&error]) { // Commit the change.
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"*** ERROR Getting database error. Error: %@",[error userInfo]);
		}
	}
    NSLog(@"Added AppDetail record=%@ to AppDetails entity",aDbMessage);
	
}	


- (NSMutableDictionary *)getAppDetails 
{
    NSMutableDictionary *appDict = [NSMutableDictionary new];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init]autorelease];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AppDetail" 
											  inManagedObjectContext:localObjectContext];
	if (entity==nil) {
        XTLOG(@"*** ERROR Data store AppDetail error entity=%@", entity);
        return nil;
    }
    [fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedArrayObjects = [localObjectContext executeFetchRequest:fetchRequest error:&error];
	
	if (fetchedArrayObjects ==nil) {
//		XTLOG(@"Error %@, %@", error, [error userInfo]);
		return nil;
	}	
	if ([fetchedArrayObjects count]==0) {
		return nil; //App Details was not created yet");
	}	
	
	AppDetail *aMessage; 
    
	for (int i=0; i<[fetchedArrayObjects count];i++) 
	{
		aMessage= (AppDetail *)[fetchedArrayObjects objectAtIndex:(NSUInteger)i];
        [appDict setValue:[aMessage xid] forKey:@"xid"];
        [appDict setValue:[aMessage country] forKey:@"country"];
        [appDict setValue:[aMessage locale] forKey:@"locale"];
        [appDict setValue:[aMessage appKey] forKey:@"appKey"];    
    }
	return appDict;
}	

-(void)removeAppDetails
{
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init]autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AppDetail" 
											  inManagedObjectContext:localObjectContext];
	if (entity==nil) {
        XTLOG(@"*** ERROR Data store empty for AppDetail. entity=%@", entity);
        return ;
    }
    [fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedArrayObjects = [localObjectContext executeFetchRequest:fetchRequest error:&error];
	
	if (fetchedArrayObjects ==nil) {
		return;
	}	
	if ([fetchedArrayObjects count]==0) {
		return; // nothing to remove
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
