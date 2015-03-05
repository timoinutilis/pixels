//
//  Renderer.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Renderer.h"

int const RendererSize = 64;
int const RendererNumSprites = 16;
int const RendererNumSpriteDefs = 64;
int const RendererSpriteSize = 8;

uint32_t const ColorPalette[16] = {0x000000, 0xffffff, 0xaaaaaa, 0x555555, 0xff0000, 0x550000, 0xaa5500, 0xffaa00, 0xffff00, 0x00aa00, 0x005500, 0x00aaff, 0x0000ff, 0x0000aa, 0xff00ff, 0xaa00aa};

uint8_t FontData[256] = {
    0x17, 0x0, 0x3, 0x0, 0x3, 0x0, 0xA, 0x1F, 0xA, 0x1F, 0xA, 0x0, 0x12, 0x15, 0x1F, 0x15, 0x9, 0x0, 0x19, 0x4, 0x13, 0x0, 0x1A, 0x15, 0x12, 0x8, 0x0, 0x3, 0x0, 0xE, 0x11, 0x0, 0x11, 0xE, 0x0, 0x15, 0xE, 0xE, 0x15, 0x0, 0x4, 0xE, 0x4, 0x0, 0x18, 0x0, 0x4, 0x4, 0x4, 0x0, 0x10, 0x0, 0x18, 0x4, 0x3, 0x0, 0x1F, 0x11, 0x1F, 0x0, 0x12, 0x1F, 0x10, 0x0, 0x1D, 0x15, 0x17, 0x0, 0x15, 0x15, 0x1F, 0x0, 0x7, 0x4, 0x1F, 0x0, 0x17, 0x15, 0x1D, 0x0, 0x1F, 0x15, 0x1D, 0x0, 0x1, 0x1, 0x1F, 0x0, 0x1F, 0x15, 0x1F, 0x0, 0x17, 0x15, 0x1F, 0x0, 0xA, 0x0, 0x1A, 0x0, 0x4, 0xA, 0x11, 0x0, 0xA, 0xA, 0xA, 0x0, 0x11, 0xA, 0x4, 0x0, 0x1, 0x15, 0x2, 0x0, 0xE, 0x11, 0x17, 0x6, 0x0, 0x1E, 0x5, 0x1E, 0x0, 0x1F, 0x15, 0xA, 0x0, 0xE, 0x11, 0x11, 0x0, 0x1F, 0x11, 0xE, 0x0, 0x1F, 0x15, 0x11, 0x0, 0x1F, 0x5, 0x1, 0x0, 0xE, 0x11, 0x1D, 0x0, 0x1F, 0x4, 0x1F, 0x0, 0x1F, 0x0, 0x11, 0x11, 0xF, 0x0, 0x1F, 0x4, 0x1B, 0x0, 0x1F, 0x10, 0x10, 0x0, 0x1F, 0x2, 0x4, 0x2, 0x1F, 0x0, 0x1F, 0x2, 0x4, 0x1F, 0x0, 0xE, 0x11, 0xE, 0x0, 0x1F, 0x5, 0x2, 0x0, 0xE, 0x11, 0x1E, 0x0, 0x1F, 0x5, 0x1A, 0x0, 0x12, 0x15, 0x9, 0x0, 0x1, 0x1F, 0x1, 0x0, 0xF, 0x10, 0x10, 0xF, 0x0, 0x7, 0x8, 0x10, 0xF, 0x0, 0x1F, 0x8, 0x4, 0x8, 0x1F, 0x0, 0x1B, 0x4, 0x1B, 0x0, 0x3, 0x1C, 0x3, 0x0, 0x19, 0x15, 0x13, 0x0
};
uint8_t FontX[256] = {0, 2, 6, 12, 18, 22, 27, 29, 32, 35, 40, 44, 46, 50, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 98, 100, 104, 108, 112, 116, 121, 125, 129, 133, 137, 141, 145, 149, 153, 155, 159, 163, 167, 173, 178, 182, 186, 190, 194, 198, 202, 207, 212, 218, 222, 226};
uint8_t FontWidth[256] = {2, 4, 6, 6, 4, 5, 2, 3, 3, 5, 4, 2, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 2, 4, 4, 4, 6, 5, 4, 4, 4, 4, 4, 4, 5, 5, 6, 4, 4, 4};


