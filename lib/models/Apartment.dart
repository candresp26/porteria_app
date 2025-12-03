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


/** This is an auto generated class representing the Apartment type in your schema. */
class Apartment extends amplify_core.Model {
  static const classType = const _ApartmentModelType();
  final String id;
  final String? _tower;
  final String? _unitNumber;
  final String? _accessCode;
  final List<User>? _residents;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ApartmentModelIdentifier get modelIdentifier {
      return ApartmentModelIdentifier(
        id: id
      );
  }
  
  String get tower {
    try {
      return _tower!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get unitNumber {
    try {
      return _unitNumber!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get accessCode {
    try {
      return _accessCode!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<User>? get residents {
    return _residents;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Apartment._internal({required this.id, required tower, required unitNumber, required accessCode, residents, createdAt, updatedAt}): _tower = tower, _unitNumber = unitNumber, _accessCode = accessCode, _residents = residents, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Apartment({String? id, required String tower, required String unitNumber, required String accessCode, List<User>? residents}) {
    return Apartment._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      tower: tower,
      unitNumber: unitNumber,
      accessCode: accessCode,
      residents: residents != null ? List<User>.unmodifiable(residents) : residents);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Apartment &&
      id == other.id &&
      _tower == other._tower &&
      _unitNumber == other._unitNumber &&
      _accessCode == other._accessCode &&
      DeepCollectionEquality().equals(_residents, other._residents);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Apartment {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("tower=" + "$_tower" + ", ");
    buffer.write("unitNumber=" + "$_unitNumber" + ", ");
    buffer.write("accessCode=" + "$_accessCode" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Apartment copyWith({String? tower, String? unitNumber, String? accessCode, List<User>? residents}) {
    return Apartment._internal(
      id: id,
      tower: tower ?? this.tower,
      unitNumber: unitNumber ?? this.unitNumber,
      accessCode: accessCode ?? this.accessCode,
      residents: residents ?? this.residents);
  }
  
  Apartment copyWithModelFieldValues({
    ModelFieldValue<String>? tower,
    ModelFieldValue<String>? unitNumber,
    ModelFieldValue<String>? accessCode,
    ModelFieldValue<List<User>?>? residents
  }) {
    return Apartment._internal(
      id: id,
      tower: tower == null ? this.tower : tower.value,
      unitNumber: unitNumber == null ? this.unitNumber : unitNumber.value,
      accessCode: accessCode == null ? this.accessCode : accessCode.value,
      residents: residents == null ? this.residents : residents.value
    );
  }
  
  Apartment.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _tower = json['tower'],
      _unitNumber = json['unitNumber'],
      _accessCode = json['accessCode'],
      _residents = json['residents']  is Map
        ? (json['residents']['items'] is List
          ? (json['residents']['items'] as List)
              .where((e) => e != null)
              .map((e) => User.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['residents'] is List
          ? (json['residents'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => User.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'tower': _tower, 'unitNumber': _unitNumber, 'accessCode': _accessCode, 'residents': _residents?.map((User? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'tower': _tower,
    'unitNumber': _unitNumber,
    'accessCode': _accessCode,
    'residents': _residents,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ApartmentModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ApartmentModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TOWER = amplify_core.QueryField(fieldName: "tower");
  static final UNITNUMBER = amplify_core.QueryField(fieldName: "unitNumber");
  static final ACCESSCODE = amplify_core.QueryField(fieldName: "accessCode");
  static final RESIDENTS = amplify_core.QueryField(
    fieldName: "residents",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Apartment";
    modelSchemaDefinition.pluralName = "Apartments";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "ADMIN", "SUPER_ADMIN" ],
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
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Apartment.TOWER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Apartment.UNITNUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Apartment.ACCESSCODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Apartment.RESIDENTS,
      isRequired: false,
      ofModelName: 'User',
      associatedKey: User.APARTMENT
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

class _ApartmentModelType extends amplify_core.ModelType<Apartment> {
  const _ApartmentModelType();
  
  @override
  Apartment fromJson(Map<String, dynamic> jsonData) {
    return Apartment.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Apartment';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Apartment] in your schema.
 */
class ApartmentModelIdentifier implements amplify_core.ModelIdentifier<Apartment> {
  final String id;

  /** Create an instance of ApartmentModelIdentifier using [id] the primary key. */
  const ApartmentModelIdentifier({
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
  String toString() => 'ApartmentModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ApartmentModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}