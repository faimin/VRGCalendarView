//
//  VRGCalendarView.m
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//

#import "VRGCalendarView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+convenience.h"
#import "NSMutableArray+convenience.h"
#import "UIView+convenience.h"

@implementation VRGCalendarView

- (void)dealloc {
    self.delegate = nil;
    self.currentMonth = nil;
    self.labelCurrentMonth = nil;
    
    self.markedDates = nil;
    self.markedColors = nil;
}

#pragma mark - Init
- (id)init {
    self = [super initWithFrame:CGRectMake(0, 0, kVRGCalendarViewWidth, 0)];
    if (self) {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds=YES;
        
        _isAnimating=NO;
        //TODO:修改显示当前月份的titleLabel
        self.labelCurrentMonth = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, kVRGCalendarViewWidth-68, 30)];   //40->30
        [self addSubview:self.labelCurrentMonth];
        //TODO:change
        self.labelCurrentMonth.backgroundColor = [UIColor clearColor];
        self.labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        self.labelCurrentMonth.textColor = [UIColor colorWithHexString:@"0x383838"];
        self.labelCurrentMonth.textAlignment = NSTextAlignmentCenter;
        
        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; //so delegate can be set after init and still get called on init
        //        [self reset];
    }
    return self;
}

#pragma mark - Select Date
- (void)selectDate:(NSInteger)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:self.currentMonth];
    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];
    
    NSInteger selectedDateYear = [self.selectedDate year];
    NSInteger selectedDateMonth = [self.selectedDate month];
    NSInteger currentMonthYear = [self.currentMonth year];
    NSInteger currentMonthMonth = [self.currentMonth month];
    
    if (selectedDateYear < currentMonthYear) {
        [self showPreviousMonth];
    } else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
    } else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
    } else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    } else {
        [self setNeedsDisplay];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:dateSelected:)]) {
        [self.delegate calendarView:self dateSelected:self.selectedDate];
    }
}

#pragma mark - Mark Dates
//NSArray can either contain NSDate objects or NSNumber objects with an NSInteger of the day.
- (void)markDates:(NSArray *)dates {
    self.markedDates = dates;
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    //TODO:标记日期的颜色
    for (NSInteger i = 0; i<[dates count]; i++) {
        //[colors addObject:[UIColor colorWithHexString:@"0x383838"]];
        [colors addObject:[UIColor blueColor]];
    }
    
    self.markedColors = [NSArray arrayWithArray:colors];
    
    [self setNeedsDisplay];
}

//NSArray can either contain NSDate objects or NSNumber objects with an NSInteger of the day.
- (void)markDates:(NSArray *)dates withColors:(NSArray *)colors {
    self.markedDates = dates;
    self.markedColors = colors;
    
    [self setNeedsDisplay];
}

#pragma mark - Set date to now
- (void)reset {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
    self.currentMonth = [gregorian dateFromComponents:components]; //clean month
    [self updateSize];
    [self setNeedsDisplay];

    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:withYear:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] withYear:[self.currentMonth year] targetHeight:self.calendarHeight animated:NO];
    }
}

#pragma mark - Next & Previous
- (void)showNextMonth {
    if (_isAnimating) return;
    
    self.markedDates = nil;
    _isAnimating = YES;
    _prepAnimationNextMonth = YES;
    
    [self setNeedsDisplay];
    
    NSInteger lastBlock = [self.currentMonth firstWeekDayInMonth] + [self.currentMonth numDaysInMonth] - 1;
    NSInteger numBlocks = [self numRows] * 7;
    BOOL hasNextMonthDays = lastBlock<numBlocks;
    
    //Old month
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //New month
    self.currentMonth = [self.currentMonth offsetMonth:1];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:withYear:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] withYear:[self.currentMonth year] targetHeight:self.calendarHeight animated:YES];
    }
    _prepAnimationNextMonth = NO;
    [self setNeedsDisplay];
    
    UIImage *imageNextMonth = [self drawCurrentState];
    CGFloat targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    
    //Animate
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imageNextMonth];
    [animationHolder addSubview:self.animationView_A];
    [animationHolder addSubview:self.animationView_B];
    
    if (hasNextMonthDays) {
        self.animationView_B.frameY = self.animationView_A.frameY + self.animationView_A.frameHeight - (kVRGCalendarViewDayHeight + 3);
    } else {
        self.animationView_B.frameY = self.animationView_A.frameY + self.animationView_A.frameHeight - 3;
    }
    
    //Animation
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         //blockSafeSelf.frameHeight = 100;
                         if (hasNextMonthDays) {
                             self.animationView_A.frameY = -self.animationView_A.frameHeight + kVRGCalendarViewDayHeight+3;
                         } else {
                             self.animationView_A.frameY = -self.animationView_A.frameHeight + 3;
                         }
                         self.animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.animationView_A removeFromSuperview];
                         [self.animationView_B removeFromSuperview];
                         _isAnimating = NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}

