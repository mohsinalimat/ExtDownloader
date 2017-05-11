# ExtDownloader 5 Frequently Asked Questions

### 1. What kind of files this can download?
**A.** This app can download any kind of file, in any size, without limitation. In Lite version it's restricted to one download every 2 hours. Opening and previewing are limited to types which iOS supports internally.

### 2. What kind of archives and compressed format are supported?
**A.** Zip, 7z, rar and tar.gz are supported, which are 95% archive files available on internet. But password-protected and multi-parted files are not supported yet. Please consider 7z files size are limited to memory of your device and it's slow to extract it in comparison to other files.

### 3. What happens to download progress if I exit app?
**A.** Active download tasks will continue, until you force close the app. Please don't force close (Double tap Home and swipe up) as it stops normal functionality of Safari Extenstion.

### 4. Which sources are supported by this app?
**A.** It’s better to say which aren’t, In general these types of websites are not supported to download:
* Sites which need complicated or cookie-based authentication like email services  (e.g. Gmail). Even desktop download managers are not able to fetch files from these sources. The best solution for these kind of sources is using native app for these services
* Upload services which offer indirect links on free services e.g. RapidShare or Upload.to. You should either obtain premium services or use desktop browser to download files from these services
* Services which offer copyrighted materials like Youtube and SoundCloud won’t allow you to download contents directly due to copyrighted material.
* JavaScript embeded links: some websites trigger javascript functions to refer to file links. These types of links are not standardized and not supported on app. But if you consider downloading contents from a popular website which is not protected by copyright law, contact us to add support for that website.
* Downloading from torrent or similar P2P services are not supported due to copyrighted material.

### 5. Why my download task restarted from the begining after I pausing task or exiting app?
**A.** App will continue download after termination or exit if these conditions are met:
* Protocol of file transmission is HTTP
* Server supports resuming which is indicated in download details page
* File has not been changed during download on server
* And the most important thing is that operating system should conserve temporary downloading data. App saves it in temporary folder in which operating system may erase its contents in case of insufficient free storage remaining.

If one of these conditions are not met, app will restart download from begining.

### 6. I downloaded a file but it's size is not appropriate and doesn't have contents which I intended.
**A.** Sometimes links are not really pointing to file itself, but referring to another webpage which may include link to file itself or not, or even may refer to an error page!

### 7. I need a feature which is not available in app. What can I do?
**A.** Feel free to contact us on extdownloader@gmail.com or [@edmapplication on Twitter](http://twitter.com/edmapplication)

###8. My question is not listed. how can I add it?
**A.** Simply create an [issue on github](https://github.com/amosavian/ExtDownloader/issues) or [contact us on website](https://edmapplication.com). We will add your question.
