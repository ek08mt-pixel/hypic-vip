#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static BOOL fake_YES(id self, SEL _cmd) { return YES; }
static long long fake_max(id self, SEL _cmd) { return 4102444800; }
static int fake_3(id self, SEL _cmd) { return 3; }

static id fake_dict(id self, SEL _cmd) {
    return @{@"isVIP":@YES,@"vipLevel":@3,@"expireTime":@(4102444800),@"isPremium":@YES,@"hasSubscription":@YES};
}

static id (*orig_obj)(id, SEL, NSString*);
static id hook_obj(id self, SEL _cmd, NSString *key) {
    if (!key) return nil;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"]||[k containsString:@"premium"]||[k containsString:@"subscription"]||[k containsString:@"pro"]) {
        return @"1";
    }
    if ([k containsString:@"expire"]) return @(4102444800);
    if ([k containsString:@"level"]) return @"3";
    return orig_obj ? orig_obj(self,_cmd,key) : nil;
}

static BOOL (*orig_bool)(id, SEL, NSString*);
static BOOL hook_bool(id self, SEL _cmd, NSString *key) {
    if (!key) return NO;
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"]||[k containsString:@"premium"]||[k containsString:@"pro"]||[k containsString:@"subscription"]) return YES;
    return orig_bool ? orig_bool(self,_cmd,key) : NO;
}

__attribute__((constructor))
static void load() {
    @autoreleasepool {
        Class nsud = [NSUserDefaults class];
        Method m1 = class_getInstanceMethod(nsud, @selector(objectForKey:));
        if(m1) {
            orig_obj = (void*)method_getImplementation(m1);
            method_setImplementation(m1, (IMP)hook_obj);
        }
        Method m2 = class_getInstanceMethod(nsud, @selector(boolForKey:));
        if(m2) {
            orig_bool = (void*)method_getImplementation(m2);
            method_setImplementation(m2, (IMP)hook_bool);
        }
        
        // Chỉ hook class cụ thể của Hypic, không duyệt toàn bộ
        NSArray *classNames = @[
            @"UserManager", @"AccountManager", @"VIPManager",
            @"SubscriptionManager", @"PaymentManager",
            @"User", @"CurrentUser", @"Profile",
            @"HYUser", @"HYAccount", @"HYVIP",
            @"MemberService", @"VIPService"
        ];
        
        for (NSString *name in classNames) {
            Class cls = objc_getClass([name UTF8String]);
            if (!cls) continue;
            
            SEL s1 = @selector(isVIP);
            Method m = class_getInstanceMethod(cls, s1);
            if (m) method_setImplementation(m, (IMP)fake_YES);
            
            SEL s2 = @selector(isPremium);
            m = class_getInstanceMethod(cls, s2);
            if (m) method_setImplementation(m, (IMP)fake_YES);
            
            SEL s3 = @selector(hasActiveSubscription);
            m = class_getInstanceMethod(cls, s3);
            if (m) method_setImplementation(m, (IMP)fake_YES);
            
            SEL s4 = @selector(vipLevel);
            m = class_getInstanceMethod(cls, s4);
            if (m) method_setImplementation(m, (IMP)fake_3);
            
            SEL s5 = @selector(vipExpireTime);
            m = class_getInstanceMethod(cls, s5);
            if (m) method_setImplementation(m, (IMP)fake_max);
        }
    }
}
