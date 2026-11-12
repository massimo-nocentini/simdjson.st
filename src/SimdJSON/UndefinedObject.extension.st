Extension { #name : 'UndefinedObject' }

{ #category : '*SimdJSON' }
UndefinedObject >> simdJSONWriteOn: aWriter [
	"null, exactly nil: another instance of my class is what my superclass makes of it"

	self == nil ifFalse: [ ^ super simdJSONWriteOn: aWriter ].
	^ aWriter writeNull
]
