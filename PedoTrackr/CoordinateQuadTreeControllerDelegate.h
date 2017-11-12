//
//  CoordinateQuadTreeControllerDelegate.h
//  PedoTrackr
//
//  Created by Mark Lagae on 11/12/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CoordinateQuadTreeControllerDelegate <NSObject>
@optional
- (void)quadTreeControllerDidLoadData;
@end
