Class {
	#name : 'SimdJSONPropertyMapping',
	#superclass : 'Object',
	#instVars : [
		'propertyName',
		'valueSchema',
		'getter',
		'setter'
	],
	#category : 'SimdJSON-Mapping',
	#package : 'SimdJSON',
	#tag : 'Mapping'
}

{ #category : 'accessing' }
SimdJSONPropertyMapping >> getter: block [
	getter := block

]

{ #category : 'printing' }
SimdJSONPropertyMapping >> printOn: stream [
	super printOn: stream.
	stream nextPut: $(; print: propertyName; nextPut: $)

]

{ #category : 'accessing' }
SimdJSONPropertyMapping >> propertyName [
	^ propertyName

]

{ #category : 'accessing' }
SimdJSONPropertyMapping >> propertyName: symbolOrString [
	propertyName := symbolOrString asSymbol

]

{ #category : 'parsing' }
SimdJSONPropertyMapping >> readObject: anObject from: jsonReader [
	| value |
	value := jsonReader nextAs: valueSchema.
	setter value: anObject value: value

]

{ #category : 'accessing' }
SimdJSONPropertyMapping >> setter: block [
	setter := block

]

{ #category : 'accessing' }
SimdJSONPropertyMapping >> valueSchema: schemaName [
	valueSchema := schemaName

]

{ #category : 'writing' }
SimdJSONPropertyMapping >> writeObject: anObject on: jsonMapWriter [
	| value |
	value := getter value: anObject.
	(value notNil or: [ jsonMapWriter writeNil ])
		ifTrue: [ jsonMapWriter writeKey: propertyName value: value as: valueSchema ]

]
