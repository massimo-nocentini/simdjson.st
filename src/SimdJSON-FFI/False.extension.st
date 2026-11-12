Extension { #name : 'False' }

{ #category : '*SimdJSON-FFI' }
False >> simdJSONTapeOn: anEncoder level: level [
	"Exactly false, as primitiveWrite: another instance of my class is what my superclass
	makes of it"

	self == false ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder falseHeader
]
