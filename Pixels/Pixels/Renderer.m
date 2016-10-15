//
//  Renderer.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Renderer.h"
#import "Fonts.h"

int const RendererMaxLayerSize = 512;
int const RendererNumColors = 16;
int const RendererNumLayers = 4;
int const RendererNumSprites = 64;
int const RendererNumSpriteDefs = 64;
int const RendererSpriteSize = 8;
int const RendererNumFonts = 4;
int const RendererNumBlocks = 64;

int const RendererFlagTransparent = 0x01;

uint32_t const ColorPalette[16] = {0x000000, 0xffffff, 0xaaaaaa, 0x555555, 0xff0000, 0x550000, 0xaa5500, 0xffaa00, 0xffff00, 0x00aa00, 0x005500, 0x00aaff, 0x0000ff, 0x0000aa, 0xff00ff, 0xaa00aa};

typedef struct Font {
    uint8_t *data;
    int *x;
    int *width;
    int height;
} Font;

@implementation Renderer {
    Layer _layers[RendererNumLayers];
    uint32_t _palettes[RendererNumLayers][RendererNumColors];
    uint8_t _copyBuffer[RendererMaxLayerSize][RendererMaxLayerSize];
    Sprite _sprites[RendererNumSprites];
    SpriteDef _spriteDefs[RendererNumSpriteDefs];
    Font _fonts[RendererNumFonts];
    Block _blocks[RendererNumBlocks];
    int _copyWidth;
    int _copyHeight;
    int _currentMaxLayerIndex;
    int _currentMaxSpriteIndex;
}

- (instancetype)init
{
    if (self = [super init])
    {
        // default layer configuration
        self.displayMode = 3; // 64x64
        self.sharedPalette = YES;
        [self openLayer:0 width:64 height:64 renderMode:0];
        [self openLayer:1 width:64 height:64 renderMode:RendererFlagTransparent];
        
        self.layerIndex = 0;
        
        for (int i = 0; i < RendererNumSprites; i++)
        {
            Sprite *sprite = &_sprites[i];
            sprite->colors[0] = -1;
            sprite->colors[1] = -1;
            sprite->colors[2] = -1;
        }
        
        _fonts[0].data = Font0Data;
        _fonts[0].x = Font0X;
        _fonts[0].width = Font0Width;
        _fonts[0].height = 6;
        
        _fonts[1].data = Font1Data;
        _fonts[1].x = Font1X;
        _fonts[1].width = Font1Width;
        _fonts[1].height = 6;
        
        _fonts[2].data = Font2Data;
        _fonts[2].x = Font2X;
        _fonts[2].width = Font2Width;
        _fonts[2].height = 8;
        
        _fonts[3].data = Font3Data;
        _fonts[3].x = Font3X;
        _fonts[3].width = Font3Width;
        _fonts[3].height = 8;
    }
    return self;
}

- (void)dealloc
{
    [self freeAllBlocks];
    [self closeLayers];
}

- (void)setDisplayMode:(int)displayMode
{
    [self closeLayers];
    _displayMode = displayMode;
    _displaySize = pow(2, displayMode + 3);
}

- (void)setSharedPalette:(BOOL)sharedPalette
{
    _sharedPalette = sharedPalette;
    if (sharedPalette)
    {
        [self initPalette];
    }
}

- (Layer *)currentLayer
{
    if (_layerIndex >= 0)
    {
        return &_layers[_layerIndex];
    }
    return NULL;
}

- (Layer *)layerAtIndex:(int)index
{
    return &_layers[index];
}

- (void)openLayer:(int)index width:(int)width height:(int)height renderMode:(int)renderMode
{
    Layer *layer = &_layers[index];
    if (layer->pixelBuffer)
    {
        free(layer->pixelBuffer);
        layer->pixelBuffer = NULL;
    }
    layer->visible = YES;
    layer->width = width;
    layer->height = height;
    layer->displayX = 0;
    layer->displayY = 0;
    layer->displayWidth = width;
    layer->displayHeight = height;
    layer->offsetX = 0;
    layer->offsetY = 0;
    layer->renderMode = renderMode;
    layer->colorIndex = 1;
    layer->bgColorIndex = 0;
    layer->borderColorIndex = 3;
    layer->fontIndex = 0;
    layer->cursorX = 0;
    layer->cursorY = 0;
    layer->cursorVisible = NO;
    
    layer->pixelBuffer = calloc(width * height, sizeof(uint8_t));
    
    _layerIndex = index;
    _currentMaxLayerIndex = MAX(_currentMaxLayerIndex, index);
    if (!_sharedPalette)
    {
        [self initPalette];
    }
}

