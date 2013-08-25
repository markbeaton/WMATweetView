//
// WMATweetView.m
//
// Copyright (c) 2012 Mark Beaton. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "WMATweetView.h"
#import <CoreText/CoreText.h>

@interface WMATweetView () <UIGestureRecognizerDelegate>
{
	CTFontRef _textFontRef;
	CTFontRef _urlFontRef;
	CTFontRef _hashtagFontRef;
	CTFontRef _userMentionFontRef;
}
@property (nonatomic, SAFE_ARC_PROP_RETAIN) NSMutableAttributedString *attributedString;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) NSArray *sortedEntities;
@property (nonatomic, assign) CTFramesetterRef framesetter;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UITapGestureRecognizer* tapGestureRecognizer;
- (void)setupDefaults;
- (void)setDirty;
@end

@interface WMATweetEntity ()
@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger end;
@property (nonatomic, assign) NSUInteger startWithOffset;
@property (nonatomic, assign) NSUInteger endWithOffset;
- (id)initWithStart:(NSUInteger)start end:(NSUInteger)end;
@end



#pragma mark -

@implementation WMATweetView



#pragma mark ivar synthesis

@synthesize attributedString = _attributedString;
@synthesize text = _text;
@synthesize entities = _entities;
@synthesize sortedEntities;
@synthesize textColor = _textColor;
@synthesize textFont = _textFont;
@synthesize urlColor = _urlColor;
@synthesize urlFont = _urlFont;
@synthesize hashtagColor = _hashtagColor;
@synthesize hashtagFont = _hashtagFont;
@synthesize userMentionColor = _userMentionColor;
@synthesize userMentionFont = _userMentionFont;
@synthesize framesetter = _framesetter;
@synthesize urlTapped = _urlTapped;
@synthesize hashtagTapped = _hashtagTapped;
@synthesize userMentionTapped = _userMentionTapped;



#pragma mark Initialisation & Deallocation

- (id)init
{
	if ((self = [super init]) != nil)
	{
		[self setupDefaults];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder])
	{
		[self setupDefaults];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self setupDefaults];
	}
	return self;
}

- (id)initWithTweet:(NSDictionary *)tweet frame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self setupDefaults];
		self.tweet = tweet;
	}
	return self;
}

- (id)initWithText:(NSString *)text frame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self setupDefaults];
		self.text = text;
	}
	return self;
}

- (void)dealloc
{
	if (_textFontRef != NULL) CFRelease(_textFontRef);
	if (_urlFontRef != NULL) CFRelease(_urlFontRef);
	if (_hashtagFontRef != NULL) CFRelease(_hashtagFontRef);
	if (_userMentionFontRef != NULL) CFRelease(_userMentionFontRef);
	if (_framesetter != NULL) CFRelease(_framesetter);
	SAFE_ARC_RELEASE(_urlTapped);
	SAFE_ARC_RELEASE(_hashtagTapped);
	SAFE_ARC_RELEASE(_userMentionTapped);
	SAFE_ARC_SUPER_DEALLOC();
}



#pragma mark Accessors

- (void)setText:(NSString *)text
{
	if (text != _text)
	{
		SAFE_ARC_RELEASE(_text);
		_text = SAFE_ARC_RETAIN(text);
		self.entities = nil;
		[self setDirty];
	}
}

