//
//  Utility.swift
//  ExtDownloader
//
//  Created by Amir Abbas on 93/8/20.
//  Copyright (c) 1393 Mousavian. All rights reserved.
//

import Foundation
import MobileCoreServices

enum ProxySettings {
    case HTTP(server: String, port: Int)
    case HTTPS(server: String, port: Int)
    case SOCKS(server: String, port: Int)
}

class Utility: NSObject {
    
    // MARK: - General functions
    struct General {
    static func generateUUID() -> String {
    var str = NSProcessInfo.processInfo().globallyUniqueString;
    str = str.substringWithRange(Range<String.Index>(start: str.startIndex, end: advance(str.startIndex, 36)))
    return str;
    }

    private static func formatInterval(timeInteval: NSTimeInterval) -> String { // Added to class extensions
        var result = "Calculating...";
        if timeInteval < NSTimeInterval(Int32.max) {
            result = "";
            let time = NSDateComponents();
            time.hour   = Int(timeInteval / 3600);
            time.minute = Int((timeInteval % 3600) / 60);
            time.second = Int(timeInteval % 60);
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
    static func logtoFile(text: String) {
        let filePath = "/Users/amirabbas/Desktop/dl.txt"
        if let file = NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding, error: nil) as? String {
            "\(file)\(text)\n".writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        } else {
            "\(text)\n".writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    }
    
    // MARK: - File operation functions
    struct File {
    static func isWebPage(Extension ext: String) -> Bool {
        switch ext.lowercaseString {
        case "css": return true;
        case "htm", "html", "xhtml", "jhtml": return true;
        case "js": return true;
        case "php", "phtml", "php4", "php3", "php5", "phps": return true;
        case "py", "pl", "cfm": return true;
        case "asp", "aspx", "jsp", "jspx": return true;
        case "cgi", "woa": return true;
        default: return false;
        }
    }

    static func utiForFiles() -> (unknown: [String], video: [String], audio: [String], image: [String], documents: [String], text: [String], archive : [String]) {
        let unknown = ["public.calendar-event", "public.database", "public.executable", "public.data", "public.content", "public.item"];
        
        let video = ["public.video", "public.movie", "public.3gpp2", "public.3gpp", "public.mpeg", "com.apple.quicktime-movie", "public.mpeg-4"];
        
        let audio = ["public.audio", "public.mp3", "public.mpeg-4-audio", "com.apple.protected-​mpeg-4-audio", "public.aifc-audio", "com.apple.coreaudio-​format", "public.aiff-audio", "com.microsoft.waveform-​audio"];
        
        let image = ["public.image", "com.compuserve.gif", "public.png", "public.tiff", "public.jpeg", "com.microsoft.ico", "com.apple.icns", "com.microsoft.bmp"];
        
        let documents = ["com.apple.keynote.key", "com.apple.iwork.keynote.key", "com.apple.iwork.keynote.kth", "com.apple.numbers.numbers", "com.apple.iwork.numbers.numbers", "om.apple.page.pages", "com.apple.iwork.pages.pages", "org.oasis.opendocument.spreadsheet", "org.oasis.opendocument.presentation", "org.oasis.opendocument.text", "com.microsoft.powerpoint.​ppt", "org.openxmlformats.presentationml.presentation", "com.microsoft.excel.xls", "org.openxmlformats.spreadsheetml.sheet", "com.microsoft.word.doc", "com.microsoft.word.wordml", "org.openxmlformats.wordprocessingml.document", "com.adobe.pdf"];
        
        let text = ["public.text", "public.plain-text", "public.utf8-plain-text", "public.utf16-external-plain-​text", "public.utf16-plain-text", "com.apple.traditional-mac-​plain-text", "public.xml", "public.html", "public.xhtml", "public.rtf", "com.apple.rtfd", "com.apple.flat-rtfd", "public.source-code", "public.c-source", "public.objective-c-source", "public.c-plus-plus-source", "public.objective-c-plus-​plus-source", "public.c-header", "public.c-plus-plus-header", "com.sun.java-source", "public.script", "public.shell-script"];
        
        let archive = ["public.archive", "public.zip-archive", "com.pkware.zip-archive", "com.pkware.zipx-archive", "com.rarlab.rar-archive", "org.7-zip.7-zip-archive"];
        
        return (unknown, video, audio, image, documents, text, archive)
    }
        
    static func utiForAllFiles() -> [String] {
       return ["public.calendar-event", "public.database", "public.executable", "public.data", "public.content", "public.item", "public.video", "public.movie", "public.3gpp2", "public.3gpp", "public.mpeg", "com.apple.quicktime-movie", "public.mpeg-4", "public.audio", "public.mp3", "public.mpeg-4-audio", "com.apple.protected-​mpeg-4-audio", "public.aifc-audio", "com.apple.coreaudio-​format", "public.aiff-audio", "com.microsoft.waveform-​audio", "public.image", "com.compuserve.gif", "public.png", "public.tiff", "public.jpeg", "com.microsoft.ico", "com.apple.icns", "com.microsoft.bmp", "com.apple.keynote.key", "com.apple.iwork.keynote.key", "com.apple.iwork.keynote.kth", "com.apple.numbers.numbers", "com.apple.iwork.numbers.numbers", "om.apple.page.pages", "com.apple.iwork.pages.pages", "org.oasis.opendocument.spreadsheet", "org.oasis.opendocument.presentation", "org.oasis.opendocument.text", "com.microsoft.powerpoint.​ppt", "org.openxmlformats.presentationml.presentation", "com.microsoft.excel.xls", "org.openxmlformats.spreadsheetml.sheet", "com.microsoft.word.doc", "com.microsoft.word.wordml", "org.openxmlformats.wordprocessingml.document", "com.adobe.pdf", "public.text", "public.plain-text", "public.utf8-plain-text", "public.utf16-external-plain-​text", "public.utf16-plain-text", "com.apple.traditional-mac-​plain-text", "public.xml", "public.html", "public.xhtml", "public.rtf", "com.apple.rtfd", "com.apple.flat-rtfd", "public.source-code", "public.c-source", "public.objective-c-source", "public.c-plus-plus-source", "public.objective-c-plus-​plus-source", "public.c-header", "public.c-plus-plus-header", "com.sun.java-source", "public.script", "public.shell-script", "public.archive", "public.zip-archive", "com.pkware.zip-archive", "com.pkware.zipx-archive", "com.rarlab.rar-archive", "org.7-zip.7-zip-archive"];
    }

    static private func getPath(directoryType: NSSearchPathDirectory) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(directoryType, NSSearchPathDomainMask.UserDomainMask, true);
        return paths[0] as! String
    }

    static var appFolders: (documents: String, cache: String, library: String, tmp: String, shared: String) {
        return (getPath(NSSearchPathDirectory.DocumentDirectory),
            getPath(NSSearchPathDirectory.CachesDirectory),
            getPath(NSSearchPathDirectory.LibraryDirectory),
            NSTemporaryDirectory(), "")
//            NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(appGroup)!.absoluteString!)
    }

    static func listFiles(path: String, withFullPath fullpath: Bool = false, sharedContainer: Bool = false, withExtension ext: String? = nil) -> [String] {
        var fileListAct = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) as! [String];
        
        if fullpath {
            fileListAct = fileListAct.map { path.stringByAppendingPathComponent($0) }
        }
        
        if let ext = ext {
            return fileListAct.filter { $0.pathExtension == ext }
        }

        return fileListAct
    }

    static func fileInfo(fullPath: String) -> (size: Int64, creationDate: NSDate, modificationDate: NSDate) {
        if NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
        let fileAttr = NSDictionary(dictionary: NSFileManager.defaultManager().attributesOfItemAtPath(fullPath, error: nil)!);
        return (Int64(fileAttr.fileSize()),
            fileAttr.fileCreationDate()!,
            fileAttr.fileModificationDate()!)
        } else {
            return (0, NSDate(), NSDate())
        }
    }