- (void)closeLayer:(int)index
{
    Layer *layer = &_layers[index];
    layer->visible = NO;
    layer->width = 0;
    layer->height = 0;
    layer->displayX = 0;
    layer->displayY = 0;
    layer->displayWidth = 0;
    layer->displayHeight = 0;
    layer->offsetX = 0;
    layer->offsetY = 0;
    layer->renderMode = 0;
    
    free(layer->pixelBuffer);
    layer->pixelBuffer = NULL;
    
    if (_layerIndex == index)
    {
        _layerIndex = -1;
    }
}

- (void)closeLayers
{
    for (int i = 0; i < RendererNumLayers; i++)
    {
        if (_layers[i].pixelBuffer)
        {
            [self closeLayer:i];
        }
    }
    _currentMaxLayerIndex = 0;
}

- (void)initPalette
{
    int paletteIndex = 0;
    if (!_sharedPalette)
    {
        if (_layerIndex == -1) return;
        paletteIndex = _layerIndex;
    }
    for (int i = 0; i < RendererNumColors; i++)
    {
        _palettes[paletteIndex][i] = ColorPalette[i];
    }
}

- (int)colorAtIndex:(int)index
{
    int paletteIndex = 0;
    if (!_sharedPalette)
    {
        if (_layerIndex == -1) return 0;
        paletteIndex = _layerIndex;
    }
    int color = _palettes[paletteIndex][index];
    return ((color >> 18) & 0x30) | ((color >> 12) & 0x0C) | ((color >> 6) & 0x03);
}

- (void)setColor:(int)color atIndex:(int)index
{
    int paletteIndex = 0;
    if (!_sharedPalette)
    {
        if (_layerIndex == -1) return;
        paletteIndex = _layerIndex;
    }
    int r = (color >> 4) & 0x03;
    int g = (color >> 2) & 0x03;
    int b = color & 0x03;
    _palettes[paletteIndex][index] = r * 0x550000 | g * 0x5500 | b * 0x55;
}

- (int)colorIndexAtX:(int)x Y:(int)y
{
    if (_layerIndex == -1) return 0;
    Layer *layer = &_layers[_layerIndex];
    if (x >= 0 && x < layer->width && y >= 0 && y < layer->height)
    {
        return layer->pixelBuffer[y * layer->width + x];
    }
    return -1;
}

- (void)clearWithColorIndex:(int)colorIndex
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    if (colorIndex == -1)
    {
        colorIndex = layer->bgColorIndex;
    }
    uint8_t *pixelBuffer = layer->pixelBuffer;
    for (int i = layer->width * layer->height - 1; i >= 0; i--)
    {
        pixelBuffer[i] = colorIndex;
    }
    layer->cursorX = 0;
    layer->cursorY = 0;
}

- (void)plotX:(int)x Y:(int)y
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    if (x >= 0 && x < layer->width && y >= 0 && y < layer->height)
    {
        layer->pixelBuffer[y * layer->width + x] = layer->colorIndex;
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
            fromX = toX;
            fromY = toY;
            
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
            fromX = toX;
            fromY = toY;
            
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
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    [self fillBoxFromX:fromX Y:fromY toX:toX Y:toY layer:layer color:layer->colorIndex];
}

- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY layer:(Layer *)layer color:(int)colorIndex
{
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    int layerWidth = layer->width;
    int layerHeight = layer->height;
    if (toX >= 0 && toY >= 0 && fromX < layerWidth && fromY < layerHeight)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= layerWidth) toX = layerWidth - 1;
        if (toY >= layerHeight) toY = layerHeight - 1;
        
        uint8_t *pixelBuffer = layer->pixelBuffer;
        for (int y = fromY; y <= toY; y++)
        {
            for (int x = fromX; x <= toX; x++)
            {
                pixelBuffer[y * layerWidth + x] = colorIndex;
            }
        }
    }
}

- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY refill:(BOOL)refill
{
    if (_layerIndex == -1) return;
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    Layer *layer = &_layers[_layerIndex];
    int layerWidth = layer->width;
    int layerHeight = layer->height;
    if (fromX < layerWidth && fromY < layerHeight && toX >= 0 && toY >= 0)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= layerWidth) toX = layerWidth - 1;
        if (toY >= layerHeight) toY = layerHeight - 1;
        
        int width = toX - fromX + 1;
        int height = toY - fromY + 1;
        uint8_t *pixelBuffer = layer->pixelBuffer;
        
        for (int oy = 0; oy < height; oy++)
        {
            for (int ox = 0; ox < width; ox++)
            {
                int x = (deltaX > 0) ? toX - ox : fromX + ox;
                int y = (deltaY > 0) ? toY - oy : fromY + oy;
                int getX = x - deltaX;
                int getY = y - deltaY;
                if (refill && (getX < fromX || getX > toX || getY < fromY || getY > toY))
                {
                    pixelBuffer[y * layerWidth + x] = layer->bgColorIndex;
                }
                else
                {
                    getX = MAX(fromX, MIN(toX, getX));
                    getY = MAX(fromY, MIN(toY, getY));
                    pixelBuffer[y * layerWidth + x] = pixelBuffer[getY * layerWidth + getX];
                }
            }
        }
    }
}

- (void)drawCircleX:(int)centerX Y:(int)centerY radius:(int)radius
{
    if (_layerIndex == -1) return;
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
    if (_layerIndex == -1) return;
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
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    int oldColor = [self colorIndexAtX:x Y:y];
    int newColor = layer->colorIndex;
    
    if (oldColor == newColor || oldColor == -1) return;
    
    int w = layer->width;
    int h = layer->height;
    uint8_t *pixelBuffer = layer->pixelBuffer;
    
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
        while (y1 >= 0 && pixelBuffer[y1 * w + x] == oldColor)
        {
            y1--;
        }
        y1++;
        spanLeft = spanRight = 0;
        while (y1 < h && pixelBuffer[y1 * w + x] == oldColor)
        {
            pixelBuffer[y1 * w + x] = newColor;
            if (!spanLeft && x > 0 && pixelBuffer[y1 * w + (x-1)] == oldColor)
            {
                [stack addObject:[RendererPoint pointWithX:x - 1 Y:y1]];
                spanLeft = 1;
            }
            else if (spanLeft && x > 0 && pixelBuffer[y1 * w + (x-1)] != oldColor)
            {
                spanLeft = 0;
            }
            if (!spanRight && x < w - 1 && pixelBuffer[y1 * w + (x+1)] == oldColor)
            {
                [stack addObject:[RendererPoint pointWithX:x + 1 Y:y1]];
                spanRight = 1;
            }
            else if (spanRight && x < w - 1 && pixelBuffer[y1 * w + (x+1)] != oldColor)
            {
                spanRight = 0;
            }
            y1++;
        }
    }
}

- (void)getLayerFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    if (_layerIndex == -1) return;
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
    
    Layer *layer = &_layers[_layerIndex];
    int layerWidth = layer->width;
    uint8_t *pixelBuffer = layer->pixelBuffer;

    for (int y = fromY; y <= toY; y++)
    {
        for (int x = fromX; x <= toX; x++)
        {
            _copyBuffer[y - fromY][x - fromX] = pixelBuffer[y * layerWidth + x];
        }
    }
}

- (void)putLayerX:(int)x Y:(int)y srcX:(int)srcX srcY:(int)srcY srcWidth:(int)srcWidth srcHeight:(int)srcHeight transparency:(int)transparency
{
    if (_layerIndex == -1) return;
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
    
    Layer *layer = &_layers[_layerIndex];
    int layerWidth = layer->width;
    int layerHeight = layer->height;
    uint8_t *pixelBuffer = layer->pixelBuffer;
    
    for (int oy = 0; oy < srcHeight; oy++)
    {
        py = oy + y;
        for (int ox = 0; ox < srcWidth; ox++)
        {
            px = ox + x;
            if (px >= 0 && py >= 0 && px < layerWidth && py < layerHeight)
            {
                uint8_t color = _copyBuffer[srcY + oy][srcX + ox];
                if (transparency == -1 || color != transparency)
                {
                    pixelBuffer[py * layerWidth + px] = color;
                }
            }
        }
    }
}

