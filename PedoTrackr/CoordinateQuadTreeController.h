//
//  CoordinateQuadTreeController.h
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QuadTree.h"
#import <MapKit/MapKit.h>
#import "PedoAnnotation.h"
#import "ClusteredPedoAnnotation.h"
#import "PedoInfo.h"
#import "CoordinateQuadTreeControllerDelegate.h"

@interface CoordinateQuadTreeController : NSObject

@property (nonatomic, weak) id <CoordinateQuadTreeControllerDelegate> delegate;

@property (assign, nonatomic) QuadTreeNode *root;
@property (strong, nonatomic) MKMapView *mapView;

float CellSizeForZoomScale(MKZoomScale zoomScale);
NSInteger ZoomScaleToZoomLevel(MKZoomScale scale);

- (void)buildTree;
- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect withZoomScale:(double)zoomScale;

@end
