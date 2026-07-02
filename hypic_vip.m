#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static id (*orig_obj)(id, SEL, NSString*);
static id hook_obj(id self, SEL _cmd, NSString *key) {
    if (!key) return nil;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"] || [k containsString:@"premium"] || [k containsString:@"subscription"] || [k containsString:@"pro"] || [k containsString:@"member"] || [k containsString:@"purchase"]) return @"1";
    if ([k containsString:@"expire"] || [k containsString:@"end"]) return @(4102444800);
    if ([k containsString:@"level"] || [k containsString:@"tier"]) return @"3";
    if ([k containsString:@"trial"]) return @"0";
    return orig_obj ? orig_obj(self, _cmd, key) : nil;
}

static BOOL (*orig_bool)(id, SEL, NSString*);
static BOOL hook_bool(id self, SEL _cmd, NSString *key) {
    if (!key) return NO;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"] || [k containsString:@"premium"] || [k containsString:@"subscription"] || [k containsString:@"pro"] || [k containsString:@"member"] || [k containsString:@"purchase"]) return YES;
    if ([k containsString:@"trial"]) return NO;
    return orig_bool ? orig_bool(self, _cmd, key) : NO;
}

static id (*orig_receipt)(id, SEL);
static id hook_receipt(id self, SEL _cmd) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [docs stringByAppendingPathComponent:@"hypic_receipt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSMutableData *d = [NSMutableData dataWithLength:8192];
        [d writeToFile:path atomically:YES];
    }
    return [NSURL fileURLWithPath:path];
}

static id (*orig_array)(id, SEL, NSString*);
static id hook_array(id self, SEL _cmd, NSString *key) {
    if (!key) return nil;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"] || [k containsString:@"premium"] || [k containsString:@"subscription"]) return @[@"premium", @"yearly", @"lifetime"];
    return orig_array ? orig_array(self, _cmd, key) : nil;
}

static id (*orig_dict)(id, SEL, NSString*);
static id hook_dict(id self, SEL _cmd, NSString *key) {
    if (!key) return nil;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"] || [k containsString:@"premium"] || [k containsString:@"subscription"] || [k containsString:@"user"]) {
        return @{@"isVIP":@"1", @"vipLevel":@"3", @"expireTime":@"4102444800", @"isPremium":@"1", @"hasSubscription":@"1", @"memberType":@"premium"};
    }
    return orig_dict ? orig_dict(self, _cmd, key) : nil;
}

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        Class nsud = [NSUserDefaults class];
        
        Method m1 = class_getInstanceMethod(nsud, @selector(objectForKey:));
        if (m1) { orig_obj = (void*)method_getImplementation(m1); method_setImplementation(m1, (IMP)hook_obj); }
        
        Method m2 = class_getInstanceMethod(nsud, @selector(boolForKey:));
        if (m2) { orig_bool = (void*)method_getImplementation(m2); method_setImplementation(m2, (IMP)hook_bool); }
        
        Method m3 = class_getInstanceMethod(nsud, @selector(stringForKey:));
        if (m3) method_setImplementation(m3, (IMP)hook_obj);
        
        Method m4 = class_getInstanceMethod(nsud, @selector(valueForKey:));
        if (m4) method_setImplementation(m4, (IMP)hook_obj);
        
        Method m5 = class_getInstanceMethod(nsud, @selector(arrayForKey:));
        if (m5) { orig_array = (void*)method_getImplementation(m5); method_setImplementation(m5, (IMP)hook_array); }
        
        Method m6 = class_getInstanceMethod(nsud, @selector(dictionaryForKey:));
        if (m6) { orig_dict = (void*)method_getImplementation(m6); method_setImplementation(m6, (IMP)hook_dict); }
        
        Method m7 = class_getInstanceMethod([NSBundle class], @selector(appStoreReceiptURL));
        if (m7) { orig_receipt = (void*)method_getImplementation(m7); method_setImplementation(m7, (IMP)hook_receipt); }
    }
}
