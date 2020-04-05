

@class DNDModeAssertionLifetime;

@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(NSString *)identifier modeIdentifier:(NSString *)modeIdentifier lifetime:(DNDModeAssertionLifetime *)lifetime;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)clientIdentifier;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface RPControlCenterClient
@property BOOL recordingOn;
@end

static BOOL DNDEnabled;
static BOOL DNDEnabledTemp;
static BOOL wasRecording;
static DNDModeAssertionService *assertionService;

%hook RPControlCenterClient
-(void)startRecordingWithHandler:(/*^block*/id)arg1{
  %orig;
  %log;
  //recording started, save the DND state and enable it if needed.
  wasRecording = true;
  DNDEnabledTemp = DNDEnabled;
  if(DNDEnabled == false){
    if (!assertionService) {
      assertionService = (DNDModeAssertionService *)[objc_getClass("DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
    }
    DNDModeAssertionDetails *newAssertion = [objc_getClass("DNDModeAssertionDetails") userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
    [assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
  }
}

-(void)screenRecorderDidUpdateState:(id)arg1{
  %orig;
  %log;
  NSLog(@"[RPScreenRecorder]gilshahar7 screenRecorderDidUpdateState");
  if(self.recordingOn == NO && wasRecording == YES){
    //recording ended, decide what to do with DND
    wasRecording = false;
    if(DNDEnabledTemp == false){
      if (!assertionService) {
        assertionService = (DNDModeAssertionService *)[objc_getClass("DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
      }
      [assertionService invalidateAllActiveModeAssertionsWithError:NULL];
    }
  }
}
%end

%hook DNDState
-(BOOL)isActive {
  //save the DND state.
	DNDEnabled = %orig;
	return DNDEnabled;
}
%end

%ctor
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
    {
        //load ReplayKitModule bundle so we can hook it
        NSBundle* moduleBundle = [NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ReplayKitModule.bundle"];
        if (!moduleBundle.loaded)
            [moduleBundle load];
        %init;
    }
}
