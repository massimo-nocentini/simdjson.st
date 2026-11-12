Extension { #name : 'BoxedFloat64' }

{ #category : '*SimdJSON-FFI' }
BoxedFloat64 >> simdJSONTapeOn: anEncoder level: level [
	"Exactly a BoxedFloat64, as primitiveWrite: an instance of a subclass is what my
	superclass makes of it"

	self class == BoxedFloat64 ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder float: self
]
