//
//  MyInstallerPane.m
//  InstallerPlugIn
//
//  Created by JinTao on 2020/12/7.
//

#import "MyInstallerPane.h"

@implementation MyInstallerPane

- (NSString *)title
{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"PaneTitle" value:nil table:nil];
}

@end
