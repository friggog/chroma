#import "HRAlphaSlider.h"
#import "HRAlphaCursor.h"
#import "HRHSVColorUtil.h"

@implementation HRAlphaSlider {
  HRAlphaCursor *_alphaCursor;

  CAGradientLayer *_sliderLayer;
  NSNumber *_alphaV;
  UIColor *_color;

  CGRect _controlFrame;
  CGRect _renderingFrame;
}

@synthesize alphaV = _alphaV;
@synthesize color = _color;

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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
    _sliderLayer = [[CAGradientLayer alloc] initWithLayer:self.layer];
    _sliderLayer.startPoint = CGPointMake(0, .5);
    _sliderLayer.endPoint = CGPointMake(1, .5);
    _sliderLayer.borderColor = [[UIColor lightGrayColor] CGColor];
    _sliderLayer.borderWidth = 1.f / [[UIScreen mainScreen] scale];

    [self.layer addSublayer:_sliderLayer];

    self.backgroundColor = [UIColor clearColor];

    UITapGestureRecognizer *tapGestureRecognizer;
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];

    UIPanGestureRecognizer *panGestureRecognizer;
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:panGestureRecognizer];

    _alphaCursor = [[HRAlphaCursor alloc] init];
    [self addSubview:_alphaCursor];

    //_needsToUpdateColor = NO;
    self.backgroundColor = [UIColor clearColor];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = (CGRect) {.origin = CGPointZero, .size = self.frame.size};
    _renderingFrame = UIEdgeInsetsInsetRect(frame, self.alignmentRectInsets);
    _controlFrame = CGRectInset(_renderingFrame, 8, 0);
    _alphaCursor.center = CGPointMake(
            CGRectGetMinX(_controlFrame),
            CGRectGetMidY(_controlFrame));
    _sliderLayer.cornerRadius = _renderingFrame.size.height / 2;
    _sliderLayer.frame = _renderingFrame;
    [self updateCursor];
}

/*
- (UIColor *)color {
    if (_needsToUpdateColor) {
        HRHSVColor hsvColor;
        HSVColorFromUIColor(_color, &hsvColor);
        hsvColor.v = _alpha.floatValue;
        _color = [[UIColor alloc] initWithHue:hsvColor.h
                                   saturation:hsvColor.s
                                   alpha:hsvColor.v
                                        alpha:1];
    }
    return _color;
}
*/
- (void)setColor:(UIColor *)color {
    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    HRHSVColor hsvColor;
    HSVColorFromUIColor(color, &hsvColor);
    UIColor *darkColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:hsvColor.v alpha:0];
    UIColor *lightColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:hsvColor.v alpha:1.0f];

    _sliderLayer.colors = @[(id) lightColorFromHsv.CGColor, (id) darkColorFromHsv.CGColor];

    [CATransaction commit];

    _color = [color colorWithAlphaComponent:[_alphaV floatValue]];
    [self updateCursor];
}


- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        [self updateCursor];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            _alphaCursor.editing = NO;
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        [self updateCursor];
        _alphaCursor.editing = YES;
    }
}

- (void)update:(CGPoint)tapPoint {
    CGFloat selectedAlpha = 0;
    CGPoint tapPointInSlider = CGPointMake(tapPoint.x - _controlFrame.origin.x, tapPoint.y);
    tapPointInSlider.x = MIN(tapPointInSlider.x, _controlFrame.size.width);
    tapPointInSlider.x = MAX(tapPointInSlider.x, 0);

    selectedAlpha = 1.0 - tapPointInSlider.x / _controlFrame.size.width;
    _alphaV = @(selectedAlpha);
    _color = [_color colorWithAlphaComponent:[_alphaV floatValue]];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)updateCursor {
    CGFloat alphaCursorX = (1.0f - self.alphaV.floatValue / 1);
    if (alphaCursorX < 0) {
        return;
    }
    CGPoint point = CGPointMake(alphaCursorX * _controlFrame.size.width + _controlFrame.origin.x, _alphaCursor.center.y);
    _alphaCursor.center = point;
    _alphaCursor.color = self.color;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

-(void)setAlphaValue:(CGFloat)v {
  _alphaV = @(v);
  _color = [_color colorWithAlphaComponent:[_alphaV floatValue]];
  [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark AutoLayout

- (UIEdgeInsets)alignmentRectInsets {
    return UIEdgeInsetsMake(10, 20, 10, 20);
}

- (CGRect)alignmentRectForFrame:(CGRect)frame {
    return UIEdgeInsetsInsetRect(frame, self.alignmentRectInsets);
}

- (CGRect)frameForAlignmentRect:(CGRect)alignmentRect {
    return UIEdgeInsetsInsetRect(alignmentRect, UIEdgeInsetsMake(-10, -20, -10, -20));
}

@end
