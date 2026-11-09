Class {
	#name : 'SimdJSONWriteError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'culprit'
	],
	#category : 'SimdJSON-Errors',
	#package : 'SimdJSON',
	#tag : 'Errors'
}

{ #category : 'accessing' }
SimdJSONWriteError >> code [
	"1 a key that is not a string, 2 a NaN or an infinity, 3 too deep a value, 4 a code point
	beyond U+10FFFF"

	^ code

]

{ #category : 'accessing' }
SimdJSONWriteError >> code: anObject [
	code := anObject

]

{ #category : 'accessing' }
SimdJSONWriteError >> culprit [
	"The object that could not be written"

	^ culprit

]

{ #category : 'accessing' }
SimdJSONWriteError >> culprit: anObject [
	culprit := anObject

]
