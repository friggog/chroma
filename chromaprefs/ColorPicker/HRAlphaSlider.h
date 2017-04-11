#import <Foundation/Foundation.h>

@protocol HRAlphaSlider

@required
@property (nonatomic, readonly) NSNumber *alphaV;
@property (nonatomic) UIColor *color;
-(void)setAlphaValue:(CGFloat)v;
@end

@interface HRAlphaSlider : UIControl <HRAlphaSlider>
@end
