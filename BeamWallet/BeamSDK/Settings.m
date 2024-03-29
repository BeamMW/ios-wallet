//
// Settings.m
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Settings.h"
#import "AppModel.h"

@implementation Settings

static NSString *askKey = @"isNeedaskPasswordForSend";
static NSString *lockScreen = @"lockScreen";
static NSString *biometricKey = @"biometricKey";
static NSString *hideAmountsKey = @"isHideAmounts";
static NSString *nodeKey = @"nodeKey";
static NSString *askHideAmountsKey = @"askHideAmountsKey";
static NSString *alowOpenLinkKey = @"alowOpenLinkKey";
static NSString *languageKey = @"languageKey";
static NSString *randomNodeKey = @"randomNodeKey";
static NSString *logsKey = @"logsKey";
static NSString *darkModeKey = @"darkModeKey";
static NSString *isSetDarkModeKey = @"isSetDarkModeKey";
static NSString *currenctKey = @"currenctKey";
static NSString *notificationsWalletKey = @"notificationsWalletKey";
static NSString *notificationsNewsKey = @"notificationsNewsKey";
static NSString *notificationsTransactionKey = @"notificationsTransactionKey";
static NSString *notificationsAddressKey = @"notificationsAddressKey";
static NSString *nodeProtocolKey = @"nodeProtocolKey";
static NSString *randomDBIdKey = @"randomDBIdKey";



