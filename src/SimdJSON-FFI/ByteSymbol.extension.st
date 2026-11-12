Extension { #name : 'ByteSymbol' }

{ #category : '*SimdJSON-FFI' }
ByteSymbol >> simdJSONTapeKeyOn: anEncoder [
	"Exactly a ByteSymbol, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == ByteSymbol ifFalse: [ ^ super simdJSONTapeKeyOn: anEncoder ].
	^ anEncoder byteString: self
]

{ #category : '*SimdJSON-FFI' }
ByteSymbol >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a ByteSymbol, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == ByteSymbol ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder byteString: self level: level
]
