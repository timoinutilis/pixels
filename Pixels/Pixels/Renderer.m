//
//  Renderer.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Renderer.h"

int const RendererSize = 32;

@implementation Renderer {
    unsigned char _pixelBuffer[RendererSize][RendererSize];
    uint32_t _colorPalette[16];
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self initColorPalette];
        self.colorIndex = 0;
        [self clear];
    }
    return self;
}

- (void)initColorPalette
{
    _colorPalette[0] = 0x222222;
    _colorPalette[1] = 0xFFFFFF;
    _colorPalette[2] = 0xFF0000;
    _colorPalette[3] = 0x00FF00;
    _colorPalette[4] = 0x0000FF;
}

- (int)size
{
    return RendererSize;
}

- (int)colorAtX:(int)x Y:(int)y
{
    return _pixelBuffer[y][x];
}

- (void)clear
{
    for (int y = 0; y < RendererSize; y++)
    {
        for (int x = 0; x < RendererSize; x++)
        {
            _pixelBuffer[y][x] = _colorIndex;
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
            _pixelBuffer[y][x] = _colorIndex;
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
            _pixelBuffer[y][x] = _colorIndex;
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
        _pixelBuffer[fromY][x] = _colorIndex;
        _pixelBuffer[toY][x] = _colorIndex;
    }
    for (int y = fromY; y <= toY; y++)
    {
        _pixelBuffer[y][fromX] = _colorIndex;
        _pixelBuffer[y][toX] = _colorIndex;
    }
}

- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY
{
    
}

- (void)drawCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY
{
    
}

- (void)fillCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY
{
    
}

- (void)drawText:(NSString *)text x:(int)x y:(int)y
{
    
}

- (uint32_t)screenColorAtX:(int)x Y:(int)y
{
    return _colorPalette[_pixelBuffer[y][x]];
}

@end