- (void)setTweet:(NSDictionary *)tweet
{
	if (tweet != _tweet)
	{
		SAFE_ARC_RELEASE(_tweet);
		_tweet = SAFE_ARC_RETAIN(tweet);
		self.text = [tweet valueForKey:@"text"];
		
		NSString *str = self.text;
		NSString *searchString = @"&amp;";
		NSMutableArray *amps = [NSMutableArray array];
		NSRange searchRange = NSMakeRange(0, [str length]);
		NSRange range;
		while ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound)
		{
			NSNumber *start = [NSNumber numberWithInteger:range.location];
			NSNumber *end = [NSNumber numberWithInteger:range.location+range.length];
			NSArray *ampIndices = [[NSArray alloc] initWithObjects: start, end, nil];
			
			NSDictionary *ampEntity = [[NSDictionary alloc] initWithObjectsAndKeys:ampIndices, @"indices", nil];
			
			[amps addObject:ampEntity];
			
			searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
		}
		
		NSMutableArray *entities = [NSMutableArray array];
		
		for (NSDictionary *tweetEntity in [[tweet valueForKey:@"entities"] valueForKey:@"urls"])
		{
			[entities addObject:[WMATweetURLEntity entityWithURL:[NSURL URLWithString:[tweetEntity valueForKey:@"url"]] expandedURL:[NSURL URLWithString:[tweetEntity valueForKey:@"expanded_url"]] displayURL:[tweetEntity valueForKey:@"display_url"] start:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:0] unsignedIntegerValue] end:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:1] unsignedIntegerValue]]];
		}
		for (NSDictionary *tweetEntity in [[tweet valueForKey:@"entities"] valueForKey:@"media"])
		{
			[entities addObject:[WMATweetURLEntity entityWithURL:[NSURL URLWithString:[tweetEntity valueForKey:@"url"]] expandedURL:[NSURL URLWithString:[tweetEntity valueForKey:@"expanded_url"]] displayURL:[tweetEntity valueForKey:@"display_url"] start:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:0] unsignedIntegerValue] end:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:1] unsignedIntegerValue]]];
		}
		for (NSDictionary *tweetEntity in [[tweet valueForKey:@"entities"] valueForKey:@"hashtags"])
		{
			[entities addObject:[WMATweetHashtagEntity entityWithText:[tweetEntity valueForKey:@"text"] start:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:0] unsignedIntegerValue] end:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:1] unsignedIntegerValue]]];
		}
		for (NSDictionary *tweetEntity in [[tweet valueForKey:@"entities"] valueForKey:@"user_mentions"])
		{
			[entities addObject:[WMATweetUserMentionEntity entityWithScreenName:[tweetEntity valueForKey:@"screen_name"] name:[tweetEntity valueForKey:@"name"] idString:[tweetEntity valueForKey:@"id_str"] start:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:0] unsignedIntegerValue] end:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:1] unsignedIntegerValue]]];
		}
		for (NSDictionary *tweetEntity in amps)
		{
			[entities addObject:[WMATweetAmpEntity entityWithStart:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:0] unsignedIntegerValue] end:[[[tweetEntity valueForKey:@"indices"] objectAtIndex:1] unsignedIntegerValue]]];
		}
		self.entities = entities;
	}
}

- (void)setEntities:(NSArray *)entities
{
	if (entities != _entities)
	{
		SAFE_ARC_RELEASE(_entities);
		_entities = SAFE_ARC_RETAIN(entities);
		self.sortedEntities = nil;
		[self setDirty];
	}
}

- (void)setTextColor:(UIColor *)textColor
{
	if (textColor != _textColor)
	{
		SAFE_ARC_RELEASE(_textColor);
		_textColor = SAFE_ARC_RETAIN(textColor);
		[self setDirty];
	}
}

- (void)setTextFont:(UIFont *)textFont
{
	if (textFont != _textFont)
	{
		SAFE_ARC_RELEASE(_textFont);
		_textFont = SAFE_ARC_RETAIN(textFont);
		if (_textFontRef != NULL) CFRelease(_textFontRef);
		if (textFont != nil) _textFontRef = CTFontCreateWithName((__bridge CFStringRef)textFont.fontName, textFont.pointSize, NULL);
		[self setDirty];
	}
}

- (void)setUrlFont:(UIFont *)urlFont
{
	if (urlFont != _urlFont)
	{
		SAFE_ARC_RELEASE(_urlFont);
		_urlFont = SAFE_ARC_RETAIN(urlFont);
		if (_urlFontRef != NULL) CFRelease(_urlFontRef);
		if (urlFont != nil) _urlFontRef = CTFontCreateWithName((__bridge CFStringRef)urlFont.fontName, urlFont.pointSize, NULL);
		[self setDirty];
	}
}

- (void)setUrlColor:(UIColor *)urlColor
{
	if (urlColor != _urlColor)
	{
		SAFE_ARC_RELEASE(_urlColor);
		_urlColor = SAFE_ARC_RETAIN(urlColor);
		[self setDirty];
	}
}

