/********* myPlugin.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <JDSDK/JDKeplerSDK.h>
#import <AlibcTradeSDK/AlibcTradeSDK.h>
@interface myPlugin : CDVPlugin {
  // Member variables go here.
}

- (void)openJD:(CDVInvokedUrlCommand*)command;

- (void)openTaobao:(CDVInvokedUrlCommand*)command;

@end

@implementation myPlugin

- (void)pluginInitialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *jdAppKey = [self.commandDelegate settings] objectForKey:@"jdAppKey"];
        NSString *jdAppSecret = [self.commandDelegate settings] objectForKey:@"jdAppSecret"];
        [[KeplerApiManager sharedKPService] asyncInitSdk:jdAppKey secretKey:jdAppSecret sucessCallback:^{
        //        ZZCLog(@"KeplerApiManager asyncInitSdk success");
            } failedCallback:^(NSError *error) {
        //        ZZCLog(@"KeplerApiManager asyncInitSdk error: %@", error);
            }];
        
        [[AlibcTradeSDK sharedInstance] setEnv:AlibcEnvironmentRelease];
         [[AlibcTradeSDK sharedInstance] asyncInitWithSuccess:^{
            NSLog(@"初始化成功");
        } failure:^(NSError *error) {
            NSLog(@"初始化失败");
        }];
    });
    
}

- (void)openJD:(CDVInvokedUrlCommand*)command
{
    __weak myPlugin *wSelf = self;
    NSString *url = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSDictionary *userInfo = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
    if (![[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"openapp.jdmobile://"]]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"code":@(-1), @"msg":@"app不存在"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        [[KeplerApiManager sharedKPService] openKeplerPageWithURL:url userInfo:userInfo failedCallback:^(NSInteger code, NSString *url) {
            if (wSelf) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"code":@(code), @"msg" : @"打开失败"}];
                [wSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    }
}

- (void)openTaobao:(CDVInvokedUrlCommand*)command{
    NSString *url = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSDictionary *showParams = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tbopen://"]]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"code":@(-1), @"msg":@"app不存在"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        AlibcWebViewController *vc = [[AlibcWebViewController alloc] init];
        AlibcTradeShowParams* showInfo = [[AlibcTradeShowParams alloc] init];
        showInfo.openType = [[showParams objectForKey:@"openType"] integerValue];
        showInfo.isNeedPush= [[showParams objectForKey:@"isNeedPush"] boolValue];
        showInfo.backUrl = [showParams objectForKey:@"backUrl"];
        showInfo.backUrl = [showParams objectForKey:@"linkKey"];
        showInfo.degradeUrl = [showParams objectForKey:@"degradeUrl"];
        showInfo.nativeFailMode=[[showParams objectForKey:@"nativeFailMode"] integerValue];
        NSString *identity = [showParams objectForKey:@"identity"];
        NSInteger ret =[[AlibcTradeSDK sharedInstance].tradeService openByUrl:url identity:identity ? identity : @"trade" webView:vc.webView parentController:vc showParams:showInfo taoKeParams:nil trackParam:nil tradeProcessSuccessCallback:^(AlibcTradeResult * _Nullable result) {
            
        } tradeProcessFailedCallback:^(NSError * _Nullable error) {
            
        }];
        NSString *msg = [self alibcResutStatus:ret];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"code":@(ret), @"msg":msg?msg:@""}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (NSString *)alibcResutStatus:(NSInteger)status{
    NSString *msg = nil;
    switch (status) {
        case 0:
            msg = @"标识跳转到手淘打开了";
            break;
        case 1:
            msg = @"标识用h5打开了";
            break;
        case 2:
            msg = @"标识用小程序打开了Url";
            break;
        case -1:
            msg = @"入参出错";
            break;
        case -2:
            msg = @"此URL需要使用openByCode 通过code来进行页面打开";
            break;
        case -3:
            msg = @"打开页面失败";
            break;
        case -4:
            msg = @"sdk初始化失败";
            break;
        case -5:
            msg = @"该版本SDK已被废弃，需要升级";
            break;
        case -6:
            msg = @"sdk不允许唤端";
            break;
        default:
            break;
    }
    return msg;
}

@end
