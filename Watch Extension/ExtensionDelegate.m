//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "ExtensionDelegate.h"
#import "ActivityMgr.h"

#define DATABASE_NAME "Activities.sqlite"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching
{
	NSArray*  paths      = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docDir     = [paths objectAtIndex: 0];
	NSString* dbFileName = [docDir stringByAppendingPathComponent:@DATABASE_NAME];
	
	Initialize([dbFileName UTF8String]);
}

- (void)applicationDidBecomeActive
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks
{
	// Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
	for (WKRefreshBackgroundTask* task in backgroundTasks)
	{
		// Check the Class of each task to decide how to process it
		if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]])
		{
			// Snapshot tasks have a unique completion call, make sure to set your expiration date
			WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
			[snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
		}
		else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]])
		{
			// Be sure to complete the background task once you’re done.
			WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
			[backgroundTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKRelevantShortcutRefreshBackgroundTask class]])
		{
			// Be sure to complete the relevant-shortcut task once you’re done.
			WKRelevantShortcutRefreshBackgroundTask *relevantShortcutTask = (WKRelevantShortcutRefreshBackgroundTask*)task;
			[relevantShortcutTask setTaskCompletedWithSnapshot:NO];
		}
		else if ([task isKindOfClass:[WKIntentDidRunRefreshBackgroundTask class]])
		{
			// Be sure to complete the intent-did-run task once you’re done.
			WKIntentDidRunRefreshBackgroundTask *intentDidRunTask = (WKIntentDidRunRefreshBackgroundTask*)task;
			[intentDidRunTask setTaskCompletedWithSnapshot:NO];
		}
		else
		{
			// make sure to complete unhandled task types
			[task setTaskCompletedWithSnapshot:NO];
		}
	}
}

#pragma mark sensor methods

- (void)stopSensors
{
}

- (void)startSensors
{
}

#pragma mark accessor methods

void activityTypeCallback(const char* type, void* context)
{
	NSMutableArray* types = (__bridge NSMutableArray*)context;
	[types addObject:[[NSString alloc] initWithUTF8String:type]];
}

- (NSMutableArray*)getActivityTypes
{
	NSMutableArray* types = [[NSMutableArray alloc] init];
	if (types)
	{
		GetActivityTypes(activityTypeCallback, (__bridge void*)types);
	}
	return types;
}

@end
