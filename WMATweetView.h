//
// WMATweetView.h
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

#import <UIKit/UIKit.h>

//  ARC Macros created by John Blanco on 28/1/2012.

#if !defined(__clang__) || __clang_major__ < 3
#ifndef __bridge
#define __bridge
#endif

#ifndef __bridge_retain
#define __bridge_retain
#endif

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __autoreleasing
#define __autoreleasing
#endif

#ifndef __strong
#define __strong
#endif

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#ifndef __weak
#define __weak
#endif
#endif

#if __has_feature(objc_arc)
#define SAFE_ARC_PROP_RETAIN strong
#define SAFE_ARC_RETAIN(x) (x)
#define SAFE_ARC_RELEASE(x)
#define SAFE_ARC_AUTORELEASE(x) (x)
#define SAFE_ARC_BLOCK_COPY(x) (x)
#define SAFE_ARC_BLOCK_RELEASE(x)
#define SAFE_ARC_SUPER_DEALLOC()
#define SAFE_ARC_AUTORELEASE_POOL_START() @autoreleasepool {
#define SAFE_ARC_AUTORELEASE_POOL_END() }
#else
#define SAFE_ARC_PROP_RETAIN retain
#define SAFE_ARC_COPY(x) ([(x) copy])
#define SAFE_ARC_RETAIN(x) ([(x) retain])
#define SAFE_ARC_RELEASE(x) ([(x) release])
#define SAFE_ARC_AUTORELEASE(x) ([(x) autorelease])
#define SAFE_ARC_BLOCK_COPY(x) (Block_copy(x))
#define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#define SAFE_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define SAFE_ARC_AUTORELEASE_POOL_END() [pool release];
#endif

@interface WMATweetEntity : NSObject
@property (nonatomic, readonly) NSUInteger start;
@property (nonatomic, readonly) NSUInteger end;
@end

@interface WMATweetURLEntity : WMATweetEntity
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSURL *URL;
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSURL *expandedURL;
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *displayURL;
+ (WMATweetURLEntity *)entityWithURL:(NSURL *)url start:(NSUInteger)start end:(NSUInteger)end;
+ (WMATweetURLEntity *)entityWithURL:(NSURL *)url expandedURL:(NSURL *)expandedURL displayURL:(NSString *)displayURL start:(NSUInteger)start end:(NSUInteger)end;
- (id)initWithURL:(NSURL *)url expandedURL:(NSURL *)expandedURL displayURL:(NSString *)displayURL start:(NSUInteger)start end:(NSUInteger)end;
@end

@interface WMATweetHashtagEntity : WMATweetEntity
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *text;
+ (WMATweetURLEntity *)entityWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end;
- (id)initWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end;
@end

@interface WMATweetUserMentionEntity : WMATweetEntity
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *name;
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *screenName;
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *idString;
+ (WMATweetUserMentionEntity *)entityWithScreenName:(NSString *)screenName name:(NSString *)name idString:(NSString *)idString start:(NSUInteger)start end:(NSUInteger)end;
+ (WMATweetUserMentionEntity *)entityWithScreenName:(NSString *)screenName start:(NSUInteger)start end:(NSUInteger)end;
- (id)initWithScreenName:(NSString *)screenName name:(NSString *)name idString:(NSString *)idString start:(NSUInteger)start end:(NSUInteger)end;
@end

@interface WMATweetAmpEntity : WMATweetEntity
@property (nonatomic, readonly, SAFE_ARC_PROP_RETAIN) NSString *text;
+ (WMATweetAmpEntity *)entityWithStart:(NSUInteger)start end:(NSUInteger)end;
- (id)initWithText:(NSString *)text start:(NSUInteger)start end:(NSUInteger)end;
@end

@interface WMATweetView : UIView <UIGestureRecognizerDelegate>
typedef void (^URLEntityTappedCallbackBlock)(WMATweetURLEntity *entity, NSUInteger numberOfTouches);
typedef void (^HashtagEntityTappedCallbackBlock)(WMATweetHashtagEntity *entity, NSUInteger numberOfTouches);
typedef void (^UserMentionEntityTappedCallbackBlock)(WMATweetUserMentionEntity *entity, NSUInteger numberOfTouches);
@property (nonatomic, SAFE_ARC_PROP_RETAIN) NSString *text;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) NSDictionary *tweet;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) NSArray *entities;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIColor *textColor;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIFont *textFont;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIColor *urlColor;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIFont *urlFont;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIColor *hashtagColor;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIFont *hashtagFont;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIColor *userMentionColor;
@property (nonatomic, SAFE_ARC_PROP_RETAIN) UIFont *userMentionFont;
@property (nonatomic, copy) URLEntityTappedCallbackBlock urlTapped;
@property (nonatomic, copy) HashtagEntityTappedCallbackBlock hashtagTapped;
@property (nonatomic, copy) UserMentionEntityTappedCallbackBlock userMentionTapped;
- (id)initWithTweet:(NSDictionary *)tweet frame:(CGRect)frame;
- (id)initWithText:(NSString *)text frame:(CGRect)frame;
@end
