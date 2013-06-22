//
//  CPPassDataManager.m
//  Passone
//
//  Created by wangyw on 6/13/13.
//  Copyright (c) 2013 codingpotato. All rights reserved.
//

#import "CPPassDataManager.h"

#import "CPHint.h"
#import "CPPassword.h"

@interface CPPassDataManager ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CPPassDataManager

static CPPassDataManager *_defaultManager = nil;

+ (CPPassDataManager *)defaultManager {
    if (!_defaultManager) {
        _defaultManager = [[CPPassDataManager alloc] init];
    }
    return _defaultManager;
}

- (NSArray *)passwords {
    if (!_passwords) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"Password" inManagedObjectContext:self.managedObjectContext]];
        [request setSortDescriptors:[[NSArray alloc] initWithObjects:[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES], nil]];
        _passwords = [self.managedObjectContext executeFetchRequest:request error:nil];
        if (!_passwords.count) {
            // TODO: 9
            for (int index = 0; index < 9; index++) {
                CPPassword *password = [NSEntityDescription insertNewObjectForEntityForName:@"Password" inManagedObjectContext:self.managedObjectContext];
                password.text = @"";
                password.index = [NSNumber numberWithInteger:index];
                password.date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
                password.red = [NSNumber numberWithFloat:0.7];
                password.green = [NSNumber numberWithFloat:0.7];
                password.blue = [NSNumber numberWithFloat:0.7];
            }
            _passwords = [self.managedObjectContext executeFetchRequest:request error:nil];
        }
    }
    return _passwords;
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // TODO: Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)setPasswordText:(NSString *)text red:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue atIndex:(NSInteger)index {
    CPPassword *password = [self.passwords objectAtIndex:index];
    NSAssert(password, @"");
    
    if ([password.text isEqualToString:@""]) {
        password.date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    } else if ([text isEqualToString:@""]) {
        password.date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    }
    
    password.text = text;
    password.red = [NSNumber numberWithFloat:red];
    password.green = [NSNumber numberWithFloat:green];
    password.blue = [NSNumber numberWithFloat:blue];
}

- (void)addHintText:(NSString *)text intoIndex:(NSInteger)index {
    CPPassword *password = [self.passwords objectAtIndex:index];
    NSAssert(password, @"");
    
    CPHint *hint = [NSEntityDescription insertNewObjectForEntityForName:@"Hint" inManagedObjectContext:self.managedObjectContext];
    hint.text = text;
    hint.password = password;
    [password addHintsObject:hint];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Passone" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Passone.sqlite"];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            /*
             TODO: Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

@end
