Extension { #name : 'OrderedCollection' }

{ #category : '*SimdJSON-FFI' }
OrderedCollection >> simdJSONTapeOn: anEncoder level: level [
	"Exactly an OrderedCollection, as primitiveWrite: an instance of a subclass is what my
	superclass makes of it"

	self class == OrderedCollection ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder orderedCollection: self level: level
]
