//
//  V3QRCodeReader.h
//
//  Created by Vivek Vithlani on 7/27/15.
//  Modify by Vivek Vithalain on 21-Nov-2018
//  Copyright (c) 2015 iOS Developer. All rights reserved.
//
// Supported BarCodeType
/*
 PDF417
 QRCode
 UPCECode
 39Code
 Code39Mod43Code
 EAN13Code
 EAN8Code
 Code93Code
 Code128Code
 AztecCode
 Interleaved2of5Code
 ITF14Code
 DataMatrixCode
 */

#import <UIKit/UIKit.h>

@protocol V3QRCodeReaderDelegate <NSObject>
@required
    - (void)getBarCodeData:(NSDictionary *)scanDictonary;

@optional
    - (void)getQRCodeData:(id)qRCodeData __attribute__((deprecated("please use getBarCodeData instead")));
@end

@interface V3QRCodeReader : UIView
// V3QRCodeReader Delegate
@property (nonatomic, retain) id delegate;

// init view
-(id)initWithFrame:(CGRect)frame viewController:(id)ViewController;

// Start Barcode reading
-(BOOL)startReading;

// Stop Barcode reading
-(void)stopReading;

// Check Barcode scanning status
-(BOOL)isRunning;
@end
