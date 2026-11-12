Extension { #name : 'UndefinedObject' }

{ #category : '*SimdJSON-FFI' }
UndefinedObject >> simdJSONTapeOn: anEncoder level: level [
	"Exactly nil, as primitiveWrite: another instance of my class is what my superclass makes
	of it"

	self == nil ifFalse: [ ^ super simdJSONTapeOn: anEncoder level: level ].
	^ anEncoder nullHeader
]
