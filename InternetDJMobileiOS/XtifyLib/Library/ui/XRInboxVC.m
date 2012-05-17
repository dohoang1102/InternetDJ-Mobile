
//InboxViewController.m
//  Xtify
//
//  Created by gilad on 6/13/10.
//  Copyright GiladM 2010. All rights reserved.
//
#import <MediaPlayer/MPMoviePlayerController.h>

#import "XRInboxVC.h"
#import "XLappMgr.h"
#import "XRDetailsVC.h"
#import "RichDbMessage.h"
#import "XLutils.h"
#import "XLDbMgr.h"
#import "XLMetricMgr.h"
#import "NSString_HTML.h"

static XRInboxVC* mInboxVC = nil;

@implementation XRInboxVC

@synthesize selectedNotification;
@synthesize managedObjectContext, fetchedResultsController;
@synthesize detailsController;

#define ROW_HEIGHT 80

#define MAINLABEL_TAG	1
#define SECONDLABEL_TAG	2
#define DATE_TAG	4

+(XRInboxVC *)get
{
	if (nil == mInboxVC)
	{
		mInboxVC = [[XRInboxVC alloc] init];
	}
	return mInboxVC;
}
- (id)init
{
	if (self = [super initWithStyle:UITableViewStylePlain ]) {
		self.title = @"Inbox";
		self.navigationItem.title=@"Inbox";
        self.tableView.rowHeight = ROW_HEIGHT;
		
		
//		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

		NSError *error = nil;
		self.managedObjectContext =[[XLDbMgr getDBMgr] managedObjectContext];
		if (![[self fetchedResultsController] performFetch:&error]) {
			NSLog(@"*** ERROR *** Unresolved store error %@, %@", error, [error userInfo]);
			[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database
		}	
		else {
			// Configure the edit buttons.
			[self.editButtonItem setTitle:@"Delete"];
 			self.navigationItem.rightBarButtonItem = self.editButtonItem;
		}
        
	}
	return self;
}
#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
    NSInteger count = [[fetchedResultsController sections] count];
	if (count == 0) {
		count = 1;
	}
    return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSInteger numberOfRows = 0;
    if ([[fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    return numberOfRows;
}

//user read the message. update the db
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell

	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
}



// Override to support editing (deleting) in the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
							forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
		RichDbMessage *aMessage = (RichDbMessage *)[fetchedResultsController objectAtIndexPath:indexPath];
		BOOL readFlag=[aMessage.read boolValue];
		NSString *mid=[[NSString alloc ]initWithString:[aMessage mid]];
		// db is updated in this thread		
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		// Save the context.
		NSError *error;
		if (![context save:&error]) {
			NSLog(@"*** ERROR *** Unresolved error %@, %@", error, [error userInfo]);
			[[XLDbMgr getDBMgr]createNewDatabase];// recovery recreate the database
		}
		
		if (!readFlag) { //user deletes a messgage without reading it...update badge count.
			unreadMessages--;
			[[XLappMgr get] inboxChangedInternal:unreadMessages];
		}
		
		[[XLMetricMgr get]insertMetricAction:xRichDelete andValue:mid andTimestamp:nil];
	
	}   
}


#pragma mark -

-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
	NSLog(@"receive viewWillAppear in InBox-v-c");
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
	 [super setEditing:editing animated:animate];
	 if(editing) {
		 NSLog(@"editMode on");
		 [self.editButtonItem setTitle:@"Done"];
	 }
	else {
		NSLog(@"Done leave editmode");
		[self.editButtonItem setTitle:@"Delete"];
	}
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    // Set up the fetched results controller if needed.
    if (fetchedResultsController == nil) {
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Inbox" 
												  inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Edit the SORT key as appropriate. by date
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"aDate" ascending:NO];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = 
		[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
											managedObjectContext:managedObjectContext 
											  sectionNameKeyPath:nil cacheName:@"Root"];
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
        
        [aFetchedResultsController release];
        [fetchRequest release];
        [sortDescriptor release];
        [sortDescriptors release];
    }
	
	return fetchedResultsController;
}    


