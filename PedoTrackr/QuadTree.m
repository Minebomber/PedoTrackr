//
//  QuadTree.m
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import "QuadTree.h"

#pragma mark - Constructors

QuadTreeNodeData QuadTreeNodeDataMake(double x, double y, void* data)
{
    QuadTreeNodeData d; d.x = x; d.y = y; d.data = data;
    return d;
}

BoundingBox BoundingBoxMake(double x0, double y0, double xf, double yf)
{
    BoundingBox bb; bb.x0 = x0; bb.y0 = y0; bb.xf = xf; bb.yf = yf;
    return bb;
}

QuadTreeNode* QuadTreeNodeMake(BoundingBox boundary, int bucketCapacity)
{
    QuadTreeNode* node = malloc(sizeof(QuadTreeNode));
    node->northWest = NULL;
    node->northEast = NULL;
    node->southWest = NULL;
    node->southEast = NULL;
    
    node->boundingBox = boundary;
    node->bucketCapacity = bucketCapacity;
    node->count = 0;
    node->points = malloc(sizeof(QuadTreeNodeData) * bucketCapacity);
    
    return node;
}

#pragma mark - Bounding Box Functions

bool BoundingBoxContainsData(BoundingBox box, QuadTreeNodeData data)
{
    bool containsX = box.x0 <= data.x && data.x <= box.xf;
    bool containsY = box.y0 <= data.y && data.y <= box.yf;
    
    return containsX && containsY;
}

bool BoundingBoxIntersectsBoundingBox(BoundingBox b1, BoundingBox b2)
{
    return (b1.x0 <= b2.xf && b1.xf >= b2.x0 && b1.y0 <= b2.yf && b1.yf >= b2.y0);
}

#pragma mark - Quad Tree Functions

void QuadTreeNodeSubdivide(QuadTreeNode* node)
{
    BoundingBox box = node->boundingBox;
    
    double xMid = (box.xf + box.x0) / 2.0;
    double yMid = (box.yf + box.y0) / 2.0;
    
    BoundingBox northWest = BoundingBoxMake(box.x0, box.y0, xMid, yMid);
    node->northWest = QuadTreeNodeMake(northWest, node->bucketCapacity);
    
    BoundingBox northEast = BoundingBoxMake(xMid, box.y0, box.xf, yMid);
    node->northEast = QuadTreeNodeMake(northEast, node->bucketCapacity);
    
    BoundingBox southWest = BoundingBoxMake(box.x0, yMid, xMid, box.yf);
    node->southWest = QuadTreeNodeMake(southWest, node->bucketCapacity);
    
    BoundingBox southEast = BoundingBoxMake(xMid, yMid, box.xf, box.yf);
    node->southEast = QuadTreeNodeMake(southEast, node->bucketCapacity);
}

bool QuadTreeNodeInsertData(QuadTreeNode* node, QuadTreeNodeData data)
{
    if (!BoundingBoxContainsData(node->boundingBox, data)) {
        return false;
    }
    
    if (node->count < node->bucketCapacity) {
        node->points[node->count++] = data;
        return true;
    }
    
    if (node->northWest == NULL) {
        QuadTreeNodeSubdivide(node);
    }
    
    if (QuadTreeNodeInsertData(node->northWest, data)) return true;
    if (QuadTreeNodeInsertData(node->northEast, data)) return true;
    if (QuadTreeNodeInsertData(node->southWest, data)) return true;
    if (QuadTreeNodeInsertData(node->southEast, data)) return true;
    
    return false;
}

void QuadTreeGatherDataInRange(QuadTreeNode* node, BoundingBox range, DataReturnBlock block)
{
    if (!BoundingBoxIntersectsBoundingBox(node->boundingBox, range)) {
        return;
    }
    
    for (int i = 0; i < node->count; i++) {
        if (BoundingBoxContainsData(range, node->points[i])) {
            block(node->points[i]);
        }
    }
    
    if (node->northWest == NULL) {
        return;
    }
    
    QuadTreeGatherDataInRange(node->northWest, range, block);
    QuadTreeGatherDataInRange(node->northEast, range, block);
    QuadTreeGatherDataInRange(node->southWest, range, block);
    QuadTreeGatherDataInRange(node->southEast, range, block);
}

void QuadTreeTraverse(QuadTreeNode* node, QuadTreeTraverseBlock block)
{
    block(node);
    
    if (node->northWest == NULL) {
        return;
    }
    
    QuadTreeTraverse(node->northWest, block);
    QuadTreeTraverse(node->northEast, block);
    QuadTreeTraverse(node->southWest, block);
    QuadTreeTraverse(node->southEast, block);
}

QuadTreeNode* QuadTreeBuildWithData(QuadTreeNodeData *data, int count, BoundingBox boundingBox, int capacity)
{
    QuadTreeNode* root = QuadTreeNodeMake(boundingBox, capacity);
    for (int i = 0; i < count; i++) {
        QuadTreeNodeInsertData(root, data[i]);
    }
    
    return root;
}

void FreeQuadTreeNode(QuadTreeNode* node)
{
    if (node->northWest != NULL) FreeQuadTreeNode(node->northWest);
    if (node->northEast != NULL) FreeQuadTreeNode(node->northEast);
    if (node->southWest != NULL) FreeQuadTreeNode(node->southWest);
    if (node->southEast != NULL) FreeQuadTreeNode(node->southEast);
    
    for (int i=0; i < node->count; i++) {
        free(node->points[i].data);
    }
    free(node->points);
    free(node);
}
