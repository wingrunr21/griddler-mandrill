## 1.0.3 (master)
* Replace `nil` for email text/html values with empty strings. #10 via [calleerlandsson](https://github.com/calleerlandsson)

## 1.0.2
* Replace slashes in filenames with underscores for temp file creation. #5 and
  #6 via [ssidelnikov](https://github.com/ssidelnikov)
* Only process inbound events. #9 via [mgauthier-joist](https://github.com/mgauthier-joist)
* Support BCC attribute

## 1.0.1
* Respect Mandrill's base64 flag to determine whether text attachments should be
  base64 decoded. #4 via [bdmac](https://github.com/bdmac)

## 1.0.0
* Initial extraction of the Mandrill adapter from griddler
