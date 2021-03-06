//
//  MMPLabel.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/31/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPLabel.h"

//https://github.com/jerrykrinock/CategoriesObjC
#import "NS(Attributed)String+Geometrics.h"

#define DEFAULT_IOS_FONT @"HelveticaNeue"
#define DEFAULT_ANDROID_FONT @"Roboto-Regular"
#define DEFAULT_FONTSIZE 16
@implementation MMPLabel {
  NSFont *_iOSFont;
  NSFont *_androidFont;
}
@synthesize stringValue = _stringValue;


+ (BOOL)numberIsFloat:(NSNumber*)num {
  if(strcmp([num objCType], @encode(float)) == 0 || strcmp([num objCType], @encode(double)) == 0) {
    return YES;
  }
  else return NO;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    self.address = @"/myLabel";
    _fontFamily=@"Default";
    _fontName=@"";
    _androidFontName = DEFAULT_ANDROID_FONT;

    _iOSFont = [NSFont fontWithName:DEFAULT_IOS_FONT size:DEFAULT_FONTSIZE];
    _androidFont = [NSFont fontWithName:DEFAULT_ANDROID_FONT size:DEFAULT_FONTSIZE];
    //_currentFont = _iOSFont;

    textView = [[NSTextView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    textView.backgroundColor=[NSColor clearColor];
    textView.font = _iOSFont;

    [textView setEditable:NO];
    [textView setTextColor:self.color];

    [self setStringValue:@"my text goes here"];
    [self setTextSize:DEFAULT_FONTSIZE];
    [self addSubview:textView];

    //DEI temp
    /*[self setHorizontalTextAlignment:kMMPHorizontalTextAlignmentCenter];
    _verticalTextAlignment = kMMPVerticalTextAlignmentBottom;
    textView.backgroundColor = [NSColor colorWithRed:1 green:0 blue:0 alpha:.3];*/
    
    [self addHandles];
    [self resizeSubviewsWithOldSize:self.frame.size]; //aka setNeedsLayout...why necc?

  }
  return self;
}


//ugly hack so that this object doesn't take touches, but passes to controls underneath
- (NSView *)hitTest:(NSPoint)aPoint{
    //if I am editing, behave nomrally like any other MMPControl...try super.
    if([self.editingDelegate isEditing]){
        NSPoint convPoint = [self convertPoint:aPoint fromView:[self superview]];
        if(NSPointInRect(convPoint, [[self handle] frame]) && !self.handle.isHidden)
            return [self handle];
        else if(NSPointInRect(aPoint, [self frame])){
            return self;
        }
        else return nil;
    }
    
    //but if not editing, look at other MMPControls and return them if touching them underneath, otherwise return the canvasView
    
    NSInteger locationInSubviews = [[[self superview] subviews] indexOfObject:self];
    for (NSInteger index = locationInSubviews - 1; index >= 0; index--) {
        NSView *subview = [[[self superview] subviews] objectAtIndex:index];
        if (NSPointInRect(aPoint, [subview frame]) && ![subview isKindOfClass:[MMPLabel class]])
            return subview;
    }
    return [self superview];
}

-(void)setStringValueUndoable:(NSString*)inString{
    
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setStringValueUndoable:) object:[self stringValue]];
    [self setStringValue:inString];
}

-(void)setStringValue:(NSString *)aString{
    _stringValue = aString;
    [textView setString:aString];
  [self resizeSubviewsWithOldSize:self.frame.size];
}

-(void)setTextSizeUndoable:(NSNumber*)inNumber{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setTextSizeUndoable:) object:[NSNumber numberWithInt:[self textSize]]];
    [self setTextSize:[inNumber intValue]];
}

-(void)setTextSize:(int)inInt{
    _textSize = inInt;

  //iOS
  if([_fontFamily isEqualToString:@"Default"]) {
    _iOSFont = [NSFont fontWithName:DEFAULT_IOS_FONT size:inInt];
  } else {
    _iOSFont = [NSFont fontWithName:_fontName size:inInt];
  }
  //Android
  if ([NSFont fontWithName:_androidFontName size:inInt])  {
    _androidFont = [NSFont fontWithName:_androidFontName size:inInt];
  }
  // kick
  textView.font = _isShowingAndroidFonts ? _androidFont : _iOSFont;
  [self resizeSubviewsWithOldSize:self.frame.size];
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    [textView setTextColor:color];
}

-(void)setFontFamily:(NSString *)fontFamily fontName:(NSString *)fontName{
    _fontName = fontName;
    _fontFamily=fontFamily;
  if([fontFamily isEqualToString:@"Default"]){
    _iOSFont = [NSFont fontWithName:DEFAULT_IOS_FONT size:_textSize];
  } else {
    _iOSFont = [NSFont fontWithName:fontName size:_textSize];
  }

  if (!_isShowingAndroidFonts) {
    textView.font = _iOSFont;
    [self resizeSubviewsWithOldSize:self.frame.size];
  }
}

-(void)setAndroidFontName:(NSString *)fontName{
    _androidFontName = fontName;
    NSFont *testForFont = [NSFont fontWithName:fontName size:12];
  //NSLog(@"%@",[[[NSFontManager sharedFontManager] availableFontFamilies] description]);
  if (testForFont) {
    _androidFont = [NSFont fontWithName:fontName size:_textSize];
    if (_isShowingAndroidFonts) { //if showing, set font
      textView.font = _androidFont;
      [self resizeSubviewsWithOldSize:self.frame.size];
    }
  }
}

