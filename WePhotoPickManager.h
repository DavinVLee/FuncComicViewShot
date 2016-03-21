//
//  WePhotoPickManager.h
//  comics
//
//  Created by 李翔 on 16/2/2.
//  Copyright © 2016年 WeComics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeFuncComicView.h"
#import "ZDStickerView.h"

#define kImage @"image"
#define kTotalHeight @"totalHeight"
#define kHightArray @"heightArray"
#define kThumbImage @"thumbImage"

typedef enum SelectiveType
{
    SelectiveMulti = 0, //多选
    SelectiveSingle = 1,//单选
    
}SelectiveType;

typedef void (^WePhotoPickManagerAllComicSetBlock)(void);
typedef void (^WePhotoPickManagerGetImageBlock)(UIImage *image);
typedef void (^WePhotoPickManagerGetDictionAryBlock)(NSDictionary *dic);

@interface WePhotoPickManager : NSObject
/**
  * 已选择缩略图容器
  */
@property (nonatomic, strong) NSMutableArray *imageArray;
/**
  * 管理WecomicView数组
  */
@property (nonatomic, strong, getter=getComicViewArray) NSMutableArray *comicViewArray;

@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic) BOOL boardAllSelected;

@property (nonatomic, strong) NSMutableDictionary *tempComicViewDic;

/**
  * 单例获取
  */
+ (WePhotoPickManager *)instance;

/**
  * 添加图片
  * @param UIImage
  * @return index当前图片总数量
  */
- (NSInteger)addImage:(UIImage *)image andSelectedIndex:(NSInteger)cellIndex;

- (NSInteger)deleteImage:(NSInteger)index;

- (NSInteger)deleteImageWithIndexs:(NSArray *)indexArray;

/**
  * 删除缓存 在每次退出照片选择页面时调用
  */
- (void)clearCache;

/**
  * 获取当前已选图片数量
  */
- (NSInteger)getThumbCount;

/**
  * 获取已选图片
  * @param 图片序列
  * @return UIImage
  */
- (UIImage *)getImage:(NSInteger)index;

/**
  * 获取comicView
  * @param comicView序列
  * @return WeFuncComicView
  */
- (WeFuncComicView *)getComicView:(NSInteger)index;

- (NSInteger)getIndexWithComicView:(WeFuncComicView *)comicView;

/**
  * 获取所有图片的合成图
  */
- (void)getViewShotWithBlock:(WePhotoPickManagerGetDictionAryBlock)block;

/**
  * 获取截图包括非子视图的图片、即截屏
  * @param view: 截图的视图
  * @param width: 生成图片的宽度（高度比例计算）
  * @param scale: 生成图片scale;
  */
+ (void)getShareImageFromView:(UIView *)view andTopView:(UIView *)topView andSquare:(BOOL)isSquare andWidth:(float)width andScale:(NSInteger)scale andBlock:(WePhotoPickManagerGetImageBlock)block;

- (void)exchangeImageWithFromIndex:(NSInteger)fromIndex andToIndex:(NSInteger)toIndex;

- (void)deleteImageWithIndex:(NSInteger)index;

- (NSInteger)getIndexWithImage:(UIImage *)image;

- (void)checkAndUpdateComicViewArray;

- (void)copyImageWithIndex:(NSInteger)index;

- (void)allComicViewSetBoardWithIndex:(NSInteger)index withBlock:(WePhotoPickManagerAllComicSetBlock)block;

- (void)allComicViewBoardResetWithBlock:(WePhotoPickManagerAllComicSetBlock)block;

- (void)allComicViewBoardResetExceptIndex:(NSInteger)index;

- (void)allComicViewBoardStatusSaveWithBlock:(WePhotoPickManagerAllComicSetBlock)block;

- (void)removeAllStickerViewFrameWithExceptView:(ZDStickerView *)stickerview;

- (BOOL)checkComicViewExistInTempDicWithSelectedIndex:(NSInteger)index;

- (WeFuncComicView *)getComicViewFromTempDicWithIndex:(NSInteger)index;

@end
