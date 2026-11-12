Extension { #name : 'Dictionary' }

{ #category : '*SimdJSON' }
Dictionary >> isSimdJSONPlain [
	"Exactly a Dictionary"

	^ self class == Dictionary
]

{ #category : '*SimdJSON' }
Dictionary >> simdJSONWrite: anObject on: aWriter [
	"A map, as NeoJSON's neoJsonOn: of my class"

	^ aWriter writeMap: anObject
]