+ (Settings*_Nonnull)sharedManager {
    static Settings *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init {
    self = [super init];
    
    randomId = [[[NSUserDefaults standardUserDefaults] objectForKey:randomDBIdKey] intValue];
    
    _lockMaxPrivacyValue = 0;
    
    _maxTokens = 10;
    
    _delegates = [NSHashTable weakObjectsHashTable];

    NSString *target =  [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    
    if ([target isEqualToString:@"BeamWalletTestNet"] || [target isEqualToString:@"BeamWalletNotificationViewTestNet"]) {
        _target = Testnet;
    }
    else if ([target isEqualToString:@"BeamWalletMasterNet"] || [target isEqualToString:@"BeamWalletNotificationViewMasterNet"]) {
        _target = Masternet;
    }
    else{
        _target = Mainnet;
    }
    
    [self moveDataBase];

  //  [self copyOldDatabaseToGroup];

    _isLocalNode = NO;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:askKey]) {
        _isNeedaskPasswordForSend = [[[NSUserDefaults standardUserDefaults] objectForKey:askKey] boolValue];
    }
    else{
        _isNeedaskPasswordForSend = NO;
    }
    
    _connectToRandomNode = YES;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:randomNodeKey]) {
        _connectToRandomNode = [[[NSUserDefaults standardUserDefaults] objectForKey:randomNodeKey] boolValue];
    }
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey]) {
        _connectToRandomNode = NO;
    }

    if ([[NSUserDefaults standardUserDefaults] objectForKey:logsKey]) {
        _logDays = [[[NSUserDefaults standardUserDefaults] objectForKey:logsKey] intValue];
    }
    else{
        _logDays = 5;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:lockScreen]) {
        _lockScreenSeconds = [[[NSUserDefaults standardUserDefaults] objectForKey:lockScreen] intValue];
    }
    else{
        _lockScreenSeconds = 0;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:biometricKey]) {
        _isEnableBiometric = [[[NSUserDefaults standardUserDefaults] objectForKey:biometricKey] boolValue];
    }
    else{
        _isEnableBiometric = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:hideAmountsKey]) {
        _isHideAmounts = [[[NSUserDefaults standardUserDefaults] objectForKey:hideAmountsKey] boolValue];
    }
    else{
        _isHideAmounts = NO;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:askHideAmountsKey]) {
        _isAskForHideAmounts = [[[NSUserDefaults standardUserDefaults] objectForKey:askHideAmountsKey] boolValue];
    }
    else{
        _isAskForHideAmounts = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:alowOpenLinkKey]) {
        _isAllowOpenLink = [[[NSUserDefaults standardUserDefaults] objectForKey:alowOpenLinkKey] boolValue];
    }
    else{
        _isAllowOpenLink = NO;
    }
        
    if (self.target == Testnet) {
        _explorerAddress = @"https://testnet.explorer.beam.mw/block?kernel_id=";
    }
    else if (self.target == Masternet) {
        _explorerAddress = @"https://master-net.explorer.beam.mw/block?kernel_id=";
    }
    else{
        _explorerAddress = @"https://explorer.beam.mw/block?kernel_id=";
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey] && _connectToRandomNode == NO) {
        _nodeAddress = [[NSUserDefaults standardUserDefaults] objectForKey:nodeKey];
    }
    else{
        _nodeAddress = [AppModel chooseRandomNode];
    }
    
    _whereBuyAddress = @"https://www.beam.mw/#exchanges";
    _documentationAddress = @"https://beam.mw/docs";
    
    if (ENALBE_LANG) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:languageKey]) {
            _language = [[NSUserDefaults standardUserDefaults] objectForKey:languageKey];
        }
        else{
            _language = [[NSLocale currentLocale] languageCode];
            
            if ([_language isEqualToString:@"zh"]) {
                _language = @"zh-Hans";
            }
            
            NSArray *languages = [self languages];
            BOOL isFound = NO;
            
            for (BMLanguage *lang in languages) {
                if([lang.code isEqualToString:_language]) {
                    isFound = YES;
                }
            }
            if(isFound) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:_language ofType:@"lproj"]]) {
                    _language = @"en";
                }
            }
            else {
                _language = @"en";
            }
        }
    }
    else {
        _language = @"en";
    }
    

    if ([[NSUserDefaults standardUserDefaults] objectForKey:currenctKey]) {
        _currency = [[[NSUserDefaults standardUserDefaults] objectForKey:currenctKey] intValue];
    }
    else{
        _currency = BMCurrencyUSD;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:notificationsNewsKey]) {
        _isNotificationNewsON = [[[NSUserDefaults standardUserDefaults] objectForKey:notificationsNewsKey] boolValue];
    }
    else{
        _isNotificationNewsON = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:notificationsWalletKey]) {
        _isNotificationWalletON = [[[NSUserDefaults standardUserDefaults] objectForKey:notificationsWalletKey] boolValue];
    }
    else{
        _isNotificationWalletON = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:notificationsAddressKey]) {
        _isNotificationAddressON = [[[NSUserDefaults standardUserDefaults] objectForKey:notificationsAddressKey] boolValue];
    }
    else{
        _isNotificationAddressON = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:notificationsTransactionKey]) {
        _isNotificationTransactionON = [[[NSUserDefaults standardUserDefaults] objectForKey:notificationsTransactionKey] boolValue];
    }
    else{
        _isNotificationTransactionON = YES;
    }
    
    _maxAddressDurationHours = 61 * 24;
    _maxAddressDurationSeconds = (24 * 60 * 60) * 61;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeProtocolKey]) {
        _isNodeProtocolEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:nodeProtocolKey] boolValue];
    }
    else{
        _isNodeProtocolEnabled = NO;
    }
    
    return self;
}

-(void)resetNode{
    _nodeAddress = [AppModel chooseRandomNode];
}
    
-(void)resetSettings {
    self.nodeAddress = [AppModel chooseRandomNode];
    self.logDays = 5;
    self.lockScreenSeconds = 0;
    self.connectToRandomNode = YES;
    self.isAllowOpenLink = NO;
    self.isAskForHideAmounts = YES;
    self.isHideAmounts = NO;
    self.isNodeProtocolEnabled = NO;
}

-(void)resetDataBase {
   // randomId = randomId + 1;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:randomId] forKey:randomDBIdKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*_Nonnull)customNode {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:nodeKey];
    }
    return @"";
}