- (void)setHashtagFont:(UIFont *)hashtagFont
{
	if (hashtagFont != _hashtagFont)
	{
		SAFE_ARC_RELEASE(_hashtagFont);
		_hashtagFont = SAFE_ARC_RETAIN(hashtagFont);
		if (_hashtagFontRef != NULL) CFRelease(_hashtagFontRef);
		if (hashtagFont != nil) _hashtagFontRef = CTFontCreateWithName((__bridge CFStringRef)hashtagFont.fontName, hashtagFont.pointSize, NULL);
		[self setDirty];
	}
}

- (void)setHashtagColor:(UIColor *)hashtagColor
{
	if (hashtagColor != _hashtagColor)
	{
		SAFE_ARC_RELEASE(_hashtagColor);
		_hashtagColor = SAFE_ARC_RETAIN(hashtagColor);
		[self setDirty];
	}
}

- (void)setUserMentionFont:(UIFont *)userMentionFont
{
	if (userMentionFont != _userMentionFont)
	{
		SAFE_ARC_RELEASE(_userMentionFont);
		_userMentionFont = SAFE_ARC_RETAIN(userMentionFont);
		if (_userMentionFontRef != NULL) CFRelease(_userMentionFontRef);
		if (userMentionFont != nil) _userMentionFontRef = CTFontCreateWithName((__bridge CFStringRef)userMentionFont.fontName, userMentionFont.pointSize, NULL);
		[self setDirty];
	}
}

- (void)setUserMentionColor:(UIColor *)userMentionColor
{
	if (userMentionColor != _userMentionColor)
	{
		SAFE_ARC_RELEASE(_userMentionColor);
		_userMentionColor = SAFE_ARC_RETAIN(userMentionColor);
		[self setDirty];
	}
}

- (CTFramesetterRef)framesetter
{
	if (_framesetter == NULL)
	{
		_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)self.attributedString);
	}
	return _framesetter;
}



#pragma mark Drawing

- (CGSize)sizeThatFits:(CGSize)size
{
	size.height = CGFLOAT_MAX;
	return CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, 0), NULL, size, NULL);
}

- (void)drawRect:(CGRect)rect
{
	if (self.attributedString != nil)
	{
		CGContextRef context = UIGraphicsGetCurrentContext();
		[self.backgroundColor set];
		CGContextFillRect(context, rect);
		CGContextTranslateCTM(context, 0.0f, rect.size.height);
		CGContextScaleCTM(context, 1.0f, -1.0f);
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, rect);
		CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
		CTFrameDraw(frame, context);
		CFRelease(frame);
		CGPathRelease(path);
	}
}



#pragma mark UITapGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer == self.tapGestureRecognizer)
	{
		WMATweetEntity* entity = [self entityForGestureRecognizer:self.tapGestureRecognizer];
		return (entity != nil);
	}
	else
	{
		return YES;
	}
}

- (void)viewTapped:(UITapGestureRecognizer *)tapRecognizer
{
	if (tapRecognizer.state != UIGestureRecognizerStateEnded)
	{
		return;
	}
    
	WMATweetEntity* entity = [self entityForGestureRecognizer:tapRecognizer];
	
	if ([entity isKindOfClass:[WMATweetURLEntity class]] && self.urlTapped != NULL)
	{
		self.urlTapped((WMATweetURLEntity *)entity, tapRecognizer.numberOfTouches);
	}
	else if ([entity isKindOfClass:[WMATweetHashtagEntity class]] && self.hashtagTapped != NULL)
	{
		self.hashtagTapped((WMATweetHashtagEntity *)entity, tapRecognizer.numberOfTouches);
	}
	else if ([entity isKindOfClass:[WMATweetUserMentionEntity class]] && self.userMentionTapped != NULL)
	{
		self.userMentionTapped((WMATweetUserMentionEntity *)entity, tapRecognizer.numberOfTouches);
	}
}