- (void)getBlock:(int)index fromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    [self freeBlock:index];
    if (_layerIndex == -1) return;
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    
    int blockWidth = toX - fromX + 1;
    int blockHeight = toY - fromY + 1;
    uint8_t *blockBuffer = calloc(blockWidth * blockHeight, sizeof(uint8_t));
    
    Layer *layer = &_layers[_layerIndex];
    int layerWidth = layer->width;
    uint8_t *pixelBuffer = layer->pixelBuffer;
    
    for (int y = fromY; y <= toY; y++)
    {
        for (int x = fromX; x <= toX; x++)
        {
            blockBuffer[(y - fromY) * blockWidth + (x - fromX)] = pixelBuffer[y * layerWidth + x];
        }
    }
    
    Block *block = &_blocks[index];
    block->width = blockWidth;
    block->height = blockHeight;
    block->pixelBuffer = blockBuffer;
}

- (void)putBlock:(int)index X:(int)x Y:(int)y mask:(BOOL)mask
{
    if (_layerIndex == -1) return;
    
    Block *block = &_blocks[index];
    if (block->pixelBuffer)
    {
        int blockWidth = block->width;
        int blockHeight = block->height;
        uint8_t *blockBuffer = block->pixelBuffer;
        
        Layer *layer = &_layers[_layerIndex];
        int layerWidth = layer->width;
        int layerHeight = layer->height;
        uint8_t *pixelBuffer = layer->pixelBuffer;
        
        for (int oy = 0; oy < blockHeight; oy++)
        {
            int py = oy + y;
            for (int ox = 0; ox < blockWidth; ox++)
            {
                int px = ox + x;
                if (px >= 0 && py >= 0 && px < layerWidth && py < layerHeight)
                {
                    uint8_t color = blockBuffer[oy * blockWidth + ox];
                    if (mask == 0 || color != 0)
                    {
                        pixelBuffer[py * layerWidth + px] = color;
                    }
                }
            }
        }
    }
}

- (void)freeBlock:(int)index
{
    Block *block = &_blocks[index];
    if (block->pixelBuffer)
    {
        free(block->pixelBuffer);
        block->pixelBuffer = NULL;
    }
    block->width = 0;
    block->height = 0;
}

- (void)freeAllBlocks
{
    for (int i = 0; i < RendererNumBlocks; i++)
    {
        [self freeBlock:i];
    }
}

- (void)drawText:(NSString *)text x:(int)x y:(int)y outline:(int)outline
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    if (outline >= 1)
    {
        [self drawText:text layer:layer color:layer->borderColorIndex x:x y:y+1 start:0 wrap:NO bg:NO outX:nil];
        if (outline >= 2)
        {
            [self drawText:text layer:layer color:layer->borderColorIndex x:x y:y-1 start:0 wrap:NO bg:NO outX:nil];
            [self drawText:text layer:layer color:layer->borderColorIndex x:x-1 y:y start:0 wrap:NO bg:NO outX:nil];
            [self drawText:text layer:layer color:layer->borderColorIndex x:x+1 y:y start:0 wrap:NO bg:NO outX:nil];
            if (outline >= 3)
            {
                [self drawText:text layer:layer color:layer->borderColorIndex x:x-1 y:y-1 start:0 wrap:NO bg:NO outX:nil];
                [self drawText:text layer:layer color:layer->borderColorIndex x:x-1 y:y+1 start:0 wrap:NO bg:NO outX:nil];
                [self drawText:text layer:layer color:layer->borderColorIndex x:x+1 y:y-1 start:0 wrap:NO bg:NO outX:nil];
                [self drawText:text layer:layer color:layer->borderColorIndex x:x+1 y:y+1 start:0 wrap:NO bg:NO outX:nil];
            }
        }
    }
    [self drawText:text layer:layer color:layer->colorIndex x:x y:y start:0 wrap:NO bg:NO outX:nil];
}

- (int)drawText:(NSString *)text layer:(Layer *)layer color:(int)colorIndex x:(int)x y:(int)y start:(int)start wrap:(BOOL)wrap bg:(BOOL)bg outX:(int *)outX
{
    Font *font = &_fonts[layer->fontIndex];
    int fontHeight = font->height;
    uint8_t *fontData = font->data;
    int layerWidth = layer->width;
    int nextStart = -1;
    for (int index = start; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        if (currentChar >= 32 && currentChar <= 90)
        {
            NSUInteger charIndex = currentChar - 32;
            int charLeftX = font->x[charIndex];
            int charWidth = font->width[charIndex];
            
            if (wrap && x + charWidth > layerWidth)
            {
                nextStart = index;
                break;
            }
            
            for (int charX = 0; charX < charWidth; charX++)
            {
                if (x >= 0 && x < layerWidth)
                {
                    uint8_t rowBits = fontData[charLeftX + charX];
                    for (int charY = 0; charY < fontHeight; charY++)
                    {
                        int pY = y+charY;
                        if (pY >= 0 && pY < layer->height)
                        {
                            if (rowBits & (1<<charY))
                            {
                                layer->pixelBuffer[pY * layer->width + x] = colorIndex;
                            }
                            else if (bg)
                            {
                                layer->pixelBuffer[pY * layer->width + x] = layer->bgColorIndex;
                            }
                        }
                    }
                }
                x++;
            }
        }
        else if (wrap && (currentChar == '\n' || currentChar == '\r'))
        {
            nextStart = index + 1;
            break;
        }
    };
    if (outX)
    {
        *outX = x;
    }
    return nextStart;
}

