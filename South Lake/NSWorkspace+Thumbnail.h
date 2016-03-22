//
//  NSWorkspace+Thumbnail.h
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>

@interface NSWorkspace (Thumbnail)

- (NSImage*) previewForFile:(NSURL*)fileURL;

@end