-(void)removeCustomNode {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:nodeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsNodeProtocolEnabled:(BOOL)isNodeProtocolEnabled {
    _isNodeProtocolEnabled = isNodeProtocolEnabled;
    
    [[NSUserDefaults standardUserDefaults] setBool:_isNodeProtocolEnabled forKey:nodeProtocolKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsHideAmounts:(BOOL)isHideAmounts {
    _isHideAmounts = isHideAmounts;
    
    for(id<SettingsModelDelegate> delegate in [Settings sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onChangeHideAmounts)]) {
            [delegate onChangeHideAmounts];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_isHideAmounts forKey:hideAmountsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsEnableBiometric:(BOOL)isEnableBiometric {
    _isEnableBiometric = isEnableBiometric;

    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_isEnableBiometric] forKey:biometricKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setLockScreenSeconds:(int)lockScreenSeconds {
    _lockScreenSeconds = lockScreenSeconds;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_lockScreenSeconds] forKey:lockScreen];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setLogDays:(int)logDays {
    _logDays = logDays;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_logDays] forKey:logsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[AppModel sharedManager] clearLogs];
}

-(void)setConnectToRandomNode:(BOOL)connectToRandomNode {
    _connectToRandomNode = connectToRandomNode;
    
    [[NSUserDefaults standardUserDefaults] setBool:_connectToRandomNode forKey:randomNodeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setDefaultDarkMode:(BOOL)isSystemMode {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:isSetDarkModeKey]) {
        self.isDarkMode = isSystemMode;
        
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:isSetDarkModeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        _isDarkMode = [[[NSUserDefaults standardUserDefaults] objectForKey:darkModeKey] boolValue];
    }
}

-(void)setIsDarkMode:(BOOL)isDarkMode {
    _isDarkMode = isDarkMode;
    
    [[NSUserDefaults standardUserDefaults] setBool:_isDarkMode forKey:darkModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for(id<SettingsModelDelegate> delegate in [Settings sharedManager].delegates)
     {
         if ([delegate respondsToSelector:@selector(onChangeDarkMode)]) {
             [delegate onChangeDarkMode];
         }
     }
}

-(void)setIsNeedaskPasswordForSend:(BOOL)isNeedaskPasswordForSend {
    _isNeedaskPasswordForSend = isNeedaskPasswordForSend;
    
    [[NSUserDefaults standardUserDefaults] setBool:_isNeedaskPasswordForSend forKey:askKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsAskForHideAmounts:(BOOL)isAskForHideAmounts{
    _isAskForHideAmounts = isAskForHideAmounts;
    
    [[NSUserDefaults standardUserDefaults] setBool:isAskForHideAmounts forKey:askHideAmountsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsAllowOpenLink:(BOOL)isAllowOpenLink {
    _isAllowOpenLink = isAllowOpenLink;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_isAllowOpenLink] forKey:alowOpenLinkKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)isChangedNode {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:nodeKey]) {
        return YES;
    }
    return NO;
}


-(NSString*_Nonnull)walletStoragePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (randomId == 0) {
        NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet.db"];
        return oldPath;
    }
    else {
        NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/wallet_%d.db", randomId]];
        return oldPath;
    }
}

-(void)setLanguage:(NSString *_Nonnull)language {
   // _language = @"en";

    _language = language;

    [[NSUserDefaults standardUserDefaults] setObject:_language forKey:languageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    for(id<SettingsModelDelegate> delegate in [Settings sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onChangeLanguage)]) {
            [delegate onChangeLanguage];
        }
    }
}


-(void)setCurrency:(BMCurrencyType)currency {
    _currency = currency;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_currency] forKey:currenctKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
    for(id<WalletModelDelegate> delegate in delegates)
    {
        if ([delegate respondsToSelector:@selector(onExchangeRatesChange)]) {
            [delegate onExchangeRatesChange];
        }
    }
    
    if([ExchangeManager sharedManager].currencies.count == 0 && [AppModel sharedManager].isConnected){
        NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
        for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:YES];
            }
        }
    }
}

-(NSString*_Nonnull)currencyName {
    switch (_currency) {
        case BMCurrencyUSD:
            return @"USD";
        case BMCurrencyBTC:
            return @"BTC";
        case BMCurrencyETH:
            return @"ETH";
        default:
            return [@"off" localized];
    }
}

