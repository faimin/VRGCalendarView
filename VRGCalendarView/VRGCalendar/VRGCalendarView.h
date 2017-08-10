//
//  VRGCalendarView.h
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "UIColor+expanded.h"

#define kVRGCalendarViewTopBarHeight 60
#define kVRGCalendarViewWidth 320

#define kVRGCalendarViewDayWidth 44
#define kVRGCalendarViewDayHeight 44

@protocol VRGCalendarViewDelegate;
@interface VRGCalendarView : UIView {
    BOOL _isAnimating;
    BOOL _prepAnimationPreviousMonth;
    BOOL _prepAnimationNextMonth;
}

@property (nonatomic, weak) id <VRGCalendarViewDelegate> delegate;
@property (nonatomic, strong) NSDate *currentMonth;
@property (nonatomic, strong) UILabel *labelCurrentMonth;
@property (nonatomic, strong) UIImageView *animationView_A;
@property (nonatomic, strong) UIImageView *animationView_B;
@property (nonatomic, strong) NSArray *markedDates;
@property (nonatomic, strong) NSArray *markedColors;
@property (nonatomic, getter = calendarHeight) float calendarHeight;
@property (nonatomic, strong, getter = selectedDate) NSDate *selectedDate;

- (void)selectDate:(NSInteger)date;        //选择日期
- (void)reset;                       //回到今天

- (void)markDates:(NSArray *)dates;
- (void)markDates:(NSArray *)dates withColors:(NSArray *)colors;

- (void)showNextMonth;
- (void)showPreviousMonth;

- (NSInteger)numRows;
- (void)updateSize;
- (UIImage *)drawCurrentState;

@end

@protocol VRGCalendarViewDelegate <NSObject>
/// 切换月份时调用
- (void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(NSInteger)month withYear:(NSInteger)year targetHeight:(float)targetHeight animated:(BOOL)animated;
/// 选择日期时调用
- (void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date;
@end
