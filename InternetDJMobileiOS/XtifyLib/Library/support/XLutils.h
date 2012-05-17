/*     Xtify Utilities and global const
 //
 //  Created by Gilad on 3/1/11.
 //  Copyright 2011 Xtify. All rights reserved.
 */

#define XTLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

//app metrics
#define xAppOpen			@"AO" //APP_OPENED"
#define xAppBackground		@"AB" //APP_BACKGROUND"
#define xNotifAck			@"NSAK" //NOTIF_SIMPLE_ACK"
#define xNotifClick			@"NSCK" //NOTIF_SIMPLE_CLICKED
#define xNotifClear			@"NSCL" //NOTIF_SIMPLE_CLEARED" //applicable only when app is in the foreground 
#define xNotifDisplay		@"NSDI" //NOTIF_SIMPLE_DISPLAYED" //applicable only when app is in the foreground 
#define xRichDisplay		@"NRDI" //NOTIF_RICH_DISPLAYED"	
#define xRichShare			@"NRS" //NOTIF_RICH_SHARED"
#define xRichAction			@"NRA" //NOTIF_RICH_ACTION"
#define xRichMap			@"NRM" //NOTIF_RICH_MAP"
#define xRichDelete			@"NRDE" //NOTIF_RICH_DELETED"
#define xRichInboxClick		@"NRIC" //NOTIF_RICH_INBOX_CLICKED"

// database to use (replace if app use a different db)
#define xDefaultDb		@"RichDb"
#define REGULAR_UPDATE_TIME_INTERVAL_SECONDS  (3 * 60) //every n minutes
#define xSdkVer				@"v2.05" // internal xtify sdk version

#define xRNErrorMessage     @"Message not retrieved yet"
#define xHTMLresource       @"expireMsgTemplate"

#define xBaseUrl            @"http://sdk.api.xtify.com/2.0"  

#define xRegistrationUrl    @"users/register"
#define xUserUpdateUrl      @"users/"
#define xRichUrl            @"rn/" 
#define xLocationUrl        @"location/"
#define xMetricsUrl         @"metrics/user/"
#define xTaggingUrl         @"tags/"
