Class {
	#name : 'SimdJSONResourceError',
	#superclass : 'Error',
	#instVars : [
		'code'
	],
	#category : 'SimdJSON-Errors',
	#package : 'SimdJSON',
	#tag : 'Errors'
}

{ #category : 'accessing' }
SimdJSONResourceError >> code [
	"The error code of the primitive, or #tooLarge"

	^ code

]

{ #category : 'accessing' }
SimdJSONResourceError >> code: anObject [
	code := anObject

]
