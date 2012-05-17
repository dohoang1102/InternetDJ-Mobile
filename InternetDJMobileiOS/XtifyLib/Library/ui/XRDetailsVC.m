//XRDetailsVC.m Details View Controller
//  Created by Gilad on 3/1/11.
//  Copyright 2011 Xtify. All rights reserved.//

#import <QuartzCore/CAAnimation.h>
#import "XRDetailsVC.h"
#import "XLServerMgr.h"
#import "MapAnnotation.h"
#import "RichDbMessage.h"
#import "XLappMgr.h"
#import "XRInboxVC.h"
#import "XLutils.h"
#import "XLMetricMgr.h"

@implementation XRDetailsVC

@synthesize inboxToolbar;
@synthesize mainView;
@synthesize flipButton,mapButton,containerView,mapView,mapAnnotations;//,saveButton,deleteButton;
@synthesize actionType, actionData;
@synthesize dbMessage, richWebView,localMainView;

- (id)init  {
	if (self = [super init]) {
        
		self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}
// Create notification message. Called once when the view is constructed 
- (void)viewDidLoad 
{
	
	[super viewDidLoad];
	
	//	[self addToolbarItems];
	containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	containerView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.containerView];
	
	// The map view
	CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= 0;
    frame.size.width=320;// 
	frame.size.height -=53 ;//Adujsment for the title sizes, but not for toolbar as it's only for the main view
	
	mapView = [[MKMapView alloc]initWithFrame:frame];
	self.mapView.mapType = MKMapTypeStandard;   // also MKMapTypeSatellite or MKMapTypeHybrid
	
	// create out annotations array, one for current location and one for the message location
    self.mapAnnotations = [[NSMutableArray alloc] initWithCapacity:1];
	
	
    // add custom flip button as the nav bar's custom right view
	// create map button as the nav bar's custom right view for the flipped view (used later)
	mapButton = [[UIBarButtonItem alloc] initWithTitle:@"Map-It" style:UIBarButtonItemStyleDone
												target:self action:@selector(flipAction:)];
	
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	frame = infoButton.frame;
    frame.size.width = 40.0;
    infoButton.frame = frame;
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	
	//create the web view
	CGRect	rectFrame = [[UIScreen mainScreen] bounds];
	rectFrame.origin.y +=0; 
	rectFrame.size.height -=53;// leave section for the title and the toolbar (2x53)
	localMainView = [[[UIView alloc] initWithFrame:rectFrame] autorelease];
	
	//content
	richWebView = [[[UIWebView alloc] initWithFrame:CGRectMake(0,0, 320, 374)] autorelease];//480-106=374
	richWebView.backgroundColor = [UIColor whiteColor];
	richWebView.scalesPageToFit = NO; // otherwise small font for regular text
	richWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	[localMainView addSubview:richWebView];
	[self setMainView:localMainView];
	
}
// called every time when it comes to view
- (void)viewWillAppear:(BOOL)animated 
{
	NSLog(@"receive viewWillAppear in DetailViewController");
    [[XLMetricMgr get]insertMetricAction:xRichDisplay andValue:dbMessage.mid andTimestamp:nil];
	[super viewWillAppear:animated];
	[[XLappMgr get] finishHandleNotification];
	
	self.title =[dbMessage subject];
	if (![mainView superview])
	{
		[self.mapView removeFromSuperview];
		[containerView addSubview:mainView];
	}
    

    NSString *rnContent = dbMessage.content;
	if(rnContent == nil || [rnContent length] < 1)
	{
        rnContent = @" ";
	}

    
	if([[XRInboxVC get] hasExpired:[dbMessage expirationDate]])
    {
        // load the content HTML into a webview
        NSString *subjectAndContent=[self getHTMLContentsFromFile];
        [richWebView loadHTMLString:subjectAndContent baseURL:nil];
    }
    
    else
    {
        //title
        NSString *subjectWithTag=[NSString stringWithString:@""];// remove title [NSString stringWithFormat:@"<p><FONT style=\"FONT-SIZE:20pt\"><b>%@</b></FONT></p>",dbMessage.subject];
        // load the content HTML into a webview
        NSString *subjectAndContent=[subjectWithTag stringByAppendingString:rnContent];
        [richWebView loadHTMLString:subjectAndContent baseURL:nil];
	}	

	
	// add the action to the toolbar
	[self addToolbarItems:[dbMessage actionLabel]];	// set the tool bar with the proper label 
	
	//check if notification was triggered by time (and not location), don't display map button
	if ( [[dbMessage ruleLat] doubleValue] <.01 && [[dbMessage ruleLon] doubleValue]<.01 ) {
		self.navigationItem.rightBarButtonItem = nil; 
		
	} else {
		self.navigationItem.rightBarButtonItem = mapButton; // start with the map button
		
	}
	
	// prepare the map pin from the message location
	CLLocation *mLocation=[[[CLLocation alloc]initWithLatitude:[[dbMessage ruleLat]doubleValue]
													longitude:[[dbMessage ruleLon]doubleValue]]autorelease];
//	NSLog(@"mlocation=%@",mLocation);
	
	MapAnnotation *anAnnotation= [[MapAnnotation alloc]initWithCordinate:mLocation];
	
	[self.mapAnnotations insertObject:anAnnotation atIndex:0];
	[self.mapView addAnnotation:[self.mapAnnotations objectAtIndex:0]];
	[anAnnotation release];
	
	MKCoordinateRegion region = 
	MKCoordinateRegionMakeWithDistance(mLocation.coordinate, 3000, 3000);
	[self.mapView setRegion:region animated:YES];
	
	
	/*
	// if need to add the current user location 	
	CLLocation *lastLocation= nil;
	 if (lastLocation==nil) { //either where the usert is now or where the user triggers the notification
	 lastLocation=[[CLLocation alloc]initWithLatitude:[[dbMessage userLat]doubleValue]
	 longitude:[[dbMessage userLon]doubleValue]];
	 }
	 if (mLocation ==nil) {
	 mLocation=lastLocation;
	 }
	 
	 CLLocationDegrees latitudeDelta =(mLocation.coordinate.latitude >lastLocation.coordinate.latitude) ? 
	 mLocation.coordinate.latitude -lastLocation.coordinate.latitude : lastLocation.coordinate.latitude -mLocation.coordinate.latitude ;
	 CLLocationDegrees longitudeDelta=(mLocation.coordinate.longitude >lastLocation.coordinate.longitude)?
	 mLocation.coordinate.longitude-lastLocation.coordinate.longitude: lastLocation.coordinate.longitude -mLocation.coordinate.longitude;
	 MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta+.02f, longitudeDelta+.02f);
	 self.mapView.region = MKCoordinateRegionMake(lastLocation.coordinate, span);
	  */
	
}	
- (NSString *) getHTMLContentsFromFile{
    NSError* error = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource: xHTMLresource ofType: @"html"];
    NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
    return res;
}
// Dismisses the email composition interface when users tap Cancel or Send. 
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	// is there a different between cancel and send?
//	MFMailComposeResultCancelled	The user cancelled the operation. No email message was queued.
//	MFMailComposeResultSaved	The email message was saved in the user’s Drafts folder.
//	MFMailComposeResultSent	The email message was queued in the user’s outbox. It is ready to send the next time the user connects to email.
//	MFMailComposeResultFailed	The email message was not saved or queued, possibly due to an error.

	// update stats if result== MFMailComposeResultSent
	[self dismissModalViewControllerAnimated:YES];
}
-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[inboxToolbar removeFromSuperview ];
	[inboxToolbar release];
}

