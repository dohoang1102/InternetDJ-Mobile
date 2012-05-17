// 
//  RichDbMessage.m
//  XtifyLib
//
//  Created by Gilad on 3/21/11.
//  Copyright 2011 Xtify. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "RichDbMessage.h"
#import "XLRichJsonMessage.h"

@implementation RichDbMessage 

@dynamic subject;
@dynamic mid;
@dynamic actionLabel;
@dynamic userLon;
@dynamic ruleLon;
@dynamic read;
@dynamic actionData;
@dynamic actionType;
@dynamic userLat;
@dynamic aDate;
@dynamic ruleLat;
@dynamic content;
@dynamic expirationDate;

-(void) setFromJson:(XLRichJsonMessage *)xMessage 
{
	
	self.mid=xMessage.mid;
	self.subject=xMessage.subject;
	self.content=xMessage.content;
    
	self.userLon=[[[NSNumber alloc] initWithDouble:[xMessage.userLon doubleValue] ]autorelease];
	self.userLat=[[[NSNumber alloc] initWithDouble:[xMessage.userLat doubleValue] ]autorelease];
	self.ruleLon=[[[NSNumber alloc] initWithDouble:[xMessage.ruleLon doubleValue] ]autorelease];
	self.ruleLat=[[[NSNumber alloc] initWithDouble:[xMessage.ruleLat doubleValue] ]autorelease];
	self.actionData=xMessage.actionData;
	self.actionType=xMessage.actionType;
	self.actionLabel=xMessage.actionLabel;
	
	self.read=[[[NSNumber alloc]initWithBool:NO]autorelease]; //1-read , 0-not read
	
	//date
	NSDateFormatter *parseFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
	[parseFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:locale] autorelease]];
    
	[parseFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];//2011-03-29T15:57:02.680-04:00
	NSString *xDate = xMessage.date; // need to get rid of T and everything right of '.'
//    NSLog(@"current locale: %@, date=%@", locale,xDate);
	self.aDate= [parseFormatter dateFromString:xDate];

//	NSLog(@"date=%@",[self aDate]);
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *xExpDate = xMessage.expirationDate;
	self.expirationDate= [inputFormatter dateFromString:xExpDate];
//    NSLog(@"expdate=%@",[self expirationDate]);
	
}

-(void) updateMessage:(BOOL )value
{
	self.read=[[[NSNumber alloc]initWithBool:value]autorelease];
}

@end