/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{

	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject 
							atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type 
							newIndexPath:(NSIndexPath *)newIndexPath 
{
//	NSLog(@"controller didChangeObject atIndexPath=%@",indexPath);

	UITableView *tableView = self.tableView;

	switch(type) {
		case NSFetchedResultsChangeInsert:
			//when a message arrived during push
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			unreadMessages++;
			[[XLappMgr get] inboxChangedInternal:unreadMessages];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			// when a message is opened it marked as read
			[self configureCell:(UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath] 
																		atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type 
{
	NSLog(@"controller didChangeSection sectionIndex=%@",sectionIndex);

	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	NSLog(@"controllerDidChangeContent");

	[self.tableView endUpdates];
}
// iterate over the token in the DB. Figure the total unread messages, and return a list of missing MIDs 
- (NSString *)iterateOverFectch
{
	NSString *missingMids=nil;
	unreadMessages=0;
	RichDbMessage *aMessage; 
	NSArray *fetchedArrayObjects =[fetchedResultsController fetchedObjects];
	for (int i=0; i<[fetchedArrayObjects count];i++) {
		aMessage= (RichDbMessage *)[fetchedArrayObjects objectAtIndex:(NSUInteger)i];
		// check if message was not completly retrieved yet
		if ([aMessage.subject length]==0) {
			NSLog(@"messag ID [%@] is null",aMessage.mid );
			if (missingMids==nil) {
				missingMids =[[NSString alloc]initWithString:aMessage.mid];
			}
			else {
				NSString *x=[NSString stringWithFormat:@",%@",aMessage.mid];
				missingMids =[missingMids stringByAppendingString:x];
			}

		}
		if (![aMessage.read boolValue]) {
			unreadMessages++;
		}
		
	}
	NSLog(@"Message count=%d, unreadMessages=%d",[fetchedArrayObjects count],unreadMessages);
	return missingMids;

//	[[XLappMgr get] inboxChangedInternal:unreadMessages];
}	
-(id) getDbMessageByMid:(NSString *)mid
{
	RichDbMessage *aMessage;
	NSArray *fetchedArrayObjects =[fetchedResultsController fetchedObjects];
	for (int i=0; i<[fetchedArrayObjects count];i++) {
		aMessage= (RichDbMessage *)[fetchedArrayObjects objectAtIndex:(NSUInteger)i];
		if ([[aMessage mid]isEqualToString:mid]) {
			return aMessage;
		}
	}
	return nil;
}

// called by delegate for each cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // A date formatter for the creation date.
    static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	}

 	UILabel *mainLabel, *secondLabel,*dateLabel;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XT"];
    
	if (cell == nil) { 
		
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"XT"] autorelease];
		
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		float x=5.0, y=3.0, dx=280.0;
		//main title
		mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x,y, dx, 22.0)] autorelease];
		mainLabel.tag = MAINLABEL_TAG;
		mainLabel.textAlignment = UITextAlignmentLeft;
		mainLabel.textColor = [UIColor blueColor];
		mainLabel.autoresizingMask = UIViewAutoresizingNone;
		[cell.contentView addSubview:mainLabel];
		y+=20;
		//content
		secondLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x,y,dx, 40.0)] autorelease];
		secondLabel.tag = SECONDLABEL_TAG;
		secondLabel.textAlignment = UITextAlignmentLeft;
		secondLabel.textColor = [UIColor blackColor];
		secondLabel.autoresizingMask = UIViewAutoresizingNone ;// | UIViewAutoresizingFlexibleHeight;
		secondLabel.lineBreakMode = UILineBreakModeClip;//UILineBreakModeWordWrap ;
		secondLabel.numberOfLines = 2; 
		[cell.contentView addSubview:secondLabel];
		//date
		dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(170, 62,100, 13)] autorelease];
		dateLabel.tag = DATE_TAG;
		dateLabel.textAlignment = UITextAlignmentRight;
		dateLabel.clipsToBounds = YES;

		dateLabel.textColor = [UIColor grayColor];
		dateLabel.autoresizingMask = UIViewAutoresizingNone;// | UIViewAutoresizingFlexibleHeight;
		[cell.contentView addSubview:dateLabel];
		
		
	} else {
		
		mainLabel = (UILabel *)[cell.contentView viewWithTag:MAINLABEL_TAG];
		secondLabel = (UILabel *)[cell.contentView viewWithTag:SECONDLABEL_TAG];
		dateLabel = (UILabel *)[cell.contentView viewWithTag:DATE_TAG];
	}
	
	// Configure the cell
	RichDbMessage *aDbMessage = (RichDbMessage *)[fetchedResultsController objectAtIndexPath:indexPath];
	
	mainLabel.text = [aDbMessage subject] ;//[aDict objectForKey:@"mainTitleKey"];
	
	if ([[aDbMessage read] boolValue]) {
		mainLabel.font = [UIFont systemFontOfSize:14.0]; //
		secondLabel.font = [UIFont systemFontOfSize:12.0];
		dateLabel.font = [UIFont systemFontOfSize:10.0];
        dateLabel.text=	[dateFormatter stringFromDate:[aDbMessage aDate]];
	} else {
		mainLabel.font = [UIFont fontWithName:@"TrebuchetMS-Bold" size:17];
		secondLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
		dateLabel.font = [UIFont systemFontOfSize:12.0];
        dateLabel.text=	[dateFormatter stringFromDate:[aDbMessage aDate]];
	}

    NSString *rnContent = [aDbMessage content];
    if(rnContent == nil || [rnContent length] < 1)
    {
        rnContent = xRNErrorMessage;
    }
	
	if ([self hasExpired:[aDbMessage expirationDate]]){
        //set gray color
        mainLabel.font = [UIFont systemFontOfSize:14.0]; //
		secondLabel.font = [UIFont systemFontOfSize:12.0];
		dateLabel.font = [UIFont systemFontOfSize:10.0];
        
        mainLabel.textColor = [UIColor grayColor];
        secondLabel.textColor = [UIColor grayColor];
        dateLabel.text=	@"Message expired";
    }
    else{
        mainLabel.textColor = [UIColor blueColor];
        
		secondLabel.textColor = [UIColor blackColor];
    }
    
	secondLabel.text = [self flattenHTML:[rnContent stringByDecodingHTMLEntities]];
	
	return cell;
}
- (BOOL) hasExpired:(NSDate*)myDate{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
    if(myDate == nil)
    {
        return false;
    }
    NSDate *now = [NSDate date];
    NSLog(@"Exp date is %@, Today is %@", [dateFormatter stringFromDate:myDate], [dateFormatter stringFromDate:now]);
    
    BOOL hasExp = !([now compare:myDate] == NSOrderedAscending);
    if(hasExp)
        NSLog(@"The notif HAS EXPIRED");
    else
        NSLog(@"The notif not exp");
    return hasExp;
}

