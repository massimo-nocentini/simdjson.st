"
I write the tape of a value for sj_ffi_write of libSimdJSONFFI (SimdJSONLibrary), which writes its JSON: 8-byte slots in pre-order, each value a header, payload << 8 | tag, then its data, and the code points of the WideStrings in a WordArray of their own (plugins/SimdJSONPlugin/include/ffi/sjFFI.h has the layout).

I walk a value as primitiveWrite walks it: nil, Booleans, Integers, Floats, ByteString, ByteSymbol, WideString, WideSymbol, Array, OrderedCollection and Dictionary, of exactly these classes; any other object is a hole, which the image writes.  The holes, the keys that are not strings, the values deeper than maxDepth, the NaNs and infinities and the WideStrings are numbered in the order I meet them (objects), so that the library can name the culprit of an error, or the object of a hole, by its number.
"
Class {
	#name : 'SimdJSONTapeEncoder',
	#superclass : 'Object',
	#instVars : [
		'tape',
		'position',
		'limit',
		'words',
		'wordPosition',
		'objects',
		'maxDepth',
		'floatHoles'
	],
	#category : 'SimdJSON-FFI-Library',
	#package : 'SimdJSON-FFI',
	#tag : 'Library'
}

{ #category : 'encoding' }
SimdJSONTapeEncoder >> array: aCollection level: level [

	| next |
	self header: 4 payload: aCollection size.
	next := level + 1.
	aCollection do: [ :each | self value: each level: next ]

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> byteString: aString [
	"Its Latin-1 bytes, padded to 8"

	| n |
	n := aString size.
	position + n > limit ifTrue: [ self reserve: n + 16 ].
	tape int64AtOffset: position put: (n bitShift: 8) + 2.
	n > 0 ifTrue: [ tape replaceFrom: position + 9 to: position + 8 + n with: aString startingAt: 1 ].
	position := position + 8 + (n + 7 bitAnd: -8)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> dictionary: aDictionary level: level [

	self header: 5 payload: aDictionary size.
	aDictionary associationsDo: [ :association | | key |
		key := association key.
		key class == ByteString
			ifTrue: [ self byteString: key ]
			ifFalse: [ self key: key ].
		self value: association value level: level + 1 ]

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> encode: anObject level: level maxDepth: depth floatHoles: aBoolean on: aByteArray [
	"Write the tape of anObject, at the indentation level, into aByteArray, or a larger
	ByteArray when it does not fit (tape), of at least 32 bytes"

	^ self encode: anObject level: level maxDepth: depth floatHoles: aBoolean on: aByteArray words: nil

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> encode: anObject level: level maxDepth: depth floatHoles: aBoolean on: aByteArray words: aWordArrayOrNil [
	"The same, with the code points of the WideStrings in aWordArrayOrNil, or in a larger
	WordArray when they do not fit (words)"

	words := aWordArrayOrNil.
	tape := aByteArray.
	limit := tape size - 16.
	position := 0.
	wordPosition := 0.
	maxDepth := depth.
	floatHoles := aBoolean.
	self value: anObject level: level

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> float: aFloat [
	"The number of a NaN or an infinity in the payload, which the library may name"

	self header: 3 payload: (aFloat isFinite ifTrue: [ 0 ] ifFalse: [ self number: aFloat ]).
	tape float64AtOffset: position put: aFloat.
	position := position + 8

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> header: tag payload: anInteger [
	"With room for the slot that may follow"

	position > limit ifTrue: [ self reserve: 16 ].
	tape int64AtOffset: position put: (anInteger bitShift: 8) + tag.
	position := position + 8

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> integer: anInteger [
	"A SmallInteger in the header, or in a slot of its own; a LargeInteger as the bytes of
	its magnitude, least significant first, padded to 8"

	| n |
	anInteger class == SmallInteger ifTrue: [
		(anInteger > -4503599627370496 and: [ anInteger < 4503599627370496 ])
			ifTrue: [ ^ self header: 1 payload: anInteger ].
		self header: 9 payload: 0.
		tape int64AtOffset: position put: anInteger.
		^ position := position + 8 ].
	n := anInteger size.
	self header: (anInteger negative ifTrue: [ 17 ] ifFalse: [ 16 ]) payload: n.
	self reserve: n + 7.
	tape replaceFrom: position + 1 to: position + n with: anInteger startingAt: 1.
	position := position + (n + 7 bitAnd: -8)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> key: aKey [
	"A string, without the check of the depth, as primitiveWrite writes a key"

	| class |
	class := aKey class.
	(class == ByteString or: [ class == ByteSymbol ]) ifTrue: [ ^ self byteString: aKey ].
	(class == WideString or: [ class == WideSymbol ]) ifTrue: [ ^ self wideString: aKey ].
	self header: 14 payload: (self number: aKey)

]

{ #category : 'private' }
SimdJSONTapeEncoder >> number: anObject [
	"The number, from 1, of an object the library may name"

	(objects ifNil: [ objects := OrderedCollection new ]) add: anObject.
	^ objects size

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> objects [
	"The objects numbered, in order (nil without any)"

	^ objects

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> position [
	"The bytes of the tape written"

	^ position

]

{ #category : 'private' }
SimdJSONTapeEncoder >> reserve: n [
	"Room for n more bytes in the tape"

	| grown |
	position + n <= tape size ifTrue: [ ^ self ].
	grown := ByteArray new: (2 * tape size max: position + n + 4096).
	grown replaceFrom: 1 to: position with: tape startingAt: 1.
	tape := grown.
	limit := tape size - 16

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> tape [

	^ tape

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> value: anObject level: level [
	"primitiveWrite's writeValue: the classes it knows exactly, the depth checked for an
	object that is neither immediate nor a Float, any other object a hole.  The most
	frequent classes are tested first; the classes are disjoint, so the order does not
	change what is written"

	| class |
	class := anObject class.
	class == ByteString ifTrue: [
		level > maxDepth ifTrue: [ ^ self header: 15 payload: (self number: anObject) ].
		^ self byteString: anObject ].
	class == SmallInteger ifTrue: [
		(anObject > -4503599627370496 and: [ anObject < 4503599627370496 ]) ifTrue: [
			position > limit ifTrue: [ self reserve: 16 ].
			tape int64AtOffset: position put: (anObject bitShift: 8) + 1.
			^ position := position + 8 ].
		^ self integer: anObject ].
	anObject == nil ifTrue: [ ^ self header: 6 payload: 0 ].
	class == Dictionary ifTrue: [
		level > maxDepth ifTrue: [ ^ self header: 15 payload: (self number: anObject) ].
		^ self dictionary: anObject level: level ].
	(class == SmallFloat64 or: [ class == BoxedFloat64 ]) ifTrue: [
		floatHoles ifTrue: [ ^ self header: 13 payload: (self number: anObject) ].
		^ self float: anObject ].
	(class == Array or: [ class == OrderedCollection ]) ifTrue: [
		level > maxDepth ifTrue: [ ^ self header: 15 payload: (self number: anObject) ].
		^ self array: anObject level: level ].
	anObject == true ifTrue: [ ^ self header: 7 payload: 0 ].
	anObject == false ifTrue: [ ^ self header: 8 payload: 0 ].
	anObject isImmediateObject ifTrue: [ ^ self header: 13 payload: (self number: anObject) ].
	level > maxDepth ifTrue: [ ^ self header: 15 payload: (self number: anObject) ].
	class == ByteSymbol ifTrue: [ ^ self byteString: anObject ].
	(class == WideString or: [ class == WideSymbol ]) ifTrue: [ ^ self wideString: anObject ].
	(class == LargePositiveInteger or: [ class == LargeNegativeInteger ]) ifTrue: [ ^ self integer: anObject ].
	self header: 13 payload: (self number: anObject)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> wideString: aString [
	"Its number, and its code points in the words"

	| n grown |
	n := aString size.
	self header: 11 payload: n.
	tape int64AtOffset: position put: (self number: aString).
	position := position + 8.
	words ifNil: [ words := WordArray new: (n + 256 max: 1024) asLargerPowerOfTwo ].
	wordPosition + n > words size ifTrue: [
		grown := WordArray new: (2 * words size max: wordPosition + n + 1024).
		grown replaceFrom: 1 to: wordPosition with: words startingAt: 1.
		words := grown ].
	n > 0 ifTrue: [ words replaceFrom: wordPosition + 1 to: wordPosition + n with: aString startingAt: 1 ].
	wordPosition := wordPosition + n

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> wordPosition [
	"The words written"

	^ wordPosition

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> words [
	"The code points of the WideStrings, or nil"

	^ words

]
