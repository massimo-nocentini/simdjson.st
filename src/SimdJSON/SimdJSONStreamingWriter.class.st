Class {
	#name : 'SimdJSONStreamingWriter',
	#superclass : 'Object',
	#instVars : [
		'jsonWriter',
		'first'
	],
	#category : 'SimdJSON-Writing',
	#package : 'SimdJSON',
	#tag : 'Writing'
}

{ #category : 'instance creation' }
SimdJSONStreamingWriter class >> on: aJSONWriter [
	^ self new
		on: aJSONWriter;
		yourself

]

{ #category : 'initialize-release' }
SimdJSONStreamingWriter >> initialize [
	super initialize.
	first := true

]

{ #category : 'initialize-release' }
SimdJSONStreamingWriter >> on: aJSONWriter [
	jsonWriter := aJSONWriter

]

{ #category : 'private' }
SimdJSONStreamingWriter >> separate [
	first
		ifTrue: [
			jsonWriter newlineIndent.
			first := false ]
		ifFalse: [ jsonWriter listElementSeparator ]

]

{ #category : 'testing' }
SimdJSONStreamingWriter >> wasUsed [
	^ first not

]

{ #category : 'writing' }
SimdJSONStreamingWriter >> writeElement: value [
	self separate.
	jsonWriter nextPut: value

]

{ #category : 'writing' }
SimdJSONStreamingWriter >> writeElement: value as: valueSchema [
	self separate.
	jsonWriter nextPut: value as: valueSchema

]

{ #category : 'writing' }
SimdJSONStreamingWriter >> writeKey: key value: value [
	self separate.
	jsonWriter encodeKey: key value: value

]

{ #category : 'writing' }
SimdJSONStreamingWriter >> writeKey: key value: value as: valueSchema [
	self separate.
	jsonWriter encodeKey: key value: value as: valueSchema

]

{ #category : 'accessing' }
SimdJSONStreamingWriter >> writeNil [
	^ jsonWriter writeNil

]
