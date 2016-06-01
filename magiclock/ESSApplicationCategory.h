//
//  NSApplication+ESSApplicationCategory.h
//
//  Created by Matthias Gansrigler on 01.10.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

/*
 SOURCE CODE LICENSE
 
 1) You can use the code in your own products.
 2) You can modify the code as you wish, and use the modified code in your products.
 3) You can redistribute the original, unmodified code, but you have to include the full license text below.
 4) You can redistribute the modified code as you wish (without the full license text below).
 5) In all cases, you must include a credit mentioning Matthias Gansrigler as the original author of the source.
 6) I’m not liable for anything you do with the code, no matter what. So be sensible.
 7) You can’t use my name or other marks to promote your products based on the code.
 8) If you agree to all of that, go ahead and download the source. Otherwise, don’t.
 
 Contact: Matthias Gansrigler || opensource@eternalstorms.at ||  http://eternalstorms.at || @eternalstorms on twitter
 
 This NSApplication Category is available on Github at: https://github.com/eternalstorms/NSBeginAlertSheet-using-Blocks
 */



#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

#define ESS_FORCETOUCHAVAILABILITY_NOTIFICATIONNAME				@"ESS_FORCETOUCHAVAILABLE_NOTIFICATIONNAME"
#define kESSForceTouchAvailableUserInfoKey						@"ESS_ForceTouch_Available"

@interface NSApplication (ESSApplicationCategory)

#pragma mark - Force Touch Availability

/*!
 @method		isForceTouchCapableDeviceAvailable:
 @abstract		Find out if a Force Touch-capable device is available to the Mac
 @param			sender
				Used internally, please pass nil.
 @return		Returns YES if a Force Touch-capable device is available to the Mac, NO if not.
 */
- (BOOL)isForceTouchCapableDeviceAvailable:(id)sender;

@end