-(void)showPreviousMonth {
    if (_isAnimating) return;
    _isAnimating = YES;
    self.markedDates = nil;
    //Prepare current screen
    _prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    BOOL hasPreviousDays = [self.currentMonth firstWeekDayInMonth] > 1;
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //Prepare next screen
    self.currentMonth = [self.currentMonth offsetMonth:-1];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:withYear:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] withYear:[self.currentMonth year] targetHeight:self.calendarHeight animated:YES];
    }
    _prepAnimationPreviousMonth = NO;
    [self setNeedsDisplay];
    UIImage *imagePreviousMonth = [self drawCurrentState];
    
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imagePreviousMonth];
    [animationHolder addSubview:self.animationView_A];
    [animationHolder addSubview:self.animationView_B];
    
    if (hasPreviousDays) {
        self.animationView_B.frameY = self.animationView_A.frameY - (self.animationView_B.frameHeight-kVRGCalendarViewDayHeight) + 3;
    } else {
        self.animationView_B.frameY = self.animationView_A.frameY - self.animationView_B.frameHeight + 3;
    }
    
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         
                         if (hasPreviousDays) {
                             self.animationView_A.frameY = self.animationView_B.frameHeight - (kVRGCalendarViewDayHeight + 3);
                             
                         } else {
                             self.animationView_A.frameY = self.animationView_B.frameHeight - 3;
                         }
                         
                         self.animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.animationView_A removeFromSuperview];
                         [self.animationView_B removeFromSuperview];
                         _isAnimating = NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}


