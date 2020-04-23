//
//  HyChartLineLayer.m
//  HyChartsDemo
//
//  Created by Hy on 2018/3/25.
//  Copyright © 2018 Hy. All rights reserved.
//

#import "HyChartLineLayer.h"
#import "HyChartLineConfigure.h"


@interface HyChartLineLayer ()
@property (nonatomic, strong) NSDictionary<NSString *, NSArray *> *layerDict;
@property (nonatomic, strong) NSArray<HyChartLineOneConfigure *> *configures;
@end


@implementation HyChartLineLayer

- (void)setNeedsRendering {
    [super setNeedsRendering];
        
    if (!self.dataSource.modelDataSource.visibleModels.count) {
        return;
    }
    
    CGFloat height = CGRectGetHeight(self.bounds);
    double maxValue = self.dataSource.axisDataSource.yAxisModel.yAxisMaxValue.doubleValue;
    double heightRate = maxValue != 0 ? height / maxValue : 0;
    CGFloat width = self.dataSource.configreDataSource.configure.scaleWidth;
    
    NSMutableArray<UIBezierPath *> *paths = @[].mutableCopy;
    NSMutableArray<UIBezierPath *> *dotPaths = @[].mutableCopy;
    NSMutableArray<NSValue *> *startPs = @[].mutableCopy;
    NSMutableArray<NSValue *> *endPs = @[].mutableCopy;
    NSInteger valueCount = self.dataSource.modelDataSource.visibleModels.firstObject.values.count;
    NSInteger count = self.dataSource.modelDataSource.visibleModels.count;
    for (NSInteger index = 0; index < valueCount; index ++) {
       [paths addObject:UIBezierPath.bezierPath];
       [dotPaths addObject:UIBezierPath.bezierPath];
    }

    for (NSInteger i = 1; i < self.dataSource.modelDataSource.visibleModels.count; i++) {

       NSMutableArray *startPoints = @[].mutableCopy;
       id<HyChartLineModelProtocol> startModel = self.dataSource.modelDataSource.visibleModels[i - 1];
       [startModel.values enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
           CGPoint startPoint = CGPointMake(startModel.visiblePosition + width / 2, height - (obj.doubleValue * heightRate));
           [startPoints addObject:[NSValue valueWithCGPoint:startPoint]];
           
           if (i == 1) {
               [self convertPoint:startPoint toLayer:self.layers[idx]];
               [paths[idx] moveToPoint:startPoint];
               [startPs addObject:[NSValue valueWithCGPoint:startPoint]];
           }
       }];
       
       NSMutableArray *endPoints = @[].mutableCopy;
       id<HyChartLineModelProtocol> endModel = self.dataSource.modelDataSource.visibleModels[i];
       [endModel.values enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           CGPoint endPoint = CGPointMake(endModel.visiblePosition + width / 2, height - (obj.doubleValue * heightRate));
            [endPoints addObject:[NSValue valueWithCGPoint:endPoint]];
           if (i == count - 1) {
               [endPs addObject:[NSValue valueWithCGPoint:endPoint]];
           }
       }];

       for (NSInteger j = 0; j < valueCount; j ++) {
           
           HyChartLineOneConfigure *configure = self.configures[j];
           CGPoint startP = [startPoints[j] CGPointValue];
           CGPoint endP = [endPoints[j] CGPointValue];
           
           if (configure.linePointType != HyChartLinePointTypeNone) {
               
               CGRect startRect = CGRectZero;
               if (i == 1) {
                   startRect = CGRectMake(startP.x - (configure.linePointSize.width / 2), startP.y - (configure.linePointSize.height / 2), configure.linePointSize.width, configure.linePointSize.height);
               }
               
               CGRect endRect = CGRectMake(endP.x - (configure.linePointSize.width / 2), endP.y - (configure.linePointSize.height / 2), configure.linePointSize.width, configure.linePointSize.height);
               if (configure.linePointType == HyChartLinePointTypeRect) {
                   if (i == 1) {
                       [dotPaths[j] appendPath:[UIBezierPath bezierPathWithRect:startRect]];
                   }
                  [dotPaths[j] appendPath:[UIBezierPath bezierPathWithRect:endRect]];

               } else  {
                   if (i == 1) {
                       [dotPaths[j] appendPath:[UIBezierPath bezierPathWithOvalInRect:startRect]];
                   }
                   [dotPaths[j] appendPath:[UIBezierPath bezierPathWithOvalInRect:endRect]];
               }
           }

           if (configure.lineType == HyChartLineTypeStraight) {
               [paths[j] addLineToPoint:endP];
           } else {
               //  二次贝塞尔曲线 addQuadCurveToPoint
               //  三次贝塞尔曲线
               [paths[j] addCurveToPoint:endP
               controlPoint1:CGPointMake((startP.x + endP.x) / 2, startP.y)
               controlPoint2:CGPointMake((startP.x + endP.x) / 2, endP.y)];
           }
       }
    }
    
            
    [self.layers enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.path = paths[idx].CGPath;
        HyChartLineOneConfigure *configure = self.configures[idx];
        if (configure.linePointType != HyChartLinePointTypeNone) {
          self.dotLayers[idx].path = dotPaths[idx].CGPath;
        }

        if (configure.shadeColors.count > 1) {
            UIBezierPath *shadePath = [UIBezierPath bezierPathWithCGPath:paths[idx].CGPath];
            [shadePath addLineToPoint:CGPointMake([endPs[idx] CGPointValue].x, CGRectGetMaxY(self.bounds))];
            [shadePath addLineToPoint:CGPointMake([startPs[idx] CGPointValue].x, CGRectGetMaxY(self.bounds))];
            [shadePath closePath];
            ((CAShapeLayer *)(self.shadeLayers[idx].mask)).path = shadePath.CGPath;
        }
    }];
}

