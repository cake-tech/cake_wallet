class CaptchaResponse {
  int success;
  String challenge;
  String gt;
  bool newCaptcha;

  CaptchaResponse({
    this.success,
    this.challenge,
    this.gt,
    this.newCaptcha,
  });

  CaptchaResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'] as int;
    challenge = json['challenge'] as String;
    gt = json['gt'] as String;
    newCaptcha = json['new_captcha'] as bool;
  }
}