- (void)setIsShowingAndroidFonts:(BOOL)isShowingAndroidFonts {
  _isShowingAndroidFonts = isShowingAndroidFonts;
  // kick
  textView.font = _isShowingAndroidFonts ? _androidFont : _iOSFont;
  [self resizeSubviewsWithOldSize:self.frame.size];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize{
  [super resizeSubviewsWithOldSize:oldBoundsSize];

  CGFloat width = self.frame.size.width;
  CGFloat height = [_stringValue heightForWidth:self.frame.size.width
                                     attributes:@{NSFontAttributeName : textView.font}];
  //[textView setFrame:CGRectMake(0, 0, self.frame.size.width, height)];

  if (_verticalTextAlignment == kMMPVerticalTextAlignmentTop) {
    [textView setFrame:CGRectMake(0,
                                  0,
                                  width,
                                  height)];
  } else if (_verticalTextAlignment == kMMPVerticalTextAlignmentCenter) {
    [textView setFrame:CGRectMake(0,
                                  MAX((self.frame.size.height - height) / 2, 0),
                                  width,
                                  height)];
  } else if (_verticalTextAlignment == kMMPVerticalTextAlignmentBottom) {
    [textView setFrame:CGRectMake(0,
                                  MAX(self.frame.size.height - height, 0),
                                  width,
                                  height)];
  }
}

-(void)setVerticalTextAlignmentUndoable:(NSNumber*)inVal {
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setVerticalTextAlignmentUndoable:)
                                      object:[NSNumber numberWithInteger:_verticalTextAlignment]];
  [self setVerticalTextAlignment:[inVal integerValue]];
}

- (void)setVerticalTextAlignment:(MMPVerticalTextAlignment)verticalTextAlignment {
  _verticalTextAlignment = verticalTextAlignment;
  [self resizeSubviewsWithOldSize:self.frame.size];
}

-(void)setHorizontalTextAlignmentUndoable:(NSNumber*)inVal {
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setHorizontalTextAlignmentUndoable:)
                                      object:[NSNumber numberWithInteger:_horizontalTextAlignment]];
  [self setHorizontalTextAlignment:[inVal integerValue]];
}

- (void)setHorizontalTextAlignment:(MMPHorizontalTextAlignment)horizontalTextAlignment {
  _horizontalTextAlignment = horizontalTextAlignment;
  switch (horizontalTextAlignment) {
    case kMMPHorizontalTextAlignmentLeft:
      textView.alignment = NSTextAlignmentLeft;
      break;
    case kMMPHorizontalTextAlignmentCenter:
      textView.alignment = NSTextAlignmentCenter;
      break;
    case kMMPHorizontalTextAlignmentRight:
      textView.alignment = NSTextAlignmentRight;
      break;
  }
}

//receive messages from PureData (via [send toGUI]), routed from ViewController via the address to this object
-(void)receiveList:(NSArray *)inArray{
  [super receiveList:inArray];
  // ignore enable message
  if ([inArray count] >= 2 &&
      [inArray[0] isKindOfClass:[NSString class]] &&
      [inArray[0] isEqualToString:@"enable"] &&
      [inArray[1] isKindOfClass:[NSNumber class]]) {
    return;
  }
  
    //if "highlight 0/1", set to highlight color
    if(([inArray count]==2) && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"highlight"]){
        if([[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
            if ([[inArray objectAtIndex:1] intValue]>0) {
                [textView setTextColor:self.highlightColor];
            }
            else {
                [textView setTextColor:self.color];
            }
        }
    }
    
    else{//otherwise it is a new text...concatenate all elements in list into a string
        NSMutableString* newString = [[NSMutableString alloc]init];
        for(id thing in inArray){
            if([thing isKindOfClass:[NSString class]]){
                [newString appendString:(NSString*)thing];
            }
            else if ([thing isKindOfClass:[NSNumber class]]){
              NSNumber* thingNumber = (NSNumber*)thing;
              if ([MMPLabel numberIsFloat:thingNumber] ){
                [newString appendString:[NSString stringWithFormat:@"%.3f", [thingNumber floatValue]]];
              }
              else {
                [newString appendString:[NSString stringWithFormat:@"%d", [thingNumber intValue]]];
              }
              
            }
            [newString appendString:@" "];
        }
        [textView setString:newString];
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.stringValue forKey:@"stringValue"];
    [coder encodeInt:self.textSize forKey:@"textSize"];
    [coder encodeObject:self.fontFamily forKey:@"fontFamily"];
    [coder encodeObject:self.fontName forKey:@"fontName"];
    [coder encodeObject:self.androidFontName forKey:@"androidFontName"];
  [coder encodeInteger:self.horizontalTextAlignment forKey:@"hAlign"];
  [coder encodeInteger:self.verticalTextAlignment forKey:@"vAlign"];

}

- (id)initWithCoder:(NSCoder *)coder {
    
    if(self=[super initWithCoder:coder]){
        [self setStringValue:[coder decodeObjectForKey:@"stringValue"]];
        [self setFontFamily:[coder decodeObjectForKey:@"fontFamily"] fontName:[coder decodeObjectForKey:@"fontName"]];
        [self setAndroidFontName:[coder decodeObjectForKey:@"androidFontName"]];
        [self setTextSize:[coder decodeIntForKey:@"textSize"]];
      [self setHorizontalTextAlignment:[coder decodeIntegerForKey:@"hAlign"]];
      [self setVerticalTextAlignment:[coder decodeIntegerForKey:@"vAlign"]];
    }
    return self;
}

@end
