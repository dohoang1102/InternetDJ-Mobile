//
//  XLRichJsonMessage.h
//  Json parser
//
//  Created by gilad on 1/25/12.
//  Copyright Xtify 2012. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface XLRichJsonMessage : NSObject  {

	NSString *ver,*mid, *subject, *content, *ruleLat, *ruleLon,*response,*date, *expirationDate;
	NSString *userLat, *userLon,*actionType,*actionData,*actionLabel;
	NSString *errorCode,*errorMessage; //in case of query error

}
//-(id)initWith

@property (nonatomic, retain) NSString *ver,*mid, *subject, *content, *ruleLat, *ruleLon,*response,*date, *expirationDate;
@property (nonatomic, retain) 	NSString *userLat, *userLon,*actionType,*actionData,*actionLabel;
@property (nonatomic, retain) 	NSString *errorCode,*errorMessage; 
@end
