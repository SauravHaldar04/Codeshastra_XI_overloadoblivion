// ignore_for_file: public_member_api_docs, sort_constructors_first
class User {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final bool emailVerified;

  User({
    required this.emailVerified,
    required this.uid,
    required this.middleName,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  User.empty()
      : emailVerified = false,
        uid = '',
        email = '',
        firstName = '',
        middleName = '',
        lastName = '';

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'emailVerified': emailVerified,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String,
      lastName: json['lastName'] as String,
      emailVerified: json['emailVerified'] as bool,
    );
  }
}
