Class {
	#name : 'SimdJSONMappingNotFound',
	#superclass : 'Error',
	#instVars : [
		'object',
		'collection'
	],
	#category : 'SimdJSON-Errors',
	#package : 'SimdJSON',
	#tag : 'Errors'
}

{ #category : 'instance creation' }
SimdJSONMappingNotFound class >> signalFor: anObject [
	^ self new
		object: anObject;
		signal

]

{ #category : 'instance creation' }
SimdJSONMappingNotFound class >> signalFor: anObject in: aCollection [
	^ self new
		object: anObject;
		collection: aCollection;
		signal

]

{ #category : 'accessing' }
SimdJSONMappingNotFound >> collection [
	^ collection

]

{ #category : 'accessing' }
SimdJSONMappingNotFound >> collection: aCollection [
	collection := aCollection

]

{ #category : 'accessing' }
SimdJSONMappingNotFound >> messageText [
	^ self standardMessageText

]

{ #category : 'accessing' }
SimdJSONMappingNotFound >> object [
	^ object

]

{ #category : 'accessing' }
SimdJSONMappingNotFound >> object: anObject [
	object := anObject

]

{ #category : 'private' }
SimdJSONMappingNotFound >> standardMessageText [
	^ String streamContents: [ :stream |
		stream << 'No mapping found for '.
		stream print: self object.
		stream << ' in '.
		stream print: self collection class ]

]
