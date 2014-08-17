#pragma mark - Chat

#define kKATGChatURLString @"http://www.keithandthegirl.com/chat/chat.aspx"

#pragma mark - Data

#define kKATGShowEntityName @"Show"
#define kKATGImageEntityName @"Image"
#define kKATGGuestEntityName @"Guest"

#pragma mark - API

static NSString * const kReachabilityURL = @"www.keithandthegirl.com";

//static NSString * const kTestServerBaseURL = @"http://protected-savannah-5921.herokuapp.com";
static NSString * const kServerBaseURL = @"https://www.keithandthegirl.com/api/v2/";
static NSString * const kSeriesListURIAddress		=	@"shows/series-overview/";
static NSString * const kShowListURIAddress		=	@"shows/list/";
static NSString * const kShowDetailsURIAddress	=	@"shows/details/?showid=%@";

static NSString * const kUpcomingURIAddress		=	@"events?sanitize=true";

static NSString * const kLiveShowStatusURIAddress = @"feed/live/";

static NSString * const kCacheForceRefreshURIAddress = @"/cache/force-refresh";

static NSString * const kFeedbackURL = @"http://www.attackwork.com/Voxback/Comment-Form-Iframe.aspx";