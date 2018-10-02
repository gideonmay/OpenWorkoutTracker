// Created by Michael Simms on 9/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StaticSummaryViewController.h"
#import "AccelerometerLine.h"
#import "ActivityAttribute.h"
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "AppStrings.h"
#import "AppDelegate.h"
#import "CorePlotViewController.h"
#import "ElevationLine.h"
#import "LapTimesViewController.h"
#import "LineFactory.h"
#import "OverlayFactory.h"
#import "Pin.h"
#import "Segues.h"
#import "SplitTimesViewController.h"
#import "StringUtils.h"
#import "TagViewController.h"

#define ROW_TITLE_STARTED              NSLocalizedString(@"Started", nil)
#define ROW_TITLE_FINISHED             NSLocalizedString(@"Finished", nil)
#define ROW_TITLE_SPLIT_TIMES          NSLocalizedString(@"Split Times", nil)
#define ROW_TITLE_LAP_TIMES            NSLocalizedString(@"Lap Times", nil)

#define SECTION_TITLE_START_AND_STOP   NSLocalizedString(@"Start and Finish", nil)
#define SECTION_TITLE_LAP_AND_SPLIT    NSLocalizedString(@"Lap and Split Times", nil)
#define SECTION_TITLE_CHARTS           NSLocalizedString(@"Charts", nil)
#define SECTION_TITLE_ATTRIBUTES       NSLocalizedString(@"Summary", nil)
#define SECTION_TITLE_SUPERLATIVES     NSLocalizedString(@"Superlatives", nil)

#define ACTION_SHEET_BUTTON_GPX        NSLocalizedString(@"GPX File", nil)
#define ACTION_SHEET_BUTTON_TCX        NSLocalizedString(@"TCX File", nil)
#define ACTION_SHEET_BUTTON_CSV        NSLocalizedString(@"CSV File", nil)

#define ACTION_SHEET_TRIM_FIRST_1      NSLocalizedString(@"Delete 1st Second", nil)
#define ACTION_SHEET_TRIM_FIRST_5      NSLocalizedString(@"Delete 1st Five Seconds", nil)
#define ACTION_SHEET_TRIM_FIRST_30     NSLocalizedString(@"Delete 1st Thirty Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_1     NSLocalizedString(@"Delete Last Second", nil)
#define ACTION_SHEET_TRIM_SECOND_5     NSLocalizedString(@"Delete Last Five Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_30    NSLocalizedString(@"Delete Last Thirty Seconds", nil)
#define ACTION_SHEET_FIX_REPS          NSLocalizedString(@"Fix Repetition Count", nil)

#define ACTION_SHEET_TITLE_EXPORT      NSLocalizedString(@"Export using", nil)
#define ACTION_SHEET_TITLE_FILE_FORMAT NSLocalizedString(@"Export as", nil)
#define ACTION_SHEET_TITLE_EDIT        NSLocalizedString(@"Edit", nil)

#define START_PIN_NAME                 NSLocalizedString(@"Start", nil)
#define FINISH_PIN_NAME                NSLocalizedString(@"Finish", nil)
#define TIME                           NSLocalizedString(@"Time", nil)

#define ALERT_TITLE_FIX_REPS           NSLocalizedString(@"Repetitions", nil)

#define EXPORT_FAILED                  NSLocalizedString(@"Export failed!", nil)

#define MSG_DELETE_QUESTION            NSLocalizedString(@"Are you sure you want to delete this workout?", nil)
#define MSG_FIX_REPS                   NSLocalizedString(@"Enter the correct number of repetitions", nil)
#define MSG_LOW_MEMORY                 NSLocalizedString(@"Low memory", nil)
#define MSG_MAIL_DISABLED              NSLocalizedString(@"Sending mail is disabled", nil)

#define EMAIL_TITLE                    NSLocalizedString(@"Workout Data", nil)
#define EMAIL_CONTENTS                 NSLocalizedString(@"The data file is attached.", nil)

typedef enum Time1Rows
{
	ROW_START_TIME = 0,
	ROW_END_TIME,
} Time1Rows;

typedef enum Time2Rows
{
	ROW_SPLIT_TIMES = 0,
	ROW_LAP_TIMES,
} Time2Rows;

typedef enum Sections
{
	SECTION_START_AND_END_TIME = 0,
	SECTION_LAP_AND_SPLIT_TIMES,
	SECTION_CHARTS,
	SECTION_ATTRIBUTES,
	SECTION_SUPERLATIVES,
	NUM_SECTIONS
} Sections;

