//
//  Renderer.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Renderer.h"
#import "Fonts.h"

int const RendererMaxScreenSize = 512;
int const RendererNumColors = 16;
int const RendererNumScreens = 4;
int const RendererNumSprites = 64;
int const RendererNumSpriteDefs = 64;
int const RendererSpriteSize = 8;
int const RendererNumFonts = 4;

int const RendererFlagTransparent = 0x01;

uint32_t const ColorPalette[16] = {0x000000, 0xffffff, 0xaaaaaa, 0x555555, 0xff0000, 0x550000, 0xaa5500, 0xffaa00, 0xffff00, 0x00aa00, 0x005500, 0x00aaff, 0x0000ff, 0x0000aa, 0xff00ff, 0xaa00aa};

typedef struct Font {
    uint8_t *data;
    int *x;
    int *width;
    int height;
} Font;

@implementation Renderer {
    Screen _screens[RendererNumScreens];
    uint32_t _palettes[RendererNumScreens][RendererNumColors];
    uint8_t _copyBuffer[RendererMaxScreenSize][RendererMaxScreenSize];
    Sprite _sprites[RendererNumSprites];
    SpriteDef _spriteDefs[RendererNumSpriteDefs];
    Font _fonts[RendererNumFonts];
    int _copyWidth;
    int _copyHeight;
    int _currentMaxScreenIndex;
    int _currentMaxSpriteIndex;
}

- (instancetype)init
{
    if (self = [super init])
    {
        // default screen configuration
        self.displayMode = 3; // 64x64
        self.sharedPalette = YES;
        [self openScreen:0 width:64 height:64 renderMode:0];
        [self openScreen:1 width:64 height:64 renderMode:RendererFlagTransparent];
        
        self.screenIndex = 0;
        
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
    [self closeScreens];
}

- (void)setDisplayMode:(int)displayMode
{
    [self closeScreens];
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

- (Screen *)currentScreen
{
    if (_screenIndex >= 0)
    {
        return &_screens[_screenIndex];
    }
    return NULL;
}

- (Screen *)screenAtIndex:(int)index
{
    return &_screens[index];
}

- (void)openScreen:(int)index width:(int)width height:(int)height renderMode:(int)renderMode
{
    Screen *screen = &_screens[index];
    if (screen->pixelBuffer)
    {
        free(screen->pixelBuffer);
        screen->pixelBuffer = NULL;
    }
    screen->width = width;
    screen->height = height;
    screen->displayX = 0;
    screen->displayY = 0;
    screen->displayWidth = width;
    screen->displayHeight = height;
    screen->offsetX = 0;
    screen->offsetY = 0;
    screen->renderMode = renderMode;
    screen->colorIndex = 1;
    screen->bgColorIndex = 0;
    screen->fontIndex = 0;
    
    screen->pixelBuffer = calloc(width * height, sizeof(uint8_t));
    
    _screenIndex = index;
    _currentMaxScreenIndex = MAX(_currentMaxScreenIndex, index);
    if (!_sharedPalette)
    {
        [self initPalette];
    }
}

- (void)closeScreen:(int)index
{
    Screen *screen = &_screens[index];
    screen->width = 0;
    screen->height = 0;
    screen->displayX = 0;
    screen->displayY = 0;
    screen->displayWidth = 0;
    screen->displayHeight = 0;
    screen->offsetX = 0;
    screen->offsetY = 0;
    screen->renderMode = 0;
    
    free(screen->pixelBuffer);
    screen->pixelBuffer = NULL;
    
    if (_screenIndex == index)
    {
        _screenIndex = -1;
    }
}

- (void)closeScreens
{
    for (int i = 0; i < RendererNumScreens; i++)
    {
        if (_screens[i].pixelBuffer)
        {
            [self closeScreen:i];
        }
    }
    _currentMaxScreenIndex = 0;
}

- (void)initPalette
{
    int paletteIndex = 0;
    if (!_sharedPalette)
    {
        if (_screenIndex == -1) return;
        paletteIndex = _screenIndex;
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
        if (_screenIndex == -1) return 0;
        paletteIndex = _screenIndex;
    }
    int color = _palettes[paletteIndex][index];
    return ((color >> 18) & 0x30) | ((color >> 12) & 0x0C) | ((color >> 6) & 0x03);
}

- (void)setColor:(int)color atIndex:(int)index
{
    int paletteIndex = 0;
    if (!_sharedPalette)
    {
        if (_screenIndex == -1) return;
        paletteIndex = _screenIndex;
    }
    int r = (color >> 4) & 0x03;
    int g = (color >> 2) & 0x03;
    int b = color & 0x03;
    _palettes[paletteIndex][index] = r * 0x550000 | g * 0x5500 | b * 0x55;
}

- (int)colorIndexAtX:(int)x Y:(int)y
{
    if (_screenIndex == -1) return 0;
    Screen *screen = &_screens[_screenIndex];
    if (x >= 0 && x < screen->width && y >= 0 && y < screen->height)
    {
        return screen->pixelBuffer[y * screen->width + x];
    }
    return -1;
}

- (void)clearWithColorIndex:(int)colorIndex
{
    if (_screenIndex == -1) return;
    Screen *screen = &_screens[_screenIndex];
    if (colorIndex == -1)
    {
        colorIndex = screen->bgColorIndex;
    }
    uint8_t *pixelBuffer = screen->pixelBuffer;
    for (int i = screen->width * screen->height - 1; i >= 0; i--)
    {
        pixelBuffer[i] = colorIndex;
    }
    screen->printY = 0;
}

- (void)plotX:(int)x Y:(int)y
{
    if (_screenIndex == -1) return;
    Screen *screen = &_screens[_screenIndex];
    if (x >= 0 && x < screen->width && y >= 0 && y < screen->height)
    {
        screen->pixelBuffer[y * screen->width + x] = screen->colorIndex;
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
    if (_screenIndex == -1) return;
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    Screen *screen = &_screens[_screenIndex];
    int screenWidth = screen->width;
    int screenHeight = screen->height;
    int colorIndex = screen->colorIndex;
    if (toX >= 0 && toY >= 0 && fromX < screenWidth && fromY < screenHeight)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= screenWidth) toX = screenWidth - 1;
        if (toY >= screenHeight) toY = screenHeight - 1;
        
        uint8_t *pixelBuffer = screen->pixelBuffer;
        for (int y = fromY; y <= toY; y++)
        {
            for (int x = fromX; x <= toX; x++)
            {
                pixelBuffer[y * screenWidth + x] = colorIndex;
            }
        }
    }
}

- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY refill:(BOOL)refill
{
    if (_screenIndex == -1) return;
    if (fromX > toX)
    {
        int value = toX; toX = fromX; fromX = value;
    }
    if (fromY > toY)
    {
        int value = toY; toY = fromY; fromY = value;
    }
    Screen *screen = &_screens[_screenIndex];
    int screenWidth = screen->width;
    int screenHeight = screen->height;
    if (fromX < screenWidth && fromY < screenHeight && toX >= 0 && toY >= 0)
    {
        if (fromX < 0) fromX = 0;
        if (fromY < 0) fromY = 0;
        if (toX >= screenWidth) toX = screenWidth - 1;
        if (toY >= screenHeight) toY = screenHeight - 1;
        
        int width = toX - fromX + 1;
        int height = toY - fromY + 1;
        uint8_t *pixelBuffer = screen->pixelBuffer;
        
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
                    pixelBuffer[y * screenWidth + x] = screen->bgColorIndex;
                }
                else
                {
                    getX = MAX(fromX, MIN(toX, getX));
                    getY = MAX(fromY, MIN(toY, getY));
                    pixelBuffer[y * screenWidth + x] = pixelBuffer[getY * screenWidth + getX];
                }
            }
        }
    }
}

