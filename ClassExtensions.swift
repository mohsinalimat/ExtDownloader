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
        let aClass : AnyClass? = self.dynamicType
        var propertiesCount : CUnsignedInt = 0
        let propertiesInAClass : UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(aClass, &propertiesCount)
        let propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
        
        for var i = 0; i < Int(propertiesCount); i++ {
            let property = propertiesInAClass[i]
            let propName = NSString(CString: property_getName(property), encoding: NSUTF8StringEncoding) ?? ""
            //var propType = property_getAttributes(property)
            let propValue : AnyObject! = self.valueForKey(propName as String);
            
            if propValue is NSObject {
                propertiesDictionary.setValue((propValue as! NSObject).toDictionary(), forKey: propName as String)
            } else if propValue is Array<NSObject> {
                var subArray = Array<NSDictionary>()
                for item in (propValue as! Array<NSObject>) {
                    subArray.append(item.toDictionary())
                }
                propertiesDictionary.setValue(subArray, forKey: propName as String)
            } else if propValue is NSData {
                propertiesDictionary.setValue((propValue as! NSData).base64EncodedStringWithOptions([]), forKey: propName as String)
            } else if propValue is Bool {
                propertiesDictionary.setValue((propValue as! Bool).boolValue, forKey: propName as String)
            } else if propValue is NSDate {
                let date = propValue as! NSDate
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "Z"
                let dateString = NSString(format: "/Date(%.0f000%@)/", date.timeIntervalSince1970, dateFormatter.stringFromDate(date))
                propertiesDictionary.setValue(dateString, forKey: propName as String as String)
            } else {
                propertiesDictionary.setValue(propValue, forKey: propName as String)
            }
        }
        
        return propertiesDictionary
    }
    
    func toJson() -> NSData! {
        let dictionary = self.toDictionary()
        do {
            return try NSJSONSerialization.dataWithJSONObject(dictionary, options:NSJSONWritingOptions(rawValue: 0))
        } catch _ {
            return nil
        }
    }
    
    func toJsonString() -> NSString! {
        return NSString(data: self.toJson(), encoding: NSUTF8StringEncoding)
    }
}

extension Float {
    func format(percision percision: Int) -> String {
        let nFormatter = NSNumberFormatter();
        nFormatter.numberStyle = .DecimalStyle;
        nFormatter.maximumFractionDigits = percision;
        return nFormatter.stringFromNumber(self)!
    }
}

extension Double {
    func format(percision percision: Int) -> String {
        let nFormatter = NSNumberFormatter();
        nFormatter.numberStyle = .DecimalStyle;
        nFormatter.maximumFractionDigits = percision;
        return nFormatter.stringFromNumber(self)!
    }
}

extension Int64 {
    var formatByte: String {
        if self < 0 {
            return "Unknown"
        }
        return NSByteCountFormatter.stringFromByteCount(self, countStyle: .File)
    }
}

