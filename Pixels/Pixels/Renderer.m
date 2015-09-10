//
//  Renderer.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Renderer.h"

int const RendererSize = 64;
int const RendererNumColors = 16;
int const RendererNumLayers = 2;
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
    uint32_t _palette[RendererNumColors];
    uint8_t _pixelBuffer[RendererNumLayers][RendererSize][RendererSize];
    Sprite _sprites[RendererNumSprites];
    SpriteDef _spriteDefs[RendererNumSpriteDefs];
    int _copyWidth;
    int _copyHeight;
    uint8_t _copyBuffer[RendererSize][RendererSize];
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self initPalette];
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

- (void)initPalette
{
    for (int i = 0; i < RendererNumColors; i++)
    {
        _palette[i] = ColorPalette[i];
    }
}

- (int)paletteAtIndex:(int)index
{
    int color = _palette[index];
    return ((color >> 18) & 0x30) | ((color >> 12) & 0x0C) | ((color >> 6) & 0x03);
}

- (void)setPalette:(int)color atIndex:(int)index
{
    int r = (color >> 4) & 0x03;
    int g = (color >> 2) & 0x03;
    int b = color & 0x03;
    _palette[index] = r * 0x550000 | g * 0x5500 | b * 0x55;
}

- (int)colorAtX:(int)x Y:(int)y
{
    if (x >= 0 && x < RendererSize && y >= 0 && y < RendererSize)
    {
        return _pixelBuffer[_layerIndex][y][x];
    }
    return -1;
}

- (void)clearWithColorIndex:(int)colorIndex
{
    for (int y = 0; y < RendererSize; y++)
    {
        for (int x = 0; x < RendererSize; x++)
        {
            _pixelBuffer[_layerIndex][y][x] = colorIndex;
        }
    }
}

- (void)plotX:(int)x Y:(int)y
{
    if (x >= 0 && y >= 0 && x < RendererSize && y < RendererSize)
    {
        _pixelBuffer[_layerIndex][y][x] = _colorIndex;
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
                _pixelBuffer[_layerIndex][y][x] = _colorIndex;
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
                _pixelBuffer[_layerIndex][y][x] = _pixelBuffer[_layerIndex][getY][getX];
            }
        }
    }
}

- (void)drawCircleX:(int)centerX Y:(int)centerY radius:(int)radius
{
    int f = 1 - radius;
    int ddF_x = 0;
    int ddF_y = -2 * radius;
    int x = 0;
    int y = radius;
    
    [self plotX:centerX Y:centerY + radius];
    [self plotX:centerX Y:centerY - radius];
    [self plotX:centerX + radius Y:centerY];
    [self plotX:centerX - radius Y:centerY];
    
    while (x < y)
    {
        if (f >= 0)
        {
            y--;
            ddF_y += 2;
            f += ddF_y;
        }
        x++;
        ddF_x += 2;
        f += ddF_x + 1;
        
        [self plotX:centerX + x Y:centerY + y];
        [self plotX:centerX - x Y:centerY + y];
        [self plotX:centerX + x Y:centerY - y];
        [self plotX:centerX - x Y:centerY - y];
        [self plotX:centerX + y Y:centerY + x];
        [self plotX:centerX - y Y:centerY + x];
        [self plotX:centerX + y Y:centerY - x];
        [self plotX:centerX - y Y:centerY - x];
    }
}

- (void)fillCircleX:(int)centerX Y:(int)centerY radius:(int)radius
{
    int f = 1 - radius;
    int ddF_x = 0;
    int ddF_y = -2 * radius;
    int x = 0;
    int y = radius;
    
    [self fillBoxFromX:centerX - radius Y:centerY toX:centerX + radius Y:centerY];
    
    while (x < y)
    {
        if (f >= 0)
        {
            y--;
            ddF_y += 2;
            f += ddF_y;
        }
        x++;
        ddF_x += 2;
        f += ddF_x + 1;
        
        [self fillBoxFromX:centerX - x Y:centerY + y toX:centerX + x Y:centerY + y];
        [self fillBoxFromX:centerX - x Y:centerY - y toX:centerX + x Y:centerY - y];
        [self fillBoxFromX:centerX - y Y:centerY + x toX:centerX + y Y:centerY + x];
        [self fillBoxFromX:centerX - y Y:centerY - x toX:centerX + y Y:centerY - x];
    }
}

