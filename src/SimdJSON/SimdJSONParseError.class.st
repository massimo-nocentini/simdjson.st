Class {
	#name : 'SimdJSONParseError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'position'
	],
	#category : 'SimdJSON-Errors',
	#package : 'SimdJSON',
	#tag : 'Errors'
}

{ #category : 'accessing' }
SimdJSONParseError >> code [
	"The simdjson error code (or the plugin's: 1001 BOM, 1002 number token check), or nil"

	^ code

]

{ #category : 'accessing' }
SimdJSONParseError >> code: anInteger [
	code := anInteger

]

{ #category : 'accessing' }
SimdJSONParseError >> position [
	"The index of the source unit (character, or byte of a ByteArray) where the value starts"

	^ position

]

{ #category : 'accessing' }
SimdJSONParseError >> position: anInteger [
	position := anInteger

]