extension String {
    init ? (base64: String) {
        if let decodedData = NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions(rawValue: 0)), let decodedString = NSString(data: decodedData, encoding: NSUTF8StringEncoding) {
            self.init(decodedString)
        }
        return nil
    }
    
    static func generateUUID() -> String {
        return NSUUID().UUIDString;
        /*var str = NSProcessInfo.processInfo().globallyUniqueString;
        str = str.substringWithRange(Range<String.Index>(start: str.startIndex, end: advance(str.startIndex, 36)))
        return str;*/
    }
    
    var base64: String {
        get {
            let plainData = (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            let base64String = plainData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            return base64String
        }
    }
    
    // Utilities
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func leftString(index: Int) -> String {
        return self.substringToIndex(self.startIndex.advancedBy(index))
    }
    
    func rightString(index: Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(length - index))
    }
    
    func midString(start: Int, count: Int) -> String {
        return self[start...(start+count)]
    }
    
    subscript (index: Int) -> Character {
        return self[self.startIndex.advancedBy(index)]
    }
    
    subscript (index: Int) -> String {
        return String(self[index] as Character)
    }
    
    subscript (range: Range<Int>) -> String {
        let endIndex = min(self.characters.count, range.endIndex)
        return substringWithRange(Range(start: startIndex.advancedBy(range.startIndex), end: startIndex.advancedBy(endIndex)))
    }
    
    func pos(subString: String, caseInsensitive: Bool = false) -> Int {
        if subString.isEmpty {
            return -1
        }
        let searchOption = caseInsensitive ? NSStringCompareOptions.CaseInsensitiveSearch : NSStringCompareOptions.LiteralSearch
        if let range = self.rangeOfString(subString, options: searchOption) where !range.isEmpty {
            return self.startIndex.distanceTo(range.startIndex)
        }
        return -1;
    }
    
    func split(separator: String) -> [String] {
        return self.componentsSeparatedByString(separator).filter {
            !$0.trim().isEmpty
        }
    }
    
    func split(characters: NSCharacterSet) -> [String] {
        return self.componentsSeparatedByCharactersInSet(characters).filter {
            !$0.trim().isEmpty
        }
    }
    
    var length: Int {
        return self.characters.count
    }
    
    var countofWords: Int {
        let regex = try? NSRegularExpression(pattern: "\\w+", options: NSRegularExpressionOptions())
        return regex?.numberOfMatchesInString(self, options: NSMatchingOptions(), range: NSMakeRange(0, self.length)) ?? 0
    }
    
    var countofParagraphs: Int {
        let regex = try? NSRegularExpression(pattern: "\\n", options: NSRegularExpressionOptions())
        let str = self.trim()
        return (regex?.numberOfMatchesInString(str, options: NSMatchingOptions(), range: NSMakeRange(0, str.length)) ?? -1) + 1
    }
    
    var stringByAddingPercentForURL: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) ?? self
    }
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func matchesForRegexInText(regex: String!) -> [String] {
        let regex = try? NSRegularExpression(pattern: regex, options: [])
        let results = regex?.matchesInString(self, options: [], range: NSMakeRange(0, self.length)) ?? []
        return results.map { self.substringWithRange(self.rangeFromNSRange($0.range)!) }
    }
}

extension String {
    func height(width: CGFloat, font: UIFont, lineBreakMode: NSLineBreakMode?) -> CGFloat {
        var attrib: [String: AnyObject] = [NSFontAttributeName: font]
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
    
    var fileURL: NSURL {
        return NSURL(fileURLWithPath: self)
    }
    
    var pathExtension: String {
        return self.fileURL.pathExtension ?? ""
    }
    
    var lastPathComponent: String {
        return self.fileURL.lastPathComponent ?? ""
    }
    
    var stringByExpandingTildeInPath: String {
        return (self as NSString).stringByExpandingTildeInPath
    }
    
    var stringByAbbreviatingWithTildeInPath: String {
        return (self as NSString).stringByAbbreviatingWithTildeInPath
    }
    
    func stringByAppendingPathComponent(pathComponent: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(pathComponent)
    }
    
    func stringByAppendingPathExtension(pathExtension: String) -> String? {
        return (self as NSString).stringByAppendingPathExtension(pathExtension)
    }
    
    var stringByDeletingLastPathComponent: String {
        return (self as NSString).stringByDeletingLastPathComponent
    }
    
    var stringByDeletingPathExtension: String {
        return (self as NSString).stringByDeletingPathExtension
    }
    
    var stringByStandardizingPath: String {
        return (self as NSString).stringByStandardizingPath
    }
    
    var stringByResolvingSymlinksInPath: String {
        return (self as NSString).stringByResolvingSymlinksInPath
    }
    
    var isDirectory: Bool {
        var isDir: ObjCBool = false;
        NSFileManager.defaultManager().fileExistsAtPath(self, isDirectory: &isDir);
        return isDir.boolValue;
    }
    
    var extensionInfo: (mime: String, uti: String, desc: String) {
        let attrib = try? NSFileManager.defaultManager().attributesOfItemAtPath(self)
        let isDirectory = (attrib?[NSFileType] as? String ?? "") == NSFileTypeDirectory
        let isSymLink = (attrib?[NSFileType] as? String ?? "") == NSFileTypeSymbolicLink
        if isDirectory {
            return("inode/directory", "public.directory", "Folder")
        } else if isSymLink {
            return("inode/symlink", "public.symlink", "Alias")
        } else {
            if !NSFileManager.defaultManager().fileExistsAtPath(self) {
                return ("", "", "")
            }
            let fileExt = self.pathExtension;
            let utiu = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil)?.takeUnretainedValue();
            let uti = String(utiu).hasPrefix("dyn.") ? "public.data" : String(utiu)
            let mimeu = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
            let mime = mimeu == nil ? "application/octet-stream" : mimeu?.takeUnretainedValue();
            let descu = UTTypeCopyDescription(utiu ?? "")
            let desc = (descu == nil) ? (self.pathExtension.uppercaseString + " File") : String(descu?.takeUnretainedValue());
            return (mime as? String ?? "application/octet-stream", uti, desc);
        }
    }
    