#pragma mark - update size & row count
- (void)updateSize {
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

- (float)calendarHeight {
    return kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
}

- (NSInteger)numRows {
    float lastBlock = [self.currentMonth numDaysInMonth] + ([self.currentMonth firstWeekDayInMonth] - 1);
    return (NSInteger)ceilf(lastBlock/7);
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoNSInteger = [touch locationInView:self];
    
    self.selectedDate = nil;
    
    //Touch a specific day
    if (touchPoNSInteger.y > kVRGCalendarViewTopBarHeight) {
        float xLocation = touchPoNSInteger.x;
        float yLocation = touchPoNSInteger.y-kVRGCalendarViewTopBarHeight;
        
        NSInteger column = floorf(xLocation/(kVRGCalendarViewDayWidth+2));
        NSInteger row = floorf(yLocation/(kVRGCalendarViewDayHeight+2));
        
        NSInteger blockNr = (column+1)+row*7;
        NSInteger firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
        NSInteger date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    }
    
    self.markedDates = nil;
    self.markedColors = nil;
    
    CGRect rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-50, 0, 50, 40);
    
    //Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoNSInteger)) {
        [self showPreviousMonth];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoNSInteger)) {
        [self showNextMonth];
    } else if (CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoNSInteger)) {
        //Detect touch in current month
        NSInteger currentMonthIndex = [self.currentMonth month];
        NSInteger todayMonth = [[NSDate date] month];
        [self reset];
        
        //TODO:自己修改的位置
        if ((todayMonth != currentMonthIndex) && [self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:withYear:targetHeight:animated:)]) {
            [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] withYear:[self.currentMonth year] targetHeight:self.calendarHeight animated:NO];
        }
        // if ((todayMonth!=currentMonthIndex) && [delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
    }
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
    NSInteger firstWeekDay = [self.currentMonth firstWeekDayInMonth] - 1; //-1 because weekdays begin at 1, not 0
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM yyyy"];
    self.labelCurrentMonth.text = [formatter stringFromDate:self.currentMonth];
    //TODO:change
    //[labelCurrentMonth sizeToFit];
    [self.labelCurrentMonth sizeThatFits:CGSizeMake(250, 40)];
    self.labelCurrentMonth.frameX = roundf(self.frame.size.width/2 - self.labelCurrentMonth.frameWidth/2);
    self.labelCurrentMonth.frameY = 10;
    [self.currentMonth firstWeekDayInMonth];
    
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,kVRGCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    //Arrows
    NSInteger arrowSize = 12;
    NSInteger xmargin = 20;
    NSInteger ymargin = 18;
    
    //Arrow Left
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, xmargin+arrowSize/1.5, ymargin);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5,ymargin+arrowSize);
    CGContextAddLineToPoint(context,xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5, ymargin);
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillPath(context);
    
    //Arrow right
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    CGContextAddLineToPoint(context,self.frame.size.width-xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5),ymargin+arrowSize);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    
    CGContextSetFillColorWithColor(context, 
                                   [UIColor blackColor].CGColor);
    CGContextFillPath(context);
    
    //Weekdays
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"EEE";
    //always assume gregorian with monday first
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
    [weekdays moveObjectFromIndex:0 toIndex:6];
    
    //TODO:星期的字体颜色
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
    for (NSInteger i = 0; i < [weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [weekdayValue drawInRect:CGRectMake(i*(kVRGCalendarViewDayWidth+2), 40, kVRGCalendarViewDayWidth+2, 20) withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];//UILineBreakModeClip
    }
    
    NSInteger numRows = [self numRows];
    
    CGContextSetAllowsAntialiasing(context, NO);
    
    //Grid background
    float gridHeight = numRows*(kVRGCalendarViewDayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,kVRGCalendarViewTopBarHeight,self.frame.size.width,gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xf3f3f3"].CGColor);
    //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xff0000"].CGColor); //红色
    CGContextFillPath(context);
    
    //Grid white lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+1);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+1);
    for (NSInteger i = 1; i<7; i++) {
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight+gridHeight);
        
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
    }
    
    CGContextStrokePath(context);
    
    //Grid dark lines
    //TODO:日历边框线条颜色
    //CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:@"0xcfd4d8"].CGColor);orangeColor
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight);
    for (NSInteger i = 1; i<7; i++) {
        //columns
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight+gridHeight);
        
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
    }
    CGContextMoveToPoint(context, 0, gridHeight+kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, gridHeight+kVRGCalendarViewTopBarHeight);
    
    CGContextStrokePath(context);
    
    CGContextSetAllowsAntialiasing(context, YES);
    
    //Draw days
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
    
    
    //NSLog(@"currentMonth month = %i, first weekday in month = %i",[self.currentMonth month],[self.currentMonth firstWeekDayInMonth]);
    
    NSInteger numBlocks = numRows*7;
    NSDate *previousMonth = [self.currentMonth offsetMonth:-1];
    NSInteger currentMonthNumDays = [self.currentMonth numDaysInMonth];
    NSInteger prevMonthNumDays = [previousMonth numDaysInMonth];
    
    NSInteger selectedDateBlock = ([self.selectedDate day] - 1) + firstWeekDay;
    
    //prepAnimationPreviousMonth nog wat mee doen
    
    //prev next month
    BOOL isSelectedDatePreviousMonth = _prepAnimationPreviousMonth;
    BOOL isSelectedDateNextMonth = _prepAnimationNextMonth;
    
    if (self.selectedDate != nil) {
        isSelectedDatePreviousMonth = ([self.selectedDate year] == [self.currentMonth year] && [self.selectedDate month] < [self.currentMonth month]) || [self.selectedDate year] < [self.currentMonth year];
        
        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([self.selectedDate year] == [self.currentMonth year] && [self.selectedDate month] > [self.currentMonth month]) || [self.selectedDate year] > [self.currentMonth year];
        }
    }
    
    if (isSelectedDatePreviousMonth) {
        NSInteger lastPositionPreviousMonth = firstWeekDay - 1;
        selectedDateBlock = lastPositionPreviousMonth - ([self.selectedDate numDaysInMonth] - [self.selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [self.currentMonth numDaysInMonth] + (firstWeekDay - 1) + [self.selectedDate day];
    }
    
    
    NSDate *todayDate = [NSDate date];
    NSInteger todayBlock = -1;
    
    NSLog(@"currentMonth month = %zd day = %zd, todaydate day = %zd", [self.currentMonth month], [self.currentMonth day], [todayDate month]);
    
    if ([todayDate month] == [self.currentMonth month] && [todayDate year] == [self.currentMonth year]) {
        todayBlock = [todayDate day] + firstWeekDay - 1;
    }
    
    for (NSInteger i = 0; i < numBlocks; i++) {
        NSInteger targetDate = i;
        NSInteger targetColumn = i%7;
        NSInteger targetRow = i/7;
        NSInteger targetX = targetColumn * (kVRGCalendarViewDayWidth+2);
        NSInteger targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2);
        
        // BOOL isCurrentMonth = NO;
        if (i<firstWeekDay) { //previous month
            targetDate = (prevMonthNumDays-firstWeekDay)+(i+1);
            NSString *hex = (isSelectedDatePreviousMonth) ? @"0x383838" : @"0x878787";    //aaaaaa
            
            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:hex].CGColor);
        } else if (i>=(firstWeekDay+currentMonthNumDays)) { //next month
            targetDate = (i+1) - (firstWeekDay+currentMonthNumDays);
            NSString *hex = (isSelectedDateNextMonth) ? @"0x383838" : @"0x878787";      //aaaaaa
            CGContextSetFillColorWithColor(context, 
                                           [UIColor colorWithHexString:hex].CGColor);
        } else { //current month
            // isCurrentMonth = YES;
            targetDate = (i-firstWeekDay)+1;
            NSString *hex = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? @"0x878787" : @"0x383838";  //0xaaaaaa
            CGContextSetFillColorWithColor(context, 
                                           [UIColor colorWithHexString:hex].CGColor);
        }
        
        NSString *date = [NSString stringWithFormat:@"%zd", targetDate];
        
        //draw selected date
        //TODO:选中的日期
        if (self.selectedDate && i == selectedDateBlock) {
            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x006dbc"].CGColor);
            CGContextFillPath(context);
            
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        } else if (todayBlock==i) {
            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
            CGContextAddRect(context, rectangleGrid);
            //TODO:今天日期的颜色
            //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor brownColor].CGColor);
            CGContextFillPath(context);
            
            CGContextSetFillColorWithColor(context, 
                                           [UIColor whiteColor].CGColor);
        }
        
        [date drawInRect:CGRectMake(targetX+2, targetY+10, kVRGCalendarViewDayWidth, kVRGCalendarViewDayHeight) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter]; //UITextAlignmentCenter  UILineBreakModeClip
    }
    
    //    CGContextClosePath(context);
    
    
    //Draw markings
    if (!self.markedDates || isSelectedDatePreviousMonth || isSelectedDateNextMonth) return;
    
    for (NSInteger i = 0; i < [self.markedDates count]; i++) {
        id markedDateObj = [self.markedDates objectAtIndex:i];
        
        NSInteger targetDate;
        if ([markedDateObj isKindOfClass:[NSNumber class]]) {
            targetDate = [(NSNumber *)markedDateObj integerValue];
        } else if ([markedDateObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)markedDateObj;
            targetDate = [date day];
        } else {
            continue;
        }
        
        NSInteger targetBlock = firstWeekDay + (targetDate-1);
        NSInteger targetColumn = targetBlock%7;
        NSInteger targetRow = targetBlock/7;
        
        NSInteger targetX = targetColumn * (kVRGCalendarViewDayWidth+2) + 7;
        NSInteger targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2) + 38;
        
        CGRect rectangle = CGRectMake(targetX,targetY,32,2);
        CGContextAddRect(context, rectangle);
        
        UIColor *color;
        if (self.selectedDate && selectedDateBlock==targetBlock) {
            color = [UIColor whiteColor];
        }  else if (todayBlock==targetBlock) {
            color = [UIColor whiteColor];
        } else {
            color  = (UIColor *)[self.markedColors objectAtIndex:i];
        }
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
    }
}

#pragma mark - Draw image for animation
- (UIImage *)drawCurrentState {
    CGFloat targetHeight = kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2) + 1;
    
    UIGraphicsBeginImageContext(CGSizeMake(kVRGCalendarViewWidth, targetHeight-kVRGCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -kVRGCalendarViewTopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

@end