- (WMATweetEntity*)entityForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
{
	WMATweetEntity* returnEntity = nil;
	CGPoint point = [gestureRecognizer locationInView:self];
	
	if (CGRectContainsPoint(self.bounds, point))
	{
		point.y = CGRectGetHeight(self.bounds) - point.y;
		
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, self.bounds);
		CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
		CFArrayRef lines = CTFrameGetLines(frame);
		CFIndex lineCount = CFArrayGetCount(lines);
		CGPoint origins[lineCount];
		CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
		BOOL found = NO;
		for (int i = 0; i < lineCount; i++)
		{
			CTLineRef line = CFArrayGetValueAtIndex(lines, i);
			CGFloat lineAscent, lineDescent;
			CGFloat lineWidth = (CGFloat)CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
			CGRect lineBounds = (CGRect){ origins[i], { lineWidth, lineAscent + lineDescent } };
			if (CGRectContainsPoint(lineBounds, point))
			{
				CFIndex lineCharIndex = CTLineGetStringIndexForPosition(line, point);
				CFArrayRef runs = CTLineGetGlyphRuns(line);
				for (int j = 0; j < CFArrayGetCount(runs); j++)
				{
					CTRunRef run = CFArrayGetValueAtIndex(runs, j);
					NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
					WMATweetEntity *entity = [attributes objectForKey:@"TweetEntity"];
					if (entity != nil && entity.startWithOffset <= lineCharIndex && entity.endWithOffset >= lineCharIndex)
					{
						returnEntity = entity;
						found = YES;
						break;
					}
				}
			}
			if (found) break;
		}
		CFRelease(path);
		CFRelease(frame);
	}
	
	return returnEntity;
}


#pragma mark Private implementation

