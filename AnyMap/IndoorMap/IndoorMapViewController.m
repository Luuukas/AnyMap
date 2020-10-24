//
//  IndoorMapViewController.m
//  AnyMap
//
//  Created by bytedance on 2020/9/8.
//  Copyright © 2020 hwl. All rights reserved.
//

#import "IndoorMapViewController.h"
#import "FloorPickerView.h"
#import <SpriteKit/SpriteKit.h>
#import "IndoorDestinationSet.h"

@interface IndoorMapViewController ()
@property(strong, nonatomic) SCNSceneSource *sceneSource;
@property(strong, nonatomic) SCNView *scnView;
@property(strong, nonatomic) SCNNode *floorNode;
@property(strong, nonatomic) SCNNode *floorNode2;
@property int cameraNodeY;

@property (strong, nonatomic) NSMutableDictionary<NSString*, MotionDna*> *networkUsers;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSNumber*> *networkUsersTimestamps;

@property (strong, nonatomic) SCNNode *node;

@property (strong, nonatomic) FloorPickerView *floorPickerView;
@property (nonatomic) uint onIdx;
- (void)startMotionDna;
@end

@interface IndoorMapViewController ()<UISearchBarDelegate>
@property (strong, nonatomic)IndoorDestinationSet *destSet;

@property (strong, nonatomic) UISearchBar *searchBar;
/** 目已加载的目的地信息 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, SCNNode*> *listDests;
/** 搜索后的目的地信息 */
@property (nonatomic, strong) NSArray<SCNNode*> *listFilterDests;
/** 已经绘制的目的地信息 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, SCNNode*> *drewDests;
@end

#pragma mark - TODO: 单例，左侧楼层选项，抽出ViweModel，navi接入

const int pickerViewWidth = 50;
const int pickerViewHeight = 250;
const CGFloat y_offset = 75;
@implementation IndoorMapViewController
- (instancetype)initWithSceneSource:(SCNSceneSource*)sceneSource {
    if(self = [super init]) {
        _sceneSource = sceneSource;
    }
    return self;
}
- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Indoor Map";
    
    // 顶部透明的关闭按钮
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    backBtn.titleLabel.text = @"back";
    [backBtn addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchDown];
    
    _listDests = [[NSMutableDictionary alloc] init];
    _drewDests = [[NSMutableDictionary alloc] init];
    // 搜索栏
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, 180)];
    _searchBar.delegate = self;
    _searchBar.searchBarStyle = UISearchBarStyleDefault;
    _searchBar.text = @"HMT";
    _searchBar.prompt = @"搜索目的地";
    _searchBar.placeholder = @"请输入要搜索的目的地";
    _searchBar.tintColor = UIColor.redColor;
    _searchBar.barTintColor = UIColor.whiteColor;
    _searchBar.translucent = YES;
    _searchBar.showsBookmarkButton = YES;
    _searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"iOS",@"Android",@"iPhone",nil];
    
    _scnView = [[SCNView alloc] initWithFrame:self.view.bounds];
    _scnView.allowsCameraControl = YES;
    _scnView.showsStatistics = YES;
    _scnView.backgroundColor = UIColor.cyanColor;
    
    SCNScene *scene  = [_sceneSource sceneWithOptions:nil error:nil];
    
    _cameraNodeY = 7250;
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.camera.automaticallyAdjustsZRange = true;
//    cameraNode.camera.orthographicScale = 2;
    [scene.rootNode addChildNode:cameraNode];
    cameraNode.position = SCNVector3Make(0, _cameraNodeY, 0);
    cameraNode.eulerAngles = SCNVector3Make(-M_PI/2, 0, 0);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 0, 100);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor whiteColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    _floorNode = [scene.rootNode childNodeWithName:@"1" recursively:YES];
    
    _floorNode2 = [scene.rootNode childNodeWithName:@"2" recursively:YES];
    [_floorNode2 setHidden:YES];
    
    _floorNode2 = [scene.rootNode childNodeWithName:@"3" recursively:YES];
    [_floorNode2 setHidden:YES];
    
    _scnView.scene = scene;
    [self.view addSubview:_scnView];
    
    SCNMaterial *redMaterial = [[SCNMaterial alloc] init];
    redMaterial.diffuse.contents = UIColor.blueColor;
    redMaterial.specular.contents = UIColor.whiteColor;
    redMaterial.shininess = 1.0;
    
    SCNCone* geometry = [SCNCone coneWithTopRadius:75 bottomRadius:5 height:y_offset*2];
    
    _node = [SCNNode nodeWithGeometry:geometry];
    _node.position = SCNVector3Make(0, y_offset, 0);
    _node.geometry.materials = @[redMaterial];
    [_scnView.scene.rootNode addChildNode: _node];
    
    [self.view addSubview:backBtn];
    [self.view addSubview:_searchBar];
    
    NSArray *floors = @[@"1", @"2", @"3"];
    _floorPickerView = [[FloorPickerView alloc] initWithFloors:floors action:^void (NSString* toFloor, uint toIdx){
        static NSString *onFloor = @"1";
        
        while(self->_onIdx<toIdx){
            ++self->_onIdx;
            SCNNode *floorNode = [scene.rootNode childNodeWithName:[floors objectAtIndex:self->_onIdx] recursively:YES];
            [floorNode setHidden:NO];
        }
        while(self->_onIdx>toIdx){
            SCNNode *floorNode = [scene.rootNode childNodeWithName:[floors objectAtIndex:self->_onIdx] recursively:YES];
            [floorNode setHidden:YES];
            --self->_onIdx;
        }
    }];
    [self.view addSubview:_floorPickerView];
    
    _floorPickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [[NSLayoutConstraint constraintWithItem:_floorPickerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:_floorPickerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:_floorPickerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:pickerViewWidth] setActive:YES];
    [NSLayoutConstraint constraintWithItem:_floorPickerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:NSLayoutAttributeHeight];
    
//    [floorPickerView setBackgroundColor:UIColor.blackColor];
    
    _networkUsers = [NSMutableDictionary dictionary];
    _networkUsersTimestamps = [NSMutableDictionary dictionary];
    [self startMotionDna];
    
    _destSet = [[IndoorDestinationSet alloc] initWithBuilding:@"1"];
    NSDictionary *dests = [_destSet destinationsAtZ:0];
    __weak typeof(self) weakself = self;
    [dests enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
        [weakself drawDestnationNodeWithName:key Props:obj Color:UIColor.redColor];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _onIdx = 0;
    [_floorPickerView.delegate pickerView:_floorPickerView didSelectRow:1 inComponent:0];
    [_floorPickerView selectRow:1 inComponent:0 animated:YES];
}

// pragma mark - 协议UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
    [_searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar{
    // called when cancel button pressed

    [searchBar setShowsCancelButton:NO animated:NO];    // 取消按钮回收

    [searchBar resignFirstResponder]; // 取消第一响应值,键盘回收,搜索结束

}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    // 恢复上次被选中的至普通状态
    SCNMaterial *material_red = [[SCNMaterial alloc] init];
    material_red.diffuse.contents = UIColor.redColor;
    material_red.specular.contents = UIColor.whiteColor;
    material_red.shininess = 1.0;
    
    for(SCNNode* node in _listFilterDests){
        node.geometry.materials = @[material_red];
    }

    // 筛选这次匹配的
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS [cd] %@",searchText];
    NSArray<NSString*> *allDestNames = [_listDests allKeys];
    NSArray<NSString*> *filterDestNames = [allDestNames filteredArrayUsingPredicate:predicate];
    
    // 上色并存储结果
    NSMutableArray<SCNNode*> *filterDests = [[NSMutableArray alloc] init];
    SCNMaterial *material_yellow = [[SCNMaterial alloc] init];
    material_yellow.diffuse.contents = UIColor.yellowColor;
    material_yellow.specular.contents = UIColor.whiteColor;
    material_yellow.shininess = 1.0;
    for(int i = 0; i < [filterDestNames count]; i++){
        SCNNode *node = [_listDests objectForKey:[filterDestNames objectAtIndex:i]];
        node.geometry.materials = @[material_yellow];
        [filterDests addObject:node];
    }
    
    _listFilterDests = filterDests;

}

- (void)clearDestinations {
    @synchronized (_drewDests) {
        for(SCNNode *node in _drewDests){
            [node removeFromParentNode];
        }
        [_drewDests removeAllObjects];
    }
}

- (void)drawDestnationNodeWithName:(NSString*)name Props:(NSDictionary*)props Color:(UIColor*)color{
    SCNMaterial *material = [[SCNMaterial alloc] init];
    material.diffuse.contents = color;
    material.specular.contents = UIColor.whiteColor;
    material.shininess = 1.0;
    SCNNode *node = [_drewDests objectForKey:name];
    if(node){
        node.geometry.materials = @[material];
        return;
    }
    node = [self generateDestinationNodeWithName:name Props:props];
    node.geometry.materials = @[material];
    SCNText *text = [SCNText textWithString:name extrusionDepth:5];
    SCNNode *textNode = [SCNNode nodeWithGeometry:text];
    CGFloat _x = [[props objectForKey:@"x"] doubleValue];
    CGFloat _y = [[props objectForKey:@"y"] doubleValue] + 90 + y_offset;
    CGFloat _z = [[props objectForKey:@"z"] doubleValue];
    text.font = [UIFont systemFontOfSize:100];
    textNode.position = SCNVector3Make(_x, _y, _z);
    [node addChildNode: textNode];
    @synchronized (_drewDests) {
        [_drewDests setObject:node forKey:name];
    }
    [_scnView.scene.rootNode addChildNode: node];
}

- (SCNNode *)generateDestinationNodeWithName:(NSString*)name Props:(NSDictionary*)props {
    SCNNode *node = nil;
    @synchronized (_listDests) {
         node = [_listDests objectForKey:name];
    }
    if(node){
        return node;
    }
    CGFloat _x = [[props objectForKey:@"x"] doubleValue];
    CGFloat _y = [[props objectForKey:@"y"] doubleValue];
    CGFloat _z = [[props objectForKey:@"z"] doubleValue];
    
    SCNCapsule* geometry = [SCNCapsule capsuleWithCapRadius:20 height:175];
    
    node = [SCNNode nodeWithGeometry:geometry];
    node.position = SCNVector3Make(_x, _y+y_offset, _z);
    @synchronized (_listDests) {
         [_listDests setObject:node forKey:name];
    }
    return node;
}

- (void)moveCubeToX:(CGFloat)x ToY:(CGFloat)y ToZ:(CGFloat)z {
    CGFloat m = 20;
    x *= m;
    y *= m;
    z *= m;
    SCNAction *moveAction = [SCNAction moveTo:SCNVector3Make(x, z+y_offset, y) duration:0.5];
    [_node runAction:moveAction];
}

- (void)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

NSString *motionTypeToNSString(MotionType motionType) {
    switch (motionType) {
        case STATIONARY:
            return @"STATIONARY";
            break;
        case FIDGETING:
            return @"FIDGETING";
            break;
        case FORWARD:
            return @"FORWARD";
            break;
        default:
            return @"UNKNOWN MOTION";
            break;
    }
    return nil;
}

@interface IndoorMapViewController (navisens)

@property (strong, nonatomic) MotionDnaManager *manager;
-(void)receiveMotionDna:(MotionDna*)motionDna;
-(void)receiveNetworkData:(MotionDna*)motionDna;
-(void)receiveNetworkData:(NetworkCode)opcode WithPayload:(NSDictionary*)payload;

@end

@implementation IndoorMapViewController (navisens)

#pragma mark MotionDna Callback Methods

//    This event receives the estimation results using a MotionDna object.
//    Check out the Getters section to learn how to read data out of this object.

- (void)receiveMotionDna:(MotionDna *)motionDna {
    Location location = [motionDna getLocation];
    XYZ localLocation = location.localLocation;
    GlobalLocation globalLocation = location.globalLocation;
//    Motion motion = [motionDna getMotion];
    
    NSString *motionDnaLocalString = [NSString stringWithFormat:@"Local XYZ Coordinates (meters): \n(%.2f,%.2f,%.2f)",localLocation.x,localLocation.y,localLocation.z];
    NSString *motionDnaHeadingString = [NSString stringWithFormat:@"Current Heading: %.2f",location.heading];
    NSString *motionDnaGlobalString = [NSString stringWithFormat:@"Global Position: \n(Lat: %.6f, Lon: %.6f)",globalLocation.latitude,globalLocation.longitude];
//    NSString *motionDnaMotionTypeString = [NSString stringWithFormat:@"Motion Type: %@",motionTypeToNSString(motion.motionType)];
//    NSDictionary<NSString*,Classifier*> *classifiers = [motionDna getClassifiers];
//    NSString *motionDnaPredictionsString = @"Predictions (BETA):\n";
//    for (NSString *classifierKey in classifiers) {
//        motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingFormat:@"Classifier: %@\n",classifierKey];
//        Classifier *classifier = [classifiers objectForKey:classifierKey];
//
//        motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingFormat:@"\tprediction: %@ confidence: %.2f\n",classifier.currentPredictionLabel,classifier.currentPredictionConfidence];
//        motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingString:@" stats:\n"];
//        for (NSString *predictionLabel in classifier.predictionStats) {
//            PredictionStats *predictionStats = [classifier.predictionStats objectForKey:predictionLabel];
//            motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingFormat:@"\t%@\n",predictionLabel];
//            motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingFormat:@"\t duration: %.2f\n",predictionStats.duration];
//            motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingFormat:@"\t distance: %.2f\n",predictionStats.distance];
//        }
//        motionDnaPredictionsString = [motionDnaPredictionsString stringByAppendingString:@"\n"];
//    }
//    [motionDnaPredictionsString stringByAppendingFormat:@"\n%@",classifiers];
//    NSString *motionDnaString = [NSString stringWithFormat:@"MotionDna Location:\n%@\n%@\n%@\n%@\n\n%@",motionDnaLocalString,
//                                 motionDnaHeadingString,
//                                 motionDnaGlobalString,
//                                 motionDnaMotionTypeString,
//                                 motionDnaPredictionsString];
    
    NSString *motionDnaString = [NSString stringWithFormat:@"MotionDna Location:\n%@\n%@\n%@\n",motionDnaLocalString,
    motionDnaHeadingString,
    motionDnaGlobalString];
    
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self->_receiveMotionDnaTextField setText:motionDnaString];
        
        NSLog(@"receiveMotionDna: %@", motionDnaLocalString);
        if(weakSelf){
            [weakSelf moveCubeToX:localLocation.x ToY:localLocation.y ToZ:localLocation.z];
        }
    });
}

//    This event receives estimation results from other devices in the server room. In order
//    to receive anything, make sure you call startUDP to connect to a room. Again, it provides
//    access to a MotionDna object, which can be unpacked the same way as above.
//
//
//    If you aren't receiving anything, then the room may be full, or there may be an error in
//    your connection. See the reportError event below for more information.

- (void)receiveNetworkData:(MotionDna *)motionDna {
//    [_networkUsers setObject:motionDna forKey:[motionDna getID]];
//    double timeSinceBootSeconds = [[NSProcessInfo processInfo] systemUptime];
//    [_networkUsersTimestamps setObject:@(timeSinceBootSeconds) forKey:[motionDna getID]];
//    __block NSString *activeNetworkUsersString = [NSString string];
//    NSMutableArray<NSString*> *toRemove = [NSMutableArray array];
//
//    activeNetworkUsersString = [activeNetworkUsersString stringByAppendingString:@"Network Shared Devices:\n"];
//    [_networkUsers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MotionDna * _Nonnull user, BOOL * _Nonnull stop) {
//        if (timeSinceBootSeconds - [[self->_networkUsersTimestamps objectForKey:[user getID]] doubleValue] > 2.0) {
//            [toRemove addObject:[user getID]];
//        } else {
//            activeNetworkUsersString = [activeNetworkUsersString stringByAppendingString:[[[user getDeviceName] componentsSeparatedByString:@";"] lastObject]];
//            XYZ location = [user getLocation].localLocation;
//            activeNetworkUsersString = [activeNetworkUsersString stringByAppendingString:[NSString stringWithFormat:@" (%.2f, %.2f, %.2f)\n",location.x, location.y, location.z]];
//        }
//    }];
//    for (NSString *key in toRemove) {
//        [_networkUsers removeObjectForKey:key];
//        [_networkUsersTimestamps removeObjectForKey:key];
//    }
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self->_receiveNetworkDataTextField.text = activeNetworkUsersString;
//    });
}

- (void)receiveNetworkData:(NetworkCode)opcode WithPayload:(NSDictionary *)payload {
    
}

- (void)startMotionDna {
    _manager = [[MotionDnaManager alloc] init];
    _manager.receiver = self;
    
    //    This functions starts up the SDK. You must pass in a valid developer's key in order for
    //    the SDK to function. IF the key has expired or there are other errors, you may receive
    //    those errors through the reportError() callback route.
    
    [_manager runMotionDna:@"6tTUNe52BD5dA6Vlm8FpW54ABDoLjRivq903gOiekpxCfBLapNcZgqsKMI70q2CV"];
    
    //    Use our internal algorithm to automatically compute your location and heading by fusing
    //    inertial estimation with global location information. This is designed for outdoor use and
    //    will not compute a position when indoors. Solving location requires the user to be walking
    //    outdoors. Depending on the quality of the global location, this may only require as little
    //    as 10 meters of walking outdoors.
    
    [_manager setLocationNavisens];
    
    //   Set accuracy for GPS positioning, states :HIGH/LOW_ACCURACY/OFF, OFF consumes
    //   the least battery.
    
    [_manager setExternalPositioningState:LOW_ACCURACY];
    
    //    Manually sets the global latitude, longitude, and heading. This enables receiving a
    //    latitude and longitude instead of cartesian coordinates. Use this if you have other
    //    sources of information (for example, user-defined address), and need readings more
    //    accurate than GPS can provide.
//    [_manager setLocationLatitude:37.787582 Longitude:-122.396627 AndHeadingInDegrees:0.0];
    
    //    Set the power consumption mode to trade off accuracy of predictions for power saving.
    
    [_manager setPowerMode:PERFORMANCE];
    
    //    Connect to your own server and specify a room. Any other device connected to the same room
    //    and also under the same developer will receive any udp packets this device sends.
    
    [_manager startUDP];
    
    //    Allow our SDK to record data and use it to enhance our estimation system.
    //    Send this file to support@navisens.com if you have any issues with the estimation
    //    that you would like to have us analyze.
    
    [_manager setBinaryFileLoggingEnabled:YES];
    
    //    Tell our SDK how often to provide estimation results. Note that there is a limit on how
    //    fast our SDK can provide results, but usually setting a slower update rate improves results.
    //    Setting the rate to 0ms will output estimation results at our maximum rate.
    
    [_manager setCallbackUpdateRateInMs:500];
    
    //    When setLocationNavisens is enabled and setBackpropagationEnabled is called, once Navisens
    //    has initialized you will not only get the current position, but also a set of latitude
    //    longitude coordinates which lead back to the start position (where the SDK/App was started).
    //    This is useful to determine which building and even where inside a building the
    //    person started, or where the person exited a vehicle (e.g. the vehicle parking spot or the
    //    location of a drop-off).
    
    [_manager setBackpropagationEnabled:YES];
    
    //    If the user wants to see everything that happened before Navisens found an initial
    //    position, he can adjust the amount of the trajectory to see before the initial
    //    position was set automatically.
    
    [_manager setBackpropagationBufferSize:2000];
    
    //    Enables AR mode. AR mode publishes orientation quaternion at a higher rate.
    
//    [_manager setARModeEnabled:YES];
}

- (void)dealloc {
    [_manager stop];
}

@end