typedef enum ExportFileTypeButtons
{
	EXPORT_BUTTON_GPX = 0,
	EXPORT_BUTTON_TCX,
	EXPORT_BUTTON_CSV,
	EXPORT_BUTTON_CANCEL
} ExportFileTypeButtons;

@interface StaticSummaryViewController ()

@end

@implementation StaticSummaryViewController

@synthesize navItem;
@synthesize toolbar;
@synthesize summaryTableView;
@synthesize deleteButton;
@synthesize exportButton;
@synthesize editButton;
@synthesize mapButton;
@synthesize bikeButton;
@synthesize tagsButton;
@synthesize spinner;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityIndex = 0;
		self->attributeIndex = 0;

		self->activityId = nil;

		self->startTime = 0;
		self->endTime = 0;

		self->hasGpsData = false;
		self->hasAccelerometerData = false;
		self->hasHeartRateData = false;
		self->hasCadenceData = false;
		self->hasPowerData = false;

		self->mapMode = MAP_OVERVIEW_COMPLETE_ROUTE;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self.deleteButton setTitle:STR_DELETE];
	[self.exportButton setTitle:STR_EXPORT];
	[self.editButton setTitle:STR_EDIT];
	[self.mapButton setTitle:STR_MAP];
	[self.bikeButton setTitle:STR_BIKE];
	[self.tagsButton setTitle:STR_TAG];

	self->movingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->movingToolbar)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		NSString* activityType = [appDelegate getHistorialActivityType:self->activityIndex];
		if (!([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE]))
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		else if ([[appDelegate getBikeNames] count] == 0)
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}
	}

	self->liftingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->liftingToolbar)
	{
		[self->liftingToolbar removeObjectIdenticalTo:self.mapButton];
		[self->liftingToolbar removeObjectIdenticalTo:self.bikeButton];
	}

	[self redraw];

	UILongPressGestureRecognizer* gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapGesture:)];
	if (gesture)
	{
		gesture.minimumPressDuration = 1.0;
		[self.mapView addGestureRecognizer:gesture];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (void)redraw
{	
	[self.mapView setShowsUserLocation:FALSE];
	[self.spinner stopAnimating];
	
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if (appDelegate && [appDelegate loadHistoricalActivity:self->activityIndex])
	{
		self->attributeNames = [[NSMutableArray alloc] init];
		self->recordNames = [[NSMutableArray alloc] init];

		self->activityId = [[NSString alloc] initWithFormat:@"%s", ConvertActivityIndexToActivityId(self->activityIndex)];
		GetHistoricalActivityStartAndEndTime(self->activityIndex, &self->startTime, &self->endTime);

		self->hasGpsData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_STARTING_LATITUDE).valid;
		self->hasAccelerometerData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_X).valid;
		self->hasHeartRateData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_HEART_RATE).valid;
		self->hasCadenceData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_CADENCE).valid;
		self->hasPowerData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_POWER).valid;
		
		self->chartTitles = [LineFactory getLineNames:self->hasGpsData withBool:self->hasAccelerometerData withBool:self->hasHeartRateData withBool:self->hasCadenceData withBool:self->hasPowerData];
		
		self->timeSection1RowNames = [[NSMutableArray alloc] init];
		if (self->timeSection1RowNames)
		{
			[self->timeSection1RowNames addObject:ROW_TITLE_STARTED];
			[self->timeSection1RowNames addObject:ROW_TITLE_FINISHED];
		}

		self->timeSection2RowNames = [[NSMutableArray alloc] init];
		if (self->hasGpsData)
		{
			[self->timeSection2RowNames addObject:ROW_TITLE_SPLIT_TIMES];
			[self->timeSection2RowNames addObject:ROW_TITLE_LAP_TIMES];
		}

		uint64_t bikeId;
		if (GetActivityBikeProfile([self->activityId UTF8String], &bikeId))
		{
			char* name = NULL;
			double weightKg = (double)0.0;
			double wheelSize = (double)0.0;
			
			if (GetBikeProfileById(bikeId, &name, &weightKg, &wheelSize))
			{
				NSString* tempName = [[NSString alloc] initWithUTF8String:name];
				[self.bikeButton setTitle:tempName];
				free((void*)name);
			}
		}

		NSArray* tempAttrNames = [appDelegate getHistoricalActivityAttributes:self->activityIndex];
		for (NSString* attrName in tempAttrNames)
		{
			ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attrName UTF8String]);
			if (attr.valid)
			{
				if ([self isRecordName:attrName])
				{
					[self->recordNames addObject:attrName];
				}
				else
				{
					[self->attributeNames addObject:attrName];
				}
			}
		}
		
		// Figure out which sections will be shown and which are empty.
		memset(self->sectionIndexes, 0, sizeof(self->sectionIndexes));
		self->numVisibleSections = 0;
		for (size_t sectionIndex = 0; sectionIndex < NUM_SECTIONS; ++sectionIndex)
		{
			NSInteger count = 0;

			switch (sectionIndex)
			{
				case SECTION_START_AND_END_TIME:
					count = [self->timeSection1RowNames count];
					break;
				case SECTION_LAP_AND_SPLIT_TIMES:
					count = [self->timeSection2RowNames count];
					break;
				case SECTION_CHARTS:
					count = [self->chartTitles count];
					break;
				case SECTION_ATTRIBUTES:
					count = [self->attributeNames count];
					break;
				case SECTION_SUPERLATIVES:
					count = [self->recordNames count];
					break;
			}

			if (count > 0)
			{
				self->sectionIndexes[self->numVisibleSections++] = sectionIndex;
			}
		}
		
		self.navItem.title = NSLocalizedString([appDelegate getHistorialActivityType:self->activityIndex], nil);
		
		[self drawRoute];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_TAG_VIEW])
	{
		TagViewController* tagVC = (TagViewController*)[segue destinationViewController];
		if (tagVC)
		{
			tagVC.title = self.navItem.title;
			[tagVC setActivityId:self->activityId];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_CORE_PLOT_VIEW])
	{
		CorePlotViewController* plotVC = (CorePlotViewController*)[segue destinationViewController];
		if (plotVC)
		{
			ChartLine* line = [LineFactory createLine:self->selectedRowStr withActivityId:self->activityId];
			if (line)
			{
				[line draw];
				[plotVC appendChartLine:line withXLabel:TIME withYLabel:self->selectedRowStr];
				[plotVC setShowMinLine:TRUE];
				[plotVC setShowMaxLine:TRUE];
				[plotVC setShowAvgLine:TRUE];
				[plotVC setTitle:self->selectedRowStr];
			}
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_MAP_OVERVIEW])
	{
		MapOverviewViewController* mapVC = (MapOverviewViewController*)[segue destinationViewController];
		if (mapVC)
		{
			if (self->mapMode == MAP_OVERVIEW_SEGMENT_VIEW)
			{
				ActivityAttributeType value = QueryHistoricalActivityAttribute(self->activityIndex, [self->selectedRowStr UTF8String]);
				[mapVC setSegment:value withSegmentName:self->selectedRowStr];
			}
			[mapVC setActivityId:self->activityId];
			[mapVC setMode:self->mapMode];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_SPLIT_TIMES_VIEW])
	{
		SplitTimesViewController* splitVC = (SplitTimesViewController*)[segue destinationViewController];
		if (splitVC)
		{
			[splitVC setActivityId:self->activityId];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_LAP_TIMES_VIEW])
	{
		LapTimesViewController* lapVC = (LapTimesViewController*)[segue destinationViewController];
		if (lapVC)
		{
			[lapVC setActivityId:self->activityId];
		}
	}
}