- (void)floodFillX:(int)x Y:(int)y
{
    int oldColor = [self colorAtX:x Y:y];
    int newColor = _colorIndex;
    int h = RendererSize;
    int w = RendererSize;
    
    if (oldColor == newColor || oldColor == -1) return;
    
    NSMutableArray *stack = [NSMutableArray array];
    
    int y1;
    bool spanLeft, spanRight;
    
    [stack addObject:[RendererPoint pointWithX:x Y:y]];
    
    RendererPoint *point;
    while ((point = stack.lastObject))
    {
        [stack removeLastObject];
        x = point.x;
        y = point.y;
        
        y1 = y;
        while (y1 >= 0 && _pixelBuffer[_layerIndex][y1][x] == oldColor)
        {
            y1--;
        }
        y1++;
        spanLeft = spanRight = 0;
        while (y1 < h && _pixelBuffer[_layerIndex][y1][x] == oldColor)
        {
            _pixelBuffer[_layerIndex][y1][x] = newColor;
            if (!spanLeft && x > 0 && _pixelBuffer[_layerIndex][y1][x - 1] == oldColor)
            {
                [stack addObject:[RendererPoint pointWithX:x - 1 Y:y1]];
                spanLeft = 1;
            }
            else if (spanLeft && x > 0 && _pixelBuffer[_layerIndex][y1][x - 1] != oldColor)
            {
                spanLeft = 0;
            }
            if (!spanRight && x < w - 1 && _pixelBuffer[_layerIndex][y1][x + 1] == oldColor)
            {
                [stack addObject:[RendererPoint pointWithX:x + 1 Y:y1]];
                spanRight = 1;
            }
            else if (spanRight && x < w - 1 && _pixelBuffer[_layerIndex][y1][x + 1] != oldColor)
            {
                spanRight = 0;
            }
            y1++;
        }
    }
}

- (void)getScreenFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    _copyWidth = toX - fromX + 1;
    _copyHeight = toY - fromY + 1;
    for (int y = fromY; y <= toY; y++)
    {
        for (int x = fromX; x <= toX; x++)
        {
            _copyBuffer[y - fromY][x - fromX] = _pixelBuffer[_layerIndex][y][x];
        }
    }
}

- (void)putScreenX:(int)x Y:(int)y srcX:(int)srcX srcY:(int)srcY srcWidth:(int)srcWidth srcHeight:(int)srcHeight transparency:(int)transparency
{
    int px, py;
    if (srcWidth == 0 || srcHeight == 0)
    {
        srcWidth = _copyWidth;
        srcHeight = _copyHeight;
    }
    else
    {
        if (srcX + srcWidth > _copyWidth)
        {
            srcWidth = _copyWidth - srcX;
        }
        if (srcY + srcHeight > _copyHeight)
        {
            srcHeight = _copyHeight - srcY;
        }
    }
    
    for (int oy = 0; oy < srcHeight; oy++)
    {
        py = oy + y;
        for (int ox = 0; ox < srcWidth; ox++)
        {
            px = ox + x;
            if (px >= 0 && py >= 0 && px < RendererSize && py < RendererSize)
            {
                uint8_t color = _copyBuffer[srcY + oy][srcX + ox];
                if (transparency == -1 || color != transparency)
                {
                    _pixelBuffer[_layerIndex][py][px] = color;
                }
            }
        }
    }
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
        if (sprite1->visible && sprite2->visible)
        {
            int diffX = floorf(sprite2->x) - floorf(sprite1->x);
            int diffY = floorf(sprite2->y) - floorf(sprite1->y);
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
    }
    return NO;
}

- (uint32_t)screenColorAtX:(int)x Y:(int)y
{
    uint8_t colorIndex = _pixelBuffer[1][y][x];
    
    // layer 1 transparent?
    if (colorIndex == 0)
    {
        // layer 0
        colorIndex = _pixelBuffer[0][y][x];
    
        // sprites
        for (int i = 0; i < RendererNumSprites; i++)
        {
            Sprite *sprite = &_sprites[i];
            if (sprite->visible)
            {
                int localX = x - (int)floorf(sprite->x);
                int localY = y - (int)floorf(sprite->y);
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
    }
    
    return _palette[colorIndex];
}

@end


@implementation RendererPoint

+ (RendererPoint *)pointWithX:(int)x Y:(int)y
{
    RendererPoint *point = [[RendererPoint alloc] init];
    point.x = x;
    point.y = y;
    return point;
}

@end