-(void)setNodeAddress:(NSString *_Nonnull)nodeAddress {
    _nodeAddress = nodeAddress;
    
    if (!_connectToRandomNode) {
        [[NSUserDefaults standardUserDefaults] setObject:_nodeAddress forKey:nodeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if([[AppModel sharedManager] isLoggedin]){
              NSArray *delegates = [AppModel sharedManager].delegates.allObjects;
      for(id<WalletModelDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:NO];
            }
        }
    }
}

-(void)setIsNotificationNewsON:(BOOL)isNotificationNewsON {
    _isNotificationNewsON = isNotificationNewsON;
    [[NSUserDefaults standardUserDefaults] setBool:_isNotificationNewsON forKey:notificationsNewsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsNotificationWalletON:(BOOL)isNotificationWalletON {
    _isNotificationWalletON = isNotificationWalletON;
    [[NSUserDefaults standardUserDefaults] setBool:_isNotificationWalletON forKey:notificationsWalletKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsNotificationAddressON:(BOOL)isNotificationAddressON {
    _isNotificationAddressON = isNotificationAddressON;
    [[NSUserDefaults standardUserDefaults] setBool:_isNotificationAddressON forKey:notificationsAddressKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setIsNotificationTransactionON:(BOOL)isNotificationTransactionON {
    _isNotificationTransactionON = isNotificationTransactionON;
    [[NSUserDefaults standardUserDefaults] setBool:_isNotificationTransactionON forKey:notificationsTransactionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*_Nonnull)logPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/beam_logs"];
    return dataPath;
}

#pragma mark - Local Node

-(int)nodePort {
    if (self.target == Testnet) {
        return 11005;
    }
    else{
        return 10005;
    }
}

-(NSString*_Nonnull)localNodeStorage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/node.db"];
    
    return dataPath;
}

-(NSString*_Nonnull)localNodeTemdDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return documentsDirectory;
}

-(NSString *)groupDBPath{
    NSString *documentsDirectory = [self groupPath];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    return dataPath;
}

-(void)copyOldDatabaseToGroup {
    [[NSFileManager defaultManager] removeItemAtPath:[self walletStoragePath] error:nil];
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle]pathForResource:@"wallet1" ofType:@"db"] toPath:[self walletStoragePath] error:&error];
    NSLog(@"%@", error);
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet.db"];
//
//    if (![[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
//        if ([[NSFileManager defaultManager] fileExistsAtPath:[self groupDBPath]]) {
//            [[NSFileManager defaultManager] copyItemAtPath:[self groupDBPath] toPath:oldPath error:nil];
//        }
//    }
}

-(void)moveDataBase {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:@"/wallet1"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
        [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:[self walletStoragePath] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
    }
}

-(NSString *)groupPath{
    NSString *groupId = @"";
    
    if (self.target == Testnet) {
        groupId = @"group.beamwallettestnet";
    }
    else if (self.target == Masternet) {
        groupId = @"group.beamwalletmasternet";
    }
    else{
        groupId = @"group.beamwalletmainnet";
    }
    
    NSString *appGroupDirectoryPath = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId].path;
    
    return appGroupDirectoryPath;
}