@implementation Renderer {
    uint8_t _pixelBuffer[RendererSize][RendererSize];
    Sprite _sprites[RendererNumSprites];
    SpriteDef _spriteDefs[RendererNumSpriteDefs];
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.colorIndex = 1;
        [self clearWithColorIndex:0];
        
        for (int i = 0; i < RendererNumSprites; i++)
        {
            Sprite *sprite = &_sprites[i];
            sprite->colors[0] = 1;
            sprite->colors[1] = 2;
            sprite->colors[2] = 3;
        }
    }
    return self;
}

- (int)size
{
    return RendererSize;
}

- (int)colorAtX:(int)x Y:(int)y
{
    if (x >= 0 && x < RendererSize && y >= 0 && y < RendererSize)
    {
        return _pixelBuffer[y][x];
    }
    return -1;
}

- (void)clearWithColorIndex:(int)colorIndex
{
    for (int y = 0; y < RendererSize; y++)
    {
        for (int x = 0; x < RendererSize; x++)
        {
            _pixelBuffer[y][x] = colorIndex;
        }
    }
}

- (void)plotX:(int)x Y:(int)y
{
    if (x >= 0 && y >= 0 && x < RendererSize && y < RendererSize)
    {
        _pixelBuffer[y][x] = _colorIndex;
    }
}

- (void)drawFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    int diffX = toX - fromX;
    int diffY = toY - fromY;
    if (ABS(diffX) >= ABS(diffY))
    {
        if (toX < fromX)
        {
            int value = toX; toX = fromX; fromX = value;
            value = toY; toY = fromY; fromY = value;
            
            diffX *= -1;
            diffY *= -1;
        }
        
        for (int i = 0; i <= diffX; i++)
        {
            int x = fromX + i;
            int y = (diffX != 0) ? fromY + roundf(diffY * i / (float)diffX) : fromY;
            [self plotX:x Y:y];
        }
    }
    else
    {
        if (toY < fromY)
        {
            int value = toX; toX = fromX; fromX = value;
            value = toY; toY = fromY; fromY = value;
            
            diffX *= -1;
            diffY *= -1;
        }
        
        for (int i = 0; i <= diffY; i++)
        {
            int x = (diffY != 0) ? fromX + roundf(diffX * i / (float)diffY) : fromX;
            int y = fromY + i;
            [self plotX:x Y:y];
        }
    }
}

- (void)drawBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    for (int x = fromX; x <= toX; x++)
    {
        [self plotX:x Y:fromY];
        [self plotX:x Y:toY];
    }
    for (int y = fromY; y <= toY; y++)
    {
        [self plotX:fromX Y:y];
        [self plotX:toX Y:y];
    }
}

- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    if (fromX < RendererSize && fromY < RendererSize && toX >= 0 && toY >= 0)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= RendererSize) toX = RendererSize - 1;
        if (toY >= RendererSize) toY = RendererSize - 1;
        
        for (int y = fromY; y <= toY; y++)
        {
            for (int x = fromX; x <= toX; x++)
            {
                _pixelBuffer[y][x] = _colorIndex;
            }
        }
    }
}

- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY
{
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    if (fromX < RendererSize && fromY < RendererSize && toX >= 0 && toY >= 0)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= RendererSize) toX = RendererSize - 1;
        if (toY >= RendererSize) toY = RendererSize - 1;
        
        int width = toX - fromX + 1;
        int height = toY - fromY + 1;
        
        for (int oy = 0; oy < height; oy++)
        {
            for (int ox = 0; ox < width; ox++)
            {
                int x = (deltaX > 0) ? toX - ox : fromX + ox;
                int y = (deltaY > 0) ? toY - oy : fromY + oy;
                int getX = MAX(fromX, MIN(toX, x - deltaX));
                int getY = MAX(fromY, MIN(toY, y - deltaY));
                _pixelBuffer[y][x] = _pixelBuffer[getY][getX];
            }
        }
    }
}

