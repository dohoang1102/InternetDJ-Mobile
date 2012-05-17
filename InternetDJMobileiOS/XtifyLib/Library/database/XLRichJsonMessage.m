//
//  XLRichJsonMessage.m
//  Json parser
//  Xtify
//  Created by gilad on 1/25/12.
//  Copyright Xtify 2012. All rights reserved.
//

#import "XLRichJsonMessage.h"

@implementation XLRichJsonMessage

@synthesize ver,mid, subject, content, ruleLat, ruleLon, userLat,userLon,actionType,actionData,actionLabel, expirationDate;
@synthesize response,date;
@synthesize errorCode,errorMessage ;

-(id)init
{
	if (self = [super init])
	{
		ver=[[NSString alloc]init];
		mid=[[NSString alloc]init];
		subject=[[NSString alloc]init];
		content=[[NSString alloc]init];
		ruleLat=[[NSString alloc]init];
		ruleLon=[[NSString alloc]init];
		userLat=[[NSString alloc]init];
		userLon=[[NSString alloc]init];
		actionType=[[NSString alloc]init];
		actionData=[[NSString alloc]init];
		actionLabel=[[NSString alloc]init];
		response=[[NSString alloc]init];
		date=[[NSString alloc]init];
		errorCode=[[NSString alloc]init];
		errorMessage=[[NSString alloc]init]; 
        expirationDate=[[NSString alloc]init];
	}
	return self;
}

	
- (NSString *) getRootElement
{
	return @"message-response";
}

- (NSString *) getSubElement
{
	return @"messages";
}
/*
// Current version supported
- (NSString *) getVersion; 
{
	return @"2.0";
}
*/
-(void )dealloc
{
	[ver release];
	[mid release];
	[subject release];
	[content release];
	[ruleLat release];
	[ruleLon release];
	[userLat release];
	[userLon release];
	[actionType release];
	[actionData release];
	[actionLabel release];
	[response release];
	[date release];
	[errorCode release];
	[errorMessage release]; 
    [expirationDate release];
	[super dealloc];
}	
@end
