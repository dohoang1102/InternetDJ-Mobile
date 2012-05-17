//
//  RichDbMessage.h
//  XtifyLib
//
//  Created by Gilad on 3/21/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#import <CoreData/CoreData.h>

@class XLRichJsonMessage;

@interface RichDbMessage :  NSManagedObject  
{
}
-(void) setFromJson:(XLRichJsonMessage *)xMessage ;
-(void) updateMessage:(BOOL )value;

@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * mid;
@property (nonatomic, retain) NSString * actionLabel;
@property (nonatomic, retain) NSNumber * userLon;
@property (nonatomic, retain) NSNumber * ruleLon;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * actionData;
@property (nonatomic, retain) NSString * actionType;
@property (nonatomic, retain) NSNumber * userLat;
@property (nonatomic, retain) NSDate * aDate;
@property (nonatomic, retain) NSNumber * ruleLat;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * expirationDate;


@end



