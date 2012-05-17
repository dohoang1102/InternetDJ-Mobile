/*
 * XLInboxMgr.h
 * Copyright Xtify Inc. All rights reserved.
 */


@class XLRichJsonlMessage,XRInboxVC,ASIHTTPRequest;

@interface XLInboxMgr : NSObject
{
	int lastStatusCode;
	NSString *lastMid;
	int isRetrieving;
	
}
+ (XLInboxMgr *)get;

-(int) getLastHttpStatusCode;
-(void)displayInboxTable ;
-(void) getPenddingNotifications:(NSString *)missingMids;
-(void)pushAndDisplayMessage:(NSDictionary *)pushMessage;
-(void)getRichMessage:(NSString *)urlString;
-(void) loadNotificationsToDb:(XLRichJsonlMessage *)axMessage;
- (void)successGetMessageMethod:(ASIHTTPRequest *) request ;
- (void)failureGetMessageMethod:(ASIHTTPRequest *) request ;
- (int) getInboxUnreadMessageCount ;
- (void) addEmptyMid:(NSString*)pushMid;


@end
