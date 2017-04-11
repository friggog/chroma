/*-
 * Copyright (c) 2011 Ryota Hayashi
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $FreeBSD$
 */

#import "HRColorPickerView.h"
#import <sys/time.h>
#import "HRColorMapView.h"
#import "HRBrightnessSlider.h"
#import "HRAlphaSlider.h"
#import "HRColorInfoView.h"
#import "HRHSVColorUtil.h"

typedef struct timeval timeval;

@interface HRColorPickerView () {
}

@end

@implementation HRColorPickerView {
    UIControl <HRColorInfoView> *_colorInfoView;
    UIControl <HRColorMapView> *_colorMapView;
    UIControl <HRBrightnessSlider> *_brightnessSlider;
    UIControl <HRAlphaSlider> *_alphaSlider;

    // 色情報
    HRHSVColor _currentHsvColor;

    // フレームレート
    timeval _lastDrawTime;
    timeval _waitTimeDuration;
}

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init {
    // フレームレートの調整
    gettimeofday(&_lastDrawTime, NULL);

    _waitTimeDuration.tv_sec = (__darwin_time_t) 0.0;
    _waitTimeDuration.tv_usec = (__darwin_suseconds_t) (1000000.0 / 15.0);
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
}

- (UIColor *)color {
    return [UIColor colorWithHue:_currentHsvColor.h
                      saturation:_currentHsvColor.s
                      brightness:_currentHsvColor.v
                           alpha:1];
}

- (void)setColor:(UIColor *)color {
    // RGBのデフォルトカラーをHSVに変換
    HSVColorFromUIColor(color, &_currentHsvColor);
}

- (UIView <HRColorInfoView> *)colorInfoView {
    if (!_colorInfoView) {
        _colorInfoView = [[HRColorInfoView alloc] init];
      _colorInfoView.color = self.color;// colorWithAlphaComponent:self.alphaValue];
        [_colorInfoView addTarget:self
                              action:@selector(colorChangedFromInfoView:)
                    forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.colorInfoView];
    }
    return _colorInfoView;
}

- (void)setColorInfoView:(UIControl <HRColorInfoView> *)colorInfoView {
    _colorInfoView = colorInfoView;
  _colorInfoView.color = self.color;// colorWithAlphaComponent:self.alphaValue];
    [_colorInfoView addTarget:self
                          action:@selector(colorChangedFromInfoView:)
                forControlEvents:UIControlEventValueChanged];
}

- (UIControl <HRBrightnessSlider> *)brightnessSlider {
    if (!_brightnessSlider) {
        _brightnessSlider = [[HRBrightnessSlider alloc] initWithLayoutForAlpha:self.wantsAlpha];
        _brightnessSlider.brightnessLowerLimit = @0;
        _brightnessSlider.color = self.color;
        [_brightnessSlider addTarget:self
                              action:@selector(brightnessChanged:)
                    forControlEvents:UIControlEventValueChanged];
        [self addSubview:_brightnessSlider];
    }
    return _brightnessSlider;
}

