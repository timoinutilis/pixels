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
    int scaleX;
    int scaleY;
    int8_t colors[3];
    int screen;
} Sprite;

typedef struct SpriteDef {
    uint16_t data[8];
    uint8_t colors[3];
} SpriteDef;

typedef struct Screen {
    BOOL visible;
    int width;
    int height;
    int displayX;
    int displayY;
    int displayWidth;
    int displayHeight;
    int offsetX;
    int offsetY;
    int renderMode;
    uint8_t *pixelBuffer;
    int colorIndex;
    int bgColorIndex;
    int borderColorIndex;
    int fontIndex;
    int printY;
} Screen;

typedef struct Block {
    int width;
    int height;
    uint8_t *pixelBuffer;
} Block;

extern int const RendererMaxScreenSize;
extern int const RendererNumColors;
extern int const RendererNumScreens;
extern int const RendererNumSprites;
extern int const RendererNumSpriteDefs;
extern int const RendererSpriteSize;
extern int const RendererNumFonts;
extern int const RendererNumBlocks;


@interface Renderer : NSObject

@property (nonatomic) int displayMode;
@property (nonatomic, readonly) int displaySize;
@property (nonatomic) BOOL sharedPalette;
@property (nonatomic) int screenIndex;
@property (nonatomic, readonly) Screen *currentScreen;

- (Screen *)screenAtIndex:(int)index;
- (void)openScreen:(int)index width:(int)width height:(int)height renderMode:(int)renderMode;
- (void)closeScreen:(int)index;
- (void)initPalette;
- (int)colorAtIndex:(int)index;
- (void)setColor:(int)color atIndex:(int)index;
- (int)colorIndexAtX:(int)x Y:(int)y;
- (void)clearWithColorIndex:(int)colorIndex;
- (void)plotX:(int)x Y:(int)y;
- (void)drawFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)drawBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY refill:(BOOL)refill;
- (void)drawCircleX:(int)centerX Y:(int)centerY radius:(int)radius;
- (void)fillCircleX:(int)centerX Y:(int)centerY radius:(int)radius;
- (void)floodFillX:(int)x Y:(int)y;
- (void)getScreenFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)putScreenX:(int)x Y:(int)y srcX:(int)srcX srcY:(int)srcY srcWidth:(int)srcWidth srcHeight:(int)srcHeight transparency:(int)transparency;
- (void)getBlock:(int)index fromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)putBlock:(int)index X:(int)x Y:(int)y mask:(BOOL)mask;
- (void)freeBlock:(int)index;
- (void)freeAllBlocks;
- (void)drawText:(NSString *)text x:(int)x y:(int)y outline:(int)outline;
- (int)widthForText:(NSString *)text;
- (void)print:(NSString *)text;
- (Sprite *)spriteAtIndex:(int)index;
- (SpriteDef *)spriteDefAtIndex:(int)index;
- (BOOL)checkCollisionBetweenSprite:(int)index1 andSprite:(int)index2;
- (BOOL)checkCollisionBetweenSprite:(int)spriteIndex andScreen:(int)screenIndex;

- (uint32_t)screenColorAtX:(int)x Y:(int)y;

@end


@interface RendererPoint : NSObject
@property int x;
@property int y;
+ (RendererPoint *)pointWithX:(int)x Y:(int)y;
@end