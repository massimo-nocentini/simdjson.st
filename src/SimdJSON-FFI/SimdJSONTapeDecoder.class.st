"
I make the objects of a JSON value from the tape that libSimdJSONFFI writes (SimdJSONLibrary): 8-byte slots in pre-order, each value a header, payload << 8 | tag, then its data (plugins/SimdJSONPlugin/include/ffi/sjFFI.h has the layout).

I make what primitiveRead makes: Arrays, and SimdJSONFlatMaps (k1 v1 k2 v2 ...) or, with SimdJSONReader flagDict, Dictionaries; ByteStrings or WideStrings, the narrowest; Integers and Floats.  The code points of the WideStrings are in a WordArray of their own, from which one primitive copies each.  The text of a number that NeoJSON's rules convert (an exponent, an integer beyond 64 bits) is a ByteString that I note as a fixup, which SimdJSONReader>>finish: converts, as it converts the plugin's.
"
Class {
	#name : 'SimdJSONTapeDecoder',
	#superclass : 'Object',
	#instVars : [
		'tape',
		'position',
		'words',
		'wordPosition',
		'dictionaries',
		'symbolKeys',
		'lastText',
		'fixups'
	],
	#category : 'SimdJSON-FFI-Library',
	#package : 'SimdJSON-FFI',
	#tag : 'Library'
}

{ #category : 'decoding' }
SimdJSONTapeDecoder >> array: n [

	| array value |
	array := Array new: n.
	1 to: n do: [ :i |
		value := self next.
		array at: i put: value.
		(lastText notNil and: [ value == lastText ]) ifTrue: [ self fixup: array slot: i ] ].
	^ array

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> byteString: n [
	"n Latin-1 bytes, padded to 8"

	| string |
	string := ByteString new: n.
	n > 0 ifTrue: [ string replaceFrom: 1 to: n with: tape startingAt: position + 1 ].
	position := position + (n + 7 bitAnd: -8).
	^ string

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> decode: aByteArray at: offset words: aWordArray flags: flags [
	"The value whose tape starts at the 0-based offset of aByteArray, the code points of
	its WideStrings in aWordArray (nil without any)"

	tape := aByteArray.
	position := offset.
	words := aWordArray.
	wordPosition := 0.
	dictionaries := flags anyMask: SimdJSONReader flagDict.
	symbolKeys := dictionaries not and: [ flags anyMask: SimdJSONReader flagSymbolKeys ].
	^ self next

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> dictionary: n [
	"A later duplicate key replaces the value, as Dictionary>>at:put: does"

	| dictionary key value |
	dictionary := Dictionary new: n.
	n timesRepeat: [
		key := self next.
		value := self next.
		dictionary at: key put: value.
		(lastText notNil and: [ value == lastText ]) ifTrue: [
			self fixup: (dictionary associationAt: key) slot: (Association allInstVarNames indexOf: #value) ] ].
	^ dictionary

]

{ #category : 'private' }
SimdJSONTapeDecoder >> fixup: container slot: index [
	"The number text lastText is at the slot index of container, for instVarAt:"

	fixups ifNil: [ fixups := OrderedCollection new ].
	fixups add: container; add: index; add: lastText.
	lastText := nil

]

{ #category : 'accessing' }
SimdJSONTapeDecoder >> fixupsFor: result [
	"The fixups of primRead:'s answer result: (container, slot) pairs of the number texts,
	the root's at the slot 2 of result; nil without any.  A text that a later duplicate key
	replaced is not one"

	| pairs |
	(lastText notNil and: [ (result at: 2) == lastText ]) ifTrue: [ self fixup: result slot: 2 ].
	fixups ifNil: [ ^ nil ].
	pairs := OrderedCollection new: fixups size // 3 * 2.
	1 to: fixups size by: 3 do: [ :i |
		((fixups at: i) instVarAt: (fixups at: i + 1)) == (fixups at: i + 2) ifTrue: [
			pairs add: (fixups at: i); add: (fixups at: i + 1) ] ].
	^ pairs ifEmpty: [ nil ] ifNotEmpty: [ pairs asArray ]

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> float [

	| float |
	float := tape float64AtOffset: position.
	position := position + 8.
	^ float

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> int64 [
	"Beyond 2^52: two uint32, the high one first (int64AtOffset: answers wrong values
	beyond the SmallIntegers)"

	| integer |
	integer := self uint64.
	^ integer >= 16r8000000000000000
		ifTrue: [ integer - 16r10000000000000000 ]
		ifFalse: [ integer ]

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> next [
	"The value at position, which moves after it; the tags of sjFFI.h, the most frequent
	first"

	| header tag |
	header := tape int64AtOffset: position.	"a SmallInteger: |payload| < 2^52"
	position := position + 8.
	tag := header bitAnd: 255.
	tag = 1 ifTrue: [ ^ header bitShift: -8 ].
	tag = 2 ifTrue: [ ^ self byteString: (header bitShift: -8) ].
	tag = 3 ifTrue: [ ^ self float ].
	tag = 4 ifTrue: [ ^ self array: (header bitShift: -8) ].
	tag = 5 ifTrue: [ ^ self object: (header bitShift: -8) ].
	tag = 6 ifTrue: [ ^ nil ].
	tag = 7 ifTrue: [ ^ true ].
	tag = 8 ifTrue: [ ^ false ].
	tag = 9 ifTrue: [ ^ self int64 ].
	tag = 10 ifTrue: [ ^ self uint64 ].
	tag = 11 ifTrue: [ ^ self wideString: (header bitShift: -8) ].
	tag = 12 ifTrue: [ ^ lastText := self byteString: (header bitShift: -8) ].
	^ self error: 'SimdJSONTapeDecoder: no tag ' , tag printString

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> object: n [

	| map value |
	dictionaries ifTrue: [ ^ self dictionary: n ].
	map := SimdJSONFlatMap new: 2 * n.
	1 to: 2 * n by: 2 do: [ :i |
		map at: i put: (symbolKeys
			ifTrue: [ self next asSymbol ]
			ifFalse: [ self next ]).
		value := self next.
		map at: i + 1 put: value.
		(lastText notNil and: [ value == lastText ]) ifTrue: [ self fixup: map slot: i + 1 ] ].
	^ map

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> uint64 [

	| integer |
	integer := ((tape uint32AtOffset: position) bitShift: 32) + (tape uint32AtOffset: position + 4).
	position := position + 8.
	^ integer

]

{ #category : 'decoding' }
SimdJSONTapeDecoder >> wideString: n [
	"The next n code points of the words"

	| string |
	string := WideString new: n.
	string replaceFrom: 1 to: n with: words startingAt: wordPosition + 1.
	wordPosition := wordPosition + n.
	^ string

]
