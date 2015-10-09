//
//  Util.swift
//  FindMe
//
//  Created by Jacky Tjoa on 5/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit

class Util: NSObject {
    
    class func circleView(view: UIView) {
    
        view.layer.cornerRadius = view.bounds.size.width * 0.5
        view.layer.borderWidth = 1.0
        view.layer.borderColor = self.normalizedColorWith(182.0, green: 161.0, blue: 129.0, alpha: 1.0).CGColor
        view.clipsToBounds = true
    }
    
    class func normalizedColorWith(red: CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
    
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
    }
    
    class func showAlertWithMessage(message: String, onViewController vc:UIViewController) {
        
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
        }
        
        alertController.addAction(closeAction)
        
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
    
    class func resizeImageWithImage(image: UIImage, scaledToSize size:CGSize) -> UIImage {
    
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        /*
        // Add a clip before drawing anything, in the shape of an rounded rect
        [[UIBezierPath bezierPathWithRoundedRect:imageView.bounds
        cornerRadius:10.0] addClip];
        
        // Draw your image
        [image drawInRect:imageView.bounds];
        */
        
        UIBezierPath(roundedRect: CGRectMake(0, 0, size.width, size.height), cornerRadius: size.width * 0.5).addClip()
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    /*
    + (UIImage *) imageWithView:(UIView *)view
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return img;
    }
    */
}