Extension { #name : 'LargeNegativeInteger' }

{ #category : '*SimdJSON-FFI' }
LargeNegativeInteger >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a LargeNegativeInteger, as primitiveWrite: an instance of a subclass is what my
	superclass makes of it"

	self class == LargeNegativeInteger ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder largeInteger: self level: level
]