- (void)drawCircleX:(int)centerX Y:(int)centerY radius:(int)radius
{
    if (_screenIndex == -1) return;
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
    if (_screenIndex == -1) return;
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
    if (_screenIndex == -1) return;
    Screen *screen = &_screens[_screenIndex];
    int oldColor = [self colorIndexAtX:x Y:y];
    int newColor = screen->colorIndex;
    
    if (oldColor == newColor || oldColor == -1) return;
    
    int w = screen->width;
    int h = screen->height;
    uint8_t *pixelBuffer = screen->pixelBuffer;
    
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

- (void)getScreenFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    if (_screenIndex == -1) return;
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
    
    Screen *screen = &_screens[_screenIndex];
    int screenWidth = screen->width;
    uint8_t *pixelBuffer = screen->pixelBuffer;

    for (int y = fromY; y <= toY; y++)
    {
        for (int x = fromX; x <= toX; x++)
        {
            _copyBuffer[y - fromY][x - fromX] = pixelBuffer[y * screenWidth + x];
        }
    }
}

- (void)putScreenX:(int)x Y:(int)y srcX:(int)srcX srcY:(int)srcY srcWidth:(int)srcWidth srcHeight:(int)srcHeight transparency:(int)transparency
{
    if (_screenIndex == -1) return;
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
    
    Screen *screen = &_screens[_screenIndex];
    int screenWidth = screen->width;
    int screenHeight = screen->height;
    uint8_t *pixelBuffer = screen->pixelBuffer;
    
    for (int oy = 0; oy < srcHeight; oy++)
    {
        py = oy + y;
        for (int ox = 0; ox < srcWidth; ox++)
        {
            px = ox + x;
            if (px >= 0 && py >= 0 && px < screenWidth && py < screenHeight)
            {
                uint8_t color = _copyBuffer[srcY + oy][srcX + ox];
                if (transparency == -1 || color != transparency)
                {
                    pixelBuffer[py * screenWidth + px] = color;
                }
            }
        }
    }
}

- (void)drawText:(NSString *)text x:(int)x y:(int)y
{
    if (_screenIndex == -1) return;
    Screen *screen = &_screens[_screenIndex];
    [self drawText:text screen:screen color:screen->colorIndex x:x y:y start:0 wrap:NO bg:NO];
}


