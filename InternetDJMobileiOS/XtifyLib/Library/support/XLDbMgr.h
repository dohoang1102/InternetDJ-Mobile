//
//  XLDbMgr.h
//  SampleRich
//
//  Created by Gilad on 4/25/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface XLDbMgr : NSObject {
	NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

+(XLDbMgr*)getDBMgr;

-(id)init;
- (NSString *)applicationDocumentsDirectory ;
- (NSPersistentStoreCoordinator *)createNewDatabase ;
- (void) isMigrationNecessary:(NSPersistentStoreCoordinator *)psc URL:(NSURL *)sourceStoreURL ;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