    var fileInfo: (size: Int64, creationDate: NSDate, modificationDate: NSDate) {
        if let fileAttrDic = try? NSFileManager.defaultManager().attributesOfItemAtPath(self) {
            let fileAttr = NSDictionary(dictionary: fileAttrDic)
            return (Int64(fileAttr.fileSize()),
                fileAttr.fileCreationDate()!,
                fileAttr.fileModificationDate()!)
        } else {
            return (0, NSDate(), NSDate())
        }
    }
    
    var stringByUniqueFileName: String {
        if (try? NSFileManager.defaultManager().attributesOfItemAtPath(self)) != nil {
            let curFileNum = self.lastPathComponent
            var unique = false
            var i = Int(curFileNum.split(" ").last ?? "noname") ?? 2
            var newName = self
            while !unique && i < 1000 {
                newName = ((self.fileURL.URLByDeletingLastPathComponent!).path! + " \(i)").fileURL.URLByAppendingPathExtension(self.pathExtension).path!;
                newName = newName.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
                unique = (try? NSFileManager.defaultManager().attributesOfItemAtPath(newName)) == nil;
                i++;
            }
            return newName
        } else {
            return self
        }
    }
}

extension NSURL {
    var remoteSize: Int64 {
        var contentLength: Int64 = NSURLSessionTransferSizeUnknown
        let request = NSMutableURLRequest(URL: self, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
        request.HTTPMethod = "HEAD";
        request.setValue("", forHTTPHeaderField: "Accept-Encoding")
        request.timeoutInterval = 2;
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            dispatch_group_leave(group)
        }).resume()
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC)))
        return contentLength
    }
    
    func supportsResume() -> Bool {
        var responseCode = -1
        let request = NSMutableURLRequest(URL: self, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
        request.HTTPMethod = "HEAD";
        request.setValue("bytes=5-10", forHTTPHeaderField: "Range")
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            responseCode = (response as? NSHTTPURLResponse)?.statusCode ?? -1
            dispatch_group_leave(group)
        }).resume()
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC)))
        return (responseCode == 206)
    }
    
    func isSameWithURL(url: NSURL) -> Bool {
        if self == url {
            return true
        }
        if self.scheme.lowercaseString != url.scheme.lowercaseString {
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
    
    var fileURLAttributes: (isDir: Bool, name: String, dateModified: NSDate, dateCreation: NSDate, size: Int64) {
        var isdirv, namev, datemodv, datecreatev, sizev: AnyObject?
        do {
            try self.getResourceValue(&isdirv, forKey: NSURLIsDirectoryKey)
        } catch _ {
        }
        do {
            try self.getResourceValue(&namev, forKey: NSURLNameKey)
        } catch _ {
        }
        do {
            try self.getResourceValue(&datemodv, forKey: NSURLContentModificationDateKey)
        } catch _ {
        }
        do {
            try self.getResourceValue(&datecreatev, forKey: NSURLCreationDateKey)
        } catch _ {
        }
        do {
            try self.getResourceValue(&sizev, forKey: NSURLFileSizeKey)
        } catch _ {
        }
        let isdir = isdirv?.boolValue ?? false
        let name = namev as? String ?? ""
        let datemod = datemodv as? NSDate ?? NSDate()
        let datecreate = datecreatev as? NSDate ?? NSDate()
        let size = sizev?.longLongValue ?? 0
        
        return (isdir, name, datemod, datecreate, size)
    }
    
    func skipBackupAttributeToItemAtURL(skip: Bool? = nil) -> Bool {
        let keys = [NSURLIsDirectoryKey, NSURLFileSizeKey]
        let enumOpt = NSDirectoryEnumerationOptions()
        if NSFileManager.defaultManager().fileExistsAtPath(self.path!) {
            if skip != nil {
                if self.path!.isDirectory {
                    let filesList = (try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(self, includingPropertiesForKeys: keys, options: enumOpt)) ?? []
                    for fileURL in filesList {
                        fileURL.skipBackupAttributeToItemAtURL(skip);
                    }
                }
                do {
                    try self.setResourceValue(NSNumber(bool: skip!), forKey: NSURLIsExcludedFromBackupKey)
                    return true
                } catch _ {
                    return false
                }
            } else {
                let dict = try? self.resourceValuesForKeys([NSURLIsExcludedFromBackupKey])
                if  let key: AnyObject = dict?[NSURLIsExcludedFromBackupKey] {
                    return key.boolValue
                }
                return false
            }
        }
        return false
    }
}

typealias ByteRange = Range<Int64>

extension NSURLRequest {
    var range: ByteRange? {
        guard let rangeStr = self.valueForHTTPHeaderField("Range")?.split("=") else {
            return nil
        }
        if rangeStr.count > 1 {
            let ranges = rangeStr[1].split("-")
            if ranges.count == 2 {
                let min = strtoll(ranges[0], nil, 10)
                let max = strtoll(ranges[1], nil, 10)
                if max > min {
                    return ByteRange(start: min, end: max + 1)
                }
            }
        }
        return nil
    }
}

extension NSHTTPURLResponse {
    var serverDateString: String? {
        return allHeaderFields["Last-Modified"] as? String
    }
    
    var serverDate: NSDate? {
        if let serverDateString = serverDateString {
            return NSDate(httpDateString: serverDateString)
        }
        return nil
    }
}

extension NSData {
    func isValidResumeData() -> Bool {
        if self.length < 1 {
            return false;
        }
        let resumeDictionary: NSDictionary?
        do {
            resumeDictionary = try NSPropertyListSerialization.propertyListWithData(self, options: NSPropertyListReadOptions(), format: nil) as? NSDictionary;
        } catch _ {
            return false
        }
        
        guard (resumeDictionary != nil)  else {
            return false
        }
        
        let localFilePath = resumeDictionary!.objectForKey("NSURLSessionResumeInfoLocalPath") as? String;
        let localFileName = resumeDictionary!.objectForKey("NSURLSessionResumeInfoTempFileName") as? String;
        if (localFileName == nil && localFilePath == nil) {
            return false
        }
        
        return true // NSFileManager.defaultManager().fileExistsAtPath(localFilePath!);
    }
}

extension NSDate {
    convenience init ? (string: String, withFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") {
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = withFormat
        dateFor.locale = NSLocale(localeIdentifier: "en_US")
        if let date = dateFor.dateFromString(string) {
            self.init(timeIntervalSince1970: date.timeIntervalSince1970)
        } else {
            self.init()
            return nil
        }
    }
    
    convenience init ? (httpDateString: String) {
        if let rfc1123 = NSDate(string: httpDateString, withFormat: "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz") {
            self.init(timeIntervalSince1970: rfc1123.timeIntervalSince1970)
            return
        }
        if let rfc850 = NSDate(string: httpDateString, withFormat: "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z") {
            self.init(timeIntervalSince1970: rfc850.timeIntervalSince1970)
            return
        }
        if let asctime =  NSDate(string: httpDateString, withFormat: "EEE MMM d HH':'mm':'ss yyyy") {
            self.init(timeIntervalSince1970: asctime.timeIntervalSince1970)
            return
        }
        self.init()
        return nil
    }
    
    func format(dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") -> String {
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = dateFormat
        return dateFor.stringFromDate(self)
    }
    
    func format(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, separator: String = ", ") -> String {
        let date = NSDateFormatter.localizedStringFromDate(self, dateStyle: dateStyle, timeStyle: .NoStyle)
        let time = NSDateFormatter.localizedStringFromDate(self, dateStyle: .NoStyle, timeStyle: timeStyle)
        return "\(date)\(separator)\(time)"
    }
}

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

public func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedDescending
}

