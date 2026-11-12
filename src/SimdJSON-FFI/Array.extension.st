Extension { #name : 'Array' }

{ #category : '*SimdJSON-FFI' }
Array >> simdJSONTapeOn: anEncoder level: level [
	"Exactly an Array, as primitiveWrite: an instance of a subclass is what my superclass
	makes of it"

	self class == Array ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder array: self level: level
]
