#import <Cordova/CDV.h>
#import "EstimoteBeacons.h"
#import "ESTBeaconManager.h"

@interface EstimoteBeacons () <ESTBeaconManagerDelegate,ESTBeaconDelegate>

@property (nonatomic, strong) ESTBeaconManager* beaconManager;


@end


@implementation EstimoteBeacons

- (EstimoteBeacons*)pluginInitialize
{
    self.rangingError = NO;
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    self.beaconManager.avoidUnknownStateBeacons = YES;
    NSMutableArray* output = [NSMutableArray array];
    self.beacons = output;
    
    //NSUUID *IPAD_UUID = [[NSUUID alloc] initWithUUIDString:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
    NSUUID *ESTIMOTE_UUID = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    //8492E75F-4FD6-469D-B132-043FE94921D8 iPad
    //major:12768
    //B9407F30-F5F8-466E-AFF9-25556B57FE6D Estimotes
    //major:50485
    self.currentRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_UUID
                                                                  major:50485
                                                             identifier:@"EstimoteSampleRegion"];
    
    self.regionWatchers = [[NSMutableDictionary alloc] init];
    
    [self.beaconManager stopMonitoringForRegion:self.currentRegion];
    [self.beaconManager startMonitoringForRegion:self.currentRegion];
    [self.beaconManager stopRangingBeaconsInRegion:self.currentRegion];
    [self.beaconManager startRangingBeaconsInRegion:self.currentRegion];
    
    return self;
}

- (void)startRangingBeaconsInRegion:(CDVInvokedUrlCommand*)command {
    [self.beaconManager stopRangingBeaconsInRegion:self.currentRegion];
    [self.beaconManager startRangingBeaconsInRegion:self.currentRegion];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)stopRangingBeaconsInRegion:(CDVInvokedUrlCommand*)command {
    [self.beaconManager stopRangingBeaconsInRegion:self.currentRegion];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    self.rangingError = NO;
    NSMutableArray* output = [NSMutableArray array];
    //    HTTP request for presence creation?
    if([beacons count] > 0)
    {
        for (id beacon in beacons) {
            [output addObject:[self beaconToDictionary:beacon]];
        }
    }
    self.beacons = output;
}

-(void)beaconManager:(ESTBeaconManager *)manager
rangingBeaconsDidFailForRegion:(ESTBeaconRegion *)region
           withError:(NSError *)error
{
    self.rangingError = YES;
    NSLog(@"Ranging Beacons failed for %@", region);
    
}

-(void)beaconManager:(ESTBeaconManager *)manager
monitoringDidFailForRegion:(ESTBeaconRegion *)region
           withError:(NSError *)error;
{
    NSLog(@"Monitoring failed for %@", region);
    
}

-(void)beaconManager:(ESTBeaconManager *)manager
      didEnterRegion:(ESTBeaconRegion *)region
{
    
    NSLog(@"ENTER REGION: %@", region);
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"You have just received a $1 coffee special at Parma!";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
}

-(void)beaconManager:(ESTBeaconManager *)manager
       didExitRegion:(ESTBeaconRegion *)region
{
    
    NSLog(@"EXIT REGION: %@", region);
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Sorry to see you leave.";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


- (void)getBeacons:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        if (self.rangingError == NO) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.beacons];
        }
        if (self.rangingError == YES) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"BeaconManager failed to commence ranging."];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (NSMutableDictionary*)beaconToDictionary:(ESTBeacon*)beacon
{
    NSMutableDictionary* props = [NSMutableDictionary dictionaryWithCapacity:16];
    NSNumber* major = beacon.major;
    NSNumber* minor = beacon.minor;
    NSNumber* rssi = [NSNumber numberWithInt:beacon.rssi];
    
    if(major == nil) {
        major = beacon.major;
    }
    if(minor == nil) {
        minor = beacon.minor;
    }
    if(rssi == nil) {
        rssi = [NSNumber numberWithInt:beacon.rssi];
    }
    
    [props setValue:major forKey:@"major"];
    [props setValue:minor forKey:@"minor"];
    [props setValue:beacon.description forKey:@"description"];
    [props setValue:rssi forKey:@"rssi"];
    [props setValue:beacon.macAddress forKey:@"macAddress"];
    [props setValue:beacon.measuredPower forKey:@"measuredPower"];
    
    if(beacon != nil) {
        [props setValue:beacon.distance forKey:@"distance"];
        [props setValue:[NSNumber numberWithInt:beacon.proximity] forKey:@"proximity"];
        
        if(beacon.proximityUUID != nil) {
            [props setValue:beacon.proximityUUID.UUIDString forKey:@"proximityUUID"];
        }
    }
    
    return props;
}

@end