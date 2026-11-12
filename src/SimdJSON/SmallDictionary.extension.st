Extension { #name : 'SmallDictionary' }

{ #category : '*SimdJSON' }
SmallDictionary >> simdJSONWrite: anObject on: aWriter [
	"A map, as NeoJSON's neoJsonOn: of my class"

	^ aWriter writeMap: anObject
]
