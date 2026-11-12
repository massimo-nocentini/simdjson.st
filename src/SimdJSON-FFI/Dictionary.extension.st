Extension { #name : 'Dictionary' }

{ #category : '*SimdJSON-FFI' }
Dictionary >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a Dictionary, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == Dictionary ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder dictionary: self level: level
]
