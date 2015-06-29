//
//  ClassExtensions.swift
//  ExtDownloader
//
//  Created by Amir Abbas on 93/9/13.
//  Copyright (c) 1393 Mousavian. All rights reserved.
//

import UIKit
import MobileCoreServices

// MARK: - Serializable NSObject
public extension NSObject {
    
    func toDictionary() -> NSDictionary {
        var aClass : AnyClass? = self.dynamicType
        var propertiesCount : CUnsignedInt = 0
        let propertiesInAClass : UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(aClass, &propertiesCount)
        var propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
        
        for var i = 0; i < Int(propertiesCount); i++ {
            var property = propertiesInAClass[i]
            var propName = NSString(CString: property_getName(property), encoding: NSUTF8StringEncoding) ?? ""
            var propType = property_getAttributes(property)
            var propValue : AnyObject! = self.valueForKey(propName as String);
            
            if propValue is NSObject {
                propertiesDictionary.setValue((propValue as! NSObject).toDictionary(), forKey: propName as String)
            } else if propValue is Array<NSObject> {
                var subArray = Array<NSDictionary>()
                for item in (propValue as! Array<NSObject>) {
                    subArray.append(item.toDictionary())
                }
                propertiesDictionary.setValue(subArray, forKey: propName as String)
            } else if propValue is NSData {
                propertiesDictionary.setValue((propValue as! NSData).base64EncodedStringWithOptions(nil), forKey: propName as String)
            } else if propValue is Bool {
                propertiesDictionary.setValue((propValue as! Bool).boolValue, forKey: propName as String)
            } else if propValue is NSDate {
                var date = propValue as! NSDate
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "Z"
                var dateString = NSString(format: "/Date(%.0f000%@)/", date.timeIntervalSince1970, dateFormatter.stringFromDate(date))
                propertiesDictionary.setValue(dateString, forKey: propName as String as String)
            } else {
                propertiesDictionary.setValue(propValue, forKey: propName as String)
            }
        }
        
        return propertiesDictionary
    }
    
    func toJson() -> NSData! {
        let dictionary = self.toDictionary()
        var err: NSError?
        return NSJSONSerialization.dataWithJSONObject(dictionary, options:NSJSONWritingOptions(0), error: &err)
    }
    
    func toJsonString() -> NSString! {
        return NSString(data: self.toJson(), encoding: NSUTF8StringEncoding)
    }
    
    //    override init() { }
}

extension Float {
    func format(#percision: Int) -> String {
        let nFormatter = NSNumberFormatter();
        nFormatter.numberStyle = .DecimalStyle;
        nFormatter.maximumFractionDigits = percision;
        return nFormatter.stringFromNumber(self)!
    }
}

extension Int64 {
    var formatByte: String {
        return NSByteCountFormatter.stringFromByteCount(self, countStyle: .File)
    }
}

extension String {
    // Utilities
    func leftString(index: Int) -> String {
        return self.substringToIndex(advance(self.startIndex, index))
    }
    
    func rightString(index: Int) -> String {
        let len = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return self.substringFromIndex(advance(self.startIndex, len - index))
    }
    
    func midString(start: Int, count: Int) -> String {
        return self.substringWithRange(Range<String.Index>(start: advance(self.startIndex, start), end: advance(self.startIndex, start + count)))
    }
    
    func pos(subString: String, caseInsensitive: Bool = false) -> Int {
        let searchOption = caseInsensitive ? NSStringCompareOptions.CaseInsensitiveSearch : NSStringCompareOptions.LiteralSearch
        if let range = self.rangeOfString(subString, options: searchOption) where !range.isEmpty {
            return distance(self.startIndex, range.startIndex)
        }
        return -1;
    }
    
