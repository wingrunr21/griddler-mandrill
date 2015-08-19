## master

## 1.1.3
* Protect against SPF spoofing. #22 via [arunthampi](https://github.com/arunthampi)

## 1.1.2
* Use Mandrill's `email` attribute to populate bcc if to and cc don't contain it. #19 and #20 via [Uelb](https://github.com/Uelb)

## 1.1.1
* Pin minimum Griddler version to >= 1.2.1 to resolve #18

## 1.1.0
* Allow email headers to be accessed. #12, #13, #14, and #17
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
