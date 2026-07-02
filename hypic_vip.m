#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static BOOL fake_YES(id self, SEL _cmd) { return YES; }
static long long fake_max(id self, SEL _cmd) { return 4102444800; }
static int fake_3(id self, SEL _cmd) { return 3; }

static id (*orig_obj)(id, SEL, NSString*);
static id hook_obj(id self, SEL _cmd, NSString *key) {
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"]||[k containsString:@"pro"]||[k containsString:@"premium"]||[k containsString:@"subscription"]||[k containsString:@"member"]||[k containsString:@"purchase"]) return @"1";
    if ([k containsString:@"expire"]) return @(4102444800);
    if ([k containsString:@"level"]) return @"3";
    if ([k containsString:@"trial"]) return @"0";
    return orig_obj ? orig_obj(self,_cmd,key) : nil;
}

static BOOL (*orig_bool)(id, SEL, NSString*);
static BOOL hook_bool(id self, SEL _cmd, NSString *key) {
    NSString *k = [key lowercaseString];
    if ([k containsString:@"vip"]||[k containsString:@"pro"]||[k containsString:@"premium"]||[k containsString:@"subscription"]||[k containsString:@"member"]) return YES;
    if ([k containsString:@"trial"]) return NO;
    return orig_bool ? orig_bool(self,_cmd,key) : NO;
}

__attribute__((constructor))
static void load() {
    @autoreleasepool {
        Class c = [NSUserDefaults class];
        Method m1 = class_getInstanceMethod(c, @selector(objectForKey:));
        if(m1){orig_obj=(void*)method_getImplementation(m1);method_setImplementation(m1,(IMP)hook_obj);}
        Method m2 = class_getInstanceMethod(c, @selector(boolForKey:));
        if(m2){orig_bool=(void*)method_getImplementation(m2);method_setImplementation(m2,(IMP)hook_bool);}
        
        unsigned int n; Class *cls = objc_copyClassList(&n);
        const char *sels[] = {
            "isVIP","isVip","isPremium","isPro","hasVIP","hasPremium",
            "hasSubscription","hasActiveSubscription","isSubscribed",
            "isMember","isVIPUser","isProUser","isPremiumUser",
            "hasPurchased","isPurchased","isUnlocked","isFullVersion",
            "isLifetimeVIP","vipStatus","isVIPActive","isPremiumActive",
            "hasValidSubscription","canUseVIPFeature","canUsePremiumFeature",
            "hasVIPPermission","hasPremiumAccess","isFeatureUnlocked",
            "isPaidUser","isYearlyVIP","isMonthlyVIP","hasLifetimeAccess",
            NULL
        };
        for(unsigned int i=0;i<n;i++) {
            Class cl = cls[i];
            for(int j=0;sels[j]!=NULL;j++) {
                SEL s = sel_registerName(sels[j]);
                Method m = class_getInstanceMethod(cl,s);
                if(m) method_setImplementation(m,(IMP)fake_YES);
                m = class_getClassMethod(cl,s);
                if(m) method_setImplementation(m,(IMP)fake_YES);
            }
            SEL v = sel_registerName("vipLevel");
            Method mv = class_getInstanceMethod(cl,v);
            if(mv) method_setImplementation(mv,(IMP)fake_3);
            SEL e = sel_registerName("vipExpireTime");
            Method me = class_getInstanceMethod(cl,e);
            if(me) method_setImplementation(me,(IMP)fake_max);
        }
        free(cls);
    }
}
