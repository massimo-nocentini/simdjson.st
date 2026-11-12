Extension { #name : 'True' }

{ #category : '*SimdJSON-FFI' }
True >> simdJSONTapeOn: anEncoder level: level [
	"Exactly true, as primitiveWrite: another instance of my class is what my superclass
	makes of it"

	self == true ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder trueHeader
]