-(NSArray <BMLanguage*> * _Nonnull)languages {
    BMLanguage *en = [BMLanguage new];
    en.code = @"en";
    en.enName = @"English";
    en.localName = @"English";
    en.ID = 2;

    BMLanguage *ru = [BMLanguage new];
    ru.code = @"ru";
    ru.enName = @"Русский";
    ru.localName = @"Russian";
    ru.ID = 0;
    
    BMLanguage *es = [BMLanguage new];
    es.code = @"es";
    es.enName = @"Español";
    es.localName = @"Spanish";
    es.ID = 0;

    BMLanguage *sw = [BMLanguage new];
    sw.code = @"sv-SE";
    sw.enName = @"Svenska";
    sw.localName = @"Swedish";
    sw.ID = 0;

    BMLanguage *ko = [BMLanguage new];
    ko.code = @"ko";
    ko.enName = @"한국어";
    ko.localName = @"Korean";
    ko.ID = 0;

    BMLanguage *vi = [BMLanguage new];
    vi.code = @"vi";
    vi.enName = @"Tiếng Việt";
    vi.localName = @"Vietnamese";
    vi.ID = 0;

    BMLanguage *ch = [BMLanguage new];
    ch.code = @"zh-Hans";
    ch.enName = @"中文";
    ch.localName = @"Chinese";
    ch.ID = 0;

    BMLanguage *tr = [BMLanguage new];
    tr.code = @"tr";
    tr.enName = @"Türk";
    tr.localName = @"Turkish";
    tr.ID = 0;

    BMLanguage *fr = [BMLanguage new];
    fr.code = @"fr";
    fr.enName = @"Français";
    fr.localName = @"French";
    fr.ID = 0;

    BMLanguage *jp = [BMLanguage new];
    jp.code = @"ja";
    jp.enName = @"日本語";
    jp.localName = @"Japanese";
    jp.ID = 0;

    BMLanguage *th = [BMLanguage new];
    th.code = @"th";
    th.enName = @"ภาษาไทย";
    th.localName = @"Thai";
    th.ID = 0;

    BMLanguage *dutch = [BMLanguage new];
    dutch.code = @"nl";
    dutch.enName = @"Nederlands";
    dutch.localName = @"Dutch";
    dutch.ID = 0;

    BMLanguage *fin = [BMLanguage new];
    fin.code = @"fi";
    fin.enName = @"Suomi";
    fin.localName = @"Finnish";
    fin.ID = 0;
    
    BMLanguage *cs = [BMLanguage new];
    cs.code = @"cs";
    cs.enName = @"Češka";
    cs.localName = @"Czech";
    cs.ID = 0;
    
    NSArray *array =  @[en, ru, es, sw, ko, vi, ch, tr, fr, jp, th, dutch, fin, cs];
  
   // NSArray *array =  @[en, sw, ch, dutch, cs];

    NSLocale *locale = [NSLocale currentLocale];
    
    for (BMLanguage *lang in array) {
        if ([lang.code isEqualToString:locale.languageCode] && lang.ID!=2) {
            lang.ID = 1;
        }
    }
    
    NSArray *sortedNames = [array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"localName" ascending:YES]]];

    NSMutableArray *result = [NSMutableArray array];
    
    for (BMLanguage *lang in sortedNames) {
        if(lang.ID == 2) {
            [result insertObject:lang atIndex:0];
        }
        else if(lang.ID == 1) {
            if(result.count==0) {
                [result insertObject:lang atIndex:0];
            }
            else{
                [result insertObject:lang atIndex:1];
            }
        }
        else{
            [result addObject:lang];
        }
     }
    
    return result;
}

-(NSString*_Nonnull)languageName{
    
    for (BMLanguage *lang in [self languages]) {
        if ([lang.code isEqualToString:_language]) {
            return lang.enName;
        }
    }
    
    return @"English";
}

-(NSString*_Nonnull)shortLanguageName {
    for (BMLanguage *lang in [self languages]) {
        if ([lang.code isEqualToString:_language]) {
            return [[lang.localName substringToIndex:2] uppercaseString];
        }
    }
    
    return @"EN";
}

#pragma mark - Delegates

-(void)addDelegate:(id<SettingsModelDelegate>) delegate{
    if(![_delegates containsObject:delegate])
    {
        [_delegates addObject: delegate];
    }
}

