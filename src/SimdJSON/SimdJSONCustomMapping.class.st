Class {
	#name : 'SimdJSONCustomMapping',
	#superclass : 'SimdJSONMapping',
	#instVars : [
		'schemaName',
		'reader',
		'writer'
	],
	#category : 'SimdJSON-Mapping',
	#package : 'SimdJSON',
	#tag : 'Mapping'
}

{ #category : 'mapping' }
SimdJSONCustomMapping >> decoder: block [
	"Set a decoder block that accepts the next object representation read
	and converts it into the actual object to be returned."

	self reader: [ :jsonReader | | representation |
		representation := jsonReader next.
		block value: representation ]

]

{ #category : 'mapping' }
SimdJSONCustomMapping >> encoder: block [
	"Set a writer block that converts anObject into the representation that is written"

	self writer: [ :jsonWriter :anObject | | representation |
		representation := block value: anObject.
		jsonWriter nextPut: representation ]

]

{ #category : 'accessing' }
SimdJSONCustomMapping >> identifier [
	^ schemaName

]

{ #category : 'mapping' }
SimdJSONCustomMapping >> listOfElementSchema: elementSchema [
	"Set the reader to a block that will create an instance of the
	standard listClass while reading a list of elements of type elementSchema."

	self reader: [ :jsonReader |
		jsonReader listClass streamContents: [ :stream |
			jsonReader parseListDo: [ | element |
				element := jsonReader nextAs: elementSchema.
				stream nextPut: element ] ] ].
	self writer: [ :jsonWriter :list |
		jsonWriter writeListStreamingDo: [ :listWriter |
			list do: [ :each |
				listWriter writeElement: each as: elementSchema ] ] ]

]

{ #category : 'mapping' }
SimdJSONCustomMapping >> listOfType: collectionClass [
	"Set the reader to a block that will create an instance of collectionClass
	using #streamContents: while reading a list of elements."

	self reader: [ :jsonReader |
		collectionClass streamContents: [ :stream |
			jsonReader parseListDo: [ | element |
				element := jsonReader next.
				stream nextPut: element ] ] ].
	self writer: [ :jsonWriter :list |
		jsonWriter writeListStreamingDo: [ :listWriter |
			list do: [ :each |
				listWriter writeElement: each ] ] ]

]

{ #category : 'mapping' }
SimdJSONCustomMapping >> listOfType: collectionClass andElementSchema: elementSchema [
	"Set the reader to a block that will create an instance of collectionClass
	using #streamContents: while reading a list of elements of type elementSchema."

	self reader: [ :jsonReader |
		collectionClass streamContents: [ :stream |
			jsonReader parseListDo: [ | element |
				element := jsonReader nextAs: elementSchema.
				stream nextPut: element ] ] ].
	self writer: [ :jsonWriter :list |
		jsonWriter writeListStreamingDo: [ :listWriter |
			list do: [ :each |
				listWriter writeElement: each as: elementSchema ] ] ]

]

{ #category : 'mapping' }
SimdJSONCustomMapping >> mapWithValueSchema: valueSchema [
	"Set the reader to a block that will create an instance of the
	standard mapClass while reading values of type valueSchema,
	with standard keys"

	self reader: [ :jsonReader | | map |
		map := jsonReader mapClass new.
		jsonReader parseMapKeysDo: [ :key | | value |
				value := jsonReader nextAs: valueSchema.
				map at: key put: value ].
		map ].
	self writer: [ :jsonWriter :map |
		jsonWriter writeMapStreamingDo: [ :mapWriter |
			map keysAndValuesDo: [ :key :value |
				mapWriter writeKey: key value: value as: valueSchema ] ] ]

]

{ #category : 'parsing' }
SimdJSONCustomMapping >> readFrom: jsonReader [
	^ reader
		ifNil: [ jsonReader next ]
		ifNotNil: [ reader value: jsonReader ]

]

{ #category : 'accessing' }
SimdJSONCustomMapping >> reader: block [
	"Set the reader to block, a 1 argument block that when given
	a jsonReader as argument reads the object that I represent.
	When there is no reader block, the default #next will be used."

	reader := block

]

{ #category : 'accessing' }
SimdJSONCustomMapping >> schemaName: schema [
	schemaName := schema

]

{ #category : 'writing' }
SimdJSONCustomMapping >> writeObject: anObject on: jsonWriter [
	"The writer block, else anObject as the writer writes it by its class"

	writer
		ifNil: [ jsonWriter nextPut: anObject ]
		ifNotNil: [ writer value: jsonWriter value: anObject ]

]

{ #category : 'accessing' }
SimdJSONCustomMapping >> writer: block [
	"Set the writer to block, a 2 argument block that, given a jsonWriter and the object to
	write, writes the object that I represent; without it the jsonWriter writes the object
	by its class"

	writer := block

]