// when user clicks on a notification, create the details controller, and push it to view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	RichDbMessage *aMessage = (RichDbMessage *)[fetchedResultsController objectAtIndexPath:indexPath];
 	if (![aMessage.read boolValue]) {
		[aMessage updateMessage:TRUE]; //message is updaged as read
		unreadMessages--;
		[[XLappMgr get] inboxChangedInternal:unreadMessages];
	}else {
		NSLog(@"message already read");
	}

    if(aMessage.content != nil || [aMessage.content length] > 0)
    {  
        if (detailsController==nil)	
            detailsController= [[XRDetailsVC alloc] init ];
	
        detailsController.dbMessage =aMessage  ;
        [[XLMetricMgr get]insertMetricAction:xRichDisplay andValue:aMessage.mid andTimestamp:nil];
        [self.navigationController pushViewController:detailsController animated:YES]; //will force call to viewDidLoad
    }
	[tableView  deselectRowAtIndexPath:indexPath  animated:YES]; 
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 75.0;
}

- (int) getInboxUnreadMessageCount 
{
	[self iterateOverFectch]; // need to update the current unread message count, without getting failed mid
	return unreadMessages;
}
- (void ) setInboxUnreadMessageCount: (int) newCount
{
	unreadMessages=newCount;
}
// trim the html tags and leading spaced to display in the inbox list
- (NSString *)flattenHTML:(NSString *)html 
{
	
    NSScanner *theScanner;
    NSString *text = nil;
	
    theScanner = [NSScanner scannerWithString:html];
	
    while ([theScanner isAtEnd] == NO) {
		
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ; 
		
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
		
        // replace the found tag with a space
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text]
											   withString:@""];
		
    } // while //
    
	NSString *trimmedString = [html stringByTrimmingCharactersInSet:
							   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedString;
	
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


- (void)dealloc {
//	[inboxParse release];
	[super dealloc];
}

@end
