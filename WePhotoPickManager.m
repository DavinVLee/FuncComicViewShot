//
//  WePhotoPickManager.m
//  comics
//
//  Created by 李翔 on 16/2/2.
//  Copyright © 2016年 WeComics. All rights reserved.
//

#import "WePhotoPickManager.h"
#import "WeLibraryAPI.h"
#import "ZDStickerView.h"
#import "WeFuncComicView.h"


@interface WePhotoPickManager ()


@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, strong, getter=getQueue) dispatch_queue_t queue;

@end

@implementation WePhotoPickManager

+ (void)getShareImageFromView:(UIView *)view andTopView:(UIView *)topView andSquare:(BOOL)isSquare andWidth:(float)width andScale:(NSInteger)scale andBlock:(WePhotoPickManagerGetImageBlock)block;
{
    float backWidth = CGRectGetHeight(view.frame);
    float backHeight = CGRectGetWidth(view.frame);
        @autoreleasepool {
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSaveGState(context);
            CGContextSetAllowsAntialiasing(context, true);
            CGContextSetShouldAntialias(context, true);
            CGContextTranslateCTM(context, view.center.x, view.center.y);
            CGContextConcatCTM(context, view.transform);
            CGContextTranslateCTM(context, -view.bounds.size.width * view.layer.anchorPoint.x, -view.bounds.size.height * view.layer.anchorPoint.y);
            
            if([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
                [view drawViewHierarchyInRect:CGRectMake(0, 0 , width, width*backWidth/backHeight) afterScreenUpdates:YES];
            else
                [view.layer renderInContext:UIGraphicsGetCurrentContext()];
            
            
            UIImage *comicImage = UIGraphicsGetImageFromCurrentImageContext();
            CGContextRestoreGState(context);
       
            if (!isSquare) {
                WeFuncComicView *comicView = (WeFuncComicView *)view;
                float rate = 414.0/CGRectGetWidth(comicView.backScrollView.frame) ;
                float offY = 0;
                if (!mIsiP6 && !mIsiP6Plus && !mIsPad) {
                    offY = 4;
                }
                CGRect imageRect = CGRectMake(0, CGRectGetMinY(comicView.backScrollView.frame)*rate*scale + offY/2,CGRectGetWidth(comicView.backScrollView.frame)*rate*scale , CGRectGetHeight(comicView.backScrollView.frame)*rate*scale - offY);
                CGImageRef imageRef = CGImageCreateWithImageInRect([comicImage CGImage], imageRect);
                UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:3.0 orientation:UIImageOrientationUp];
                CGImageRelease(imageRef);
                if (newImage) {
                    block(newImage);
                }
            }else
            {
                if (block) {
                    block(comicImage);
                }
            }
        }
}

#pragma mark - init

+ (WePhotoPickManager *)instance
{
    static WePhotoPickManager *_manager = nil;
    static dispatch_once_t managerOnce;
    dispatch_once(&managerOnce, ^{
        _manager = [[WePhotoPickManager alloc] init];
    });
    return _manager;
}

- (id)init
{
    if (self == [super init]) {
        [self setup];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setup
{
    _imageArray = [NSMutableArray array];
    _selectedIndex = 0;
    _boardAllSelected = YES;
    _tempComicViewDic = [[NSMutableDictionary alloc] init];
    _comicViewArray = [[NSMutableArray alloc] initWithCapacity:6];
    
}

- (dispatch_queue_t)getQueue
{
    if (!_queue) {
        _queue = dispatch_queue_create("photoPickManager", NULL);
    }
    return _queue;
}

#pragma mark - call_Method
- (void)exchangeImageWithFromIndex:(NSInteger)fromIndex andToIndex:(NSInteger)toIndex
{
    if (_imageArray.count > fromIndex && _imageArray.count > toIndex) {

        WeFuncComicView *comicView = [_comicViewArray objectAtIndex:fromIndex];
        [_comicViewArray removeObjectAtIndex:fromIndex];
        [_comicViewArray insertObject:comicView atIndex:toIndex];
        
        UIImage *image = [_imageArray objectAtIndex:fromIndex];
        [_imageArray removeObjectAtIndex:fromIndex];
        [[self mutableArrayValueForKey:@"imageArray"] insertObject:image atIndex:toIndex];
       
       
    }
}

- (void)deleteImageWithIndex:(NSInteger)index
{
    if (_imageArray.count > index) {
         [_comicViewArray removeObjectAtIndex:index];
        [[self mutableArrayValueForKey:@"imageArray"] removeObjectAtIndex:index];
       
    }
}

- (void)checkAndUpdateComicViewArray
{
    if (_imageArray.count > _comicViewArray.count) {
        for (int i = (int)_comicViewArray.count; i < _imageArray.count; i++) {
            
            BOOL exist = [self checkComicViewExistInTempDicWithSelectedIndex:i+1];
            if (exist) {
                WeFuncComicView *comiView = [_tempComicViewDic objectForKey:[NSString stringWithFormat:@"%ld",(long)i+1]];
                CGRect rect = comiView.frame;
                rect.origin.x = 0;
                rect.origin.y = 0;
                comiView.frame = rect;
                comiView.stickBackView.hidden = NO;
                 comiView.backgroundColor = [[WeTheme instance] getColorWithIndex:15];
                [_comicViewArray addObject:comiView];
                [_tempComicViewDic removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)i+1]];
            }else
            {
                UIImage *image = [_imageArray objectAtIndex:i];
                WeFuncComicView *comicView = [[WeFuncComicView alloc] initWithFrame:CGRectMake(0, 0, mScreenWidth, mScreenWidth)];
                [comicView setOrginImage:image];
                [_comicViewArray addObject:comicView];
                }

          
        }
    }
}

- (void)copyImageWithIndex:(NSInteger)index
{
    if (_imageArray.count > index) {
        UIImage * image = [_imageArray objectAtIndex:index];
        UIImage *image2 = [image copy];
        [_imageArray insertObject:image2 atIndex:index + 1];
    }
}

- (void)allComicViewSetBoardWithIndex:(NSInteger)index withBlock:(WePhotoPickManagerAllComicSetBlock)block
{
    for (WeFuncComicView *comicView in _comicViewArray) {
        [comicView boardSelectedWithIndex:index];
    }
    if (block) {
        block();
    }
}

- (void)allComicViewBoardResetWithBlock:(WePhotoPickManagerAllComicSetBlock)block;
{
    for (WeFuncComicView *comicView in _comicViewArray) {
        [comicView boardReSet];
    }
    if (block) {
        block();
    }
 
}

- (void)allComicViewBoardResetExceptIndex:(NSInteger)index
{
    for (int i = 0 ; i<_comicViewArray.count; i++) {
        if (i != index) {
            WeFuncComicView *comicView = [_comicViewArray objectAtIndex:i];
            [comicView boardReSet];
        }
    }
}


- (void)allComicViewBoardStatusSaveWithBlock:(WePhotoPickManagerAllComicSetBlock)block
{
    for (WeFuncComicView *comicView in _comicViewArray) {
        [comicView boardSave];
    }
    if (block) {
        block();
    }

}

- (void)removeAllStickerViewFrameWithExceptView:(ZDStickerView *)stickerview
{
    for (WeFuncComicView *comic in _comicViewArray ) {
        [comic removeAllStickerViewFrameWithExceptView:stickerview];
    }
}

- (BOOL)checkComicViewExistInTempDicWithSelectedIndex:(NSInteger)index
{
    return [[self.tempComicViewDic allKeys] containsObject:[NSString stringWithFormat:@"%ld",(long)index]];
}

- (WeFuncComicView *)getComicViewFromTempDicWithIndex:(NSInteger)index
{
    return [self.tempComicViewDic objectForKey:[NSString stringWithFormat:@"%ld",(long)index]];
}

#pragma  mark - add_delete

- (NSInteger)addImage:(UIImage *)image andSelectedIndex:(NSInteger)cellIndex
{
    [_lock lock];
    [[self mutableArrayValueForKey:@"imageArray"] addObject:image];//调用观察者响应
    _selectedIndex = _imageArray.count;
    [mNotificationCenter postNotificationName:FuncImageThumbAddNotification object:@{@"data" : @[@(cellIndex)]}];
    [_lock unlock];
    return _selectedIndex;
}

- (NSInteger)deleteImage:(NSInteger)index
{
    [_lock lock];
    if (_imageArray.count > index - 1) {
        [[self mutableArrayValueForKey:@"imageArray"] removeObjectAtIndex:index - 1];
        if ([self checkComicViewExistInTempDicWithSelectedIndex:index]) {
            [self.tempComicViewDic removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)index]];
        }
        _selectedIndex = _imageArray.count;
    }
    [mNotificationCenter postNotificationName:FuncImagePickViewThumbDeleteNotification object:@{@"data":@(index)}];
    [_lock unlock];
    return _selectedIndex;
}

