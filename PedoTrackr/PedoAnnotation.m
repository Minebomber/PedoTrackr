//
//  PedoAnnotation.m
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import "PedoAnnotation.h"

@implementation PedoAnnotation
{
//     PedoInfo* pedoInfo;
}
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate pedoInfo:(PedoInfo *)pedophileInfo {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _pedoInfo = pedophileInfo;
    }
    return self;
}

- (NSUInteger)hash {
    NSString *toHash = [NSString stringWithFormat:@"%.5F%.5F", self.coordinate.latitude, self.coordinate.longitude];
    return [toHash hash];
}

- (BOOL)isEqual:(id)object {
    return [self hash] == [object hash];
}

@end
