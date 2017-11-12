//
//  QuadTree.h
//  PedoTrackr
//
//  Created by Hackathon on 11/11/17.
//  Copyright © 2017 Mark Lagae. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct QuadTreeNodeData {
    double x;
    double y;
    void* data;
} QuadTreeNodeData;
QuadTreeNodeData QuadTreeNodeDataMake(double x, double y, void* data);

typedef struct BoundingBox {
    double x0; double y0;
    double xf; double yf;
} BoundingBox;
BoundingBox BoundingBoxMake(double x0, double y0, double xf, double yf);

typedef struct quadTreeNode {
    struct quadTreeNode* northWest;
    struct quadTreeNode* northEast;
    struct quadTreeNode* southWest;
    struct quadTreeNode* southEast;
    BoundingBox boundingBox;
    int bucketCapacity;
    QuadTreeNodeData *points;
    int count;
} QuadTreeNode;
QuadTreeNode* QuadTreeNodeMake(BoundingBox boundary, int bucketCapacity);

void FreeQuadTreeNode(QuadTreeNode* node);

bool BoundingBoxContainsData(BoundingBox box, QuadTreeNodeData data);
bool BoundingBoxIntersectsBoundingBox(BoundingBox b1, BoundingBox b2);

typedef void(^QuadTreeTraverseBlock)(QuadTreeNode* currentNode);
void QuadTreeTraverse(QuadTreeNode* node, QuadTreeTraverseBlock block);

typedef void(^DataReturnBlock)(QuadTreeNodeData data);
void QuadTreeGatherDataInRange(QuadTreeNode* node, BoundingBox range, DataReturnBlock block);

bool QuadTreeNodeInsertData(QuadTreeNode* node, QuadTreeNodeData data);
QuadTreeNode* QuadTreeBuildWithData(QuadTreeNodeData *data, int count, BoundingBox boundingBox, int capacity);