- (int)widthForText:(NSString *)text
{
    if (_layerIndex == -1) return 0;
    int width = 0;
    int *charWidths = _fonts[_layers[_layerIndex].fontIndex].width;
    for (NSUInteger index = 0; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        if (currentChar >= 32 && currentChar <= 90)
        {
            NSUInteger charIndex = currentChar - 32;
            width += charWidths[charIndex];
        }
    }
    return width;
}

- (void)print:(NSString *)text newLine:(BOOL)newLine wrap:(BOOL)wrap
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    int fontHeight = _fonts[layer->fontIndex].height;
    
    if (layer->cursorVisible)
    {
        [self drawCursorWithLayer:layer bg:YES];
    }
    
    int index = 0;
    do
    {
        int yOver = layer->cursorY + fontHeight - layer->height;
        if (yOver > 0)
        {
            [self scrollFromX:0 Y:0 toX:layer->width - 1 Y:layer->height - 1 deltaX:0 Y:-yOver refill:YES];
            layer->cursorY -= yOver;
        }
        
        index = [self drawText:text layer:layer color:layer->colorIndex x:layer->cursorX y:layer->cursorY start:index wrap:wrap bg:YES outX:&layer->cursorX];
        
        if (newLine || index >= 0 || (wrap && layer->cursorX >= layer->width))
        {
            layer->cursorY += fontHeight;
            layer->cursorX = 0;
        }
    }
    while (index > 0);
    
    if (layer->cursorVisible)
    {
        [self drawCursorWithLayer:layer bg:NO];
    }
}

- (void)clearCharacter:(unichar)character
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    Font *font = &_fonts[layer->fontIndex];
    int charWidth = font->width[character - 32];
    
    if (layer->cursorVisible)
    {
        [self drawCursorWithLayer:layer bg:YES];
    }
    
    layer->cursorX -= charWidth;
    [self fillBoxFromX:layer->cursorX Y:layer->cursorY toX:layer->cursorX + charWidth - 1 Y:layer->cursorY + font->height - 1
                 layer:layer color:layer->bgColorIndex];

    if (layer->cursorVisible)
    {
        [self drawCursorWithLayer:layer bg:NO];
    }
}

- (void)showCursor
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    layer->cursorVisible = YES;
    [self drawCursorWithLayer:layer bg:NO];
}

- (void)hideCursor
{
    if (_layerIndex == -1) return;
    Layer *layer = &_layers[_layerIndex];
    layer->cursorVisible = NO;
    [self drawCursorWithLayer:layer bg:YES];
}

- (void)drawCursorWithLayer:(Layer *)layer bg:(BOOL)bg
{
    Font *font = &_fonts[layer->fontIndex];
    [self fillBoxFromX:layer->cursorX Y:layer->cursorY toX:layer->cursorX + font->width[0] - 1 Y:layer->cursorY + font->height - 1
                 layer:layer color:(bg ? layer->bgColorIndex : layer->colorIndex)];
}

