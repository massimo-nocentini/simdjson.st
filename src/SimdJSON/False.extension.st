Extension { #name : 'False' }

{ #category : '*SimdJSON' }
False >> simdJSONWriteOn: aWriter [
	"false, exactly: another instance of my class is what my superclass makes of it"

	self == false ifFalse: [ ^ super simdJSONWriteOn: aWriter ].
	^ aWriter writeBoolean: self
]
