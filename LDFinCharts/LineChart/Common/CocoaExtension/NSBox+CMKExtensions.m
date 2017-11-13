//
//  NSBox+CMKExtensions.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 21/04/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "NSBox+CMKExtensions.h"

@implementation NSBox (CMKExtensions)

- (void)setView:(NSView *)view enabled:(BOOL)enabled
{
    // enumerate subviews...
    for (NSView *v in view.subviews)
    {
//        if ([v isKindOfClass:[NSTextField class]])
        if ([v.className isEqualToString:@"NSTextField"])
        {
            // make all text labels match disabled control text
            v.layer.opacity = enabled ? 1.0f : 0.3f;
        }
        else if ([v respondsToSelector:@selector(setEnabled:)])
        {
            // disable controls
            NSControl *c = (NSControl *)v;
            c.enabled = enabled;
        }
        [self setView:v enabled:enabled];
    }
}


/*
    func setView(view: NSView, enabled: Bool) {
        // enumerate subviews...
        for o in view.subviews {
            if let v = o as? NSView {
                //println("v \(v)")
                if (v.className == "NSTextField") {
                    // make all text labels match disabled control text
                    if let layer = v.layer {
                        layer.opacity = enabled ? 1.0 : 0.3;
                    }
                } else if (v.respondsToSelector("setEnabled:")) {
                    // disable controls
                    let c = v as NSControl
                    c.enabled = enabled
                }
                self.setView(v, enabled:enabled)
            }
        }
    }
*/


- (void)setEnabled:(BOOL)enabled
{
    self.layer.opacity = enabled ? 1.0f : 0.7f;
    [self setView:self enabled:enabled];
}

/*
    func setBox(box: NSBox, enabled: Bool) {
        // set whole box alpha
        if let layer = box.layer {
            layer.opacity = enabled ? 1.0 : 0.7;
        }
        // now cycle through and disable subviews/controls
        self.setView(box, enabled: enabled)
    
    }
*/



@end
