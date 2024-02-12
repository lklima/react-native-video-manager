
#import "RNVideoManager.h"

@implementation RNVideoManager

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(merge:(NSArray *)fileNames
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [self MergeVideo:fileNames resolver:resolve rejecter:reject];
}

-(void)LoopVideo:(NSArray *)fileNames callback:(RCTResponseSenderBlock)successCallback
{
    for (id object in fileNames)
    {
        NSLog(@"video: %@", object);
    }
}


RCT_EXPORT_METHOD(trim:(NSString *)videoPath
                  startTime:(nonnull NSNumber *)startTime
                    endTime:(nonnull NSNumber *)endTime
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject) {
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    [self trimVideo:videoURL startTime:startTime endTime:endTime completion:^(NSURL *trimmedURL, NSError *error) {
        if (trimmedURL) {
            resolve(trimmedURL.absoluteString);
        } else {
            reject(@"trim_video_error", error.localizedDescription, error);
        }
    }];
}


RCT_EXPORT_METHOD(getVideoDuration:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSURL *videoURL = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    // Get the duration of the video
    CMTime duration = asset.duration;
    NSTimeInterval durationInSeconds = CMTimeGetSeconds(duration);
    
    resolve(@(durationInSeconds));
}

// trim functionality starts
- (void)trimVideo:(NSURL *)videoURL
        startTime:(NSNumber *)startTime
          endTime:(NSNumber *)endTime
       completion:(void (^)(NSURL *trimmedURL, NSError *error))completion {
    
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    CMTime startCMTime = CMTimeMakeWithSeconds([startTime doubleValue], NSEC_PER_SEC);
    CMTime endCMTime = CMTimeMakeWithSeconds([endTime doubleValue], NSEC_PER_SEC);
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    if (!exportSession) {
        NSError *error = [NSError errorWithDomain:@"TrimVideoError" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create AVAssetExportSession"}];
        completion(nil, error);
        return;
    }

    NSString* documentsDirectory= NSTemporaryDirectory();
    NSString * myDocumentPath = [documentsDirectory stringByAppendingPathComponent:@"trimmed_video.mp4"];
    NSURL * urlVideoMain = [[NSURL alloc] initFileURLWithPath: myDocumentPath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myDocumentPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:myDocumentPath error:nil];
    }
   
    exportSession.outputURL = urlVideoMain;
    exportSession.outputFileType = @"com.apple.quicktime-movie";
    exportSession.shouldOptimizeForNetworkUse = YES;
    // Set time range to trim
    CMTimeRange timeRange = CMTimeRangeMake(startCMTime, CMTimeSubtract(endCMTime, startCMTime));
    exportSession.timeRange = timeRange;
    // Perform the export asynchronously
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                completion(urlVideoMain, nil);
            } else {
                NSError *error = exportSession.error ? exportSession.error : [NSError errorWithDomain:@"TrimVideoError" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error occurred during video export"}];
                completion(nil, error);
            }
        });
    }];
}
// trim functionality ends

-(void)MergeVideo:(NSArray *)fileNames resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    
    CGFloat totalDuration;
    totalDuration = 0;
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime insertTime = kCMTimeZero;
    CGAffineTransform originalTransform;
    
    for (id object in fileNames)
    {
        
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:object]];
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        
        [videoTrack insertTimeRange:timeRange
                            ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                             atTime:insertTime
                              error:nil];
        
        [audioTrack insertTimeRange:timeRange
                            ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                             atTime:insertTime
                              error:nil];
        
        insertTime = CMTimeAdd(insertTime,asset.duration);
        
        // Get the first track from the asset and its transform.
        NSArray* tracks = [asset tracks];
        AVAssetTrack* track = [tracks objectAtIndex:0];
        originalTransform = [track preferredTransform];
    }
    
    // Use the transform from the original track to set the video track transform.
    if (originalTransform.a || originalTransform.b || originalTransform.c || originalTransform.d) {
        videoTrack.preferredTransform = originalTransform;
    }
    
    NSString* documentsDirectory= [self applicationDocumentsDirectory];
    NSString * myDocumentPath = [documentsDirectory stringByAppendingPathComponent:@"merged_video.mp4"];
    NSURL * urlVideoMain = [[NSURL alloc] initFileURLWithPath: myDocumentPath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myDocumentPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:myDocumentPath error:nil];
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = urlVideoMain;
    exporter.outputFileType = @"com.apple.quicktime-movie";
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch ([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
                reject(@"event_failure", @"merge video error",  nil);
                break;
                
            case AVAssetExportSessionStatusCancelled:
                break;
                
            case AVAssetExportSessionStatusCompleted:
                resolve([@"file://" stringByAppendingString:myDocumentPath]);
                break;
            default:
                break;
        }
    }];
}

- (NSString*) applicationDocumentsDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

@end
  