- (Sprite *)spriteAtIndex:(int)index
{
    _currentMaxSpriteIndex = MAX(_currentMaxSpriteIndex, index);
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
            if (   sprite1->x + (RendererSpriteSize << sprite1->scaleX) > sprite2->x
                && sprite1->y + (RendererSpriteSize << sprite1->scaleY) > sprite2->y
                && sprite1->x < sprite2->x + (RendererSpriteSize << sprite2->scaleX)
                && sprite1->y < sprite2->y + (RendererSpriteSize << sprite2->scaleY)
                )
            {
                int diffX = floorf(sprite2->x) - floorf(sprite1->x);
                int diffY = floorf(sprite2->y) - floorf(sprite1->y);
                
                SpriteDef *def1 = &_spriteDefs[sprite1->image];
                SpriteDef *def2 = &_spriteDefs[sprite2->image];
                
                int minX = MAX(0, diffX);
                int minY = MAX(0, diffY);
                int maxX = MIN(RendererSpriteSize << sprite1->scaleX, (RendererSpriteSize << sprite2->scaleX) + diffX);
                int maxY = MIN(RendererSpriteSize << sprite1->scaleY, (RendererSpriteSize << sprite2->scaleY) + diffY);
                for (int y = minY; y < maxY; y++)
                {
                    for (int x = minX; x < maxX; x++)
                    {
                        if (   getSpritePixel(def1, x >> sprite1->scaleX, y >> sprite1->scaleY) > 0
                            && getSpritePixel(def2, (x - diffX) >> sprite2->scaleX, (y - diffY) >> sprite2->scaleY) > 0)
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

- (BOOL)checkCollisionBetweenSprite:(int)spriteIndex andLayer:(int)layerIndex
{
    Sprite *sprite = &_sprites[spriteIndex];
    Layer *layer = &_layers[layerIndex];
    if (sprite->visible && layer->visible)
    {
        int diffX = layer->displayX - layer->offsetX - floorf(sprite->x);
        int diffY = layer->displayY - layer->offsetY - floorf(sprite->y);
        if (   diffX < (RendererSpriteSize << sprite->scaleX) && diffX > -layer->width
            && diffY < (RendererSpriteSize << sprite->scaleY) && diffY > -layer->height)
        {
            SpriteDef *def = &_spriteDefs[sprite->image];
            uint8_t *pixelBuffer = layer->pixelBuffer;
            int layerWidth = layer->width;
            int minX = MAX(0, diffX);
            int minY = MAX(0, diffY);
            int maxX = MIN(RendererSpriteSize << sprite->scaleX, layer->width + diffX);
            int maxY = MIN(RendererSpriteSize << sprite->scaleY, layer->height + diffY);
            for (int y = minY; y < maxY; y++)
            {
                for (int x = minX; x < maxX; x++)
                {
                    if (getSpritePixel(def, x >> sprite->scaleX, y >> sprite->scaleY) > 0 && pixelBuffer[(y - diffY) * layerWidth + (x - diffX)] > 0)
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
    uint8_t colorIndex = 0;
    int layerIndex = 0;
    
    // layers
    for (int i = _currentMaxLayerIndex; i >= 0 ; i--)
    {
        Layer *layer = &_layers[i];
        if (layer->visible)
        {
            int localX = x - layer->displayX;
            int localY = y - layer->displayY;
            if (localX >= 0 && localY >= 0 && localX < layer->displayWidth && localY < layer->displayHeight)
            {
                localX += layer->offsetX;
                localY += layer->offsetY;
                uint8_t layerColorIndex = 0;
                if (localX >= 0 && localY >= 0 && localX < layer->width && localY < layer->height)
                {
                    layerColorIndex = layer->pixelBuffer[localY * layer->width + localX];
                }
                if (!(layer->renderMode & RendererFlagTransparent) || layerColorIndex > 0)
                {
                    colorIndex = layerColorIndex;
                    layerIndex = i;
                    break;
                }
            }
        }
    }
    
    // sprites
    for (int i = 0; i <= _currentMaxSpriteIndex; i++)
    {
        Sprite *sprite = &_sprites[i];
        if (sprite->visible && sprite->layer >= layerIndex)
        {
            int localX = (x - (int)floorf(sprite->x)) >> sprite->scaleX;
            int localY = (y - (int)floorf(sprite->y)) >> sprite->scaleY;
            if (localX >= 0 && localY >= 0 && localX < RendererSpriteSize && localY < RendererSpriteSize)
            {
                SpriteDef *def = &_spriteDefs[sprite->image];
                uint8_t pixel = getSpritePixel(def, localX, localY);
                if (pixel > 0)
                {
                    int8_t spriteColorIndex = sprite->colors[pixel - 1];
                    if (spriteColorIndex >= 0)
                    {
                        // use sprite palette
                        colorIndex = spriteColorIndex;
                    }
                    else
                    {
                        // use sprite def palette
                        colorIndex = def->colors[pixel - 1];
                    }
                    layerIndex = sprite->layer;
                    break;
                }
            }
        }
    }
    
    // final color
    if (_sharedPalette)
    {
        return _palettes[0][colorIndex];
    }
    return _palettes[layerIndex][colorIndex];
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
