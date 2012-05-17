//
//  AppDetail.h
//  SampleRich
//
//  Created by Gilad on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AppDetail : NSManagedObject

@property (nonatomic, retain) NSString * locale;
@property (nonatomic, retain) NSString * appKey;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * xid;

@end
