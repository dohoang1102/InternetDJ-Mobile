//
//  XLInboxJsonParser.m
//  Xtify
//
//  Created by gilad on 26/1/12.
//  Copyright Xtify 2012. All rights reserved.
//
// 
#import <UIKit/UIKit.h> 
#import "XLInboxJsonParser.h"

#import "XLRichJsonMessage.h"
#import "SBJson.h"

@implementation XLInboxJsonParser

@synthesize inboxMessages;

- (id) init 
{
	if (self=[super init]) {
        inboxMessages = [[NSMutableArray alloc] init];
    }
	return self;
}
// Populate the inbox based on the response string. 
// Return true if success, false if no message is pending or if error 
- (BOOL) parseResponse:(NSString *)responseString
{
//    NSLog(@"%@",responseString);
	NSDictionary *responseDictionary = [responseString JSONValue];
    NSString *jsonVer=[responseDictionary valueForKeyPath:@"ver"];
    if (jsonVer == nil || (![jsonVer isEqualToString:RICH_VER] ) ) {
        NSLog(@"*** ERROR *** incompatable versions. Ecpecting ver[%@], while json version is [%@]",RICH_VER,jsonVer);
        return FALSE;
    }
    NSString *errorCode=[responseDictionary valueForKeyPath:@"errorCode"];
    if (errorCode !=nil ) { 
        NSLog(@"*** ERROR *** errorCode errorCode=%@",errorCode);
        return FALSE;
    }

	int n=0;

    if  ([responseDictionary valueForKeyPath:@"messages"] == [NSNull null] ) {
        return TRUE; //@"No pending messages");
    }
    NSMutableArray * aMessageArray =[responseDictionary valueForKeyPath:@"messages"];
        
    n=[aMessageArray count];
    for (int i=0;i<n; i++) {
        NSDictionary *aMsg=[aMessageArray objectAtIndex:i];
        NSLog(@"aMsg=%@",aMsg);
        XLRichJsonMessage *jsonMessage=[[XLRichJsonMessage alloc]init];
        jsonMessage.mid=[aMsg objectForKey:@"mid"];
        jsonMessage.subject=[aMsg objectForKey:@"subject"];
        jsonMessage.content=[aMsg objectForKey:@"content"];
        jsonMessage.ruleLat=[aMsg objectForKey:@"ruleLat"];
        jsonMessage.ruleLon=[aMsg objectForKey:@"ruleLon"];
        jsonMessage.date=[aMsg objectForKey:@"date"];
        jsonMessage.expirationDate=[aMsg objectForKey:@"expirationDate"];
        jsonMessage.userLat=[aMsg objectForKey:@"userLat"];
        jsonMessage.userLon=[aMsg objectForKey:@"userLon"];
        jsonMessage.actionType=[aMsg objectForKey:@"actionType"];
        jsonMessage.actionData=[aMsg objectForKey:@"actionData"];
        jsonMessage.actionLabel=[aMsg objectForKey:@"actionLabel"];
		[inboxMessages addObject:jsonMessage];
	}

    
    return true;

}

- (NSInteger ) getMessageCount {
	return [inboxMessages count];
}	
-(id) getMidMessage:(NSString *)mid 
{
	if ([inboxMessages count]==0) {
		return nil;
	}
	for (int i=0; i<[inboxMessages count]; i++) {
		if ([[[inboxMessages objectAtIndex:i]mid]isEqualToString:mid]) {
			return [inboxMessages objectAtIndex:i];
		}
	}
	return nil;
}
-(id)  getMessageAtIndex:(NSUInteger )indeX
{
	if ([inboxMessages count]>indeX) {
		return [inboxMessages objectAtIndex:indeX];
	}
	return nil;
	
}
- (void) dealloc 
{
    XLRichJsonMessage *aXMessage;
	//iterate over elements and releasee them
	if ([self getMessageCount]>0) {
		for (int i=0; i<[self getMessageCount]; i++) {
			aXMessage =[inboxMessages objectAtIndex:i];
			[aXMessage release];
		}
	}

	[inboxMessages release];
	[super dealloc];
}

@end