- (NSDictionary<NSString *,NSArray *> *)layerDict {
    if (!_layerDict){
        NSMutableArray<CAShapeLayer *> *layers = @[].mutableCopy;
        NSMutableArray<CAShapeLayer *> *dotLayers = @[].mutableCopy;
        NSMutableArray<CAGradientLayer *> *shadeLayers = @[].mutableCopy;
        NSMutableArray<HyChartLineOneConfigure *> *configures = @[].mutableCopy;
        NSInteger count = self.dataSource.modelDataSource.models.firstObject.values.count;
        if (self.dataSource.configreDataSource.configure.lineConfigureAtIndexBlock) {
           for (NSInteger i = 0; i < count; i++) {
               HyChartLineOneConfigure *configure = HyChartLineOneConfigure.defaultConfigure;
               self.dataSource.configreDataSource.configure.lineConfigureAtIndexBlock(i, configure);
               [configures addObject:configure];
           
               CAShapeLayer *layer = [CAShapeLayer layer];
               layer.strokeColor = configure.lineColor.CGColor;
               layer.lineWidth = configure.lineWidth;
               layer.fillColor = UIColor.clearColor.CGColor;
               layer.lineCap = kCALineCapRound;
               layer.lineJoin = kCALineCapRound;
               layer.masksToBounds = YES;
               layer.frame = self.bounds;
               [self addSublayer:layer];
               [layers addObject:layer];
               
               CAShapeLayer *dotLayer = [CAShapeLayer layer];
               dotLayer.lineWidth = configure.linePointWidth;
               dotLayer.fillColor = configure.linePointFillColor.CGColor;
               dotLayer.strokeColor = configure.linePointStrokeColor.CGColor;
               dotLayer.lineCap = kCALineCapRound;
               dotLayer.lineJoin = kCALineCapRound;
               dotLayer.zPosition = 999;
               dotLayer.masksToBounds = YES;
               dotLayer.frame = self.bounds;
               [self addSublayer:dotLayer];
               [dotLayers addObject:dotLayer];
               
               CAGradientLayer *shadeLayer = [CAGradientLayer layer];
               NSMutableArray *shadeColors = [NSMutableArray array];
               for (UIColor *color in configure.shadeColors) {
                   [shadeColors addObject:(__bridge id)color.CGColor];
               }
               shadeLayer.colors = shadeColors;
               shadeLayer.locations = @[@0.0, @0.2, @1.0];
               shadeLayer.startPoint = CGPointMake(0.5, 0.5);
               shadeLayer.endPoint = CGPointMake(0.5, 1);
               shadeLayer.mask = [CAShapeLayer layer];
               shadeLayer.frame = self.bounds;
               [self addSublayer:shadeLayer];
               [shadeLayers addObject:shadeLayer];
           }
       }
        _layerDict = @{@"layers" : layers.copy,
                       @"dotLayers" : dotLayers.copy,
                       @"shadeLayers" : shadeLayers.copy
        };
        self.configures = configures.copy;
    }
    return _layerDict;
}

- (NSArray<CAShapeLayer *> *)layers {
    return self.layerDict[@"layers"];
}

- (NSArray<CAShapeLayer *> *)dotLayers {
    return self.layerDict[@"dotLayers"];
}

- (NSArray<CAGradientLayer *> *)shadeLayers {
    return self.layerDict[@"shadeLayers"];
}

@end