#pragma mark random methods

- (BOOL)isRecordName:(NSString*)name
{
	return (([name rangeOfString:@"Fastest"].location != NSNotFound) ||
			([name rangeOfString:@"Biggest"].location != NSNotFound) ||
			([name rangeOfString:@"Min."].location != NSNotFound) ||
			([name rangeOfString:@"Max."].location != NSNotFound));
}

#pragma mark action sheet methods

- (BOOL)showFileFormatSheet
{
	if (GetNumHistoricalActivities() > 0)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_FILE_FORMAT
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		
		LoadAllHistoricalActivitySensorData(self->activityIndex);

		if (GetNumHistoricalActivityLocationPoints(self->activityIndex) > 0)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_GPX style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_GPX to:self->selectedExportLocation];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_TCX style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_TCX to:self->selectedExportLocation];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_CSV style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_CSV to:self->selectedExportLocation];
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];

		[self presentViewController:alertController animated:YES completion:nil];

		if (self->exportedFileName)
		{
			if ([self->selectedExportLocation isEqualToString:@"Email"])
			{
				[self displayEmailComposerSheet];
			}
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:EXPORT_FAILED];
		}
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_LOW_MEMORY];
	}
	return FALSE;
}

- (BOOL)showCloudSheet
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	
	NSMutableArray* fileSites = [appDelegate getBikeNames];
	if ([fileSites count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_EXPORT
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		
		for (NSString* fileSite in fileSites)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:fileSite style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->selectedExportLocation = fileSite;
				[self showFileFormatSheet];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
		
		return TRUE;
	}
	return FALSE;
}

