//
//  FileUtils.m
//  practicework
//
//  Created by bleach on 16/6/12.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "FileUtils.h"

NSInteger loadFileIntoMemory(const char *filename, unsigned char **out) {
    NSCAssert(out, @"loadFileIntoMemory: invalid 'out' parameter");
    NSCAssert(&*out, @"loadFileIntoMemory: invalid 'out' parameter");
    
    size_t size = 0;
    FILE* f = fopen(filename, "rb");
    if(!f) {
        *out = NULL;
        return -1;
    }
    
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    *out = malloc(size);
    size_t read = fread(*out, 1, size, f);
    if(read != size) {
        free(*out);
        *out = NULL;
        return -1;
    }
    
    fclose(f);
    
    return size;
}

@implementation FileUtils

@end