// create the toolbar with Label
- (void )addToolbarItems:(NSString *)actionLabel
{	
	inboxToolbar = [UIToolbar new];
	inboxToolbar.barStyle = UIBarStyleBlack;//UIBarStyleDefault;
	inboxToolbar.translucent=NO;
	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	// size up the toolbar and set its frame
	[inboxToolbar sizeToFit];
	CGFloat toolbarHeight = [inboxToolbar frame].size.height;
	CGRect mainViewBounds = self.view.bounds;
	CGRect temp=CGRectMake(CGRectGetMinX(mainViewBounds),
						   CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight * 2.0) + 2.0,
						   CGRectGetWidth(mainViewBounds),
						   toolbarHeight);
	
	temp.origin.y +=45;
	[inboxToolbar setFrame:temp];
	
	// create the system-defined "send-to" button
	UIBarButtonItem *sendtoItem = nil;
	BOOL canSend=[MFMailComposeViewController canSendMail];
	if (canSend) {
	    sendtoItem = [[UIBarButtonItem alloc]
					  initWithBarButtonSystemItem:UIBarButtonSystemItemAction
					  target:self action:@selector(sendMsgTo:)];
		sendtoItem.style = style;
	}		
	// setup action/phone button
	UIBarButtonItem *actionItem ;
	
	// flex item used to separate the left groups items and right grouped items
	UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			  target:nil
																			  action:nil];
	NSArray *itemsTemp=nil;
	if (actionLabel.length > 0 ) {
		actionItem = [[UIBarButtonItem alloc] initWithTitle:actionLabel style:UIBarButtonItemStyleDone
													 target:self action:@selector(actionButtonHandler:)];
		itemsTemp=[NSArray arrayWithObjects: flexItem ,actionItem,flexItem,nil];
		
		[actionItem release];
	}
	NSArray *itemsFinal=[NSArray arrayWithArray:itemsTemp];
	if (canSend) {
		NSArray *t=[NSArray arrayWithObjects: flexItem ,sendtoItem,flexItem,nil];
		if (itemsTemp) {
			itemsFinal=[itemsTemp arrayByAddingObjectsFromArray:t];
		} else {
			itemsFinal=[NSArray arrayWithArray:t];
		} 
	}
	if (itemsFinal) {
		[inboxToolbar setItems:itemsFinal animated:NO];
	}

	[mainView addSubview:inboxToolbar]; //- (void)removeFromSuperview
	[flexItem release];
	[sendtoItem release];
}	