    var stringByAddingPercentForURL: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) ?? self
    }
    
    // Style
    func height(width: CGFloat, font: UIFont, lineBreakMode: NSLineBreakMode?) -> CGFloat {
        var attrib: [NSString: AnyObject] = [NSFontAttributeName: font]
        if lineBreakMode != nil {
            let paragraphStyle = NSMutableParagraphStyle();
            paragraphStyle.lineBreakMode = lineBreakMode!;
            attrib.updateValue(paragraphStyle, forKey: NSParagraphStyleAttributeName);
        }
        let size = CGSize(width: width, height: CGFloat(DBL_MAX));
        return ceil((self as NSString).boundingRectWithSize(size, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes:attrib, context: nil).height)
    }
    
    func colorSubString(subString: String, color: UIColor) -> NSMutableAttributedString {
        var start = 0;
        var ranges: [NSRange] = []
        while true {
            let range = (self as NSString).rangeOfString(subString, options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(start, (self as NSString).length - start))
            if range.location == NSNotFound {
                break;
            } else {
                ranges.append(range)
                start = range.location + range.length
            }
        }
        let attrText = NSMutableAttributedString(string: self);
        for range in ranges {
            attrText.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
        return attrText;
    }
    
    // File Operations
    var isDirectory: Bool {
        var isDir: ObjCBool = false;
        NSFileManager.defaultManager().fileExistsAtPath(self, isDirectory: &isDir);
        return isDir.boolValue;
    }
    
    var extensionInfo: (mime: String, uti: String, desc: String) {
        if !NSFileManager.defaultManager().fileExistsAtPath(self) {
            return ("", "", "")
        }
        if self.isDirectory {
            return("inode/directory", "public.directory", "Folder")
        } else {
            let fileExt = self.pathExtension;
            let utiu = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil).takeUnretainedValue();
            let uti = String(utiu).hasPrefix("dyn.") ? "public.data" : String(utiu)
            let mimeu = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
            let mime = mimeu == nil ? "application/octet-stream" : mimeu.takeUnretainedValue();
            let descu = UTTypeCopyDescription(utiu)
            let desc = (descu == nil) ? (self.pathExtension.uppercaseString + " File") : String(descu.takeUnretainedValue());
            return (mime as String, uti, desc);
        }
    }
}

