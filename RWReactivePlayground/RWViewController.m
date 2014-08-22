//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *usernameValid) {
        return [usernameValid boolValue] ? [UIColor clearColor]: [UIColor yellowColor];
    }];
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor]: [UIColor yellowColor];
    }];
    
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }];
    
//    [signUpActiveSignal subscribeNext:^(NSNumber *signUpActive) {
//        self.signInButton.enabled = [signUpActive boolValue];
//    }];
    
    RAC(self.signInButton, enabled) = [signUpActiveSignal map:^id(NSNumber *signUpActive) {
        return @([signUpActive boolValue]);
    }];
    
    [[[[self.signInButton
      rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^(id x) {
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      }]
     flattenMap:^id(id value) {
         return [self signInSignal];
     }]
     subscribeNext:^(NSNumber *signIn) {
         BOOL success = [signIn boolValue];
         self.signInButton.enabled = YES;
         self.signInFailureText.hidden = success;
         if (success) {
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
    }];
    
    RACSignal *usernameChangeSignal = self.usernameTextField.rac_textSignal;
    RACSignal *passwordChangeSignal = self.passwordTextField.rac_textSignal;
    RACSignal *hiddenFailureTextSignal = [RACSignal combineLatest:@[usernameChangeSignal, passwordChangeSignal]];
    RAC(self.signInFailureText, hidden) = [hiddenFailureTextSignal map:^id(id value) {
        return @(YES);
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (RACSignal *)signInSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService
         signInWithUsername:self.usernameTextField.text
         password:self.passwordTextField.text
         complete:^(BOOL success) {
             [subscriber sendNext:@(success)];
             [subscriber sendCompleted];
        }];
        return nil;
    }];
}

//- (IBAction)signInButtonTouched:(id)sender {
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  
//  // sign in
//  [self.signInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid

@end
