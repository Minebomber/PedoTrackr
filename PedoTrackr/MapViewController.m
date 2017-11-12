//
//  MapViewController.m
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import "MapViewController.h"

double DeltaForScale(double scale) {
    NSLog(@"SCALE: %f", scale);
    if (scale <= 0.000008) {
        return 80.0;
    } else if (scale > 0.000008 && scale <= 0.000025) {
        return 20.0;
    } else if (scale > 0.000025 && scale <= 0.000101){
        return 5.0;
    } else if (scale > 0.000101 && scale <= 0.000168) {
        return 3.0;
    } else {
        return 1.0;
    }
}

@interface MapViewController ()
{
    CLGeocoder *geocoder;
}
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.quadTreeController = [[CoordinateQuadTreeController alloc] init];
    self.quadTreeController.delegate = self;
    self.quadTreeController.mapView = self.mapView;
    [self.quadTreeController buildTree];
    
    geocoder = [[CLGeocoder alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    if (self.mapView.annotations == nil) { return; }
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    
    if ([self.mapView userLocation]) {
        [before removeObject:[self.mapView userLocation]];
    }
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    }];
}

- (void)quadTreeControllerDidLoadData {
    [self updatePinsInMap];
}

- (void)updatePinsInMap {
    CGFloat boundsWidth = self.mapView.bounds.size.width;
    CGFloat visibleWidth = self.mapView.visibleMapRect.size.width;
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale =  boundsWidth / visibleWidth;
        NSArray *annotations = [self.quadTreeController clusteredAnnotationsWithinMapRect:_mapView.visibleMapRect withZoomScale:scale];
        
        [self updateMapViewAnnotationsWithAnnotations:annotations];
    }];
}

- (void)addBounceAnnimationToView:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    
    bounceAnimation.duration = 0.6;
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++) {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

#pragma mark - MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self updatePinsInMap];
    NSLog(@"DELTA LAT: %f", [self.mapView region].span.latitudeDelta);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *const reuseIdCluster = @"ClusterAnnotationView";
    static NSString *const reuseIdSingle = @"AnnotationView";
    
    if ([annotation isKindOfClass:[PedoAnnotation class]]) {
        // Single annotation
        MKAnnotationView *annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdSingle];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdSingle];
        }
        
        NSString* firstnamesString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"firstnames" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        
        NSArray* firstnames = [firstnamesString componentsSeparatedByString:@"\n"];
        
        NSString* lastnamesString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"lastnames" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        
        NSArray* lastnames = [lastnamesString componentsSeparatedByString:@"\n"];
        
        NSString *rndName = [NSString stringWithFormat:@"%@ %@", [firstnames objectAtIndex:arc4random() % [firstnames count]], [lastnames objectAtIndex:arc4random() % [lastnames count]]];
        
        PedoAnnotation *pedoAnnotation = (PedoAnnotation*)annotation;
        pedoAnnotation.title = rndName;
        
        char* cOid = pedoAnnotation.pedoInfo->oid;
        NSString* oid = [NSString stringWithUTF8String:cOid];
        
        NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        if ([oid rangeOfCharacterFromSet:cset].location == NSNotFound) {
            annotationView.image = [UIImage imageNamed:@"no-image-pedo"];
            
            [geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude] completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                
                NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
                if (error == nil && [placemarks count] > 0)
                {
                    CLPlacemark *placemark = [placemarks lastObject];
                    pedoAnnotation.subtitle = [NSString stringWithFormat:@"%@", placemark.name];
                }
            }];
            
        } else {
            annotationView.image = [UIImage imageNamed:@"pedo"];
            
            UIImageView* faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 200, 200)];
            
            NSString *imageUrl = [NSString stringWithFormat:@"https://awsphoto.familywatchdog.us/OffenderPhoto/OffenderPhoto.aspx?id=%@&width=200", oid];
            NSLog(@"%@", imageUrl);
            faceImageView.contentMode = UIViewContentModeScaleAspectFit;
            [faceImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
            
            annotationView.detailCalloutAccessoryView = faceImageView;
        }
        annotationView.canShowCallout = YES;
        
        return annotationView;
    } else if ([annotation isKindOfClass:[ClusteredPedoAnnotation class]]) {
        // Cluster annotation
        
        ClusteredPedoAnnotationView *annotationView = (ClusteredPedoAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdCluster];
        if (!annotationView) {
            annotationView = [[ClusteredPedoAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdCluster];
        }
        
        annotationView.canShowCallout = NO;
        annotationView.count = [(ClusteredPedoAnnotation *)annotation count];
        
        return annotationView;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[ClusteredPedoAnnotation class]]) {
        // zoom
        ClusteredPedoAnnotation *annotation = (ClusteredPedoAnnotation*)view.annotation;
        
        CLLocationCoordinate2D center = annotation.coordinate;
        
        CGFloat boundsWidth = self.mapView.bounds.size.width;
        CGFloat visibleWidth = self.mapView.visibleMapRect.size.width;
        double scale = boundsWidth / visibleWidth;
        double delta = DeltaForScale(scale);
        
        MKCoordinateSpan span = MKCoordinateSpanMake(delta, delta);
        [self.mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (UIView *view in views) {
        [self addBounceAnnimationToView:view];
    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