extension NSURL {
    var remoteSize: Int64 {
        let request = NSMutableURLRequest(URL: self, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
        request.HTTPMethod = "HEAD";
        request.setValue("", forHTTPHeaderField: "Accept-Encoding")
        request.timeoutInterval = 2;
        var response: NSURLResponse?;
        var error: NSError?
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        let HTTPResponse = response as? NSHTTPURLResponse;
        if let contentLength = HTTPResponse?.allHeaderFields["Content-Length"] as? String {
            return Int64(contentLength.toInt() ?? -1);
        } else {
            return -1;
        }
    }
    
    func supportsResume() -> Bool {
        let request = NSMutableURLRequest(URL: self, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
        request.HTTPMethod = "HEAD";
        request.setValue("bytes=10-15", forHTTPHeaderField: "Range")
        var response: NSURLResponse?;
        var error: NSError?
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        if (response != nil) && (response! is NSHTTPURLResponse) && ((response! as! NSHTTPURLResponse).statusCode == 206) {
            return true;
        } else {
            return false
        }
    }
    
    func isSameWithURL(url: NSURL) -> Bool {
        if self == url {
            return true
        }
        if self.scheme?.lowercaseString != url.scheme?.lowercaseString {
            return false
        }
        if let host1 = self.host, host2 = url.host {
            let whost1 = host1.hasPrefix("www.") ? host1 : "www." + host1
            let whost2 = host2.hasPrefix("www.") ? host2 : "www." + host2
            if whost1 != whost2 {
                return false
            }
        }
        if self.path?.lowercaseString != url.path?.lowercaseString {
            return false
        }
        if self.port != url.port {
            return false
        }
        if self.query?.lowercaseString != url.query?.lowercaseString {
            return false
        }
        return true
    }
    
    var fileName: String {
        var fileN = self.lastPathComponent ?? ""
        if fileN.pos("?") > -1 {
            fileN = fileN.leftString(fileN.pos("?"))
        }
        if fileN.isEmpty {
            fileN = "noname"
        }
        return fileN;
    }
}

extension NSDate {
    convenience init ? (string: String, withFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") {
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = withFormat
        if let date = dateFor.dateFromString(string) {
            self.init(timeIntervalSince1970: date.timeIntervalSince1970)
        } else {
            self.init()
            return nil
        }
    }
    
    func format(dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") -> String {
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = dateFormat
        return dateFor.stringFromDate(self)
    }
    
    func format(#dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, separator: String = ", ") -> String {
        let date = NSDateFormatter.localizedStringFromDate(self, dateStyle: dateStyle, timeStyle: .NoStyle)
        let time = NSDateFormatter.localizedStringFromDate(self, dateStyle: .NoStyle, timeStyle: timeStyle)
        return "\(date)\(separator)\(time)"
    }
}
extension NSTimeInterval {
    var formatted: String {
        var result = "Calculating...";
        if self < NSTimeInterval(Int32.max) {
            result = "";
            let time = NSDateComponents();
            time.hour   = Int(self / 3600);
            time.minute = Int((self % 3600) / 60);
            time.second = Int(self % 60);
            if NSClassFromString("NSDateComponentsFormatter") != nil {
                let dateComponentsFormatter = NSDateComponentsFormatter()
                dateComponentsFormatter.unitsStyle = .Short
                result = dateComponentsFormatter.stringFromDateComponents(time)!;
            } else {
                if time.hour > 0 { result.extend("\(time.hour) hrs") }
                if time.minute > 0 { result.extend(" \(time.minute) mins") }
                if time.second > 0 { result.extend(" \(time.second) secs") }
                if result == "" { result = "0 sec" }
            }
        }
        return result.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
    }
}

extension Set {
    mutating func append(member: T) {
        self.insert(member)
    }
    
    subscript (index: Int) -> T {
        return self[advance(self.startIndex, index)]
    }
}

extension UIColor {
    /**
    Returns a UIColor object from a Hexadecimal string with an adjustable alpha channel

    :param: color The 6 digit hexadecimal string representation of the string including the # or not
    :param: alpha The transparency, represented as a CGFloat Double between 0 and 1
    :returns: a UIColor, nil if the casting fails
    */
    convenience init? (hexColor: String, alpha: CGFloat) {
        assert(alpha <= 1.0, "The alpha channel cannot be above 1")
        assert(alpha >= 0, "The alpha channel cannot be below 0")
        var rgbValue : UInt32 = 0
        let scanner = NSScanner(string: hexColor)
        scanner.scanLocation = hexColor.hasPrefix("#") ? 1 : 0;
        
        if scanner.scanHexInt(&rgbValue) {
            let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((rgbValue & 0xFF00) >> 16) / 255.0
            let blue = CGFloat((rgbValue & 0xFF) >> 16) / 255.0
            
            self.init(red: red, green: green, blue: blue, alpha: alpha)
            return
        }
        
        self.init(red: 0, green: 0, blue: 0, alpha: 1)
        return nil
    }
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    var hsla: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }

    var alpha: CGFloat {
        var result: CGFloat = 0
        self.getHue(nil, saturation: nil, brightness: nil, alpha: &result)
        return result
    }
 
    var white: CGFloat {
        var result: CGFloat = 0
        self.getWhite(&result, alpha: nil)
        return result
    }
}

extension UIImage {
    func imageWithColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext() as CGContextRef
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        
        let rect = CGRectMake(0, 0, self.size.width, self.size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func withPad(#topLeft: CGPoint, bottomRight: CGPoint, scaleFactor: CGFloat = 0) -> UIImage {
        let newSize = CGSizeMake(self.size.width + (topLeft.x + bottomRight.x), self.size.height + (topLeft.y + bottomRight.y));
        UIGraphicsBeginImageContextWithOptions(newSize, false, scaleFactor);
        self.drawAtPoint(topLeft);
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    func withSize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}

extension Dictionary {
    func sortedKeys(isOrderedBefore:(Key,Key) -> Bool) -> [Key] {
        var array = Array(self.keys)
        sort(&array, isOrderedBefore)
        return array
    }
    
    // Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
    func sortedKeysByValue(isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        return sortedKeys {
            isOrderedBefore(self[$0]!, self[$1]!)
        }
    }
    
    // Faster because of no lookups, may take more memory because of duplicating contents
    func keysSortedByValue(isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        var array = Array(self)
        sort(&array) {
            let (lk, lv) = $0
            let (rk, rv) = $1
            return isOrderedBefore(lv, rv)
        }
        return array.map {
            let (k, v) = $0
            return k
        }
    }
}

extension NSDictionary {
    convenience init ? (json: String) {
        if let data = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
            self.init(dictionary: data)
        } else {
            self.init()
            return nil
        }
    }
    
    func formatJSON() -> String? {
        if let jsonData = NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions.allZeros, error: nil) {
            let jsonStr = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
            return String(jsonStr ?? "")
        }
        return nil
    }
}
