Extension { #name : 'OrderedDictionary' }

{ #category : '*SimdJSON' }
OrderedDictionary >> simdJSONWrite: anObject on: aWriter [
	"A map, as NeoJSON's neoJsonOn: of my class"

	^ aWriter writeMap: anObject
]