    static var diskInfo: (total: Int64, free: Int64) {
        var error: NSError?;
        let dict = NSFileManager.defaultManager().attributesOfFileSystemForPath(appFolders.documents, error: nil) as NSDictionary?;
        let totalSize = dict?.objectForKey(NSFileSystemSize)?.longLongValue ?? 0;
        let freeSize = dict?.objectForKey(NSFileSystemFreeSize)?.longLongValue ?? 0;
        return (totalSize, freeSize);
    }

    static func uniqueFileName(filePath: String) -> String {
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            var unique = false
            var i = 2
            var newName = filePath
            while !unique {
                newName = (filePath.stringByDeletingPathExtension + " \(i)").stringByAppendingPathExtension(filePath.pathExtension)!;
                newName = newName.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
                unique = !NSFileManager.defaultManager().fileExistsAtPath(newName);
                i++;
            }
            return newName
        } else {
            return filePath
        }
    }
        
    static func concatFiles(files: [String], outputFile: String) {
        let fpoutput = fopen(NSString(string: outputFile).UTF8String, "a".UTF8String)
        for file in files {
            var ch: Int32 = 0;
            let fp = fopen(NSString(string: file).UTF8String, "r".UTF8String);
            do {
                ch = getc(fp);
                if ch != EOF {
                    putc(ch, fpoutput)
                }
            } while ch != EOF
            fclose(fp)
        }
        fclose(fpoutput)
    }

    private static func isDirectory(filePath: String) -> Bool { // Added to class extensions
        var isDir: ObjCBool = false;
        NSFileManager.defaultManager().fileExistsAtPath(filePath, isDirectory: &isDir);
        return isDir.boolValue;
    }