- (NSInteger)deleteImageWithIndexs:(NSArray *)indexArray
{
     NSArray *imageIndexArray = [indexArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {//删除序列排序
         NSInteger c1 = [obj1 integerValue];
         NSInteger c2 = [obj2 integerValue];
         if (c1 > c2) {
             return NSOrderedDescending;
         }else
         {
             return NSOrderedAscending;
         }
     }];

    [_lock lock];
    for (int i = 0; i < imageIndexArray.count; i++) {//从小到大依次删除
        NSInteger delInd = [[imageIndexArray objectAtIndex:i] integerValue] - i - 1;
        if (_imageArray.count > delInd) {
            [[self mutableArrayValueForKey:@"imageArray"] removeObjectAtIndex:delInd];
            if ([self checkComicViewExistInTempDicWithSelectedIndex:delInd + 1]) {
                [self.tempComicViewDic removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)delInd + 1]];
            }

        }
    }
    if (imageIndexArray > 0) {
        [mNotificationCenter postNotificationName:FuncImagePickGroupChangeNotification object:@{@"data" : imageIndexArray}];
    }
    [_lock unlock];
    return _imageArray.count;
}

#pragma mark - get
- (NSInteger)getThumbCount
{
    return _imageArray.count;
}

- (UIImage *)getImage:(NSInteger)index
{
    if (_imageArray.count > index) {
        return [_imageArray objectAtIndex:index];
    }else
    {
        return nil;
    }
}