extension NSDate: Comparable { }

extension NSTimeInterval {
    @available(iOS 8.0, *)
    func format(timeStyle timeStyle: NSDateComponentsFormatterUnitsStyle) -> String {
        var result = "Calculating...";
        let dateComponentsFormatter = NSDateComponentsFormatter()
        let time = NSDateComponents();
        time.hour   = Int(self / 3600);
        time.minute = Int((self % 3600) / 60);
        time.second = Int(self % 60);
        dateComponentsFormatter.unitsStyle = timeStyle
        dateComponentsFormatter.allowedUnits = [NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
        result = dateComponentsFormatter.stringFromTimeInterval(self) ?? ""
        return result
    }
    
    var formatted: String {
        var result = "Calculating...";
        if self < NSTimeInterval(Int32.max) {
            result = "";
            let time = NSDateComponents();
            time.hour   = Int(self / 3600);
            time.minute = Int((self % 3600) / 60);
            time.second = Int(self % 60);
            #if iOS8target
            let dateComponentsFormatter = NSDateComponentsFormatter()
            dateComponentsFormatter.unitsStyle = .Short
            result = dateComponentsFormatter.stringFromDateComponents(time)!;
            #else
            if #available(iOS 8.0, *) {
                let dateComponentsFormatter = NSDateComponentsFormatter()
                dateComponentsFormatter.unitsStyle = .Short
                result = dateComponentsFormatter.stringFromDateComponents(time)!;
            } else {
                if time.hour > 0 { result += "\(time.hour) hrs" }
                if time.minute > 0 { result += " \(time.minute) mins" }
                if time.second > 0 { result += " \(time.second) secs" }
                if result == "" { result = "0 sec" }
            }
            #endif
        }
        return result.trim();
    }
    
