//
//  Renderer.h
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct Sprite {
    BOOL visible;
    float x;
    float y;
    int image;
    uint8_t colors[3];
} Sprite;

typedef struct SpriteDef {
    uint16_t data[8];
} SpriteDef;

extern int const RendererNumLayers;
extern int const RendererNumSprites;
extern int const RendererNumSpriteDefs;
extern int const RendererSpriteSize;


@interface Renderer : NSObject

@property (readonly) int size;
@property int colorIndex;
@property int layerIndex;

- (int)colorAtX:(int)x Y:(int)y;
- (void)clearWithColorIndex:(int)colorIndex;
- (void)plotX:(int)x Y:(int)y;
- (void)drawFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)drawBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY;
- (void)drawCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY;
- (void)fillCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY;
- (void)floodFillX:(int)x Y:(int)y;
- (void)drawText:(NSString *)text x:(int)x y:(int)y;
- (int)widthForText:(NSString *)text;
- (Sprite *)spriteAtIndex:(int)index;
- (SpriteDef *)spriteDefAtIndex:(int)index;
- (BOOL)checkCollisionBetweenSprite:(int)index1 andSprite:(int)index2;

- (uint32_t)screenColorAtX:(int)x Y:(int)y;

@end


@interface RendererPoint : NSObject
@property int x;
@property int y;
+ (RendererPoint *)pointWithX:(int)x Y:(int)y;
@end