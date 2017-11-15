VURIG Calendar
=====================
![](https://github.com/faimin/VRGCalendarView/blob/master/Screenshot%202013.12.17%2013.48.51.png)

#### A calendar view for iOS.
Easy to use, simple, clean.

Also animated. 😀😀😀

### Installation
Copy the files from the calendar group to your own project.

### Usage

```objc
VRGCalendarView *calendar = [[VRGCalendarView alloc] init];
calendar.delegate=self;
[self.view addSubview:calendar];
```

### Delegate methods

#### Selecting days
Whenever a user selects a date, the following method will be called:

```objc
-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date;
```

##### Switching months
This delegate method will be called whenever a user switches to the next or previous month.  

```objc
-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated;
```

With the way the calendar layouts work, the number of rows (and thus the height) can vary. You can react to this change by using the targetHeight parameter.

Mark the dates of that month by sending an array with NSDate or NSNumber objects. Like so:

```objc
NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:5], nil];
[calendarView markDates:dates];
```

Or 

```objc
NSArray *date = [NSArray arrayWithObjects:[NSDate date], nil];
NSArray *color = [NSArray arrayWithObjects:[UIColor redColor],nil];
[calendarView markDates:date withColors:color];
```




	
