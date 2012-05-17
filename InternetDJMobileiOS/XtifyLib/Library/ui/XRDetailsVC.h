//	InBoxDetailViewController.h
//  XtifyRamp
//
//  Created by gilad on 6/13/10.
//  Copyright GiladM 2010. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import <MessageUI/MFMailComposeViewController.h>
@class RichDbMessage,CAAnimation;

@interface XRDetailsVC : UIViewController <MKMapViewDelegate,UIWebViewDelegate,MFMailComposeViewControllerDelegate> { 

	UIButton *actionButton;					
	UIBarButtonItem *mapButton,*flipButton;
	UIToolbar *inboxToolbar ;
	UIView *containerView; //Top most view. At any given time holds the mapView or the mainView
	MKMapView *mapView; // view for the map
	UIView *mainView; // Each new view (toolbar, title) are added to the main window.
	NSMutableArray *mapAnnotations;			
	NSString *actionType, *actionData;
	RichDbMessage	*dbMessage;
	UIWebView	*richWebView;
	UIView	*localMainView;
				
}

- (void) addToolbarItems:(NSString *)actionLabel;
-(void)displaySentToComposerSheet ;
- (void)flipAction:(id)sender;
- (void)sendMsgTo:(id)sender ;
- (void)actionButtonHandler:(id)sender ;
- (void)flipViewAnimationDidStop:(CAAnimation *)theAnimation finished:(NSNumber *)finished context:(void *)context ;
- (NSString *) getHTMLContentsFromFile;

@property (nonatomic, retain) UIView *mainView;
@property (nonatomic, retain) UIToolbar *inboxToolbar ;
@property (nonatomic, retain) UIBarButtonItem *mapButton, *flipButton; //, *saveButton,*deleteButton;
@property (nonatomic, retain) UIView *containerView ;//,*instructionsView;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSMutableArray *mapAnnotations;
@property (nonatomic, retain) NSString *actionType, *actionData;
@property (nonatomic, retain) RichDbMessage	*dbMessage;
@property (nonatomic, retain) UIWebView *richWebView;
@property (nonatomic, retain) UIView	*localMainView;

@end
