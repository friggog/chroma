#import "CircleViews.h"

static UIColor * darkenedColour(UIColor* color) {
  CGFloat amount = 0.75;
  CGFloat hue, saturation, brightness, alpha;
  if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
      brightness += (amount-1.0);
      brightness = MAX(MIN(brightness, 1.0), 0.0);
      return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
  }

  CGFloat white;
  if ([color getWhite:&white alpha:&alpha]) {
      white += (amount-1.0);
      white = MAX(MIN(white, 1.0), 0.0);
      return [UIColor colorWithWhite:white alpha:1];
  }

  return [UIColor clearColor];
}

@implementation CircleColourView
-(id)initWithFrame:(CGRect)frame andColour:(UIColor*)colour{
  self = [super initWithFrame:frame];
  if(self) {
    if([colour isEqual:[UIColor clearColor]])
      self.hidden = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.layer.cornerRadius = 15;
    self.layer.borderColor = [darkenedColour(colour) CGColor];
    self.layer.borderWidth = 2.0;
    self.backgroundColor = colour;
  }
  return self;
}

-(void)setBackgroundColor:(UIColor*)col {
  if(![col isEqual:[UIColor clearColor]]) {
    self.hidden = NO;
    self.layer.borderColor = [darkenedColour(col) CGColor];
    [super setBackgroundColor:col];
  }
}
@end
