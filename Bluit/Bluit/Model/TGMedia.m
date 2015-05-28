//
//  TGMedia.m
//  redditPad
//
//  Created by Tom Graham on 28/05/2015.
//  Copyright (c) 2015 Tom Graham. All rights reserved.
//

#import "TGMedia.h"

@implementation TGMedia

- (TGMediaType) type
{
	if (_type == TGMediaTypeUnknown) // TODO use MIME type
	{
		NSString *urlFileExtension = _url.lastPathComponent.pathExtension;
		
		if (urlFileExtension != nil)
		{
			if ([urlFileExtension isEqualToString:@"png"] || [urlFileExtension isEqualToString:@"jpg"] || [urlFileExtension isEqualToString:@"jpeg"]) _type = TGMediaTypeImage;
			else if ([urlFileExtension isEqualToString:@"mp4"]) _type = TGMediaTypeVideo;
			else if ([urlFileExtension isEqualToString:@"gif"]) _type = TGMediaTypeGif;
		}
	}
	
	return _type;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"URL: %@, type: %lu, size: %fx%f \ntitle: \"%@\" \ncaption:\"%@\"", _url, (unsigned long)_type, _size.width, _size
			.height, _title, _caption];
}

@end
