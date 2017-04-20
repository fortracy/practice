//
//  FileUtils.h
//  practicework
//
//  Created by bleach on 16/6/12.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

NSInteger loadFileIntoMemory(const char *filename, unsigned char **out);

@interface FileUtils : NSObject

@end
