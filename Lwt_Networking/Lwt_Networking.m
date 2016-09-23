//
//  Lwt_Network.m
//  App
//
//  Created by 李文韬 on 16/8/16.
//  Copyright © 2016年 com.lightcar. All rights reserved.
//

#import "Lwt_Networking.h"


@interface Lwt_Networking ()

@property (nonatomic,assign,readwrite) NetworkStatus networkStatu;


@property (nonatomic,strong,readwrite) AFHTTPSessionManager *httpManager;

@property (nonatomic,strong,readwrite) AFURLSessionManager *urlManager;

@end


@implementation Lwt_Networking


+ (instancetype)sharedHTTPSession
{
    static Lwt_Networking *httpSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpSession = [[Lwt_Networking alloc] initHTTPSesion];
    });
    
    return httpSession;
}

+ (instancetype)sharedURLSession
{
    static Lwt_Networking *urlSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urlSession = [[Lwt_Networking alloc] initURLPSesion];
    });
    
    return urlSession;
}



- (instancetype)initHTTPSesion
{
    self = [super init];
    if (self)
    {
        
        
        //缓存在缓存文件夹 NSCachesDirectory
        _httpCache = [YYCache cacheWithName:NetworkResponseName];
        _httpCache.memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
        
        //检测网络状态
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            _networkStatu = status;
        }];
        [manager startMonitoring];
        
        _httpManager = [AFHTTPSessionManager manager];
        
        //设置请求参数的类型:HTTP (AFJSONRequestSerializer,AFHTTPRequestSerializer)
        _httpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        //设置请求的超时时间
        _httpManager.requestSerializer.timeoutInterval = 30.f;
        //设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
        _httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        //    https请求设置
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        _httpManager.securityPolicy = securityPolicy;
        
        _httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain", nil];
        
    }
    
    return self;
}

- (instancetype)initURLPSesion
{
    self = [super init];
    if (self)
    {
      
        
        //缓存在缓存文件夹 NSCachesDirectory
        _urlCache = [YYCache cacheWithName:resumeDataDoucment];
        _urlCache.memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
        
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
         _urlManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
    }
    
    return self;
}



#pragma mark - GET请求

- (void  )GET:(NSString *)URL isCache:(BOOL)isCache parameters:(NSDictionary *)parameters success:(Success)success failure:(Failed)failure
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
   
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",URL,jsonStr];
    
    //读取缓存
    id cacheData = nil;
    
    if (isCache)
    {
        //同步取缓存
        cacheData = [_httpCache objectForKey:cacheKey];
        
        if (success!=nil && cacheData !=nil)
        {
            success(cacheData);
        }


    }
    
    
    [_httpManager GET:URL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (isCache)
        {
            if (success && ![cacheData isEqual:responseObject])
            {
                success(responseObject);
                //异步缓存数据
                [_httpCache setObject:responseObject forKey:cacheKey withBlock:nil];
            }

        }else
        {
            if (success)
            {
                success(responseObject);
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (failure)
        {
            failure(error);
        }
    }];
    
    
   
}


#pragma mark - POST请求

- (void)POST:(NSString *)URL isCache:(BOOL)isCache parameters:(NSDictionary *)parameters success:(Success)success failure:(Failed)failure
{

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    //可能url一样 key+
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",URL,jsonStr];
    
    
    //读取缓存
    id cacheData = nil;
    
    if (isCache)
    {
        //同步取缓存
        cacheData = [_httpCache objectForKey:cacheKey];
        
        if (success!=nil && cacheData !=nil)
        {
            success(cacheData);
        }
    }

  
   
    [_httpManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {

        NSLog(@"%f",uploadProgress.completedUnitCount*0.1/uploadProgress.totalUnitCount);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (isCache)
        {
            if (success && ![cacheData isEqual:responseObject])
            {
                success(responseObject);
                //缓存数据
             [_httpCache setObject:responseObject forKey:cacheKey withBlock:nil];
            }
            
        }else
        {
            if (success)
            {
                success(responseObject);
            }
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (failure)
        {
            failure(error);
        }
    }];
}


#pragma mark - 上传数据
- (NSURLSessionUploadTask *)uploadWithURL:(NSString *)URL parameters:(NSDictionary *)parameters datas:(NSArray<NSData *> *)datas name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(Progress)progress success:(Success)success failure:(Failed)failure
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [datas enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [formData appendPartWithFileData:obj name:name fileName:fileName  mimeType:mimeType];
        }];
    } error:nil];
    
   NSURLSessionUploadTask *task =  [_urlManager
     uploadTaskWithStreamedRequest:request
     progress:^(NSProgress * _Nonnull uploadProgress) {
       
         //上传进度
         if (progress)
         {
             CGFloat progressF = uploadProgress.completedUnitCount*1.0/uploadProgress.totalUnitCount;
             progress(progressF);
         }
     }
     completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         if (error)
         {
            
             if (failure)
             {
                 failure(error);
             }
         } else {
           
             if (success)
             {
                 success(responseObject);
             }
         }
     }];
    
    [task resume];
    
    return task;

}


#pragma mark - 下载数据
- (NSURLSessionDownloadTask *)downloadWithURL:(NSString *)URL fileName:(NSString *)fileName progress:(Progress)progress Success:(Success)success failure:(Failed)failure;
    
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    
    NSURLSessionDownloadTask *downloadTask = [_urlManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        if (progress)
        {
            CGFloat progressF = downloadProgress.completedUnitCount*1.0/downloadProgress.totalUnitCount;
            progress(progressF);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:fileName];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (success)
        {
            success(filePath.absoluteString);
        }
       
        if(error&&failure)
        {
            failure(error);
        }
        
    }];
    
    //开始下载
    [downloadTask resume];
    
    return downloadTask;
}

#pragma mark - 续传数据

- (NSURLSessionDownloadTask *)downloadwithResumeData:(NSData *)resumeData fileName:(NSString *)fileName progress:(Progress)progress Success:(Success)success failure:(Failed)failure
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

  NSURLSessionDownloadTask *downloadTask = [_urlManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        if (progress)
        {
            CGFloat progressF = downloadProgress.completedUnitCount*1.0/downloadProgress.totalUnitCount;
            progress(progressF);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:fileName];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (success)
        {
            success(filePath.absoluteString);
        }
        
        if(error&&failure)
        {
            failure(error);
        }
    }];
    
    //开始下载
    [downloadTask resume];
    
    return downloadTask;

}






@end
