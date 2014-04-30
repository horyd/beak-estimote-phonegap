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
    
    NSUUID *ESTIMOTE_UUID = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
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
}

- (void)getBeacons:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        if (self.rangingError == NO) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.beacons];
        }
        if (self.rangingError == YES) {
            NSLog(@"Ranging error discovered in getBeacons request... attempting to reboot monitoring and ranging services...");
            [self.beaconManager stopMonitoringForRegion:self.currentRegion];
            [self.beaconManager startMonitoringForRegion:self.currentRegion];
            [self.beaconManager stopRangingBeaconsInRegion:self.currentRegion];
            [self.beaconManager startRangingBeaconsInRegion:self.currentRegion];
            if (self.rangingError == NO) {
                NSLog(@"Ranging has successfully commenced from an earlier error");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.beacons];
            }
            if (self.rangingError == YES) {
                NSLog(@"The earlier ranging error persists...");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"BeaconManager failed to commence ranging."];
            }
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
