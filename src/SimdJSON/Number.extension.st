Extension { #name : 'Number' }

{ #category : '*SimdJSON' }
Number >> simdJSONWrite: anObject on: aWriter [
	"Any other number, as a Float"

	^ aWriter writeFloat: anObject asFloat
]
