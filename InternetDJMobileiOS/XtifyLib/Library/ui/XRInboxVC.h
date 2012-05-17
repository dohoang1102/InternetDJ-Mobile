//
//	InBoxViewController.h
//  XtifyRamp
//
//  Created by gilad on 6/13/10.
//  Copyright GiladM 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class XRDetailsVC ;
@class RichDbMessage;

@interface XRInboxVC : UITableViewController <UINavigationBarDelegate, NSFetchedResultsControllerDelegate>
{

	NSIndexPath  *selectedNotification; // the selected row/notification
	XRDetailsVC *detailsController;
	

    NSManagedObjectContext *managedObjectContext;	    

	NSFetchedResultsController *fetchedResultsController;
	int unreadMessages; //same as badges

}

+(XRInboxVC *) get;
- (NSString *)flattenHTML:(NSString *)html;
- (NSString *)iterateOverFectch ;
- (id) getDbMessageByMid:(NSString *)mid;
- (int) getInboxUnreadMessageCount ;
- (void ) setInboxUnreadMessageCount: (int) newCount;
- (BOOL) hasExpired:(NSDate*)myDate;

@property(nonatomic, retain) NSIndexPath *selectedNotification;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) XRDetailsVC *detailsController;
- (NSString *)applicationDocumentsDirectory;

@end

