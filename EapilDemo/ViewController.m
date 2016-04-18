//
//  ViewController.m
//  EapilDemo
//
//  Created by mazhong on 16/4/17.
//  Copyright © 2016年 mazhong. All rights reserved.
//

#import "ViewController.h"
#import <GCDWebUploader.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "MZSelectFileViewController.h"

@interface ViewController ()

@property (nonatomic) GCDWebUploader *webServer;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
//    _webServer.delegate = self;
    _webServer.allowHiddenItems = YES;
    if ([_webServer startWithPort:8088 bonjourName:@""]) {
        _tipLabel.text = [NSString stringWithFormat:NSLocalizedString(@"wifi传输：在电脑浏览器输入以下地址来上传文件\nhttp://%@:%d", nil), [self getIPAddress], (int)_webServer.port];
    } else {
        _tipLabel.text = NSLocalizedString(@"GCDWebServer not running!", nil);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

- (IBAction)openFile:(UIButton *)sender {
    MZSelectFileViewController *vc = [[MZSelectFileViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