- (int)drawText:(NSString *)text screen:(Screen *)screen color:(int)colorIndex x:(int)x y:(int)y start:(int)start wrap:(BOOL)wrap bg:(BOOL)bg
{
    Font *font = &_fonts[screen->fontIndex];
    int fontHeight = font->height;
    uint8_t *fontData = font->data;
    int screenWidth = screen->width;
    for (int index = start; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        NSUInteger charIndex = currentChar - 32;
        int charLeftX = font->x[charIndex];
        int charWidth = font->width[charIndex];
        
        if (wrap && x + charWidth > screenWidth)
        {
            return index;
        }
        
        for (int charX = 0; charX < charWidth; charX++)
        {
            if (x >= 0 && x < screenWidth)
            {
                uint8_t rowBits = fontData[charLeftX + charX];
                for (int charY = 0; charY < fontHeight; charY++)
                {
                    int pY = y+charY;
                    if (pY >= 0 && pY < screen->height)
                    {
                        if (rowBits & (1<<charY))
                        {
                            screen->pixelBuffer[pY * screen->width + x] = colorIndex;
                        }
                        else if (bg)
                        {
                            screen->pixelBuffer[pY * screen->width + x] = screen->bgColorIndex;
                        }
                    }
                }
            }
            x++;
        }
    };
    return 0;
}

- (int)widthForText:(NSString *)text
{
    if (_screenIndex == -1) return 0;
    int width = 0;
    int *charWidths = _fonts[_screens[_screenIndex].fontIndex].width;
    for (NSUInteger index = 0; index < text.length; index++)
    {
        unichar currentChar = [text characterAtIndex:index];
        NSUInteger charIndex = currentChar - 32;
        width += charWidths[charIndex];
    }
    return width;
}

- (void)print:(NSString *)text
{
    if (_screenIndex == -1) return;
    Screen *screen = &_screens[_screenIndex];
    int fontHeight = _fonts[screen->fontIndex].height;
    
    int index = 0;
    do
    {
        index = [self drawText:text screen:screen color:screen->colorIndex x:0 y:screen->printY start:index wrap:YES bg:YES];
        
        if (screen->printY > screen->height - 2 * fontHeight)
        {
            [self scrollFromX:0 Y:0 toX:screen->width - 1 Y:screen->printY + fontHeight - 1 deltaX:0 Y:-fontHeight refill:YES];
        }
        else
        {
            screen->printY += fontHeight;
        }
    }
    while (index > 0);
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

- (BOOL)checkCollisionBetweenSprite:(int)spriteIndex andScreen:(int)screenIndex
{
    Sprite *sprite = &_sprites[spriteIndex];
    Screen *screen = &_screens[screenIndex];
    if (sprite->visible && screen->pixelBuffer)
    {
        int diffX = screen->displayX - screen->offsetX - floorf(sprite->x);
        int diffY = screen->displayY - screen->offsetY - floorf(sprite->y);
        if (   diffX < RendererSpriteSize && diffX > -screen->width
            && diffY < RendererSpriteSize && diffY > -screen->height)
        {
            SpriteDef *def = &_spriteDefs[sprite->image];
            uint8_t *pixelBuffer = screen->pixelBuffer;
            int screenWidth = screen->width;
            int minX = MAX(0, diffX);
            int minY = MAX(0, diffY);
            int maxX = MIN(RendererSpriteSize, screen->width + diffX);
            int maxY = MIN(RendererSpriteSize, screen->height + diffY);
            for (int y = minY; y < maxY; y++)
            {
                for (int x = minX; x < maxX; x++)
                {
                    if (getSpritePixel(def, x, y) > 0 && pixelBuffer[(y - diffY) * screenWidth + (x - diffX)] > 0)
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
    int screenIndex = 0;
    
    // screens
    for (int i = _currentMaxScreenIndex; i >= 0 ; i--)
    {
        Screen *screen = &_screens[i];
        if (screen->pixelBuffer)
        {
            int localX = x - screen->displayX;
            int localY = y - screen->displayY;
            if (localX >= 0 && localY >= 0 && localX < screen->displayWidth && localY < screen->displayHeight)
            {
                localX += screen->offsetX;
                localY += screen->offsetY;
                uint8_t screenColorIndex = 0;
                if (localX >= 0 && localY >= 0 && localX < screen->width && localY < screen->height)
                {
                    screenColorIndex = screen->pixelBuffer[localY * screen->width + localX];
                }
                if (!(screen->renderMode & RendererFlagTransparent) || screenColorIndex > 0)
                {
                    colorIndex = screenColorIndex;
                    screenIndex = i;
                    break;
                }
            }
        }
    }
    
    // sprites
    for (int i = 0; i <= _currentMaxSpriteIndex; i++)
    {
        Sprite *sprite = &_sprites[i];
        if (sprite->visible && sprite->screen >= screenIndex)
        {
            int localX = x - (int)floorf(sprite->x);
            int localY = y - (int)floorf(sprite->y);
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
                    screenIndex = sprite->screen;
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
    return _palettes[screenIndex][colorIndex];
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
