Extension { #name : 'Collection' }

{ #category : '*SimdJSON' }
Collection >> simdJSONWrite: anObject on: aWriter [
	"Any other collection, as a list"

	^ aWriter writeList: anObject
]