#pragma mark accessor methods

- (void)setActivityIndex:(NSInteger)index
{
	self->activityIndex = index;

	CreateHistoricalActivityObject(index);
	LoadHistoricalActivitySummaryData(index);
}

#pragma mark location handling methods

- (void)drawRoute
{
	const NSInteger SCREEN_HEIGHT_IPHONE5 = 568;
	const NSInteger SCREEN_TOP = 60;
	const NSInteger BAR_HEIGHT = 50;
	
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;

	size_t pointIndex = 0;
	Coordinate coordinate;
	NSInteger screenHeight = [[UIScreen mainScreen] bounds].size.height;
	CLLocation* location = nil;

	while (GetHistoricalActivityPoint(self->activityIndex, pointIndex, &coordinate))
	{
		// Draw every other point.
		if (pointIndex % 2 == 0)
		{
			location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
			if (location)
			{
				if (location.coordinate.latitude > maxLat)
					maxLat = location.coordinate.latitude;
				if (location.coordinate.latitude < minLat)
					minLat = location.coordinate.latitude;
				if (location.coordinate.longitude > maxLon)
					maxLon = location.coordinate.longitude;
				if (location.coordinate.longitude < minLon)
					minLon = location.coordinate.longitude;

				[self addNewLocation:location];
			}
		}

		if (pointIndex == 0)
		{
			Pin* pin = [[Pin alloc] initWithCoordinates:location.coordinate placeName:START_PIN_NAME description:@""];
			if (pin)
			{
				[self.mapView addAnnotation:pin];
			}
		}

		++pointIndex;
	}

	if (location)
	{
		Pin* pin = [[Pin alloc] initWithCoordinates:location.coordinate placeName:FINISH_PIN_NAME description:@""];
		if (pin)
		{
			[self.mapView addAnnotation:pin];
		}
	}

	if (pointIndex > 0)
	{
		// Set the map region.
		
		MKCoordinateRegion region;
		region.center.latitude     = (maxLat + minLat) / 2;
		region.center.longitude    = (maxLon + minLon) / 2;
		region.span.latitudeDelta  = (maxLat - minLat) * 1.1;
		region.span.longitudeDelta = (maxLon - minLon) * 1.1;
		
		[self.mapView setRegion:region];
		[self.mapView setDelegate:self];
		
		// Compute the size of the table view.

		NSInteger tableHeight = (screenHeight / 2) - BAR_HEIGHT;
		NSInteger tableTop    = (screenHeight / 2);

		// Resize the table view.
		
		CGRect tvbounds = [self.summaryTableView bounds];
		
		[self.summaryTableView setBounds:CGRectMake(0, tableTop, tvbounds.size.width, tableHeight)];
		[self.summaryTableView setFrame:CGRectMake(0, tableTop, tvbounds.size.width, tableHeight)];

		// Resize and show the map view.

		CGRect mvbounds = [self.mapView bounds];

		[self.mapView setBounds:CGRectMake(0, 0, mvbounds.size.width, tableTop)];
		self.mapView.hidden = FALSE;

		// Setup the toolbar.

		[self.toolbar setItems:self->movingToolbar animated:NO];
	}
	else
	{
		// Hide the map view.

		self.mapView.hidden = TRUE;
		
		// Resize the table view.

		CGRect tvbounds = [self.summaryTableView bounds];

		NSInteger tableHeight = 370;
		if (screenHeight == SCREEN_HEIGHT_IPHONE5)
			tableHeight = 458;

		[self.summaryTableView setBounds:CGRectMake(0, SCREEN_TOP, tvbounds.size.width, tableHeight)];
		[self.summaryTableView setFrame:CGRectMake(0, SCREEN_TOP, tvbounds.size.width, tableHeight)];

		// Setup the toolbar.

		[self.toolbar setItems:self->liftingToolbar animated:NO];
	}
}