- (WeFuncComicView *)getComicView:(NSInteger)index
{
//    if (self.comicViewArray.count > index) {
//        return [self.comicViewArray objectAtIndex:index];
//    }else
//    {
        [self checkAndUpdateComicViewArray];
        if (self.comicViewArray.count > index) {
            return [self.comicViewArray objectAtIndex:index];
        }else
        {
             return nil;
        }
//    }
}

- (NSInteger)getIndexWithComicView:(WeFuncComicView *)comicView
{
    NSInteger index = 0;
    if ([_comicViewArray containsObject:comicView]) {
        index  = [self.comicViewArray indexOfObject:comicView];
        if (index > 6 || index < 0) {
            return 0;
        }

    }else
    {
        return -1;
    }
       return index;
}

- (NSMutableArray *)getComicViewArray
{
    if (!_comicViewArray || _comicViewArray.count < 1) {
        
            for (int i = 0 ; i < _imageArray.count;  i ++) {
                UIImage *image = [_imageArray objectAtIndex:i];
             BOOL exist = [self checkComicViewExistInTempDicWithSelectedIndex:i+1];
                if (exist) {
                    WeFuncComicView *comiView = [_tempComicViewDic objectForKey:[NSString stringWithFormat:@"%ld",(long)i+1]];
                    CGRect rect = comiView.frame;
                    rect.origin.x = 0;
                    rect.origin.y = 0;
                    comiView.frame = rect;
                    comiView.stickBackView.hidden = NO;
                     comiView.backgroundColor = [[WeTheme instance] getColorWithIndex:15];
                    comiView.backScrollView.alwaysBounceHorizontal = YES;
                    comiView.backScrollView.alwaysBounceVertical = YES;
                    [_comicViewArray addObject:comiView];
                    [_tempComicViewDic removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)i+1]];
                }else
                {
                    WeFuncComicView *comicView = [[WeFuncComicView alloc] initWithFrame:CGRectMake(0, 0, mScreenWidth, mScreenWidth)];
                    [comicView setOrginImage:image];
                    [comicView statusSave];
                    [_comicViewArray addObject:comicView];
                }
          
        }
    }
    return _comicViewArray;
}


