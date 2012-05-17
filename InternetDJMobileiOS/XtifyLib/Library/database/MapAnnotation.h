/*
     File: MapAnnotation.h 
 //  Created by gilad on 6/13/10.
 //  Copyright Xtify 2010. All rights reserved.
 //
 */

#import <MapKit/MapKit.h>

@interface MapAnnotation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D theCoordinate;
}
- (id) initWithCordinate: (CLLocation *)location;
@property (nonatomic) CLLocationCoordinate2D theCoordinate;

@end