#pragma mark button handlers

- (IBAction)onDelete:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_CAUTION
																			 message:MSG_DELETE_QUESTION
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		DeleteActivity([self->activityId UTF8String]);
		InitializeHistoricalActivityList();
		[self.navigationController popViewControllerAnimated:YES];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onExport:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* fileSites = [appDelegate getEnabledFileExportServices];
	if ([fileSites count] == 1)
	{
		self->selectedExportLocation = [fileSites objectAtIndex:0];
		[self showFileFormatSheet];
	}
	else
	{
		if ([self showCloudSheet] == FALSE)
		{
			[self showFileFormatSheet];
		}			
	}
}

- (IBAction)onEdit:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_EDIT
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_1 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 1) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_5 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 5) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_30 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 30) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_1 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 1) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_5 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 5) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_30 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 30) * 1000;
		TrimActivityData([self->activityId UTF8String], newTime, TRUE);
		InitializeHistoricalActivityList();		
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	ActivityAttributeType repsValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_REPS);
	if (repsValue.valid)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_FIX_REPS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			UIAlertController* repsAlertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_FIX_REPS
																					 message:MSG_FIX_REPS
																			  preferredStyle:UIAlertControllerStyleAlert];
			[repsAlertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
				textField.placeholder = [[NSString alloc] initWithFormat:@"%llu", repsValue.value.intVal];
				textField.keyboardType = UIKeyboardTypeNumberPad;
			}];
			[repsAlertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				UITextField* field = repsAlertController.textFields.firstObject;

				ActivityAttributeType value;
				value.value.intVal = [[field text] intValue];
				value.valueType = TYPE_INTEGER;
				value.measureType = MEASURE_COUNT;

				SetHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_REPS_CORRECTED, value);
				SaveHistoricalActivitySummaryData(self->activityIndex);
			}]];
			[self presentViewController:repsAlertController animated:YES completion:nil];
		}]];
	}
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onTag:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_TAG_VIEW sender:self];
}

- (IBAction)onBike:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* fileSites = [appDelegate getBikeNames];
	if ([fileSites count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_BIKE
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		for (NSString* fileSite in fileSites)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:fileSite style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self->bikeButton setTitle:fileSite];
				[appDelegate setBikeForActivityId:fileSite withActivityId:self->activityId];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

#pragma mark called when the user selects a row

- (void)handleSelectedRow:(NSIndexPath*)indexPath onTable:(UITableView*)tableView
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];

	self->selectedRowStr = cell.textLabel.text;

	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			break;
		case SECTION_LAP_AND_SPLIT_TIMES:
			if (row == ROW_SPLIT_TIMES)
			{
				self.spinner.hidden = FALSE;
				[self.spinner startAnimating];
				[self performSegueWithIdentifier:@SEGUE_TO_SPLIT_TIMES_VIEW sender:self];
			}
			else if (row == ROW_LAP_TIMES)
			{
				self.spinner.hidden = FALSE;
				[self.spinner startAnimating];
				[self performSegueWithIdentifier:@SEGUE_TO_LAP_TIMES_VIEW sender:self];
			}
			break;
		case SECTION_CHARTS:
			{
				self.spinner.hidden = FALSE;
				[self.spinner startAnimating];
				[self performSegueWithIdentifier:@SEGUE_TO_CORE_PLOT_VIEW sender:self];
			}
			break;
		case SECTION_ATTRIBUTES:
			break;
		case SECTION_SUPERLATIVES:
			if ([self superlativeHasSegue:cell])
			{
				self->mapMode = MAP_OVERVIEW_SEGMENT_VIEW;
				self.spinner.hidden = FALSE;
				[self.spinner startAnimating];
				[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
			}
			break;
	}

	[self.spinner stopAnimating];
}

#pragma mark UITableView methods

