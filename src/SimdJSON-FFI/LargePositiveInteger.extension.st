Extension { #name : 'LargePositiveInteger' }

{ #category : '*SimdJSON-FFI' }
LargePositiveInteger >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a LargePositiveInteger, as primitiveWrite: an instance of a subclass is what my
	superclass makes of it"

	self class == LargePositiveInteger ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder largeInteger: self level: level
]
