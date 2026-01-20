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


/** This is an auto generated class representing the Package type in your schema. */
class Package extends amplify_core.Model {
  static const classType = const _PackageModelType();
  final String id;
  final String? _courier;
  final String? _photoKey;
  final amplify_core.TemporalDateTime? _receivedAt;
  final amplify_core.TemporalDateTime? _deliveredAt;
  final String? _apartmentUnit;
  final User? _recipient;
  final PackageStatus? _status;
  final String? _signatureKey;
  final DeliveryMethod? _deliveryMethod;
  final String? _receivedBy;
  final String? _deliveredBy;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  PackageModelIdentifier get modelIdentifier {
      return PackageModelIdentifier(
        id: id
      );
  }
  
  String get courier {
    try {
      return _courier!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get photoKey {
    return _photoKey;
  }
  
  amplify_core.TemporalDateTime get receivedAt {
    try {
      return _receivedAt!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get deliveredAt {
    return _deliveredAt;
  }
  
  String? get apartmentUnit {
    return _apartmentUnit;
  }
  
  User? get recipient {
    return _recipient;
  }
  
  PackageStatus get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get signatureKey {
    return _signatureKey;
  }
  
  DeliveryMethod? get deliveryMethod {
    return _deliveryMethod;
  }
  
  String? get receivedBy {
    return _receivedBy;
  }
  
  String? get deliveredBy {
    return _deliveredBy;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Package._internal({required this.id, required courier, photoKey, required receivedAt, deliveredAt, apartmentUnit, recipient, required status, signatureKey, deliveryMethod, receivedBy, deliveredBy, createdAt, updatedAt}): _courier = courier, _photoKey = photoKey, _receivedAt = receivedAt, _deliveredAt = deliveredAt, _apartmentUnit = apartmentUnit, _recipient = recipient, _status = status, _signatureKey = signatureKey, _deliveryMethod = deliveryMethod, _receivedBy = receivedBy, _deliveredBy = deliveredBy, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Package({String? id, required String courier, String? photoKey, required amplify_core.TemporalDateTime receivedAt, amplify_core.TemporalDateTime? deliveredAt, String? apartmentUnit, User? recipient, required PackageStatus status, String? signatureKey, DeliveryMethod? deliveryMethod, String? receivedBy, String? deliveredBy}) {
    return Package._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      courier: courier,
      photoKey: photoKey,
      receivedAt: receivedAt,
      deliveredAt: deliveredAt,
      apartmentUnit: apartmentUnit,
      recipient: recipient,
      status: status,
      signatureKey: signatureKey,
      deliveryMethod: deliveryMethod,
      receivedBy: receivedBy,
      deliveredBy: deliveredBy);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Package &&
      id == other.id &&
      _courier == other._courier &&
      _photoKey == other._photoKey &&
      _receivedAt == other._receivedAt &&
      _deliveredAt == other._deliveredAt &&
      _apartmentUnit == other._apartmentUnit &&
      _recipient == other._recipient &&
      _status == other._status &&
      _signatureKey == other._signatureKey &&
      _deliveryMethod == other._deliveryMethod &&
      _receivedBy == other._receivedBy &&
      _deliveredBy == other._deliveredBy;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Package {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("courier=" + "$_courier" + ", ");
    buffer.write("photoKey=" + "$_photoKey" + ", ");
    buffer.write("receivedAt=" + (_receivedAt != null ? _receivedAt!.format() : "null") + ", ");
    buffer.write("deliveredAt=" + (_deliveredAt != null ? _deliveredAt!.format() : "null") + ", ");
    buffer.write("apartmentUnit=" + "$_apartmentUnit" + ", ");
    buffer.write("recipient=" + (_recipient != null ? _recipient!.toString() : "null") + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("signatureKey=" + "$_signatureKey" + ", ");
    buffer.write("deliveryMethod=" + (_deliveryMethod != null ? amplify_core.enumToString(_deliveryMethod)! : "null") + ", ");
    buffer.write("receivedBy=" + "$_receivedBy" + ", ");
    buffer.write("deliveredBy=" + "$_deliveredBy" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Package copyWith({String? courier, String? photoKey, amplify_core.TemporalDateTime? receivedAt, amplify_core.TemporalDateTime? deliveredAt, String? apartmentUnit, User? recipient, PackageStatus? status, String? signatureKey, DeliveryMethod? deliveryMethod, String? receivedBy, String? deliveredBy}) {
    return Package._internal(
      id: id,
      courier: courier ?? this.courier,
      photoKey: photoKey ?? this.photoKey,
      receivedAt: receivedAt ?? this.receivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      apartmentUnit: apartmentUnit ?? this.apartmentUnit,
      recipient: recipient ?? this.recipient,
      status: status ?? this.status,
      signatureKey: signatureKey ?? this.signatureKey,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      receivedBy: receivedBy ?? this.receivedBy,
      deliveredBy: deliveredBy ?? this.deliveredBy);
  }
  
  Package copyWithModelFieldValues({
    ModelFieldValue<String>? courier,
    ModelFieldValue<String?>? photoKey,
    ModelFieldValue<amplify_core.TemporalDateTime>? receivedAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? deliveredAt,
    ModelFieldValue<String?>? apartmentUnit,
    ModelFieldValue<User?>? recipient,
    ModelFieldValue<PackageStatus>? status,
    ModelFieldValue<String?>? signatureKey,
    ModelFieldValue<DeliveryMethod?>? deliveryMethod,
    ModelFieldValue<String?>? receivedBy,
    ModelFieldValue<String?>? deliveredBy
  }) {
    return Package._internal(
      id: id,
      courier: courier == null ? this.courier : courier.value,
      photoKey: photoKey == null ? this.photoKey : photoKey.value,
      receivedAt: receivedAt == null ? this.receivedAt : receivedAt.value,
      deliveredAt: deliveredAt == null ? this.deliveredAt : deliveredAt.value,
      apartmentUnit: apartmentUnit == null ? this.apartmentUnit : apartmentUnit.value,
      recipient: recipient == null ? this.recipient : recipient.value,
      status: status == null ? this.status : status.value,
      signatureKey: signatureKey == null ? this.signatureKey : signatureKey.value,
      deliveryMethod: deliveryMethod == null ? this.deliveryMethod : deliveryMethod.value,
      receivedBy: receivedBy == null ? this.receivedBy : receivedBy.value,
      deliveredBy: deliveredBy == null ? this.deliveredBy : deliveredBy.value
    );
  }
  
  Package.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _courier = json['courier'],
      _photoKey = json['photoKey'],
      _receivedAt = json['receivedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['receivedAt']) : null,
      _deliveredAt = json['deliveredAt'] != null ? amplify_core.TemporalDateTime.fromString(json['deliveredAt']) : null,
      _apartmentUnit = json['apartmentUnit'],
      _recipient = json['recipient'] != null
        ? json['recipient']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['recipient']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['recipient']))
        : null,
      _status = amplify_core.enumFromString<PackageStatus>(json['status'], PackageStatus.values),
      _signatureKey = json['signatureKey'],
      _deliveryMethod = amplify_core.enumFromString<DeliveryMethod>(json['deliveryMethod'], DeliveryMethod.values),
      _receivedBy = json['receivedBy'],
      _deliveredBy = json['deliveredBy'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'courier': _courier, 'photoKey': _photoKey, 'receivedAt': _receivedAt?.format(), 'deliveredAt': _deliveredAt?.format(), 'apartmentUnit': _apartmentUnit, 'recipient': _recipient?.toJson(), 'status': amplify_core.enumToString(_status), 'signatureKey': _signatureKey, 'deliveryMethod': amplify_core.enumToString(_deliveryMethod), 'receivedBy': _receivedBy, 'deliveredBy': _deliveredBy, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'courier': _courier,
    'photoKey': _photoKey,
    'receivedAt': _receivedAt,
    'deliveredAt': _deliveredAt,
    'apartmentUnit': _apartmentUnit,
    'recipient': _recipient,
    'status': _status,
    'signatureKey': _signatureKey,
    'deliveryMethod': _deliveryMethod,
    'receivedBy': _receivedBy,
    'deliveredBy': _deliveredBy,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<PackageModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<PackageModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final COURIER = amplify_core.QueryField(fieldName: "courier");
  static final PHOTOKEY = amplify_core.QueryField(fieldName: "photoKey");
  static final RECEIVEDAT = amplify_core.QueryField(fieldName: "receivedAt");
  static final DELIVEREDAT = amplify_core.QueryField(fieldName: "deliveredAt");
  static final APARTMENTUNIT = amplify_core.QueryField(fieldName: "apartmentUnit");
  static final RECIPIENT = amplify_core.QueryField(
    fieldName: "recipient",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final SIGNATUREKEY = amplify_core.QueryField(fieldName: "signatureKey");
  static final DELIVERYMETHOD = amplify_core.QueryField(fieldName: "deliveryMethod");
  static final RECEIVEDBY = amplify_core.QueryField(fieldName: "receivedBy");
  static final DELIVEREDBY = amplify_core.QueryField(fieldName: "deliveredBy");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Package";
    modelSchemaDefinition.pluralName = "Packages";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["recipientID"], name: "byRecipient")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.COURIER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.PHOTOKEY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.RECEIVEDAT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.DELIVEREDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.APARTMENTUNIT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Package.RECIPIENT,
      isRequired: false,
      targetNames: ['recipientID'],
      ofModelName: 'User'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.SIGNATUREKEY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.DELIVERYMETHOD,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.RECEIVEDBY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Package.DELIVEREDBY,
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

class _PackageModelType extends amplify_core.ModelType<Package> {
  const _PackageModelType();
  
  @override
  Package fromJson(Map<String, dynamic> jsonData) {
    return Package.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Package';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Package] in your schema.
 */
class PackageModelIdentifier implements amplify_core.ModelIdentifier<Package> {
  final String id;

  /** Create an instance of PackageModelIdentifier using [id] the primary key. */
  const PackageModelIdentifier({
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
  String toString() => 'PackageModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is PackageModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}