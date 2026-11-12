Extension { #name : 'True' }

{ #category : '*SimdJSON' }
True >> simdJSONWriteOn: aWriter [
	"true, exactly: another instance of my class is what my superclass makes of it"

	self == true ifFalse: [ ^ super simdJSONWriteOn: aWriter ].
	^ aWriter writeBoolean: self
]
