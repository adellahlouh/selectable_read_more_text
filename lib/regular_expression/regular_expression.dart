

class RegularExpression {

  /// Validate link
  RegExp get linkReg =>  RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+') ;

  /// Validate email
  RegExp get emailReg => RegExp(
  r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  /// This regular expression is used to validate phone numbers with digits between 10 and 14.
  /// For example:
  /// if the number has a country code of +962 or 00962,
  /// Or if it is in the format
  /// 0712345678, similar to Jordan phone numbers.
  /// or 07123456789, similar to Iraq phone numbers.
  RegExp get phoneNumberReg =>  RegExp(r'(^(?:[+0]9)?[0-9]{10,14}$)') ;


}