    var formatshort: String {
        var result = "0:00";
        if self < NSTimeInterval(Int32.max) {
            result = "";
            let time = NSDateComponents();
            time.hour   = Int(self / 3600);
            time.minute = Int((self % 3600) / 60);
            time.second = Int(self % 60);
            let formatter = NSNumberFormatter()
            formatter.paddingCharacter = "0"
            formatter.minimumIntegerDigits = 2
            formatter.maximumFractionDigits = 0
            let formatterFirst = NSNumberFormatter()
            formatterFirst.maximumFractionDigits = 0
            if time.hour > 0 {
                result = "\(formatterFirst.stringFromNumber(time.hour)!):\(formatter.stringFromNumber(time.minute)!):\(formatter.stringFromNumber(time.second)!)"
            } else {
                result = "\(formatterFirst.stringFromNumber(time.minute)!):\(formatter.stringFromNumber(time.second)!)"
            }
        }
        result = result.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ": "))
        return result
    }
}

extension CollectionType {
    func unique <T: Equatable> () -> [T] {
        var result = [T]()
        
        for item in self {
            if !result.contains(item as! T) {
                result.append(item as! T)
            }
        }
        
        return result
    }
}

extension CollectionType where Index == Int {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

extension Set {
    mutating func append(member: Element) {
        self.insert(member)
    }
    
