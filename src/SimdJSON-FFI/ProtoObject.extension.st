Extension { #name : 'ProtoObject' }

{ #category : '*SimdJSON-FFI' }
ProtoObject >> isSimdJSONSmallInteger [
	"Whether I am a SmallInteger, as primitiveRead and primitiveWrite want their numbers; a
	proxy answers for itself, as they look at the oop"

	^ false
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> isSimdJSONTapeEntry [
	"Whether primitiveWrite walks a Dictionary with me in a slot of its array that is not
	empty (nil): only exactly an Association; any other object makes it a hole"

	^ false
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONEncoding [
	"The SJ_ENC_* of sjBridge.h with which the library reads me in place, or nil; a proxy
	answers for itself, as the FFI passes its own slots"

	^ nil
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONPassableCopy [
	"A copy of me that the library reads in place as primitiveRead reads me, by my format: my
	bytes in a ByteString (Latin-1), my 32-bit words in a WideString (UTF-32); nil for any
	other format, which primitiveRead refuses.  SimdJSONLibrary>>passable: asks it of a
	source that the FFI does not pass in place, since my own tfPointerAddress may not be the
	address of my bytes (an ExternalAddress answers the one it holds, an Integer its value).
	A proxy answers for itself, as primitiveRead looks at its own format; thisContext sizes
	me, since a class rooted at ProtoObject has no basicSize"

	| copy |
	self class isBytes ifTrue: [ copy := ByteString new: (thisContext objectSize: self) ].
	self class isWords ifTrue: [ copy := WideString new: (thisContext objectSize: self) ].
	^ copy ifNotNil: [
		copy replaceFrom: 1 to: copy size with: self startingAt: 1.
		copy ]
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONTapeKeyOn: anEncoder [
	"Write me as a key of a Dictionary, without the check of the depth: a key that is not a
	string, the culprit of the error"

	^ anEncoder badKey: self
]

{ #category : '*SimdJSON-FFI' }
ProtoObject >> simdJSONTapeOn: anEncoder level: level [
	"Write my tape on anEncoder, at level, as primitiveWrite writes me: any object that it
	does not know is a hole, which the image writes"

	^ anEncoder hole: self level: level
]
