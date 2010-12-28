#import "KTextView.h"
#import "KStyleElement.h"
#import "KScroller.h"
#import "common.h"

@implementation KTextView


// text container rect adjustments
static NSSize kTextContainerInset = (NSSize){6.0, 4.0}; // {(LR),(TB)}
static CGFloat kTextContainerXOffset = -8.0;
static CGFloat kTextContainerYOffset = 0.0;


- (id)initWithFrame:(NSRect)frame {
  if ((self = [super initWithFrame:frame])) {
    [self setAllowsUndo:YES];
    [self setAutomaticLinkDetectionEnabled:NO];
    [self setSmartInsertDeleteEnabled:NO];
    [self setAutomaticQuoteSubstitutionEnabled:NO];
    [self setAllowsDocumentBackgroundColorChange:NO];
    [self setAllowsImageEditing:NO];
    [self setRichText:NO];
    [self setImportsGraphics:NO];
    [self turnOffKerning:self]; // we are monospace (robot voice)
    [self setAutoresizingMask:NSViewWidthSizable];
    [self setUsesFindPanel:YES];
    [self setTextContainerInset:NSMakeSize(2.0, 4.0)];
    [self setVerticallyResizable:YES];
    [self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    
    // TODO: the following settings should follow the current style
    [self setBackgroundColor:
        [NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
    [self setTextColor:[NSColor whiteColor]];
    [self setInsertionPointColor:
        [NSColor colorWithCalibratedRed:1.0 green:0.2 blue:0.1 alpha:1.0]];
    [self setSelectedTextAttributes:[NSDictionary dictionaryWithObject:
        [NSColor colorWithCalibratedRed:0.12 green:0.18 blue:0.27 alpha:1.0]
        forKey:NSBackgroundColorAttributeName]];

    // later adjusted by textContainerOrigin
    [self setTextContainerInset:kTextContainerInset];
  }
  return self;
}


- (NSPoint)textContainerOrigin {
  NSPoint origin = [super textContainerOrigin];
  origin.x += kTextContainerXOffset;
  origin.y += kTextContainerYOffset;
  return origin;
}


- (void)mouseDown:(NSEvent*)event {
  NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
  NSInteger charIndex = [self characterIndexForInsertionAtPoint:point];
  NSRange effectiveRange;
  NSDictionary *attributes =
      [[self attributedString] attributesAtIndex:charIndex
                                  effectiveRange:&effectiveRange];
  NSString *styleElementKey =
      [attributes objectForKey:KStyleElementAttributeName];

  if (styleElementKey) {
    DLOG("clicked on element of type '%@'", styleElementKey);
    if ([styleElementKey isEqualToString:@"url"]) {
      NSString *effectiveString =
          [[[self textStorage] string] substringWithRange:effectiveRange];
      effectiveString = [effectiveString stringByTrimmingCharactersInSet:
          [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
      NSURL *url = [NSURL URLWithString:effectiveString];
      NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
      if ([workspace openURL:url]) {
        // avoid cursor movement
        return;
      }
    }
  }

  [super mouseDown:event];
}


- (void)keyDown:(NSEvent*)event {
//	DLOG("keyDown %@ %ld", event, [[event characters] characterAtIndex:0]);
	if (event.keyCode == 48) {
		NSInteger charIndex = [[[self selectedRanges] objectAtIndex:0] rangeValue].location;
		NSInteger lineNumber = [self.textStorage.delegate lineNumberForLocation:charIndex];
		
		NSInteger start = [self.textStorage.delegate locationOfLineAtLineNumber:lineNumber];
		
		NSRange oldRange = [self selectedRange];
		int delta = 0;
		
		if (([event modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask)) != 0) {
			// unindent
			NSRange indent = NSMakeRange(start, 4);
			if ([[self.textStorage.string substringWithRange:indent] isEqualToString:@"    "]) {
				[super setSelectedRange:indent];
				[super insertText:@""];
				delta = -4;
			}
		}else{
			// indent
			[super setSelectedRange:NSMakeRange(start, 0)];
			[super insertText:@"    "];
			delta = 4;
		}
		[super setSelectedRange:NSMakeRange(oldRange.location+delta, 0)];
	}else{
		[super keyDown:event];
	}
}


- (void)mouseMoved:(NSEvent*)event {
  NSPoint loc = [event locationInWindow]; // window coords
  KScroller *scroller =
      (KScroller*)[(NSScrollView*)(self.superview.superview) verticalScroller];
  if (!scroller.isCollapsed) {
    NSRect scrollerFrame = [scroller frame];
    NSPoint loc2 = [scroller convertPointFromBase:loc];
    if (loc2.x <= 0.0) {
      // only delegate mouseMoved to NSTextView if the mouse is outside of the
      // scroller
      [super mouseMoved:event];
    }
  }
}


/*- (void)resetCursorRects {
  [self addCursorRect:NSMakeRect(0.0, 0.0, 100.0, 100.0)
               cursor:[NSCursor arrowCursor]];
}
- (void)cursorUpdate:(NSEvent*)event {
  DLOG("cursorUpdate:%@", event);
}*/

@end
