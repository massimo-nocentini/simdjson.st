Class {
	#name : 'SimdJSONFailure',
	#superclass : 'Object',
	#instVars : [
		'ec'
	],
	#category : 'SimdJSON-Core',
	#package : 'SimdJSON',
	#tag : 'Core'
}

{ #category : 'instance creation' }
SimdJSONFailure class >> on: errorCode [
	"The error code of a failed primitive of the plugin (nil when the plugin is missing)"

	^ self new
		ec: errorCode;
		yourself

]

{ #category : 'accessing' }
SimdJSONFailure >> ec [
	^ ec

]

{ #category : 'accessing' }
SimdJSONFailure >> ec: errorCode [
	ec := errorCode

]

{ #category : 'testing' }
SimdJSONFailure >> isNoCMemory [
	^ ec == #'insufficient C memory'

]

{ #category : 'testing' }
SimdJSONFailure >> isNoMemory [
	"An object allocation failed, after the VM's own retries"

	^ ec == #'insufficient object memory'

]

{ #category : 'testing' }
SimdJSONFailure >> isUnavailable [
	"The module could not be loaded, or it has no such primitive"

	^ ec isNil or: [ ec == #'not found' ]

]