- (UIControl <HRAlphaSlider> *)alphaSlider {
  if (!_alphaSlider && self.wantsAlpha) {
    _alphaSlider = [[HRAlphaSlider alloc] init];
    _alphaSlider.color = self.color;
    [_alphaSlider setAlphaValue:self.alphaValue];
    [_alphaSlider addTarget:self action:@selector(alphaChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_alphaSlider];
  }
  else
    self.alphaValue = 1.0;
  return _alphaSlider;
}

- (void)setBrightnessSlider:(UIControl <HRBrightnessSlider> *)brightnessSlider {
    _brightnessSlider = brightnessSlider;
    _brightnessSlider.color = self.color;
    [_brightnessSlider addTarget:self
                          action:@selector(brightnessChanged:)
                forControlEvents:UIControlEventValueChanged];
}

- (void)setAlphaSlider:(UIControl <HRAlphaSlider> *)alphaSlider {
    _alphaSlider = alphaSlider;
    _alphaSlider.color = self.color;
    [_alphaSlider setAlphaValue:self.alphaValue];
    [_alphaSlider addTarget:self
                          action:@selector(alphaChanged:)
                forControlEvents:UIControlEventValueChanged];
}

- (UIControl <HRColorMapView> *)colorMapView {
    if (!_colorMapView) {
        HRColorMapView *colorMapView;
        colorMapView = [HRColorMapView colorMapWithFrame:CGRectZero
                                    saturationUpperLimit:1.0];
        colorMapView.tileSize = @16;
        _colorMapView = colorMapView;

        _colorMapView.brightness = _currentHsvColor.v;
        _colorMapView.color = self.color;
        _colorMapView.alpha = self.alphaValue;
        [_colorMapView addTarget:self
                          action:@selector(colorMapColorChanged:)
                forControlEvents:UIControlEventValueChanged];
        _colorMapView.backgroundColor = [UIColor redColor];
        [self addSubview:_colorMapView];
    }
    return _colorMapView;
}

- (void)setColorMapView:(UIControl <HRColorMapView> *)colorMapView {
    _colorMapView = colorMapView;
    _colorMapView.brightness = _currentHsvColor.v;
    _colorMapView.color = self.color;
    _colorMapView.alpha = self.alphaValue;
    [_colorMapView addTarget:self
                      action:@selector(colorMapColorChanged:)
            forControlEvents:UIControlEventValueChanged];
}

- (void)brightnessChanged:(UIControl <HRBrightnessSlider> *)slider {
    _currentHsvColor.v = slider.brightness.floatValue;
    self.colorMapView.brightness = _currentHsvColor.v;
    self.colorMapView.color = self.color;
    self.colorInfoView.color = [self.color colorWithAlphaComponent:self.alphaValue];
    self.alphaSlider.color = self.color;
    [self sendActions];
}

- (void)alphaChanged:(UIControl <HRAlphaSlider> *)slider {
    self.alphaValue = [slider.alphaV floatValue];
    self.colorMapView.alpha = self.alphaValue;
    self.colorInfoView.color = [self.color colorWithAlphaComponent:self.alphaValue];
    [self sendActions];
}

-(void)colorChangedFromInfoView:(UIControl <HRColorInfoView> *)infoView {
  HSVColorFromUIColor(infoView.color, &_currentHsvColor);
  self.colorMapView.brightness = _currentHsvColor.v;
  self.colorMapView.color = self.color;
  self.brightnessSlider.color = self.color;
  self.alphaSlider.color = self.color;
  [self sendActions];
}

- (void)colorMapColorChanged:(UIControl <HRColorMapView> *)colorMapView {
    HSVColorFromUIColor(colorMapView.color, &_currentHsvColor);
    self.brightnessSlider.color = self.color;
    self.colorInfoView.color = [self.color colorWithAlphaComponent:self.alphaValue];
    self.alphaSlider.color = self.color;
    [self sendActions];
}

- (void)sendActions {
    timeval now, diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_waitTimeDuration, >)) {
        _lastDrawTime = now;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (BOOL)usingAutoLayout {
    return self.constraints && self.constraints.count > 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.usingAutoLayout) {
        return;
    }

    CGFloat headerHeight = (20 + 44) * 1.625;
    self.colorMapView.frame = CGRectMake(
            0, headerHeight,
            CGRectGetWidth(self.frame),
            MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - headerHeight)
    );
    // use intrinsicContentSize for 3.5inch screen
    CGRect colorMapFrame = (CGRect) {
            .origin = CGPointZero,
            .size = self.colorMapView.intrinsicContentSize
    };
    colorMapFrame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(colorMapFrame);
    self.colorMapView.frame = colorMapFrame;
    headerHeight = CGRectGetMinY(colorMapFrame);

    self.colorInfoView.frame = CGRectMake(8, (headerHeight - 84) / 2.0f, 66, 84);

    CGFloat hexLabelHeight = 18;
    CGFloat sliderHeight = 11;
    CGFloat brightnessPickerTop = CGRectGetMaxY(self.colorInfoView.frame) - hexLabelHeight - sliderHeight;

    CGRect brightnessPickerFrame = CGRectMake(
            CGRectGetMaxX(self.colorInfoView.frame) + 9,
            brightnessPickerTop,
            CGRectGetWidth(self.frame) - CGRectGetMaxX(self.colorInfoView.frame) - 9 * 2,
            sliderHeight);

    self.brightnessSlider.frame = [self.brightnessSlider frameForAlignmentRect:brightnessPickerFrame];

    if(self.wantsAlpha) {
      CGRect alphaPickerFrame = CGRectMake(
              CGRectGetMaxX(self.colorInfoView.frame) + 9,
              brightnessPickerTop-35,
              CGRectGetWidth(self.frame) - CGRectGetMaxX(self.colorInfoView.frame) - 9 * 2,
              sliderHeight);

      self.alphaSlider.frame = [self.alphaSlider frameForAlignmentRect:alphaPickerFrame];
    }
}

@end