- (void)getViewShotWithBlock:(WePhotoPickManagerGetDictionAryBlock)block;
{
   __block  NSMutableArray *imageArray = [[NSMutableArray alloc] initWithCapacity:6];
   __block float height = 0.0;
    __block  NSMutableArray *heightArray = [[NSMutableArray alloc] initWithCapacity:6];
    __block UIImage *thumbImage ;
    WS(ws);
    WePhotoPickManagerGetImageBlock imageBlock = ^(UIImage *image)
    {
        if (imageArray.count == ws.comicViewArray.count) {
            UIGraphicsEndImageContext();
            double delayInSeconds = 1.0;
            dispatch_time_t timeQueue = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *NSEC_PER_SEC));
                dispatch_after(timeQueue, dispatch_get_main_queue(), ^{
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(414, height), NO, 3.0);
                if (!mIsPad) {
                    CGContextRef context = UIGraphicsGetCurrentContext();
                    CGContextSetAllowsAntialiasing(context, true);
                    CGContextSetShouldAntialias(context, true);
                    
                }
                height = 0;
                for (int i = 0; i < imageArray.count; i++) {
                    UIImage *tempImage = imageArray[i];
                    [tempImage drawInRect:CGRectMake(0, height, 414, [heightArray[i] floatValue])];
                    height += [heightArray[i] floatValue];
                }
                UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
                NSDictionary *dic = nil;
                if (resultImg && thumbImage != nil) {
                    dic = @{kImage : resultImg, kTotalHeight : @(height), kHightArray : heightArray, kThumbImage : thumbImage};
                }else if (resultImg)
                {
                    dic = @{kImage : resultImg, kTotalHeight : @(height), kHightArray : heightArray};
                }
                if (block) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block(dic);
                    });
                    
                }
            });
 
        }
    };
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(414.0, 414.0), YES, 3.0);
    
    for (int i = 0; i < self.comicViewArray.count; i++) {
        WeFuncComicView *comicView = [self.comicViewArray objectAtIndex:i];
        BOOL isSquare = comicView.cvType == CVSquare;
        dispatch_sync(mAppDelegate.queue, ^{
            [WePhotoPickManager getShareImageFromView:comicView andTopView:comicView.stickBackView andSquare:isSquare andWidth:414.0 andScale:3.0 andBlock:^(UIImage *image) {
                if (i == 0) {
                    thumbImage = image;
                }
                [imageArray addObject:image];
                [heightArray addObject:@(image.size.height)];
                height += image.size.height;
                imageBlock(image);
                
            }];
  
        });
    }
   }

- (NSInteger)getIndexWithImage:(UIImage *)image
{
    NSInteger index = [_imageArray indexOfObject:image];
    return index;
}

#pragma mark - clearCache
- (void)clearCache
{
    [[self mutableArrayValueForKey:@"imageArray"] removeAllObjects];
    [[self mutableArrayValueForKey:@"comicViewArray"] removeAllObjects];
    _boardAllSelected = YES;
    _selectedIndex = 0;
    [_tempComicViewDic removeAllObjects];
}

@end