    static func skipBackupAttributeToItemAtURL(fileUrl : NSURL, skip: Bool? = nil) -> Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(fileUrl.path!) {
            if skip != nil {
                if isDirectory(fileUrl.path!) {
                    for file in listFiles(fileUrl.path!, withFullPath: true) {
                        skipBackupAttributeToItemAtURL(NSURL(fileURLWithPath: file)!, skip: skip);
                    }
                }
                return fileUrl.setResourceValue(NSNumber(bool: skip!), forKey: NSURLIsExcludedFromBackupKey, error: nil)
            } else {
                let dict = fileUrl.resourceValuesForKeys([NSURLIsExcludedFromBackupKey], error: nil)
                if  let key: AnyObject = dict?[NSURLIsExcludedFromBackupKey] {
                    return key.boolValue
                }
                return false
            }
        }
        return false
    }
        
    static func directoryFilesCount(path: String, updateHandler: ((Int) -> Void)?) -> Int {
        var count = 0
        for file in Utility.File.listFiles(path, withFullPath: true) {
            if Utility.File.isDirectory(file) {
                count += directoryFilesCount(file, updateHandler: nil)
            } else {
                count++
            }
            dispatch_async(dispatch_get_main_queue(), {
                updateHandler?(count)
                return
            })
        }
        return count
    }
        
    static func directoriesCount(path: String, updateHandler: ((Int) -> Void)?) -> Int {
        var count = 0
        for file in Utility.File.listFiles(path, withFullPath: true) {
            if Utility.File.isDirectory(file) {
                count++;
                count += directoriesCount(file, updateHandler: nil)
            }
            dispatch_async(dispatch_get_main_queue(), {
                updateHandler?(count)
                return
            })
        }
        return count
    }
        
    static func directorySize(path: String, updateHandler: ((Int64) -> Void)?) -> Int64 {
        var size: Int64 = 0
        if !isDirectory(path) {
            return fileInfo(path).size
        }
        for file in Utility.File.listFiles(path, withFullPath: true) {
            if Utility.File.isDirectory(file) {
                size += directorySize(file, updateHandler: nil)
            } else {
                size += File.fileInfo(file).size;
            }
            dispatch_async(dispatch_get_main_queue(), {
                updateHandler?(size)
                return
            })
        }
        return size
    }
        
    static func clearTempFiles() {
        let tmpFiles = listFiles(appFolders.tmp, withFullPath: true);
        for tmpFile in tmpFiles {
            NSFileManager.defaultManager().removeItemAtPath(tmpFile, error: nil)
        }
    }
    }
    

    
    // MARK: - Network functions
    struct Net {
    static func isValidResumeData(data: NSData?) -> Bool {
        if data == nil {
            return false;
        }
        
        if let data = data where data.length < 1 {
            return false;
        }
    
        var error: NSError?;
        let resumeDictionary = NSPropertyListSerialization.propertyListWithData(data!, options: 0, format: nil, error: &error) as? NSDictionary;

        if (resumeDictionary == nil || error != nil) {
            return false
        }
    
        let localFilePath = resumeDictionary!.objectForKey("NSURLSessionResumeInfoLocalPath") as? String;

        if (localFilePath == nil) {
            return false
        }
        
        return true // NSFileManager.defaultManager().fileExistsAtPath(localFilePath!);
    }

    private static func supportsResume(url: NSURL) -> Bool { // Added to class extensions
        let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
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

    static func proxyDictionary(proxies: ProxySettings...) -> [String: AnyObject] {
        var proxydic: [String: AnyObject] = [ : ]
        var nserver, hostParam, portParam: String;
        var nport: Int;
        for proxy in proxies {
            switch proxy {
            case let .HTTP(server, port):
                hostParam = kCFStreamPropertyHTTPProxyHost as String;
                portParam = kCFStreamPropertyHTTPProxyPort as String;
                nserver = server;
                nport = port != 0 ? port : 80;
            case let .HTTPS(server, port):
                hostParam = kCFStreamPropertyHTTPSProxyHost as String;
                portParam = kCFStreamPropertyHTTPSProxyPort as String;
                nserver = server;
                nport = port != 0 ? port : 443;
            case let .SOCKS(server, port):
                hostParam = kCFStreamPropertySOCKSProxyHost as String;
                portParam = kCFStreamPropertySOCKSProxyPort as String;
                nserver = server;
                nport = port != 0 ? port : 1080;
            }
            if !nserver.isEmpty {
                proxydic[hostParam] = nserver;
                proxydic[portParam] = String(nport);
            }
        }
        return proxydic;
    }

    static func checkProxy(proxy: ProxySettings, timeout: NSTimeInterval = 5.0) -> Bool {
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        session.configuration.connectionProxyDictionary = proxyDictionary(proxy);
        let request = NSMutableURLRequest(URL: NSURL(string: "http://www.google.com")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout);
        request.HTTPMethod = "HEAD";
        var responseOK: Bool? = nil;
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (_, response, _) -> Void in
            if (response != nil) && ((response! as! NSHTTPURLResponse).statusCode == 200) {
                responseOK = true;
            } else {
                responseOK = false;
            }
        })
        let starttime = NSDate();
        while responseOK == nil {
            if responseOK != nil || abs(starttime.timeIntervalSinceNow) > timeout {
                responseOK = false;
                break
            }
        }
        session.invalidateAndCancel();
        return responseOK!
    }

    static func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }

    static func JSONParseArray(jsonString: String) -> [AnyObject] {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            if let array = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)  as? [AnyObject] {
                return array
            }
        }
        return [AnyObject]()
    }
    }
}
