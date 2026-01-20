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


/** This is an auto generated class representing the BuildingSettings type in your schema. */
class BuildingSettings extends amplify_core.Model {
  static const classType = const _BuildingSettingsModelType();
  final String id;
  final int? _maxAdmins;
  final int? _maxGuards;
  final String? _currentAccessCode;
  final amplify_core.TemporalDateTime? _codeExpiresAt;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  BuildingSettingsModelIdentifier get modelIdentifier {
      return BuildingSettingsModelIdentifier(
        id: id
      );
  }
  
  int get maxAdmins {
    try {
      return _maxAdmins!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get maxGuards {
    try {
      return _maxGuards!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get currentAccessCode {
    return _currentAccessCode;
  }
  
  amplify_core.TemporalDateTime? get codeExpiresAt {
    return _codeExpiresAt;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const BuildingSettings._internal({required this.id, required maxAdmins, required maxGuards, currentAccessCode, codeExpiresAt, createdAt, updatedAt}): _maxAdmins = maxAdmins, _maxGuards = maxGuards, _currentAccessCode = currentAccessCode, _codeExpiresAt = codeExpiresAt, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory BuildingSettings({String? id, required int maxAdmins, required int maxGuards, String? currentAccessCode, amplify_core.TemporalDateTime? codeExpiresAt}) {
    return BuildingSettings._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      maxAdmins: maxAdmins,
      maxGuards: maxGuards,
      currentAccessCode: currentAccessCode,
      codeExpiresAt: codeExpiresAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildingSettings &&
      id == other.id &&
      _maxAdmins == other._maxAdmins &&
      _maxGuards == other._maxGuards &&
      _currentAccessCode == other._currentAccessCode &&
      _codeExpiresAt == other._codeExpiresAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("BuildingSettings {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("maxAdmins=" + (_maxAdmins != null ? _maxAdmins!.toString() : "null") + ", ");
    buffer.write("maxGuards=" + (_maxGuards != null ? _maxGuards!.toString() : "null") + ", ");
    buffer.write("currentAccessCode=" + "$_currentAccessCode" + ", ");
    buffer.write("codeExpiresAt=" + (_codeExpiresAt != null ? _codeExpiresAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  BuildingSettings copyWith({int? maxAdmins, int? maxGuards, String? currentAccessCode, amplify_core.TemporalDateTime? codeExpiresAt}) {
    return BuildingSettings._internal(
      id: id,
      maxAdmins: maxAdmins ?? this.maxAdmins,
      maxGuards: maxGuards ?? this.maxGuards,
      currentAccessCode: currentAccessCode ?? this.currentAccessCode,
      codeExpiresAt: codeExpiresAt ?? this.codeExpiresAt);
  }
  
  BuildingSettings copyWithModelFieldValues({
    ModelFieldValue<int>? maxAdmins,
    ModelFieldValue<int>? maxGuards,
    ModelFieldValue<String?>? currentAccessCode,
    ModelFieldValue<amplify_core.TemporalDateTime?>? codeExpiresAt
  }) {
    return BuildingSettings._internal(
      id: id,
      maxAdmins: maxAdmins == null ? this.maxAdmins : maxAdmins.value,
      maxGuards: maxGuards == null ? this.maxGuards : maxGuards.value,
      currentAccessCode: currentAccessCode == null ? this.currentAccessCode : currentAccessCode.value,
      codeExpiresAt: codeExpiresAt == null ? this.codeExpiresAt : codeExpiresAt.value
    );
  }
  
  BuildingSettings.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _maxAdmins = (json['maxAdmins'] as num?)?.toInt(),
      _maxGuards = (json['maxGuards'] as num?)?.toInt(),
      _currentAccessCode = json['currentAccessCode'],
      _codeExpiresAt = json['codeExpiresAt'] != null ? amplify_core.TemporalDateTime.fromString(json['codeExpiresAt']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'maxAdmins': _maxAdmins, 'maxGuards': _maxGuards, 'currentAccessCode': _currentAccessCode, 'codeExpiresAt': _codeExpiresAt?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'maxAdmins': _maxAdmins,
    'maxGuards': _maxGuards,
    'currentAccessCode': _currentAccessCode,
    'codeExpiresAt': _codeExpiresAt,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<BuildingSettingsModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<BuildingSettingsModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final MAXADMINS = amplify_core.QueryField(fieldName: "maxAdmins");
  static final MAXGUARDS = amplify_core.QueryField(fieldName: "maxGuards");
  static final CURRENTACCESSCODE = amplify_core.QueryField(fieldName: "currentAccessCode");
  static final CODEEXPIRESAT = amplify_core.QueryField(fieldName: "codeExpiresAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "BuildingSettings";
    modelSchemaDefinition.pluralName = "BuildingSettings";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BuildingSettings.MAXADMINS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BuildingSettings.MAXGUARDS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BuildingSettings.CURRENTACCESSCODE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BuildingSettings.CODEEXPIRESAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
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

class _BuildingSettingsModelType extends amplify_core.ModelType<BuildingSettings> {
  const _BuildingSettingsModelType();
  
  @override
  BuildingSettings fromJson(Map<String, dynamic> jsonData) {
    return BuildingSettings.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'BuildingSettings';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [BuildingSettings] in your schema.
 */
class BuildingSettingsModelIdentifier implements amplify_core.ModelIdentifier<BuildingSettings> {
  final String id;

  /** Create an instance of BuildingSettingsModelIdentifier using [id] the primary key. */
  const BuildingSettingsModelIdentifier({
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
  String toString() => 'BuildingSettingsModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is BuildingSettingsModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}