-(void)removeDelegate:(id<SettingsModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

-(NSArray <BMLockScreenValue*> * _Nonnull)lockScreenValues {
    BMLockScreenValue *never = [BMLockScreenValue new];
    never.name = [@"never" localized];
    never.shortName = [@"never" localized];
    never.seconds = 0;

    BMLockScreenValue *a_15 = [BMLockScreenValue new];
    a_15.name = [@"a_15" localized];
    a_15.shortName = [@"a_15_1" localized];
    a_15.seconds = 15;
    
    BMLockScreenValue *a_30 = [BMLockScreenValue new];
    a_30.name = [@"a_30" localized];
    a_30.shortName = [@"a_30_1" localized];
    a_30.seconds = 30;
    
    BMLockScreenValue *a_60 = [BMLockScreenValue new];
    a_60.name = [@"a_60" localized];
    a_60.shortName = [@"a_60_1" localized];
    a_60.seconds = 60;
    
    return @[never,a_15,a_30,a_60];
}

-(BMLockScreenValue*_Nonnull)currentLocedValue {
    for (BMLockScreenValue *v in [self lockScreenValues]) {
        if (v.seconds == _lockScreenSeconds) {
            return v;
        }
    }
    
    return nil;
}

-(NSArray <BMLogValue*> * _Nonnull)logValues {
    BMLogValue *never = [BMLogValue new];
    never.name = [@"all_time" localized];
    never.days = 0;

    BMLogValue *d_5 = [BMLogValue new];
    d_5.name = [@"last_5_days" localized];
    d_5.days = 5;
    
    BMLogValue *d_15 = [BMLogValue new];
    d_15.name = [@"last_15_days" localized];
    d_15.days = 15;
    
    BMLogValue *d_30 = [BMLogValue new];
    d_30.name = [@"last_30_days" localized];
    d_30.days = 30;
    
    return @[never,d_5,d_15,d_30];
}

-(BMLogValue*_Nonnull)currentLogValue {
    for (BMLogValue *v in [self logValues]) {
        if (v.days == _logDays) {
            return v;
        }
    }
    
    return nil;
}

-(NSArray <BMMaxPrivacyLock*> * _Nonnull)maxPrivacyLockValues {
    BMMaxPrivacyLock *noLimit = [BMMaxPrivacyLock new];
    noLimit.detail = [@"no_limit_with_hint" localized];
    noLimit.hours = 0;
    noLimit.title = [@"no_limit" localized];

    BMMaxPrivacyLock *h24 = [BMMaxPrivacyLock new];
    h24.detail = [@"h24" localized];
    h24.hours = 24;
    h24.title = [@"h24" localized];

    BMMaxPrivacyLock *h36 = [BMMaxPrivacyLock new];
    h36.detail = [@"h36" localized];
    h36.hours = 36;
    h36.title = [@"h36" localized];

    BMMaxPrivacyLock *h48 = [BMMaxPrivacyLock new];
    h48.detail = [@"h48" localized];
    h48.hours = 48;
    h48.title = [@"h48" localized];

    BMMaxPrivacyLock *h60 = [BMMaxPrivacyLock new];
    h60.detail = [@"h60" localized];
    h60.hours = 60;
    h60.title = [@"h60" localized];

    BMMaxPrivacyLock *h72 = [BMMaxPrivacyLock new];
    h72.detail = [@"h72_recommended" localized];
    h72.hours = 72;
    h72.title = [@"h72" localized];

    return @[noLimit, h72, h60, h48, h36, h24];
}

-(BMMaxPrivacyLock*_Nonnull)currentMaxPrivacyLockValue {
    for (BMMaxPrivacyLock *v in [self maxPrivacyLockValues]) {
        if (v.hours == _lockMaxPrivacyValue) {
            return v;
        }
    }
    
    return nil;
}

-(NSString*_Nonnull)dAppUrl {
    if (_target == Testnet) {
        return @"https://apps-testnet.beam.mw/appslist.json";
    }
    else if (_target == Masternet) {
        return @"http://3.16.160.95/app/appslist.json";
    }
    return @"https://apps.beam.mw/appslist.json";
}

-(NSString*_Nonnull)assetBlockchainUrl:(int)assetId {
    if (self.target == Testnet) {
        return [NSString stringWithFormat:@"https://testnet.explorer.beam.mw/assets/details/%d", assetId];
    }
    else if (self.target == Masternet) {
        return [NSString stringWithFormat:@"https://master-net.explorer.beam.mw/assets/details/%d", assetId];
    }
    else{
        return [NSString stringWithFormat:@"https://explorer.beam.mw/assets/details/%d", assetId];
    }
}

@end
