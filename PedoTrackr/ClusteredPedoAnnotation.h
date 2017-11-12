//
//  ClusteredPedoAnnotation.h
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ClusteredPedoAnnotation : NSObject<MKAnnotation>

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;
@property (assign, nonatomic) NSInteger count;
@property (assign, nonatomic) MKMapRect rect;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate count:(NSInteger)count rect:(MKMapRect)rect;

@end
