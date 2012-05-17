//
//  XLDbMgr.m
//  SampleRich
//
//  Created by Gilad on 4/25/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#import "XLDbMgr.h"
#include "XLutils.h"

static XLDbMgr* mDbMgr = nil;

@implementation XLDbMgr
@synthesize managedObjectContext;

+(XLDbMgr *)getDBMgr
{
	if (nil == mDbMgr)
	{
		mDbMgr = [[XLDbMgr alloc] init];
		[mDbMgr managedObjectContext];// initilize the managedObjectContext
	}
	return mDbMgr;
}
- (id)init
{
	if (self = [super init ]) {
	}
	return self;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [NSManagedObjectContext new];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }

	NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"richnotification" ofType:@"mom"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:dbPath]];
  
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	return [self createNewDatabase];
}
- (NSPersistentStoreCoordinator *) createNewDatabase 
{
	NSError *error=nil;
	NSString *dbName = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:xDefaultDb];
	NSString *dbPath =[dbName stringByAppendingString:@".sqlite"];
	
    // Set up V2 store. 	 Remove v1 if exsits
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSURL *storeUrl = [NSURL fileURLWithPath:dbPath];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
   
    //For debugging. Prints the schema found
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl error:&error];
    
    if (!sourceMetadata)
    {
        XTLOG(@"New installation. SourceMetadata is nil");
    }
    else
    {
        XTLOG(@"SourceMetadata is %@", sourceMetadata);
    }

    // First attempt to open the store with no migraton options
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		XTLOG(@"Store new version, might need migration. error= %@",[error userInfo]);
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                        [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

        //Attempt to migrate
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
            XTLOG(@"*** ERROR auto migration failed: %@, %@", error, [error userInfo]);
            NSLog(@"Removing old (%@)database, starting a new one",dbPath);		
            BOOL success = [fileManager removeItemAtPath:dbPath error:&error];
            if (!success) {
                    NSLog(@"Error removing database %@. Error=%@",dbPath, [error localizedDescription]);
            }
            // last attempt to open the store
            if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
                XTLOG(@"*** ERROR error opening store= %@",[error userInfo]);
                return nil;
            }

        }
    }    
	
    return persistentStoreCoordinator;
}
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void) isMigrationNecessary:(NSPersistentStoreCoordinator *)psc URL:(NSURL *)sourceStoreURL
{
    NSString *sourceStoreType = nil; /* type for the source store, or nil if not known */ ;
    NSError *error = nil;
    
    NSDictionary *sourceMetadata =  [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:sourceStoreType
                                                               URL:sourceStoreURL
                                                             error:&error];
    
    if (sourceMetadata == nil) {
        XTLOG(@"deal with error");
        return ;
    }
    
    NSString *configuration = nil; /* name of configuration, or nil */ ;
    NSManagedObjectModel *destinationModel = [psc managedObjectModel];
    BOOL pscCompatibile = [destinationModel
                           isConfiguration:configuration
                           compatibleWithStoreMetadata:sourceMetadata];
    
    if (pscCompatibile) {
        XTLOG(@"No need to migrate");
        return ;
    }

    XTLOG(@"Deal with migration");

}
@end