- (void)drawCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY
{
    
}

- (void)fillCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY
{
    
}

- (void)drawText:(NSString *)text x:(int)x y:(int)y
{
    for (NSUInteger index = 0; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        if (currentChar == ' ')
        {
            x += 3;
        }
        else
        {
            NSUInteger fontIndex = currentChar - 33;
            int charLeftX = FontX[fontIndex];
            int charWidth = FontWidth[fontIndex];
            
            for (int charX = 0; charX < charWidth; charX++)
            {
                if (x >= 0 && x < RendererSize)
                {
                    uint8_t rowBits = FontData[charLeftX + charX];
                    for (int charY = 0; charY < 8; charY++)
                    {
                        if (rowBits & (1<<charY))
                        {
                            [self plotX:x Y:y+charY];
                        }
                    }
                }
                x++;
            }
        }
    };
}

- (int)widthForText:(NSString *)text
{
    int width = 0;
    for (NSUInteger index = 0; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        if (currentChar == ' ')
        {
            width += 3;
        }
        else
        {
            NSUInteger fontIndex = currentChar - 33;
            width += FontWidth[fontIndex];
        }
    }
    return width;
}

- (Sprite *)spriteAtIndex:(int)index
{
    return &_sprites[index];
}

- (SpriteDef *)spriteDefAtIndex:(int)index
{
    return &_spriteDefs[index];
}

uint8_t getSpritePixel(SpriteDef *def, int x, int y)
{
    return (def->data[y] >> ((RendererSpriteSize - x - 1) << 1)) & 0x03;
}

- (BOOL)checkCollisionBetweenSprite:(int)index1 andSprite:(int)index2
{
    if (index1 != index2)
    {
        Sprite *sprite1 = &_sprites[index1];
        Sprite *sprite2 = &_sprites[index2];
        int diffX = sprite2->x - sprite1->x;
        int diffY = sprite2->y - sprite1->y;
        if (ABS(diffX) < RendererSpriteSize && ABS(diffY) < RendererSpriteSize)
        {
            SpriteDef *def1 = &_spriteDefs[sprite1->image];
            SpriteDef *def2 = &_spriteDefs[sprite2->image];
            
            int minX = MAX(0, diffX);
            int minY = MAX(0, diffY);
            int maxX = MIN(RendererSpriteSize, RendererSpriteSize + diffX);
            int maxY = MIN(RendererSpriteSize, RendererSpriteSize + diffY);
            for (int y = minY; y < maxY; y++)
            {
                for (int x = minX; x < maxX; x++)
                {
                    if (getSpritePixel(def1, x, y) > 0 && getSpritePixel(def2, x - diffX, y - diffY) > 0)
                    {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (uint32_t)screenColorAtX:(int)x Y:(int)y
{
    uint8_t colorIndex = _pixelBuffer[y][x];
    
    // sprites
    for (int i = 0; i < RendererNumSprites; i++)
    {
        Sprite *sprite = &_sprites[i];
        if (sprite->visible)
        {
            int localX = x - sprite->x;
            int localY = y - sprite->y;
            if (localX >= 0 && localY >= 0 && localX < RendererSpriteSize && localY < RendererSpriteSize)
            {
                SpriteDef *def = &_spriteDefs[sprite->image];
                uint8_t color = getSpritePixel(def, localX, localY);
                if (color > 0)
                {
                    colorIndex = sprite->colors[color - 1];
                    break;
                }
            }
        }
    }
    
    return ColorPalette[colorIndex];
}

@end
