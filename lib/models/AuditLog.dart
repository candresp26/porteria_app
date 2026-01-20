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


/** This is an auto generated class representing the AuditLog type in your schema. */
class AuditLog extends amplify_core.Model {
  static const classType = const _AuditLogModelType();
  final String id;
  final String? _action;
  final String? _actorName;
  final String? _targetName;
  final String? _details;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  AuditLogModelIdentifier get modelIdentifier {
      return AuditLogModelIdentifier(
        id: id
      );
  }
  
  String get action {
    try {
      return _action!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get actorName {
    try {
      return _actorName!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get targetName {
    return _targetName;
  }
  
  String? get details {
    return _details;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const AuditLog._internal({required this.id, required action, required actorName, targetName, details, createdAt, updatedAt}): _action = action, _actorName = actorName, _targetName = targetName, _details = details, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory AuditLog({String? id, required String action, required String actorName, String? targetName, String? details, amplify_core.TemporalDateTime? createdAt}) {
    return AuditLog._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      action: action,
      actorName: actorName,
      targetName: targetName,
      details: details,
      createdAt: createdAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditLog &&
      id == other.id &&
      _action == other._action &&
      _actorName == other._actorName &&
      _targetName == other._targetName &&
      _details == other._details &&
      _createdAt == other._createdAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("AuditLog {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("action=" + "$_action" + ", ");
    buffer.write("actorName=" + "$_actorName" + ", ");
    buffer.write("targetName=" + "$_targetName" + ", ");
    buffer.write("details=" + "$_details" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  AuditLog copyWith({String? action, String? actorName, String? targetName, String? details, amplify_core.TemporalDateTime? createdAt}) {
    return AuditLog._internal(
      id: id,
      action: action ?? this.action,
      actorName: actorName ?? this.actorName,
      targetName: targetName ?? this.targetName,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt);
  }
  
  AuditLog copyWithModelFieldValues({
    ModelFieldValue<String>? action,
    ModelFieldValue<String>? actorName,
    ModelFieldValue<String?>? targetName,
    ModelFieldValue<String?>? details,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt
  }) {
    return AuditLog._internal(
      id: id,
      action: action == null ? this.action : action.value,
      actorName: actorName == null ? this.actorName : actorName.value,
      targetName: targetName == null ? this.targetName : targetName.value,
      details: details == null ? this.details : details.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value
    );
  }
  
  AuditLog.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _action = json['action'],
      _actorName = json['actorName'],
      _targetName = json['targetName'],
      _details = json['details'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'action': _action, 'actorName': _actorName, 'targetName': _targetName, 'details': _details, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'action': _action,
    'actorName': _actorName,
    'targetName': _targetName,
    'details': _details,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AuditLogModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AuditLogModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final ACTION = amplify_core.QueryField(fieldName: "action");
  static final ACTORNAME = amplify_core.QueryField(fieldName: "actorName");
  static final TARGETNAME = amplify_core.QueryField(fieldName: "targetName");
  static final DETAILS = amplify_core.QueryField(fieldName: "details");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "AuditLog";
    modelSchemaDefinition.pluralName = "AuditLogs";
    
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
      key: AuditLog.ACTION,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AuditLog.ACTORNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AuditLog.TARGETNAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AuditLog.DETAILS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AuditLog.CREATEDAT,
      isRequired: false,
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

class _AuditLogModelType extends amplify_core.ModelType<AuditLog> {
  const _AuditLogModelType();
  
  @override
  AuditLog fromJson(Map<String, dynamic> jsonData) {
    return AuditLog.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'AuditLog';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [AuditLog] in your schema.
 */
class AuditLogModelIdentifier implements amplify_core.ModelIdentifier<AuditLog> {
  final String id;

  /** Create an instance of AuditLogModelIdentifier using [id] the primary key. */
  const AuditLogModelIdentifier({
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
  String toString() => 'AuditLogModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is AuditLogModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}