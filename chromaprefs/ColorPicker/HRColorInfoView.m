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

static UIColor* UIColorFromHexString(NSString* hexString) {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1]; // bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#import "HRColorInfoView.h"

const CGFloat kHRColorInfoViewLabelHeight = 18.;
const CGFloat kHRColorInfoViewCornerRadius = 3.;

@interface HRColorInfoView () {
    UIColor *_color;
}
-(void)handleTapFrom:(id)sender;
@end

@implementation HRColorInfoView {
    UILabel *_hexColorLabel;
    CALayer *_borderLayer;
}

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
    self.backgroundColor = [UIColor clearColor];
    _hexColorLabel = [[UILabel alloc] init];
    _hexColorLabel.backgroundColor = [UIColor clearColor];
    _hexColorLabel.font = [UIFont systemFontOfSize:12];
    _hexColorLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    _hexColorLabel.textAlignment = NSTextAlignmentCenter;

    [self addSubview:_hexColorLabel];

    _borderLayer = [[CALayer alloc] initWithLayer:self.layer];
    _borderLayer.cornerRadius = kHRColorInfoViewCornerRadius;
    _borderLayer.borderColor = [[UIColor lightGrayColor] CGColor];
    _borderLayer.borderWidth = 1.f / [[UIScreen mainScreen] scale];
    [self.layer addSublayer:_borderLayer];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _hexColorLabel.frame = CGRectMake(
            0,
            CGRectGetHeight(self.frame) - kHRColorInfoViewLabelHeight,
            CGRectGetWidth(self.frame),
            kHRColorInfoViewLabelHeight);

    _borderLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.frame.size};
}

- (void)setColor:(UIColor *)color {
    _color = color;
    CGFloat r, g, b, a;
    [_color getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int) (r * 255.0f)<<16 | (int) (g * 255.0f)<<8 | (int) (b * 255.0f)<<0;
    _hexColorLabel.text = [NSString stringWithFormat:@"#%06x", rgb];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGRect colorRect = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect) - kHRColorInfoViewLabelHeight);

    UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:colorRect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(4, 4)];
    [rectanglePath closePath];
    [self.color setFill];
    [rectanglePath fill];
}

- (UIView *)viewForBaselineLayout {
    return _hexColorLabel;
}

-(void)handleTapFrom:(id)sender {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hex Value"
                                                  message:@"Enter custom hex value"
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Enter"
                        , nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  alert.tag = 12300931;
  [alert textFieldAtIndex:0].placeholder = _hexColorLabel.text;
  [alert textFieldAtIndex:0].text = @"#";//?
  [[alert textFieldAtIndex:0] setDelegate:self];
  [alert show];
  //[[alert textFieldAtIndex:0] resignFirstResponder];
  //[[alert textFieldAtIndex:0] becomeFirstResponder];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1 && alertView.tag == 12300931) {
    NSString * value = [alertView textFieldAtIndex:0].text;
    NSCharacterSet *hash = [NSCharacterSet characterSetWithCharactersInString:@"#"];
    if(NSNotFound == [value rangeOfCharacterFromSet:hash].location)
      value = [NSString stringWithFormat:@"#%@",value];

    NSCharacterSet *chars = [[NSCharacterSet characterSetWithCharactersInString:@"#0123456789ABCDEFabcdef"] invertedSet];
    BOOL isValid = (NSNotFound == [value rangeOfCharacterFromSet:chars].location);

    if(isValid) {
      [self setColor:UIColorFromHexString(value)];
      [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid HEX code"
                                                      message:@"Please enter a valid HEX code e.g. #1F334A"
                                                    delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil
         , nil];
      alert.tag = 120314;
      [alert show];
    }
  }
  else if(alertView.tag == 120314) {
    [self handleTapFrom:nil];
  }
}

@end
