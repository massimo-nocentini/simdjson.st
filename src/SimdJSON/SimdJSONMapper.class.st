Class {
	#name : 'SimdJSONMapper',
	#superclass : 'Object',
	#instVars : [
		'mappings'
	],
	#category : 'SimdJSON-Mapping',
	#package : 'SimdJSON',
	#tag : 'Mapping'
}

{ #category : 'private' }
SimdJSONMapper >> customMappingFor: schemaName [
	^ self mappings
		at: schemaName
		ifAbsentPut: [
			SimdJSONCustomMapping new
				schemaName: schemaName;
				yourself ]

]

{ #category : 'mapping' }
SimdJSONMapper >> for: schemaName customDo: block [
	"Execute the code in block to further customize the mapping for schemaName.
	Create and add a new custom mapping for schemaName if necessary."

	| mapping |
	mapping := self customMappingFor: schemaName.
	block value: mapping.
	^ mapping

]

{ #category : 'mapping' }
SimdJSONMapper >> for: smalltalkClass do: block [
	"Execute the code in block to further customize the mapping for schemaName.
	Create and add a new standard object mapping for schemaName if necessary."

	| mapping |
	mapping := self objectMappingFor: smalltalkClass.
	block value: mapping.
	^ mapping

]

{ #category : 'convenience' }
SimdJSONMapper >> mapAllInstVarsFor: smalltalkClass [
	"Map the instance variables of smalltalkClass and all its super classes"

	| mapping |
	mapping := self objectMappingFor: smalltalkClass.
	mapping mapAllInstVars.
	^ mapping

]

{ #category : 'convenience' }
SimdJSONMapper >> mapInstVarsFor: smalltalkClass [
	"Map the instance variables of smalltalkClass"

	| mapping |
	mapping := self objectMappingFor: smalltalkClass.
	mapping mapInstVars.
	^ mapping

]

{ #category : 'accessing' }
SimdJSONMapper >> mappingFor: schema [
	^ self
		mappingFor: schema
		ifAbsent: [ SimdJSONMappingNotFound signalFor: schema in: self ]

]

{ #category : 'accessing' }
SimdJSONMapper >> mappingFor: schema ifAbsent: block [
	(self mappings includesKey: schema)
		ifFalse: [ self resolveMappingFor: schema ].
	^ self mappings
		at: schema
		ifAbsent: block

]

{ #category : 'private' }
SimdJSONMapper >> mappings [
	^ mappings
		ifNil: [ mappings := Dictionary new ]

]

{ #category : 'private' }
SimdJSONMapper >> objectMappingFor: smalltalkClass [
	^ self mappings
		at: smalltalkClass
		ifAbsentPut: [
			SimdJSONObjectMapping new
				subjectClass: smalltalkClass;
				yourself ]

]

{ #category : 'private' }
SimdJSONMapper >> resolveMappingFor: class [
	"The class-side hook of NeoJSON, neoJsonMapping: mapper, sends only the mapper protocol"

	(class respondsTo: #neoJsonMapping:)
		ifTrue: [
			class perform: #neoJsonMapping: with: self ]

]
