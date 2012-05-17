//
//  MetricDb.h
//  SampleRich
//
//  Created by Gilad on 4/21/11.
//  Copyright 2011 Xtify. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface MetricDb :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * action;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * timeStamp;
@property (nonatomic, retain) NSString * status;

@end