- (BOOL)superlativeHasSegue:(UITableViewCell*)cell
{
	return !self.mapView.hidden && [self isRecordName:cell.textLabel.text];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
	return self->numVisibleSections;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)visibleSection
{
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			return SECTION_TITLE_START_AND_STOP;
		case SECTION_LAP_AND_SPLIT_TIMES:
			return SECTION_TITLE_LAP_AND_SPLIT;
		case SECTION_CHARTS:
			return SECTION_TITLE_CHARTS;
		case SECTION_ATTRIBUTES:
			return SECTION_TITLE_ATTRIBUTES;
		case SECTION_SUPERLATIVES:
			return SECTION_TITLE_SUPERLATIVES;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)visibleSection
{
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			return [self->timeSection1RowNames count];
		case SECTION_LAP_AND_SPLIT_TIMES:
			return [self->timeSection2RowNames count];			
		case SECTION_CHARTS:
			return [self->chartTitles count];
		case SECTION_ATTRIBUTES:
			return [self->attributeNames count];
		case SECTION_SUPERLATIVES:
			return [self->recordNames count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}

	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];
	
	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			switch (row)
			{
				case ROW_START_TIME:
					cell.textLabel.text = ROW_TITLE_STARTED;
					if (startTime == 0)
						cell.detailTextLabel.text = @"--";
					else
						cell.detailTextLabel.text = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
					break;
				case ROW_END_TIME:
					cell.textLabel.text = ROW_TITLE_FINISHED;
					if (endTime == 0)
						cell.detailTextLabel.text = @"--";
					else
						cell.detailTextLabel.text = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:endTime]];
					break;
			}
			break;
		case SECTION_LAP_AND_SPLIT_TIMES:
			switch (row)
			{
				case ROW_SPLIT_TIMES:
					cell.textLabel.text = ROW_TITLE_SPLIT_TIMES;
					cell.detailTextLabel.text = @"";
					break;
				case ROW_LAP_TIMES:
					cell.textLabel.text = ROW_TITLE_LAP_TIMES;
					cell.detailTextLabel.text = @"";
					break;
			}
			break;
		case SECTION_CHARTS:
			cell.textLabel.text = NSLocalizedString([self->chartTitles objectAtIndex:row], nil);
			cell.detailTextLabel.text = @"";
			break;
		case SECTION_ATTRIBUTES:
			{
				NSString* attributeName = [self->attributeNames objectAtIndex:row];
				ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attributeName UTF8String]);
				if (attr.valid)
				{
					NSString* valueStr = [StringUtils formatActivityViewType:attr];
					NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];

					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", valueStr, unitsStr];
					else
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", valueStr];
				}
				else
				{
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					cell.detailTextLabel.text = @"";
				}
			}
			break;
		case SECTION_SUPERLATIVES:
			{
				NSString* attributeName = [self->recordNames objectAtIndex:row];
				ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attributeName UTF8String]);
				if (attr.valid)
				{
					NSString* valueStr = [StringUtils formatActivityViewType:attr];
					NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];
					
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", valueStr, unitsStr];
					else
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", valueStr];
				}
				else
				{
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					cell.detailTextLabel.text = @"";
				}
			}
			break;
		default:
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];

	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			cell.accessoryType = UITableViewCellAccessoryNone;
			break;
		case SECTION_LAP_AND_SPLIT_TIMES:
			cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
			break;
		case SECTION_CHARTS:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case SECTION_ATTRIBUTES:
			cell.accessoryType = UITableViewCellAccessoryNone;
			break;
		case SECTION_SUPERLATIVES:
			if ([self superlativeHasSegue:cell])
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

#pragma mark mail composition methods

- (void)displayEmailComposerSheet
{
	NSString* subjectStr = EMAIL_TITLE;
	NSString* bodyStr = EMAIL_CONTENTS;

	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
		if (mailController)
		{
			[mailController setEditing:TRUE];
			[mailController setSubject:subjectStr];
			[mailController setMessageBody:bodyStr isHTML:NO];
			[mailController setMailComposeDelegate:self];
			
			if (self->exportedFileName)
			{
				NSString* justTheFileName = [[[NSFileManager defaultManager] displayNameAtPath:self->exportedFileName] lastPathComponent];
				NSData* myData = [NSData dataWithContentsOfFile:self->exportedFileName];
				[mailController addAttachmentData:myData mimeType:@"text/xml" fileName:justTheFileName];
			}
			
			[self presentViewController:mailController animated:YES completion:nil];
		}
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_MAIL_DISABLED];
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result
{
	[self becomeFirstResponder];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			break;
		default:
			break;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate deleteFile:self->exportedFileName];

	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIGestureRecognizer methods

- (void)handleMapGesture:(UIGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateBegan)
	{
		self->mapMode = MAP_OVERVIEW_COMPLETE_ROUTE;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
}

@end
