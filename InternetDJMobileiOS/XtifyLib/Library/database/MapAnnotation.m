/*
     File: MapAnnotation.m 
 //  Created by gilad on 6/13/10.
 //  Copyright Xtify 2010. All rights reserved.
 //
 
 */

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize theCoordinate;

- (id) initWithCordinate: (CLLocation *)location
{
	if (self=[super init]) {
		//theCoordinate =[[CLLocationCoordinate2D alloc]init];
		theCoordinate.latitude = location.coordinate.latitude;
		theCoordinate.longitude =location.coordinate.longitude;
	}
	return self;
}
- (CLLocationCoordinate2D)coordinate;
{
    return theCoordinate; 
}

- (void)dealloc
{
    [super dealloc];
}

@end