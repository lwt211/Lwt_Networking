//
//  Lwt_Network.h
//  App
//
//  Created by 李文韬 on 16/8/16.
//  Copyright © 2016年 com.lightcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "YYCache.h"


//缓存数据文件夹名
static NSString *const NetworkResponseName= @"NetworkResponseCache";

//续传数据文件夹名
static NSString *const resumeDataDoucment = @"resumeDataDoucment";


//网络状态
typedef NS_ENUM(NSUInteger, NetworkStatus) {
    NetworkStatusUnknown = -1, //未知网络
    NetworkStatusNotReachable = 0, //无网络
    NetworkStatusReachableViaWWAN =1 ,//移动网络
    NetworkStatusReachableViaWiFi =2//WIFI
};


/**
 *  网络状态
 */
typedef void(^NetworkStatu)(NetworkStatus status);



/**
 请求成功
 */
typedef void(^Success)(id result);


/**
 请求失败
 */
typedef void(^Failed)(NSError *error);


/**
 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
 */
typedef void (^Progress)(CGFloat progress);


@interface Lwt_Networking : NSObject


@property (nonatomic,assign,readonly) NetworkStatus networkStatu;

@property (nonatomic,strong,readwrite) YYCache *httpCache;

@property (nonatomic,strong,readwrite) YYCache *urlCache;

@property (nonatomic,strong,readonly) AFHTTPSessionManager *httpManager;

@property (nonatomic,strong,readonly) AFURLSessionManager *urlManager;



+ (instancetype)sharedHTTPSession;
+ (instancetype)sharedURLSession;


/**
 *  GET 请求
 */

- (void )GET:(NSString *)URL isCache:(BOOL)isCache parameters:(NSDictionary *)parameters success:(Success)success
    failure:(Failed)failure;




/**
 *  POST请求
 */
- (void )POST:(NSString *)URL isCache:(BOOL)isCache parameters:(NSDictionary *)parameters success:(Success)success failure:(Failed)failure;


/**
 *  上传数据
 */

- (NSURLSessionUploadTask *)uploadWithURL:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                             datas:(NSData *)datas //多个数据
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                           mimeType:(NSString *)mimeType
                           progress:(Progress)progress
                            success:(Success)success
                            failure:(Failed)failure;

/**
 *  下载数据
 */
- (NSURLSessionDownloadTask *)downloadWithURL:(NSString *)URL fileName:(NSString *)fileName
                             progress:(Progress)progress
                              Success:(Success)success
                              failure:(Failed)failure;

/**
 *  续载数据
 */
- (NSURLSessionDownloadTask *)downloadwithResumeData:(NSData *)resumeData fileName:(NSString *)fileName progress:(Progress)progress Success:(Success)success failure:(Failed)failure;




@end