    subscript (index: Int) -> Element? {
        if index < self.count && index > -1 {
            return self[self.startIndex.advancedBy(index)]
        }
        return nil
    }
}

extension UIColor {
    /**
    Returns a UIColor object from a Hexadecimal string with an adjustable alpha channel

    - parameter color: The 6 digit hexadecimal string representation of the string including the # or not
    - parameter alpha: The transparency, represented as a CGFloat Double between 0 and 1
    - returns: a UIColor, nil if the casting fails
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
    func withColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        let rect = CGRectMake(0, 0, self.size.width, self.size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func withPad(topLeft topLeft: CGPoint, bottomRight: CGPoint, scaleFactor: CGFloat = 0) -> UIImage {
        let newSize = CGSizeMake(self.size.width + (topLeft.x + bottomRight.x), self.size.height + (topLeft.y + bottomRight.y));
        UIGraphicsBeginImageContextWithOptions(newSize, false, scaleFactor);
        self.drawAtPoint(topLeft);
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    func withSize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.drawInRect(CGRect(origin: CGPointZero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    func squareImage() -> UIImage {
        let width = self.size.width
        let height = self.size.height
        let pad: CGPoint
        if self.size.width > self.size.height {
            pad = CGPoint(x: 0, y: (width - height) / 2)
        } else {
            pad = CGPoint(x: (height - width) / 2, y: 0)
        }
        return self.withPad(topLeft:pad, bottomRight: pad)
    }
    
    func scaleDownImage(maxSize: CGSize) -> UIImage {
        let height, width: CGFloat
        if self.size.width > self.size.height {
            width = maxSize.width
            height = (self.size.height / self.size.width) * width
        } else {
            height = maxSize.height
            width = (self.size.width / self.size.height) * height
        }
        return self.withSize(CGSize(width: width, height: height))
    }
    
}

extension UIApplication {
    func runInBackground(closure: () -> Void, expirationHandler: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let taskID: UIBackgroundTaskIdentifier
            if let expirationHandler = expirationHandler {
                taskID = self.beginBackgroundTaskWithExpirationHandler(expirationHandler)
            } else {
                taskID = self.beginBackgroundTaskWithExpirationHandler({ })
            }
            closure();
            self.endBackgroundTask(taskID)
        }
    }
}

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func sortedKeys(isOrderedBefore:(Key,Key) -> Bool) -> [Key] {
        var array = Array(self.keys)
        array.sortInPlace(isOrderedBefore)
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
        array.sortInPlace {
            let (_, lv) = $0
            let (_, rv) = $1
            return isOrderedBefore(lv, rv)
        }
        return array.map {
            let (k, _) = $0
            return k
        }
    }
}

extension NSDictionary {
    convenience init ? (json: String) {
        if let data = (try? NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: NSJSONReadingOptions.MutableContainers)) as? NSDictionary {
            self.init(dictionary: data)
        } else {
            self.init()
            return nil
        }
    }
    
    func formatJSON() -> String? {
        if let jsonData = try? NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions()) {
            let jsonStr = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
            return String(jsonStr ?? "")
        }
        return nil
    }
}

enum NSFileArrangeKind: CustomStringConvertible {
    case Name(Bool);
    case Kind(Bool);
    case DateModified(Bool);
    case DateCreated(Bool);
    case Size(Bool);
    
    static var allItems: [NSFileArrangeKind] {
        return [.Name(true), .Kind(true), .DateModified(true),
            .DateCreated(true), .Size(true)]
    }
    
    static var defaultValue = NSFileArrangeKind.Name(true)
    
    var description: String {
        switch self {
        case Name(let ascending): return "Name" + (ascending ? "" : " ⬇️")
        case Kind(let ascending):return "Kind" + (ascending ? "" : " ⬇️")
        case DateModified(let ascending): return "Date Modified" + (ascending ? "" : " ⬇️")
        case DateCreated(let ascending): return "Date Created" + (ascending ? "" : " ⬇️")
        case Size(let ascending): return "Size" + (ascending ? "" : " ⬇️")
        }
    }
    
    init(string: String, ascending: Bool = true) {
        switch string {
        case "Name": self = .Name(ascending)
        case "Kind": self = .Kind(ascending)
        case "Date Modified": self = .DateModified(ascending)
        case "Date Created": self = .DateCreated(ascending)
        case "Size": self = .Size(ascending)
        default: self = .Name(ascending)
        }
    }
}

extension NSFileManager {
    var diskInfo: (total: Int64, free: Int64) {
        let dict = (try? attributesOfFileSystemForPath(documentsFolder)) as NSDictionary?;
        let totalSize = dict?.objectForKey(NSFileSystemSize)?.longLongValue ?? 0;
        let freeSize = dict?.objectForKey(NSFileSystemFreeSize)?.longLongValue ?? 0;
        return (totalSize, freeSize);
    }
    
    func pathOf(directoryType: NSSearchPathDirectory) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(directoryType, NSSearchPathDomainMask.UserDomainMask, true);
        return paths[0] 
    }
    
    var documentsFolder: String {
        return pathOf(NSSearchPathDirectory.DocumentDirectory)
    }
    
    var cacheFolder: String {
        return pathOf(NSSearchPathDirectory.CachesDirectory)
    }
    
    var libraryFolder: String {
        return pathOf(NSSearchPathDirectory.LibraryDirectory)
    }
    
    var tempFolder: String {
        return NSTemporaryDirectory()
    }
    
    func concatFiles(files: [String], toFile outputFile: String, removeSourceFiles: Bool, appendingMode: Bool = false) {
        let chunkMaxLen = 5_000_000
        if files.count == 0 {
            return
        }
        if !appendingMode {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(outputFile)
            } catch _ {
            }
        }
        if !NSFileManager.defaultManager().fileExistsAtPath(outputFile) {
            NSFileManager.defaultManager().createFileAtPath(outputFile, contents: nil, attributes: [NSFileProtectionKey: NSFileProtectionNone])
        }
        if let outputFileHandle = NSFileHandle(forWritingAtPath: outputFile) {
            if appendingMode {
                outputFileHandle.seekToEndOfFile()
            } else {
                outputFileHandle.seekToFileOffset(0)
            }
            for file in files {
                if let fileHandle = NSFileHandle(forReadingAtPath: file) {
                    fileHandle.seekToFileOffset(0)
                    autoreleasepool {
                        var data = fileHandle.readDataOfLength(chunkMaxLen)
                        while data.length > 0 {
                            outputFileHandle.writeData(data)
                            data = fileHandle.readDataOfLength(chunkMaxLen)
                        }
                    }
                    fileHandle.closeFile()
                    if removeSourceFiles {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(file)
                        } catch _ {
                        }
                    }
                }
            }
            outputFileHandle.closeFile()
        }
    }
    
    func listFiles(path: String, withFullPath fullpath: Bool = false, withExtension ext: String? = nil) -> [String] {
        var fileListAct = (try? contentsOfDirectoryAtPath(path)) ?? [];
        
        if fullpath {
            fileListAct = fileListAct.map { path.fileURL.URLByAppendingPathComponent($0).path ?? path }
        }
        
        if let ext = ext {
            return fileListAct.filter { $0.pathExtension == ext }
        }
        
        return fileListAct
    }
    
    func iterateDirectory(path: String, deep: Bool, updateHandler: ((folders: Int, files: Int, totalsize: Int64) -> Void)? = nil) -> (folders: Int, files: Int, totalsize: Int64) {
        var folders = 0
        var files = 0
        var totalsize: Int64 = 0
        let pathURL = NSURL(fileURLWithPath: path)
        let keys = [NSURLIsDirectoryKey, NSURLFileSizeKey]
        let enumOpt = NSDirectoryEnumerationOptions()
        
        let iterateClosure = { (fileURL: NSURL) -> Void in
            var isdirv, sizev: AnyObject?
            do {
                try fileURL.getResourceValue(&isdirv, forKey: NSURLIsDirectoryKey)
            } catch _ {
            }
            do {
                try fileURL.getResourceValue(&sizev, forKey: NSURLFileSizeKey)
            } catch _ {
            }
            let isdir = isdirv?.boolValue ?? false
            let size = sizev?.longLongValue ?? 0
            isdir ? folders++ : files++
            totalsize += size
            dispatch_async(dispatch_get_main_queue(), {
                updateHandler?(folders: folders, files: files, totalsize: totalsize)
                return
            })
        }
        
        if deep {
            let filesList = enumeratorAtURL(pathURL, includingPropertiesForKeys: keys, options: enumOpt, errorHandler: nil)
            while let fileURL = filesList?.nextObject() as? NSURL {
                iterateClosure(fileURL)
            }
        } else {
            let filesList = try? contentsOfDirectoryAtURL(pathURL, includingPropertiesForKeys: keys, options: enumOpt)
            for fileURL in (filesList ?? []) {
                iterateClosure(fileURL)
            }
        }
        
        return (folders, files, totalsize)
    }
    
    func countFilesOf(path: String, deep: Bool, updateHandler: ((Int) -> Void)? = nil) -> Int {
        return iterateDirectory(path, deep: deep, updateHandler: { (_, files, _) -> Void in
            updateHandler?(files)
        }).files
    }
    
    func countFoldersOf(path: String, deep: Bool, updateHandler: ((Int) -> Void)? = nil) -> Int {
        return iterateDirectory(path, deep: deep, updateHandler: { (folders, _, _) -> Void in
            updateHandler?(folders)
        }).folders
    }
    
    func directorySizeOf(path: String, deep: Bool, updateHandler: ((Int64) -> Void)? = nil) -> Int64 {
        return iterateDirectory(path, deep: deep, updateHandler: { (_, _, totalsize) -> Void in
            updateHandler?(totalsize)
        }).totalsize
    }
    
    func sortFilesList(fileList: [NSURL], sortBy: NSFileArrangeKind, directoryFirst: Bool = false) -> [NSURL] {
        return fileList.sort { (file1: NSURL, file2: NSURL) -> Bool in
            let fileAtt1 = file1.fileURLAttributes
            let fileAtt2 = file2.fileURLAttributes
            
            let comp: Bool
            if directoryFirst {
                if fileAtt1.isDir && !fileAtt2.isDir {
                    return true
                }
                if !fileAtt1.isDir && fileAtt2.isDir {
                    return false
                }
            }
            switch sortBy {
            case .Name(let ascending):
                comp =  fileAtt1.name.localizedStandardCompare(fileAtt2.name)  == (ascending ? .OrderedAscending : .OrderedDescending)
            case .Kind(let ascending):
                let kind1 = fileAtt1.isDir ? "folder" : file1.pathExtension ?? ""
                let kind2 = fileAtt2.isDir ? "folder" : file2.pathExtension ?? ""
                comp = kind1.localizedCaseInsensitiveCompare(kind2) == (ascending ? .OrderedAscending : .OrderedDescending)
            case .DateModified(let ascending):
                comp = ascending ? fileAtt1.dateModified < fileAtt2.dateModified : fileAtt1.dateModified > fileAtt2.dateModified
            case .DateCreated(let ascending):
                comp = ascending ? fileAtt1.dateCreation < fileAtt2.dateCreation : fileAtt1.dateCreation > fileAtt2.dateCreation
            case .Size(let ascending):
                let realsize1 = fileAtt1.isDir ? self.directorySizeOf(file1.path!, deep: true) : fileAtt1.size
                let realsize2 = fileAtt2.isDir ? self.directorySizeOf(file2.path!, deep: true) : fileAtt2.size
                comp = ascending ? realsize1 < realsize2 : realsize1 > realsize2
            }
            return comp
        }
    }
}
