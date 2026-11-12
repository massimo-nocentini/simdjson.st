"
I write the tape of a value for sj_ffi_write of libSimdJSONFFI (SimdJSONLibrary), which writes its JSON: 8-byte slots in pre-order, each value a header, payload << 8 | tag, then its data, and the code points of the WideStrings in a WordArray of their own (plugins/SimdJSONPlugin/include/ffi/sjFFI.h has the layout).

I walk a value as primitiveWrite walks it.  Each value answers simdJSONTapeOn:level: with my method for its kind (nullHeader, smallInteger:, float:, byteString:level:, array:level:, dictionary:level:...), and each key answers simdJSONTapeKeyOn:.  primitiveWrite knows nil, true, false and the instances of exactly SmallInteger, LargePositiveInteger, LargeNegativeInteger, SmallFloat64, BoxedFloat64, ByteString, ByteSymbol, WideString, WideSymbol, Array, OrderedCollection and Dictionary: their methods check that the receiver is exactly of their class (or nil, true, false itself) and pass any other instance to their superclass, up to ProtoObject's, which makes it a hole that the image writes; a Dictionary is a hole too when a slot of its array holds anything but nil or exactly an Association (isSimdJSONTapeEntry), and what I wrote of it is taken back.  The holes, the keys that are not strings, the values deeper than maxDepth, the NaNs and infinities and the WideStrings are numbered in the order I meet them (objects), so that the library can name the culprit of an error, or the object of a hole, by its number.
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
SimdJSONTapeEncoder >> array: anArray level: level [
	"Each element, one level deeper"

	| next |
	level > maxDepth ifTrue: [ ^ self deep: anArray ].
	self header: 4 payload: anArray size.
	next := level + 1.
	1 to: anArray size do: [ :i | (anArray at: i) simdJSONTapeOn: self level: next ]

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> badKey: aKey [
	"A key that is not a string, the culprit of the error"

	self header: 14 payload: (self number: aKey)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> byteString: aString [
	"Its Latin-1 bytes, padded to 8, without the check of the depth (a key); byteString:level:
	repeats me, one send fewer per string value, and changes with me"

	| n |
	n := aString size.
	position + n > limit ifTrue: [ self reserve: n + 16 ].
	tape int64AtOffset: position put: (n bitShift: 8) + 2.
	n > 0 ifTrue: [ tape replaceFrom: position + 9 to: position + 8 + n with: aString startingAt: 1 ].
	position := position + 8 + (n + 7 bitAnd: -8)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> byteString: aString level: level [
	"As byteString:, after the check of the depth; inline, one send fewer per string"

	| n |
	level > maxDepth ifTrue: [ ^ self deep: aString ].
	n := aString size.
	position + n > limit ifTrue: [ self reserve: n + 16 ].
	tape int64AtOffset: position put: (n bitShift: 8) + 2.
	n > 0 ifTrue: [ tape replaceFrom: position + 9 to: position + 8 + n with: aString startingAt: 1 ].
	position := position + 8 + (n + 7 bitAnd: -8)

]

{ #category : 'private' }
SimdJSONTapeEncoder >> deep: anObject [
	"The culprit of a value deeper than maxDepth"

	self header: 15 payload: (self number: anObject)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> dictionary: aDictionary level: level [
	"Each key, then its value, one level deeper, in the order of the slots of its array, as
	primitiveWrite; a hole, as there, when a slot that is not empty is not isSimdJSONTapeEntry
	(an instance of a subclass of Association, added with add:).  primitiveWrite checks the
	slots first; I check each one as I walk, and on such a slot take back what I wrote of
	aDictionary, and the objects I numbered in it, in one pass"

	| array next start startWords numbered |
	level > maxDepth ifTrue: [ ^ self deep: aDictionary ].
	array := aDictionary array.
	start := position.
	startWords := wordPosition.
	numbered := objects ifNil: [ 0 ] ifNotNil: [ objects size ].
	self header: 5 payload: aDictionary size.
	next := level + 1.
	1 to: array size do: [ :i |
		(array at: i) ifNotNil: [ :association |
			association isSimdJSONTapeEntry ifFalse: [
				position := start.
				wordPosition := startWords.
				objects ifNotNil: [ objects removeLast: objects size - numbered ].
				^ self hole: aDictionary ].
			association key simdJSONTapeKeyOn: self.
			association value simdJSONTapeOn: self level: next ] ]

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
	anObject simdJSONTapeOn: self level: level

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> falseHeader [
	"false, in the header"

	self header: 8 payload: 0

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> float: aFloat [
	"A hole with floatHoles; the number of a NaN or an infinity in the payload, which the
	library may name"

	floatHoles ifTrue: [ ^ self hole: aFloat ].
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
SimdJSONTapeEncoder >> hole: anObject [
	"Written by the image; without the check of the depth (an immediate, a Float with
	floatHoles)"

	self header: 13 payload: (self number: anObject)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> hole: anObject level: level [
	"Written by the image, after the check of the depth"

	level > maxDepth ifTrue: [ ^ self deep: anObject ].
	self hole: anObject

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> largeInteger: anInteger level: level [
	"The bytes of its magnitude, least significant first, padded to 8"

	| n |
	level > maxDepth ifTrue: [ ^ self deep: anInteger ].
	n := anInteger size.
	self header: (anInteger negative ifTrue: [ 17 ] ifFalse: [ 16 ]) payload: n.
	self reserve: n + 7.
	tape replaceFrom: position + 1 to: position + n with: anInteger startingAt: 1.
	position := position + (n + 7 bitAnd: -8)

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> nullHeader [
	"null, in the header"

	self header: 6 payload: 0

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

{ #category : 'encoding' }
SimdJSONTapeEncoder >> orderedCollection: aCollection level: level [
	"As array:level:, each element one level deeper"

	| next |
	level > maxDepth ifTrue: [ ^ self deep: aCollection ].
	self header: 4 payload: aCollection size.
	next := level + 1.
	aCollection do: [ :each | each simdJSONTapeOn: self level: next ]

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

{ #category : 'encoding' }
SimdJSONTapeEncoder >> smallInteger: anInteger [
	"In the header, or in a slot of its own beyond 52 bits"

	(anInteger > -4503599627370496 and: [ anInteger < 4503599627370496 ]) ifTrue: [
		position > limit ifTrue: [ self reserve: 16 ].
		tape int64AtOffset: position put: (anInteger bitShift: 8) + 1.
		^ position := position + 8 ].
	self header: 9 payload: 0.
	tape int64AtOffset: position put: anInteger.
	position := position + 8

]

{ #category : 'accessing' }
SimdJSONTapeEncoder >> tape [

	^ tape

]

{ #category : 'encoding' }
SimdJSONTapeEncoder >> trueHeader [
	"true, in the header"

	self header: 7 payload: 0

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

{ #category : 'encoding' }
SimdJSONTapeEncoder >> wideString: aString level: level [
	"As wideString:, after the check of the depth"

	level > maxDepth ifTrue: [ ^ self deep: aString ].
	self wideString: aString

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