- (void)dealloc {	
	[richWebView release];
	[actionType release];
	[actionButton release];
	[mapButton release];
	[flipButton release];
	[containerView release];
	[super dealloc];
}

#pragma mark flip
// called when the user presses the 'i' icon to change the app settings
- (void)flipViewAnimationDidStop:(CAAnimation *)theAnimation finished:(NSNumber *)finished context:(void *)context 
{
    NSLog(@"flipViewAnimationDidStop");
}
- (void)flipAction:(id)sender
{
	NSLog(@"flip");
	[UIView setAnimationDelegate:self];
 	[UIView setAnimationDidStopSelector:@selector(flipViewAnimationDidStop:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.75];
	
	[UIView setAnimationTransition:([self.mapView superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
                           forView:containerView cache:YES];

	if ([mainView superview])
	{
		[self.mainView removeFromSuperview];
		[containerView addSubview:self.mapView];
		[[XLMetricMgr get]insertMetricAction:xRichMap andValue:dbMessage.mid andTimestamp:nil];
	}
	else
	{
		[self.mainView removeFromSuperview];
		[containerView addSubview:mainView];
	}
	
	[UIView commitAnimations];
	
	// adjust the map/info buttons accordingly
	if ([mainView superview])
		self.navigationItem.rightBarButtonItem = mapButton;
	else
		self.navigationItem.rightBarButtonItem = flipButton;
}
#pragma mark MKMapViewDelegate
/*
 - (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
 {
 NSLog(@"viewForAnnotation=%@",annotation);
 }
 */
// Display only updates if Hold/Release button hasn't been pressed 
- (void)actionButtonHandler:(id)sender 
{
	NSString *actionT=[dbMessage actionType];
	NSLog(@"actionT=%@",actionT);
	if ( actionT.length == 0 ) {
		return;
	}
	[[XLMetricMgr get]insertMetricAction:xRichAction andValue:[dbMessage mid] andTimestamp:nil];
	
	if([dbMessage.actionType  caseInsensitiveCompare:@"NONE"]==NSOrderedSame) {
		NSLog(@"None is true...no Action button to begin with");
		return ;
	}
	
	UIAlertView *alertView=nil ;
	NSString *cancelButton=nil;
	NSString *otherButton=nil;
	
	if([dbMessage.actionType  caseInsensitiveCompare:@"PHN"]==NSOrderedSame) {
		cancelButton=[[NSString alloc]initWithString:@"Cancel" ];
		otherButton=[[NSString alloc]initWithString:@"Call"];
	}
	else if([dbMessage.actionType  caseInsensitiveCompare:@"WEB"]==NSOrderedSame) {
		cancelButton=[[NSString alloc]initWithString:@"Cancel" ];
		otherButton=[[NSString alloc]initWithString:@"Safari"];
	}
	///
	else if([dbMessage.actionType  caseInsensitiveCompare:@"CST"]==NSOrderedSame) {
		[[XLappMgr get] performDeveloperCustomAction:[dbMessage actionData]];
 	}
	//
	if (cancelButton !=nil) {
		alertView = [[UIAlertView alloc] initWithTitle:nil message:[dbMessage actionData] delegate:self 
									 cancelButtonTitle:cancelButton otherButtonTitles:otherButton, nil];
		[alertView show];
		[alertView	 release];		
		[cancelButton release];
	}
	if (otherButton !=nil) 			
		[otherButton release];

	
}

-(void)displaySentToComposerSheet 
{
	[[XLMetricMgr get]insertMetricAction:xRichShare andValue:[dbMessage mid] andTimestamp:nil];
	
	//[self displayComposerSheet:[dbMessage subject];
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	[picker setSubject:[dbMessage subject]];//subjectLabel.text];
	// Fill out the email body text
	NSString *emailBody =[dbMessage content] ;//substringToIndex:size]; 
	[picker setMessageBody:emailBody isHTML:YES];
	
	[self presentModalViewController:picker animated:YES];
	[picker release];
	
}


#pragma mark -
#pragma mark - UIAlertViewDelegate
//Called when the user click (and open) the notification message
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) { // user select open
		NSLog(@"User selects the action ");
		NSString *actionD=[dbMessage actionData];
		[[XLMetricMgr get]insertMetricAction:xRichAction andValue:[dbMessage mid] andTimestamp:nil];
		
		if([dbMessage.actionType  caseInsensitiveCompare:@"PHN"]==NSOrderedSame) {
			NSString *telUrl=[NSString stringWithFormat:@"tel:%@",actionD] ; 
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:telUrl]];
		}
		if([dbMessage.actionType  caseInsensitiveCompare:@"WEB"]==NSOrderedSame) {
			NSString *urlLink=[[[NSString alloc]initWithString:[dbMessage actionData]]autorelease];
			NSURL *url = [NSURL URLWithString:urlLink];
			[[UIApplication sharedApplication] openURL:url];
		}
	}
}
#pragma mark -
- (void)sendMsgTo:(id)sender {
	[self displaySentToComposerSheet];
//	NSLog(@"sendMsgTo button was pushed");
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSLog(@"Web load error=%@",error);
	
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+3 color='blue'>An error occurred:<br>%@<br>for url:%@<br></font></center></html>",
							 error.localizedDescription,[dbMessage actionData]];
	[webView loadHTMLString:errorString baseURL:nil];
}
@end
