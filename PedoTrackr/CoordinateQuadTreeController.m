//
//  CoordinateQuadTreeController.m
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import "CoordinateQuadTreeController.h"

BoundingBox BoundingBoxForMapRect(MKMapRect mapRect)
{
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    return BoundingBoxMake(minLat, minLon, maxLat, maxLon);
}

MKMapRect MapRectForBoundingBox(BoundingBox boundingBox)
{
    MKMapPoint topLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.x0, boundingBox.y0));
    MKMapPoint botRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.xf, boundingBox.yf));
    
    return MKMapRectMake(topLeft.x, botRight.y, fabs(botRight.x - topLeft.x), fabs(botRight.y - topLeft.y));
}

NSInteger ZoomScaleToZoomLevel(MKZoomScale scale)
{
    double totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));
    
    return zoomLevel;
}

float CellSizeForZoomScale(MKZoomScale zoomScale)
{
    NSInteger zoomLevel = ZoomScaleToZoomLevel(zoomScale);
    
    switch (zoomLevel) {
        case 13:
        case 14:
        case 15:
            return 64;
        case 16:
        case 17:
        case 18:
            return 32;
        case 19:
            return 16;
            
        default:
            return 88;
    }
}

QuadTreeNodeData DataFromMarker(NSDictionary *marker) {
    double lat = [[marker objectForKey:@"lt"] doubleValue];
    double lon = [[marker objectForKey:@"ln"] doubleValue];
    NSString* oidStr = [marker objectForKey:@"oid"];
    NSString* aidStr = [marker objectForKey:@"aid"];
    int c = [[marker objectForKey:@"c"] intValue];
    int mt = [[marker objectForKey:@"mt"] intValue];
    int at = [[marker objectForKey:@"at"] intValue];
    
    PedoInfo* pedoInfo = malloc(sizeof(PedoInfo));
    
    pedoInfo->oid = malloc(sizeof(char) * oidStr.length + 1);
    strncpy(pedoInfo->oid, [oidStr UTF8String], oidStr.length + 1);
    pedoInfo->aid = malloc(sizeof(char) * aidStr.length + 1);
    strncpy(pedoInfo->aid, [aidStr UTF8String], aidStr.length + 1);
    pedoInfo->c = c;
    pedoInfo->mt = mt;
    pedoInfo->at = at;
    
    return QuadTreeNodeDataMake(lat, lon, pedoInfo);
}

@implementation CoordinateQuadTreeController

-(void)buildTree {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource: @"pedoinfo"
                                             withExtension: @"json"];
        NSAssert(url!=nil, @"URL not found for target resource.");
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSAssert(data!=nil, @"Reading data file failed.");
        NSError *parseError = nil;
        NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
        NSAssert(parseError==nil, @"Parsing JSON object failed.");
        NSArray *markers = result[@"markers"];
        
        NSInteger count = markers.count - 1;
        
        QuadTreeNodeData* dataArray = malloc(sizeof(QuadTreeNodeData) * count);
        
        for (NSInteger i = 0; i < count; i++) {
            dataArray[i] = DataFromMarker(markers[i]);
        }
        
        BoundingBox world = BoundingBoxMake(19, -166, 72, -53);
        _root = QuadTreeBuildWithData(dataArray, (int)count, world, 4);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate quadTreeControllerDidLoadData];
        });
    });
}

- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect withZoomScale:(double)zoomScale {
    double cellSize = CellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / cellSize;
    NSInteger minX = floor(MKMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MKMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);
    
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSInteger x = minX; x <= maxX; x++) {
        for (NSInteger y = minY; y <= maxY; y++) {
            MKMapRect mapRect = MKMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int count = 0;
            
            __block PedoInfo* lastPedoInfo;
            
            QuadTreeGatherDataInRange(self.root, BoundingBoxForMapRect(mapRect), ^(QuadTreeNodeData data) {
                lastPedoInfo = (PedoInfo*)data.data;
                
                double dx = data.x;
                double dy = data.y;
                
                totalX += dx;
                totalY += dy;
                count++;
            });
            
            if (count == 1) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX, totalY);
                PedoAnnotation *annotation = [[PedoAnnotation alloc] initWithCoordinate:coordinate pedoInfo:lastPedoInfo];
                [clusteredAnnotations addObject:annotation];
            }
            
            if (count > 1) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                
                ClusteredPedoAnnotation *annotation = [[ClusteredPedoAnnotation alloc] initWithCoordinate:coordinate count:count  rect:rect];
                [clusteredAnnotations addObject:annotation];
            }
        }
    }
    return [NSArray arrayWithArray:clusteredAnnotations];
}

@end
