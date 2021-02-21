// Created by Michael Simms on 7/29/19.
// Copyright © 2019 Michael J Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ActivityAttribute.h"
#import "ActivityHash.h"
#import "ActivityMgr.h"
#import "HashUtils.h"
#import "StringUtils.h"

@implementation ActivityHash

- (id)init
{
	self = [super init];
	return self;
}

NSString* NumToFloatStringForHashing(NSNumber* num)
{
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setPaddingCharacter:@"0"];
	[formatter setMinimumFractionDigits:6];
	[formatter setMaximumFractionDigits:6];
	return [formatter stringFromNumber:num];
}

void GpsDataHashCallback(const char* activityId, void* context)
{
	ActivityAttributeType latValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_LATITUDE);
	ActivityAttributeType lonValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_LONGITUDE);
	ActivityAttributeType altValue = QueryHistoricalActivityAttributeById(activityId, ACTIVITY_ATTRIBUTE_ALTITUDE);

	if (latValue.valid && lonValue.valid && altValue.valid)
	{
		CC_SHA512_CTX* ctx = (CC_SHA512_CTX*)context;

		NSNumber* time = [NSNumber numberWithLongLong:latValue.startTime];
		NSNumber* latitude = [NSNumber numberWithDouble:latValue.value.doubleVal];
		NSNumber* longitude = [NSNumber numberWithDouble:lonValue.value.doubleVal];
		NSNumber* altitude = [NSNumber numberWithDouble:altValue.value.doubleVal];
		
		NSString* timeStr = [time stringValue];
		NSString* latitudeStr = NumToFloatStringForHashing(latitude);
		NSString* longitudeStr = NumToFloatStringForHashing(longitude);
		NSString* altitudeStr = NumToFloatStringForHashing(altitude);
		
		CC_SHA512_Update(ctx, [timeStr UTF8String], (CC_LONG)[timeStr length]);
		CC_SHA512_Update(ctx, [latitudeStr UTF8String], (CC_LONG)[latitudeStr length]);
		CC_SHA512_Update(ctx, [longitudeStr UTF8String], (CC_LONG)[longitudeStr length]);
		CC_SHA512_Update(ctx, [altitudeStr UTF8String], (CC_LONG)[altitudeStr length]);
	}
}

- (NSString*)calculateWithActivityId:(NSString*)activityId
{
	CC_SHA512_CTX ctx;

	InitializeHistoricalActivityList();
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// Initialize the context.
	CC_SHA512_Init(&ctx);

	// Load the data.
	CreateHistoricalActivityObject(activityIndex);

	// Hash the locations.
	LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_LOCATION, GpsDataHashCallback, (void*)&ctx);

	// Compute the hash.
	uint8_t digest[CC_SHA512_DIGEST_LENGTH] = {0};
	CC_SHA512_Final(digest, &ctx);

	// Convert to a string.
	NSData* data = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
	return [StringUtils bytesToHexStr:data];
}

@end
