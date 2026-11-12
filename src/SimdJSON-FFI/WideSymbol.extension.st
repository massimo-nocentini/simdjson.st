Extension { #name : 'WideSymbol' }

{ #category : '*SimdJSON-FFI' }
WideSymbol >> simdJSONPassableCopy [
	"A copy that the library reads in place: a WideString"

	^ WideString withAll: self
]

{ #category : '*SimdJSON-FFI' }
WideSymbol >> simdJSONTapeKeyOn: anEncoder [
	"Exactly a WideSymbol, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == WideSymbol ifFalse: [ ^ super simdJSONTapeKeyOn: anEncoder ].
	^ anEncoder wideString: self
]

{ #category : '*SimdJSON-FFI' }
WideSymbol >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a WideSymbol, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == WideSymbol ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder wideString: self level: level
]
