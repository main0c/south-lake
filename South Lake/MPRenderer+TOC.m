//
//  MPRenderer+TOC.m
//  South Lake
//
//  Created by Philip Dow on 2/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

#import "MPRenderer+TOC.h"
#import <hoedown/html.h>
#import "hoedown_html_patch.h"

extern hoedown_renderer *MPCreateHTMLTOCRenderer;

@implementation MPRenderer (TOC)

- (NSString*) tableOfContents {
    
    id<MPRendererDelegate> delegate = self.delegate;
    NSString *markdown = [self.dataSource rendererMarkdown:self];
    int flags = [delegate rendererExtensions:self];
    NSData *inputData = [markdown dataUsingEncoding:NSUTF8StringEncoding];
    
    // TOC renderer: see MPRenderer NS_INLINE hoedown_renderer *MPCreateHTMLTOCRenderer()
    
    hoedown_renderer *tocRenderer = hoedown_html_toc_renderer_new(6);
    tocRenderer->header = hoedown_patch_render_toc_header;
    
    // Create document and render toc, see MPRenderer: MPHTMLFromMarkdown
    
    hoedown_document *document = hoedown_document_new(tocRenderer, flags, SIZE_MAX);
    hoedown_buffer *ob = hoedown_buffer_new(64);
    hoedown_document_render(document, ob, inputData.bytes, inputData.length);
    
    NSString *toc = [NSString stringWithUTF8String:hoedown_buffer_cstr(ob)];
    
    // Free TOC renderer: see MPRenderer NS_INLINE void MPFreeHTMLRenderer(hoedown_renderer *htmlRenderer)
    
    hoedown_html_renderer_state_extra *extra = ((hoedown_html_renderer_state *)tocRenderer->opaque)->opaque;
    if (extra) { free(extra); }
    hoedown_html_renderer_free(tocRenderer);
    
    return toc;
}

@end
