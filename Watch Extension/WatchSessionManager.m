//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSessionManager.h"
#import "WatchMessages.h"
#import "ExtensionDelegate.h"
#import "Notifications.h"
#import "Preferences.h"

@interface WatchSessionManager ()

@end


@implementation WatchSessionManager

- (void)startWatchSession
{
	self->watchSession = [WCSession defaultSession];
	self->watchSession.delegate = self;
	[self->watchSession activateSession];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];
}

- (void)sendSyncPrefsMsg
{
	NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_SYNC_PREFS, @WATCH_MSG_TYPE, nil];

	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

- (void)sendRegisterDeviceMsg
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_REGISTER_DEVICE, @WATCH_MSG_TYPE,
							 [extDelegate getDeviceId], @WATCH_MSG_DEVICE_ID,
							 nil];

	[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
}

- (void)checkIfActivitiesAreUploaded
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	size_t numHistoricalActivities = [extDelegate initializeHistoricalActivityList];

	for (size_t i = 0; i < numHistoricalActivities; ++i)
	{
		NSString* hash = [extDelegate retrieveHashForActivityIndex:i];

		if (hash)
		{
			NSDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@WATCH_MSG_CHECK_ACTIVITY, @WATCH_MSG_TYPE,
									 hash, @WATCH_MSG_ACTIVITY_HASH,
									 nil];

			[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
		}
	}
}

- (void)sendActivity:(NSString*)activityHash
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSString* activityId = [extDelegate retrieveActivityIdByHash:activityHash];
	NSInteger activityIndex = [extDelegate getActivityIndexFromActivityId:activityId];
	NSString* activityType = [extDelegate getHistoricalActivityType:activityIndex];

	if (activityId && activityType)
	{
		NSString* activityName = [extDelegate getHistoricalActivityName:activityIndex];
		NSArray* locationData = [extDelegate getHistoricalActivityLocationData:activityId];

		time_t tempStartTime = 0;
		time_t tempEndTime = 0;
		[extDelegate getHistoricalActivityStartAndEndTime:activityIndex withStartTime:&tempStartTime withEndTime:&tempEndTime];
		NSNumber* startTime = [NSNumber numberWithUnsignedLongLong:tempStartTime];
		NSNumber* endTime = [NSNumber numberWithUnsignedLongLong:tempEndTime];

		NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										@WATCH_MSG_ACTIVITY, @WATCH_MSG_TYPE,
										activityId, @WATCH_MSG_ACTIVITY_ID,
										activityType, @WATCH_MSG_ACTIVITY_TYPE,
										activityHash, @WATCH_MSG_ACTIVITY_HASH,
										startTime, @WATCH_MSG_ACTIVITY_START_TIME,
										endTime, @WATCH_MSG_ACTIVITY_END_TIME,
										nil];

		if ([activityName length] > 0)
			[msgData setObject:activityName forKey:@WATCH_MSG_ACTIVITY_NAME];
		if (locationData)
			[msgData setObject:locationData forKey:@WATCH_MSG_ACTIVITY_LOCATIONS];

		[self->watchSession sendMessage:msgData replyHandler:^(NSDictionary<NSString *,id>* replyMessage) {
		} errorHandler:^(NSError* error) {
		}];
	}
}

- (void)session:(nonnull WCSession*)session didReceiveApplicationContext:(NSDictionary<NSString*, id>*)applicationContext
{
}

- (void)session:(nonnull WCSession*)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError*)error
{
	switch (activationState)
	{
		case WCSessionActivationStateNotActivated:
			break;
		case WCSessionActivationStateInactive:
			break;
		case WCSessionActivationStateActivated:
			[self sendSyncPrefsMsg];
			[self sendRegisterDeviceMsg];
			break;
	}
}

- (void)sessionReachabilityDidChange:(nonnull WCSession*)session
{
	if (session.reachable)
	{
		[self sendRegisterDeviceMsg];
		[self checkIfActivitiesAreUploaded];
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(nonnull NSDictionary<NSString*,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString*,id> * __nonnull))replyHandler
{
	// Don't process phone messages when we're doing an activity.
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	if ([extDelegate isActivityInProgress])
	{
		return;
	}

	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];

	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The phone app wants to sync preferences.
		[Preferences importPrefs:message];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The phone app is asking the watch to register itself.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app wants to download interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The phone app wants to download pace plans.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_WORKOUT])
	{
		// The phone app is sending an interval workout.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_PACE_PLAN])
	{
		// The phone app is sending a pace plan.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
		NSString* activityHash = [message objectForKey:@WATCH_MSG_ACTIVITY_HASH];
		[self sendActivity:activityHash];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
		// The phone app is sending an activity.
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
	// Don't process phone messages when we're doing an activity.
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	if ([extDelegate isActivityInProgress])
	{
		return;
	}

	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];

	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The phone app wants to sync preferences.
		[Preferences importPrefs:message];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The phone app is asking the watch to register itself.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The phone app is sending interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The phone app is sending pace plans.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The phone app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The phone app is requesting an activity.
		NSString* activityHash = [message objectForKey:@WATCH_MSG_ACTIVITY_HASH];
		[self sendActivity:activityHash];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
		// The phone app is sending an activity.
	}
}

- (void)session:(nonnull WCSession*)session didReceiveMessageData:(NSData*)messageData
{
}

- (void)session:(nonnull WCSession*)session didReceiveMessageData:(NSData*)messageData replyHandler:(void (^)(NSData *replyMessageData))replyHandler
{
}

- (void)session:(nonnull WCSession*)session didReceiveFile:(WCSessionFile*)file
{
}

- (void)session:(nonnull WCSession*)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo
{
}

- (void)session:(nonnull WCSession*)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(NSError *)error
{
}

- (void)activityStopped:(NSNotification*)notification
{
	if (self->watchSession)
	{
		NSMutableDictionary* msgData = [[notification object] mutableCopy];

		[msgData setObject:@WATCH_MSG_CHECK_ACTIVITY forKey:@WATCH_MSG_TYPE];
		[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
	}
}

@end