- (void)setupDefaults
{
	self.backgroundColor = [UIColor whiteColor];
	self.tapGestureRecognizer = SAFE_ARC_AUTORELEASE([[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]);
	self.tapGestureRecognizer.delegate = self;
	[self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setDirty
{
	self.attributedString = nil;
	if (_framesetter != NULL)
	{
		CFRelease(_framesetter);
		_framesetter = NULL;
	}
	[self setNeedsDisplay];
}

- (NSAttributedString *)attributedString
{
	if (_attributedString == nil && self.text != nil)
	{
		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.text];
        
		// We're replacing text in entities, so we need to recalculate ranges
		if (self.sortedEntities == nil)
		{
			self.sortedEntities = [self.entities sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
			{
				if (((WMATweetEntity *)obj1).start < ((WMATweetEntity *)obj2).start)
					 return NSOrderedAscending;
				else if (((WMATweetEntity *)obj1).start > ((WMATweetEntity *)obj2).start)
					 return NSOrderedDescending;
				else
					 return NSOrderedSame;
			}];
		}
		NSInteger rangeStartOffset = 0;
		
		// Parse entities
		for (WMATweetEntity *entity in sortedEntities)
		{
			NSRange range = NSMakeRange(entity.start + rangeStartOffset, (entity.end - entity.start));
			if ([entity isKindOfClass:[WMATweetURLEntity class]])
			{
				WMATweetURLEntity *urlEntity = (WMATweetURLEntity *)entity;
				if (urlEntity.expandedURL != nil && urlEntity.displayURL != nil)
				{
					NSString *displayURL = urlEntity.displayURL;
					[attributedString replaceCharactersInRange:range withString:displayURL];
					entity.startWithOffset = entity.start + rangeStartOffset;
					entity.endWithOffset = entity.startWithOffset + [urlEntity.displayURL length];
					rangeStartOffset += [urlEntity.displayURL length] - range.length;
				}
			}
			else if ([entity isKindOfClass:[WMATweetAmpEntity class]])
			{
				NSString *displayAmp = @"&";
				[attributedString replaceCharactersInRange:range withString:displayAmp];
				entity.startWithOffset = entity.start + rangeStartOffset;
				entity.endWithOffset = entity.startWithOffset + [displayAmp length];
				rangeStartOffset += [displayAmp length] - range.length;
			}
			else
			{
				entity.startWithOffset = entity.start + rangeStartOffset;
				entity.endWithOffset = entity.end + rangeStartOffset;
			}
		}
		
		// Set default attributes
		UIColor *textColor = self.textColor;
		if (textColor == nil) textColor = [UIColor blackColor];
		UIFont *textFont = self.textFont;
		if (textFont == nil) textFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		if (_textFontRef == NULL) _textFontRef = CTFontCreateWithName((__bridge CFStringRef)textFont.fontName, textFont.pointSize, NULL);
		[attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)textColor.CGColor range:NSMakeRange(0, [attributedString length])];
		[attributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)_textFontRef range:NSMakeRange(0, [attributedString length])];
		
		// Set attributes for entities
		UIColor *defaultLinkColour = [UIColor blueColor];
		UIColor *urlColor = (self.urlColor  != nil ? self.urlColor : defaultLinkColour);
		UIColor *hashtagColor = (self.hashtagColor  != nil ? self.hashtagColor : defaultLinkColour);
		UIColor *userMentionColor = (self.userMentionColor  != nil ? self.userMentionColor : defaultLinkColour);
		UIFont *urlFont = (self.urlFont != nil ? self.urlFont : textFont);
		UIFont *hashtagFont = (self.hashtagFont != nil ? self.hashtagFont : textFont);
		UIFont *userMentionFont = (self.userMentionFont != nil ? self.userMentionFont : textFont);
		if (_urlFontRef == NULL) _urlFontRef = CTFontCreateWithName((__bridge CFStringRef)urlFont.fontName, urlFont.pointSize, NULL);
		if (_hashtagFontRef == NULL) _hashtagFontRef = CTFontCreateWithName((__bridge CFStringRef)hashtagFont.fontName, hashtagFont.pointSize, NULL);
		if (_userMentionFontRef == NULL) _userMentionFontRef = CTFontCreateWithName((__bridge CFStringRef)userMentionFont.fontName, userMentionFont.pointSize, NULL);
		for (WMATweetEntity *entity in sortedEntities)
		{
			NSRange range = NSMakeRange(entity.startWithOffset, (entity.endWithOffset - entity.startWithOffset));
			[attributedString addAttribute:@"TweetEntity" value:entity range:range];
			UIColor *entityColor = nil;
			CTFontRef entityFont = NULL;
			if ([entity isKindOfClass:[WMATweetURLEntity class]])
			{
				entityColor = urlColor;
				entityFont = _urlFontRef;
			}
			else if ([entity isKindOfClass:[WMATweetHashtagEntity class]])
			{
				entityColor = hashtagColor;
				entityFont = _hashtagFontRef;
			}
			else if ([entity isKindOfClass:[WMATweetUserMentionEntity class]])
			{
				entityColor = userMentionColor;
				entityFont = _userMentionFontRef;
			}
			else if ([entity isKindOfClass:[WMATweetAmpEntity class]])
			{
				entityColor = textColor;
				entityFont = _textFontRef;
			}
			[attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)entityColor.CGColor range:range];
			[attributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)entityFont range:range];
		}
		_attributedString = attributedString;
	}
	return _attributedString;
}

@end



#pragma mark -

@implementation WMATweetEntity

@synthesize start = _start;
@synthesize end = _end;
@synthesize startWithOffset = _startWithOffset;
@synthesize endWithOffset = _endWithOffset;

