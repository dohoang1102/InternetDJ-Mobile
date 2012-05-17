//
//  XLInboxJsonParser.h
//  Xtify
//
//  Created by gilad on 26/1/12.
//  Copyright Xtify 2012. All rights reserved.
//


#import <UIKit/UIKit.h>
#define RICH_VER @"2.0"

@class XLRichJsonMessage;

@interface XLInboxJsonParser : NSObject {
	
	NSMutableArray *inboxMessages; // array with all the inbox messages
}

- (NSInteger ) getMessageCount ;
- (BOOL) parseResponse:(NSString *)responseString;

-(id) getMessageAtIndex:(NSUInteger )index ;
-(id) getMidMessage:(NSString *)mid ;

@property (nonatomic, retain) NSMutableArray *inboxMessages;

@end
