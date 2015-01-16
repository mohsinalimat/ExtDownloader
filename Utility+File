//
//  Utility.swift
//  ExtDownloader
//
//  Created by Amir Abbas on 93/8/20.
//  Copyright (c) 1393 Mousavian. All rights reserved.
//

import UIKit
import MobileCoreServices

class Utility: NSObject {

    struct File {

    static func extensionInfo(file: String) -> (mime: String, uti: String) {
        if File.isDirectory(file) {
            return("inode/directory", "public.directory")
        } else {
            let fileExt = file.pathExtension;
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil).takeUnretainedValue();
            let mimeu = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
            let mime = mimeu == nil ? "unknown" : mimeu.takeUnretainedValue();
            return (mime, uti);
        }
    }

    static private func getPath(directoryType: NSSearchPathDirectory) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(directoryType, NSSearchPathDomainMask.UserDomainMask, true);
        return paths[0] as String
    }

    static var appFolders: (documents: String, cache: String, library: String, tmp: String, shared: String) {
        return (getPath(NSSearchPathDirectory.DocumentDirectory),
            getPath(NSSearchPathDirectory.CachesDirectory),
            getPath(NSSearchPathDirectory.LibraryDirectory),
            NSTemporaryDirectory(),
            NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(appGroup)!.absoluteString!)
    }

    static func listFiles(path: String, withFullPath fullpath: Bool = false, withExtension ext: String? = nil) -> [String] {
        var fileListAct = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) as [String];
        
        if ext != nil {
            var tmpFileListAct: [String] = [];
            tmpFileListAct.reserveCapacity(fileListAct.count)
            for file in fileListAct {
                if file.pathExtension == ext! {
                    tmpFileListAct.append(file);
                }
            }
            fileListAct = tmpFileListAct;
        }

        if fullpath {
            var fileListFull = [String]()
            fileListFull.reserveCapacity(fileListAct.count)
            for file in fileListAct {
                fileListFull.append(path.stringByAppendingPathComponent(file));
            }
            return fileListFull
        }
        return fileListAct
    }

    static func fileInfo(fullPath: String) -> (size: Int64, creationDate: NSDate, modificationDate: NSDate) {
        let fileAttr = NSDictionary(dictionary: NSFileManager.defaultManager().attributesOfItemAtPath(fullPath, error: nil)!);
        return (Int64(fileAttr.fileSize()),
            fileAttr.fileCreationDate()!,
            fileAttr.fileModificationDate()!)
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

    static func isDirectory(filePath: String) -> Bool {
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
                if  dict?.indexForKey(NSURLIsExcludedFromBackupKey) != nil && dict![NSURLIsExcludedFromBackupKey] is Bool {
                    return dict![NSURLIsExcludedFromBackupKey] as Bool
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
}
