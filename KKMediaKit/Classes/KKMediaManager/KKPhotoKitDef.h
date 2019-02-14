//
//  KKPhotoKitDef.h
//  KKPhotoKit
//
//  Created by kkfinger on 2019/2/12.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//用户访问相册权限
typedef NS_ENUM(NSInteger, KKPhotoAuthorizationStatus){
    KKPhotoAuthorizationStatusNotDetermined = 0,  // User has not yet made a choice with regards to this application
    
    KKPhotoAuthorizationStatusRestricted,         // This application is not authorized to access photo data.
    // The user cannot change this application’s status, possibly due to active restrictions
    //   such as parental controls being in place.
    KKPhotoAuthorizationStatusDenied,             // User has explicitly denied this            application access to photos data.
    
    KKPhotoAuthorizationStatusAuthorized         // User has authorized this application to access photos data.
};

#define KKNotifyPhotoLibraryDidChange @"KKNotifyPhotoLibraryDidChange"
#define KKNotifyVideoLibraryDidChange @"KKNotifyVideoLibraryDidChange"

#define UIDeviceScreenSize   [[UIScreen mainScreen] bounds].size
#define UIDeviceScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define UIDeviceScreenHeight [[UIScreen mainScreen] bounds].size.height

NS_ASSUME_NONNULL_END
