# WMATweetView

This is a self-contained UIView subclass that renders the text portion of a tweet according to Twitter's guidelines at [https://dev.twitter.com/terms/display-guidelines](https://dev.twitter.com/terms/display-guidelines). 

It parses the following tweet entities & provides callbacks for tap gestures:

- URLs
- \#Hashtags
- User @mentions

The callbacks are passed a WMATweetEntity subclass that contains all of the data you'll need to process the tap according to Twitter's guidelines.

**Note: this view only renders the tweet text - you're responsible for adding avatars, author names, dates etc. But that's the easy part!**

## Supported iOS versions/ARC support

The code should work on iOS 4.0 and above. It might even work on iOS 3.2 (when CoreText was made public), although I haven't tested that at all.

It also supports including in both ARC and non-ARC Xcode projects - you don't have to set any flags, it's all handled via compile-time macros (thanks to [John Blanco](http://raptureinvenice.com/arc-support-without-branches/)).

## Example usage

Once you've added the <code>WMATweetView.h</code> & <code>WMATweetView.m</code> files to your Xcode project, you'll need to add a reference to CoreText.framework as well.

Currently, there are two ways to initialise the view:

### From an NSDictionary

This is the easiest option - assuming you've got an <code>NSDictionary</code> instance containing the tweet data (i.e. from Twitter's API), you can just pass that to the view's <code>initWithTweet:</code> initialiser. Contrived example:

<code>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Set up window
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor whiteColor];
	
	// Get tweet dictionary from JSON - typicallthis would come from Twitter's API rather than a resource file...
	NSData *tweetData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tweet" ofType:@"json"]];
	NSDictionary *tweet = [NSJSONSerialization JSONObjectWithData:tweetData options:0 error:NULL];
	
	// Build & add tweet view - let's emulate Tweetbot
	WMATweetView *tweetView = [[WMATweetView alloc] initWithTweet:tweet frame:CGRectMake(10, 30, 300, 300)];
	tweetView.backgroundColor = [UIColor colorWithRed:0.906 green:0.945 blue:0.980 alpha:1.];
	tweetView.textColor = [UIColor colorWithRed:0.176 green:0.306 blue:0.431 alpha:1.];
	tweetView.textFont = [UIFont systemFontOfSize:12];
	tweetView.urlColor = [UIColor colorWithRed:0.153 green:0.431 blue:0.702 alpha:1.];
	tweetView.hashtagColor = [UIColor colorWithRed:0.518 green:0.600 blue:0.690 alpha:1.];
	tweetView.userMentionColor = [UIColor colorWithRed:0.267 green:0.349 blue:0.427 alpha:1.];
	tweetView.userMentionFont = [UIFont boldSystemFontOfSize:12];
	[self.window addSubview:tweetView];
	[tweetView sizeToFit];

	// Add tap gesture handlers for parsed tweet entities
	tweetView.urlTapped = ^(WMATweetURLEntity *entity, NSUInteger numberOfTouches)
	{
		NSLog(@"Tapped entity: %@", entity);
	};
	tweetView.hashtagTapped = ^(WMATweetHashtagEntity *entity, NSUInteger numberOfTouches)
	{
		NSLog(@"Tapped entity: %@", entity);
	};
	tweetView.userMentionTapped = ^(WMATweetUserMentionEntity *entity, NSUInteger numberOfTouches)
	{
		NSLog(@"Tapped entity: %@", entity);
	};
	
	// Go!
	[self.window makeKeyAndVisible];
	return YES;
}
</code>