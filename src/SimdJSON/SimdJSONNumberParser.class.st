Class {
	#name : 'SimdJSONNumberParser',
	#superclass : 'Object',
	#instVars : [
		'readStream'
	],
	#category : 'SimdJSON-Core',
	#package : 'SimdJSON',
	#tag : 'Core'
}

{ #category : 'parsing' }
SimdJSONNumberParser class >> parse: aString [
	"Convert the text of a JSON number token with NeoJSON's rules: 1e2 is 100, 1e-2 is 1/100"

	^ self new
		on: aString readStream;
		parseNumber

]

{ #category : 'private' }
SimdJSONNumberParser >> error: text [
	SimdJSONParseError new signal: text

]

{ #category : 'initialize-release' }
SimdJSONNumberParser >> on: aReadStream [
	readStream := aReadStream

]

{ #category : 'parsing' }
SimdJSONNumberParser >> parseNumber [
	| negated number isFloat |
	negated := readStream peekFor: $-.
	number := self parseNumberInteger.
	isFloat := (readStream peekFor: $.)
		ifTrue: [ number := number + self parseNumberFraction. true ]
		ifFalse: [ false ].
	((readStream peekFor: $e) or: [ readStream peekFor: $E ])
		ifTrue: [ number := number * self parseNumberExponent ].
	isFloat ifTrue: [ number := number asFloat ].
	negated
		ifTrue: [ number := number negated ].
	^ number

]

{ #category : 'parsing' }
SimdJSONNumberParser >> parseNumberExponent [
	| number negated |
	number := 0.
	(negated := readStream peekFor: $-)
		ifFalse: [ readStream peekFor: $+ ].
	(readStream atEnd or: [ readStream peek isDigit not ])
		ifTrue: [ self error: 'number exponent expected' ].
	[ readStream atEnd not and: [ readStream peek isDigit ] ]
		whileTrue: [ number := 10 * number + readStream next digitValue ].
	negated
		ifTrue: [ number := number negated ].
	number positive
		ifTrue: [ number > Float emax ifTrue: [ self error: 'number exponent too large' ] ]
		ifFalse: [ number < Float emin ifTrue: [ self error: 'number exponent too small' ] ].
	^ 10 raisedTo: number

]

{ #category : 'parsing' }
SimdJSONNumberParser >> parseNumberFraction [
	| number power |
	number := 0.
	power := 1.
	[ readStream atEnd not and: [ readStream peek isDigit ] ]
		whileTrue: [
			number := 10 * number + readStream next digitValue.
			power := power * 10 ].
	^ number / power

]

{ #category : 'parsing' }
SimdJSONNumberParser >> parseNumberInteger [
	| number |
	number := nil.
	[ readStream atEnd not and: [ readStream peek isDigit ] ]
		whileTrue: [
			number := 10 * (number ifNil: [ 0 ]) + readStream next digitValue ].
	number ifNil: [ self error: 'Integer digit expected' ].
	^ number

]
