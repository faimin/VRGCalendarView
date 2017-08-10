//
//  VRGViewController.m
//  Vurig Calendar
//
//  Created by in 't Veen Tjeerd on 5/29/12.
//  Copyright (c) 2012 Vurig. All rights reserved.
//

#import "VRGViewController.h"
#import "NSDate+convenience.h"
#import "VRGCalendarView.h"

@interface VRGViewController () <VRGCalendarViewDelegate>

@end

@implementation VRGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];
    calendar.delegate = self;
    [self.view addSubview:calendar];
}

#pragma mark - VRGCalendarViewDelegate

- (void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(NSInteger)month withYear:(NSInteger)year targetHeight:(float)targetHeight animated:(BOOL)animated {
    if (month == [[NSDate date] month]) {
        NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],[NSNumber numberWithInt:5], nil];
        [calendarView markDates:dates];
    }

}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    NSLog(@"Selected date = %@", date);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



@end
