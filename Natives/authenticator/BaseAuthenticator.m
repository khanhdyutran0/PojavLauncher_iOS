#import "BaseAuthenticator.h"
#import "../ios_uikit_bridge.h"
#import "../utils.h"

@implementation BaseAuthenticator

static BaseAuthenticator *current = nil;

+ (id)current {
    return current;
}

+ (id)loadSavedName:(NSString *)name {
    NSMutableDictionary *authData = parseJSONFromFile([NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), name]);
    if (authData[@"error"] != nil) {
        showDialog(viewController, NSLocalizedString(@"Error", nil), ((NSError *)authData[@"error"]).localizedDescription);
        return nil;
    }
    if ([authData[@"accessToken"] length] < 5) {
        return [[LocalAuthenticator alloc] initWithData:authData];
    } else { 
        return [[MicrosoftAuthenticator alloc] initWithData:authData];
    }
}

- (id)initWithData:(NSMutableDictionary *)data {
    current = self = [self init];
    self.authData = data;
    return self;
}

- (id)initWithInput:(NSString *)string {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"input"] = string;
    return [self initWithData:data];
}

- (void)loginWithCallback:(void (^)(BOOL success))callback {
}

- (void)refreshTokenWithCallback:(void (^)(BOOL success))callback {
}

- (BOOL)saveChanges {
    NSError *error;

    [self.authData removeObjectForKey:@"input"];

    NSString *newPath = [NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), self.authData[@"username"]];
    if (self.authData[@"oldusername"] != nil && ![self.authData[@"username"] isEqualToString:self.authData[@"oldusername"]]) {
        NSString *oldPath = [NSString stringWithFormat:@"%s/accounts/%@.json", getenv("POJAV_HOME"), self.authData[@"oldusername"]];
        [NSFileManager.defaultManager moveItemAtPath:oldPath toPath:newPath error:&error];
        // handle error?
    }

    [self.authData removeObjectForKey:@"oldusername"];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.authData options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData == nil) {
        showDialog(viewController, @"Error while converting to JSON", error.localizedDescription);
        return NO;
    }

    BOOL success = [jsonData writeToFile:newPath options:NSDataWritingAtomic error:&error];
    if (!success) {
        showDialog(viewController, @"Error while saving file", error.localizedDescription);
    }
    return success;
}

@end
