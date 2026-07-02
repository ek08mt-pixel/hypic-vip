#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

// Chặn anti-tamper check
static int (*orig_ptrace)(int, pid_t, caddr_t, int);
static int hook_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) return 0; // PT_DENY_ATTACH
    return orig_ptrace ? orig_ptrace(request, pid, addr, data) : 0;
}

static int (*orig_sysctl)(int*, u_int, void*, size_t*, void*, size_t);
static int hook_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl ? orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen) : 0;
    if (name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && oldp) {
        struct kinfo_proc *info = (struct kinfo_proc *)oldp;
        info->kp_proc.p_flag &= ~P_TRACED;
    }
    return ret;
}

static int (*orig_csops)(pid_t, unsigned int, void*, size_t);
static int hook_csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize) {
    int ret = orig_csops ? orig_csops(pid, ops, useraddr, usersize) : 0;
    return ret;
}

// Chặn exit/abort
static void (*orig_exit)(int);
static void hook_exit(int status) {
    return;
}

// VIP bypass
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

// Debug detection
static BOOL (*orig_isDebuggerAttached)(void);
static BOOL hook_isDebuggerAttached(void) {
    return NO;
}

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Hook anti-tamper functions
        void *libc = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
        if (libc) {
            orig_ptrace = dlsym(libc, "ptrace");
            orig_sysctl = dlsym(libc, "sysctl");
            orig_exit = dlsym(libc, "exit");
            
            // Use fishhook-style replacement via method swizzling on related ObjC methods
        }
        
        // Hook NSUserDefaults
        Class nsud = [NSUserDefaults class];
        Method m1 = class_getInstanceMethod(nsud, @selector(objectForKey:));
        if (m1) { orig_obj = (void*)method_getImplementation(m1); method_setImplementation(m1, (IMP)hook_obj); }
        Method m2 = class_getInstanceMethod(nsud, @selector(boolForKey:));
        if (m2) { orig_bool = (void*)method_getImplementation(m2); method_setImplementation(m2, (IMP)hook_bool); }
        Method m3 = class_getInstanceMethod(nsud, @selector(stringForKey:));
        if (m3) method_setImplementation(m3, (IMP)hook_obj);
        Method m4 = class_getInstanceMethod(nsud, @selector(valueForKey:));
        if (m4) method_setImplementation(m4, (IMP)hook_obj);
        
        // Hook receipt
        Method m5 = class_getInstanceMethod([NSBundle class], @selector(appStoreReceiptURL));
        if (m5) { orig_receipt = (void*)method_getImplementation(m5); method_setImplementation(m5, (IMP)hook_receipt); }
        
        // Hook debugger check
        Class dbg = NSClassFromString(@"NSDebugger");
        if (dbg) {
            Method m6 = class_getClassMethod(dbg, @selector(isDebuggerAttached));
            if (m6) method_setImplementation(m6, (IMP)hook_isDebuggerAttached);
        }
    }
}
