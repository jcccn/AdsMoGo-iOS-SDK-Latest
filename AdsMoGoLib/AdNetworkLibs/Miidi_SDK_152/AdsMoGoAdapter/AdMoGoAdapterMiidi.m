//
//  AdMoGoAdapterMiidi.m
//  TestMOGOSDKAPP
//
//  Created by 孟令之 on 13-1-11.
//
//

#import "AdMoGoAdapterMiidi.h"
#import "AdMoGoAdNetworkRegistry.h"
#import "AdMoGoAdNetworkConfig.h"
#import "AdMoGoAdNetworkAdapter+Helpers.h"
#import "AdMoGoConfigDataCenter.h"
#import "AdMoGoConfigData.h"
#import "AdMoGoDeviceInfoHelper.h"
#import "MiidiManager.h"



@implementation AdMoGoAdapterMiidi
+ (AdMoGoAdNetworkType)networkType{
    return AdMoGoAdNetworkTypeMiidi;
}

+ (void)load {
	[[AdMoGoAdSDKBannerNetworkRegistry sharedRegistry] registerClass:self];
}

- (void)getAd{
    isSuccess = NO;

    isStop = NO;
    
    [adMoGoCore adDidStartRequestAd];
    AdMoGoConfigDataCenter *configDataCenter = [AdMoGoConfigDataCenter singleton];
    
    AdMoGoConfigData *configData = [configDataCenter.config_dict objectForKey:adMoGoCore.config_key];
    
	[adMoGoCore adapter:self didGetAd:@"miidi"];
    
    //    AdViewType type = adMoGoView.adType;
    AdViewType type =[configData.ad_type intValue];
    
    MiidiAdSizeIdentifier miidiSize = MiidiAdSizeUnknow;
    switch (type) {
        case AdViewTypeNormalBanner:
        case AdViewTypeiPadNormalBanner:
            miidiSize = MiidiAdSize320x50;
            break;
        case AdViewTypeRectangle:
            miidiSize = MiidiAdSize200x200;
            break;
        case AdViewTypeMediumBanner:
            miidiSize = MiidiAdSize460x72;
            break;
        case AdViewTypeLargeBanner:
            miidiSize = MiidiAdSize768x72;
            break;
        default:
            [adMoGoCore adapter:self didFailAd:nil];
            break;
    }
    if (!isManagerCreate) {

        isManagerCreate = YES;
        [MiidiManager setMiidiBasAppPublisher:[[self.ration objectForKey:@"key"] objectForKey:@"appID"]
                        withMiidiBasAppSecret:[[self.ration objectForKey:@"key"] objectForKey:@"appPassword"] ];
        
        
    }
    
    adMiidiView = [[MiidiAdView alloc]initMiidiBasAdViewWithContentSizeIdentifier:miidiSize withMiidiBasDelegate:self];
    
    CGRect frame1 = adMiidiView.frame;
	frame1.origin.x = 0;
	frame1.origin.y = 0;
	adMiidiView.frame = frame1;
    self.adNetworkView = adMiidiView;
    
    
    id _timeInterval = [self.ration objectForKey:@"to"];
    if ([_timeInterval isKindOfClass:[NSNumber class]]) {
        timer = [[NSTimer scheduledTimerWithTimeInterval:[_timeInterval doubleValue] target:self selector:@selector(loadAdTimeOut:) userInfo:nil repeats:NO] retain];
    }
    else{
        timer = [[NSTimer scheduledTimerWithTimeInterval:AdapterTimeOut8 target:self selector:@selector(loadAdTimeOut:) userInfo:nil repeats:NO] retain];
    }
    [adMiidiView requestMiidiBasAd];
//    if (isSuccess) {
//        [adMoGoCore adapter:self didReceiveAdView:adMiidiView];
//        
//    }
}

- (void)stopBeingDelegate {
    [self stopTimer];
    if (adMiidiView) {
        adMiidiView.delegate = nil;
    }
}

- (void)stopAd{
    [self stopBeingDelegate];
    isStop = YES;
}

- (void)stopTimer {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}


- (void)dealloc {
    isStop = YES;
    if (adMiidiView != nil) {
        adMiidiView.delegate = nil;
        [adMiidiView release], adMiidiView = nil;
    }
	[super dealloc];
}


- (void)loadAdTimeOut:(NSTimer*)theTimer{
    
    if (isStop) {
        return;
    }
    isStop = YES;
    [self stopBeingDelegate];
    [adMoGoCore adapter:self didFailAd:nil];
}

#pragma mark - MiidiAdViewDelegate
// 请求广告条数据成功后调用
//
// 详解:当接收服务器返回的广告数据成功后调用该函数
// 补充：第一次返回成功数据后调用
- (void)didMiidiBasReceiveAd:(MiidiAdView *)adView{
    MGLog(MGT,@"midi subviews %@",[adView subviews]);
    
    if(isStop){
        return;
    }
    [self stopTimer];
    if(isSuccess){
        return;
    }
    isSuccess = YES;
    
//    NSArray *subViews = [adView subviews];
//    if (subViews==NULL || [subViews count] == 0) {
//        return;
//    }else{
        [adMoGoCore adapter:self didReceiveAdView:adMiidiView];
//    }
}

// 请求广告条数据失败后调用
//
// 详解:当接收服务器返回的广告数据失败后调用该函数
// 补充：第一次和接下来每次如果请求失败都会调用该函数
- (void)didMiidiBasFailReceiveAd:(MiidiAdView *)adView  withMiidiBasError:(NSError *)error{
    if(isStop || isSuccess){
        return;
    }
    [self stopTimer];
    [adMoGoCore adapter:self didFailAd:error];
}



@end
