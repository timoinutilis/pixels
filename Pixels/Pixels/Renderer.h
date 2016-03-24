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
    int8_t colors[3];
} Sprite;

typedef struct SpriteDef {
    uint16_t data[8];
    uint8_t colors[3];
} SpriteDef;

typedef struct Screen {
    int width;
    int height;
    int displayX;
    int displayY;
    int displayWidth;
    int displayHeight;
    int offsetX;
    int offsetY;
    int renderMode;
    uint32_t palette[16]; // RendererNumColors
    uint8_t *pixelBuffer;
} Screen;

extern int const RendererMaxScreenSize;
extern int const RendererNumColors;
extern int const RendererNumScreens;
extern int const RendererNumSprites;
extern int const RendererNumSpriteDefs;
extern int const RendererSpriteSize;


@interface Renderer : NSObject

@property (nonatomic) int displayMode;
@property (nonatomic, readonly) int displaySize;
@property (nonatomic) int colorIndex;
@property (nonatomic) int screenIndex;
@property (nonatomic, readonly) Screen *currentScreen;

- (Screen *)screenAtIndex:(int)index;
- (void)openScreen:(int)index width:(int)width height:(int)height renderMode:(int)renderMode;
- (void)closeScreen:(int)index;
- (void)initPalette;
- (int)paletteAtIndex:(int)index;
- (void)setPalette:(int)color atIndex:(int)index;
- (int)colorAtX:(int)x Y:(int)y;
- (void)clearWithColorIndex:(int)colorIndex;
- (void)plotX:(int)x Y:(int)y;
- (void)drawFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)drawBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY;
- (void)drawCircleX:(int)centerX Y:(int)centerY radius:(int)radius;
- (void)fillCircleX:(int)centerX Y:(int)centerY radius:(int)radius;
- (void)floodFillX:(int)x Y:(int)y;
- (void)getScreenFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)putScreenX:(int)x Y:(int)y srcX:(int)srcX srcY:(int)srcY srcWidth:(int)srcWidth srcHeight:(int)srcHeight transparency:(int)transparency;
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