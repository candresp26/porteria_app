/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the User type in your schema. */
class User extends amplify_core.Model {
  static const classType = const _UserModelType();
  final String id;
  final String? _username;
  final bool? _isFirstLogin;
  final Role? _role;
  final String? _name;
  final bool? _isActive;
  final String? _email;
  final String? _tower;
  final String? _unit;
  final bool? _isDevice;
  final Apartment? _apartment;
  final List<Package>? _packages;
  final String? _pinCode;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserModelIdentifier get modelIdentifier {
      return UserModelIdentifier(
        id: id
      );
  }
  
  String get username {
    try {
      return _username!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool get isFirstLogin {
    try {
      return _isFirstLogin!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  Role get role {
    try {
      return _role!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get name {
    return _name;
  }
  
  bool get isActive {
    try {
      return _isActive!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get email {
    return _email;
  }
  
  String? get tower {
    return _tower;
  }
  
  String? get unit {
    return _unit;
  }
  
  bool? get isDevice {
    return _isDevice;
  }
  
  Apartment? get apartment {
    return _apartment;
  }
  
  List<Package>? get packages {
    return _packages;
  }
  
  String? get pinCode {
    return _pinCode;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const User._internal({required this.id, required username, required isFirstLogin, required role, name, required isActive, email, tower, unit, isDevice, apartment, packages, pinCode, createdAt, updatedAt}): _username = username, _isFirstLogin = isFirstLogin, _role = role, _name = name, _isActive = isActive, _email = email, _tower = tower, _unit = unit, _isDevice = isDevice, _apartment = apartment, _packages = packages, _pinCode = pinCode, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory User({String? id, required String username, required bool isFirstLogin, required Role role, String? name, required bool isActive, String? email, String? tower, String? unit, bool? isDevice, Apartment? apartment, List<Package>? packages, String? pinCode}) {
    return User._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      username: username,
      isFirstLogin: isFirstLogin,
      role: role,
      name: name,
      isActive: isActive,
      email: email,
      tower: tower,
      unit: unit,
      isDevice: isDevice,
      apartment: apartment,
      packages: packages != null ? List<Package>.unmodifiable(packages) : packages,
      pinCode: pinCode);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
      id == other.id &&
      _username == other._username &&
      _isFirstLogin == other._isFirstLogin &&
      _role == other._role &&
      _name == other._name &&
      _isActive == other._isActive &&
      _email == other._email &&
      _tower == other._tower &&
      _unit == other._unit &&
      _isDevice == other._isDevice &&
      _apartment == other._apartment &&
      DeepCollectionEquality().equals(_packages, other._packages) &&
      _pinCode == other._pinCode;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("User {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("username=" + "$_username" + ", ");
    buffer.write("isFirstLogin=" + (_isFirstLogin != null ? _isFirstLogin!.toString() : "null") + ", ");
    buffer.write("role=" + (_role != null ? amplify_core.enumToString(_role)! : "null") + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("isActive=" + (_isActive != null ? _isActive!.toString() : "null") + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("tower=" + "$_tower" + ", ");
    buffer.write("unit=" + "$_unit" + ", ");
    buffer.write("isDevice=" + (_isDevice != null ? _isDevice!.toString() : "null") + ", ");
    buffer.write("apartment=" + (_apartment != null ? _apartment!.toString() : "null") + ", ");
    buffer.write("pinCode=" + "$_pinCode" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  User copyWith({String? username, bool? isFirstLogin, Role? role, String? name, bool? isActive, String? email, String? tower, String? unit, bool? isDevice, Apartment? apartment, List<Package>? packages, String? pinCode}) {
    return User._internal(
      id: id,
      username: username ?? this.username,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      role: role ?? this.role,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      tower: tower ?? this.tower,
      unit: unit ?? this.unit,
      isDevice: isDevice ?? this.isDevice,
      apartment: apartment ?? this.apartment,
      packages: packages ?? this.packages,
      pinCode: pinCode ?? this.pinCode);
  }
  
  User copyWithModelFieldValues({
    ModelFieldValue<String>? username,
    ModelFieldValue<bool>? isFirstLogin,
    ModelFieldValue<Role>? role,
    ModelFieldValue<String?>? name,
    ModelFieldValue<bool>? isActive,
    ModelFieldValue<String?>? email,
    ModelFieldValue<String?>? tower,
    ModelFieldValue<String?>? unit,
    ModelFieldValue<bool?>? isDevice,
    ModelFieldValue<Apartment?>? apartment,
    ModelFieldValue<List<Package>?>? packages,
    ModelFieldValue<String?>? pinCode
  }) {
    return User._internal(
      id: id,
      username: username == null ? this.username : username.value,
      isFirstLogin: isFirstLogin == null ? this.isFirstLogin : isFirstLogin.value,
      role: role == null ? this.role : role.value,
      name: name == null ? this.name : name.value,
      isActive: isActive == null ? this.isActive : isActive.value,
      email: email == null ? this.email : email.value,
      tower: tower == null ? this.tower : tower.value,
      unit: unit == null ? this.unit : unit.value,
      isDevice: isDevice == null ? this.isDevice : isDevice.value,
      apartment: apartment == null ? this.apartment : apartment.value,
      packages: packages == null ? this.packages : packages.value,
      pinCode: pinCode == null ? this.pinCode : pinCode.value
    );
  }
  
  User.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _username = json['username'],
      _isFirstLogin = json['isFirstLogin'],
      _role = amplify_core.enumFromString<Role>(json['role'], Role.values),
      _name = json['name'],
      _isActive = json['isActive'],
      _email = json['email'],
      _tower = json['tower'],
      _unit = json['unit'],
      _isDevice = json['isDevice'],
      _apartment = json['apartment'] != null
        ? json['apartment']['serializedData'] != null
          ? Apartment.fromJson(new Map<String, dynamic>.from(json['apartment']['serializedData']))
          : Apartment.fromJson(new Map<String, dynamic>.from(json['apartment']))
        : null,
      _packages = json['packages']  is Map
        ? (json['packages']['items'] is List
          ? (json['packages']['items'] as List)
              .where((e) => e != null)
              .map((e) => Package.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['packages'] is List
          ? (json['packages'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Package.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _pinCode = json['pinCode'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'username': _username, 'isFirstLogin': _isFirstLogin, 'role': amplify_core.enumToString(_role), 'name': _name, 'isActive': _isActive, 'email': _email, 'tower': _tower, 'unit': _unit, 'isDevice': _isDevice, 'apartment': _apartment?.toJson(), 'packages': _packages?.map((Package? e) => e?.toJson()).toList(), 'pinCode': _pinCode, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'username': _username,
    'isFirstLogin': _isFirstLogin,
    'role': _role,
    'name': _name,
    'isActive': _isActive,
    'email': _email,
    'tower': _tower,
    'unit': _unit,
    'isDevice': _isDevice,
    'apartment': _apartment,
    'packages': _packages,
    'pinCode': _pinCode,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERNAME = amplify_core.QueryField(fieldName: "username");
  static final ISFIRSTLOGIN = amplify_core.QueryField(fieldName: "isFirstLogin");
  static final ROLE = amplify_core.QueryField(fieldName: "role");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final ISACTIVE = amplify_core.QueryField(fieldName: "isActive");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final TOWER = amplify_core.QueryField(fieldName: "tower");
  static final UNIT = amplify_core.QueryField(fieldName: "unit");
  static final ISDEVICE = amplify_core.QueryField(fieldName: "isDevice");
  static final APARTMENT = amplify_core.QueryField(
    fieldName: "apartment",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Apartment'));
  static final PACKAGES = amplify_core.QueryField(
    fieldName: "packages",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Package'));
  static final PINCODE = amplify_core.QueryField(fieldName: "pinCode");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "User";
    modelSchemaDefinition.pluralName = "Users";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["username"], name: "byUsername"),
      amplify_core.ModelIndex(fields: const ["apartmentID"], name: "byApartment")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.USERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.ISFIRSTLOGIN,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.ROLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.NAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.ISACTIVE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.EMAIL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.TOWER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.UNIT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.ISDEVICE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: User.APARTMENT,
      isRequired: false,
      targetNames: ['apartmentID'],
      ofModelName: 'Apartment'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: User.PACKAGES,
      isRequired: false,
      ofModelName: 'Package',
      associatedKey: Package.RECIPIENT
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.PINCODE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _UserModelType extends amplify_core.ModelType<User> {
  const _UserModelType();
  
  @override
  User fromJson(Map<String, dynamic> jsonData) {
    return User.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'User';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [User] in your schema.
 */
class UserModelIdentifier implements amplify_core.ModelIdentifier<User> {
  final String id;

  /** Create an instance of UserModelIdentifier using [id] the primary key. */
  const UserModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'UserModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}