- (id)initWithStart:(NSUInteger)start end:(NSUInteger)end
{
	if ((self = [super init]) != nil)
	{
		_start = start;
		_end = end;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@,\n  indexes: { start: %d, end: %d, startWithOffset: %d, endWithOffset: %d }", [super description], self.start, self.end, self.startWithOffset, self.endWithOffset];
}

@end



#pragma mark -

@implementation WMATweetURLEntity

@synthesize URL = _URL;
@synthesize expandedURL = _expandedURL;
@synthesize displayURL = _displayURL;

+ (WMATweetURLEntity *)entityWithURL:(NSURL *)url expandedURL:(NSURL *)expandedURL displayURL:(NSString *)displayURL start:(NSUInteger)start end:(NSUInteger)end
{
	return SAFE_ARC_AUTORELEASE([[WMATweetURLEntity alloc] initWithURL:url expandedURL:expandedURL displayURL:displayURL start:start end:end]);
}

+ (WMATweetURLEntity *)entityWithURL:(NSURL *)url start:(NSUInteger)start end:(NSUInteger)end
{
	return [WMATweetURLEntity entityWithURL:url expandedURL:nil displayURL:nil start:start end:end];
}

- (id)initWithURL:(NSURL *)url expandedURL:(NSURL *)expandedURL displayURL:(NSString *)displayURL start:(NSUInteger)start end:(NSUInteger)end
{
	if ((self = [super initWithStart:start end:end]) != nil)
	{
		_URL = SAFE_ARC_RETAIN(url);
		_expandedURL = SAFE_ARC_RETAIN(expandedURL);
		_displayURL = [displayURL copy];
	}
	return self;
}

- (void)dealloc
{
	SAFE_ARC_RELEASE(_URL);
	SAFE_ARC_RELEASE(_expandedURL);
	SAFE_ARC_RELEASE(_displayURL);
	SAFE_ARC_SUPER_DEALLOC();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@,\n  URL: %@,\n  displayURL: %@,\n  expandedURL: %@", [super description], self.URL, self.displayURL, self.expandedURL];
}

@end



#pragma mark -

@implementation WMATweetHashtagEntity

@synthesize text = _text;

+ (WMATweetEntity *)entityWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end
{
	return SAFE_ARC_AUTORELEASE([[WMATweetHashtagEntity alloc] initWithText:text start:start end:end]);
}

- (id)initWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end
{
	if ((self = [super initWithStart:start end:end]) != nil)
	{
		_text = [text copy];
	}
	return self;
}

- (void)dealloc
{
	SAFE_ARC_RELEASE(_text);
	SAFE_ARC_SUPER_DEALLOC();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@,\n  text: %@", [super description], self.text];
}

@end



#pragma mark -

@implementation WMATweetUserMentionEntity

@synthesize name = _name;
@synthesize screenName = _screenName;
@synthesize idString = _idString;

+ (WMATweetUserMentionEntity *)entityWithScreenName:(NSString *)screenName name:(NSString *)name idString:(NSString *)idString start:(NSUInteger)start end:(NSUInteger)end
{
	return SAFE_ARC_AUTORELEASE([[WMATweetUserMentionEntity alloc] initWithScreenName:screenName name:name idString:idString start:start end:end]);
}

+ (WMATweetUserMentionEntity *)entityWithScreenName:(NSString *)screenName start:(NSUInteger)start end:(NSUInteger)end
{
	return [WMATweetUserMentionEntity entityWithScreenName:screenName name:nil idString:nil start:start end:end];
}

- (id)initWithScreenName:(NSString *)screenName name:(NSString *)name idString:(NSString *)idString start:(NSUInteger)start end:(NSUInteger)end
{
	if ((self = [super initWithStart:start end:end]) != nil)
	{
		_name = [name copy];
		_screenName = [screenName copy];
		_idString = [idString copy];
	}
	return self;
}

+ (WMATweetEntity *)entityWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end
{
	return SAFE_ARC_AUTORELEASE([[WMATweetHashtagEntity alloc] initWithText:text start:start end:end]);
}

- (void)dealloc
{
	SAFE_ARC_RELEASE(_name);
	SAFE_ARC_RELEASE(_screenName);
	SAFE_ARC_RELEASE(_idString);
	SAFE_ARC_SUPER_DEALLOC();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@,\n  screenName: %@,\n  name: %@,\n  id: %@", [super description], self.screenName, self.name, self.idString];
}

@end

#pragma mark -

@implementation WMATweetAmpEntity

@synthesize text = _text;

+ (WMATweetAmpEntity *)entityWithStart:(NSUInteger)start end:(NSUInteger)end
{
	return SAFE_ARC_AUTORELEASE([[WMATweetAmpEntity alloc] initWithText:@"&amp;" start:start end:end]);
}

- (id)initWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end
{
	if ((self = [super initWithStart:start end:end]) != nil)
	{
		_text = [text copy];
	}
	return self;
}

- (void)dealloc
{
	SAFE_ARC_RELEASE(_text);
	SAFE_ARC_SUPER_DEALLOC();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@", [super description]];
}

@end

