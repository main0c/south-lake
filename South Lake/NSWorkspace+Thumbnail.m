//
//  NSWorkspace+Thumbnail.m
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

#import "NSWorkspace+Thumbnail.h"

@implementation NSWorkspace (Thumbnail)

- (nullable NSImage*) previewForFile:(NSURL*)fileURL {
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kQLThumbnailOptionIconModeKey];
    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(500,500), (__bridge CFDictionaryRef)options);
    
    if (ref == NULL) {
        return nil;
    }
    
    NSImage *image = [[NSImage alloc] initWithCGImage:ref size:NSZeroSize];
    CGImageRelease(ref);
    
    return image;
}

@end
