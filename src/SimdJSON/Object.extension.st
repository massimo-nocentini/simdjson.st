Extension { #name : 'Object' }

{ #category : '*SimdJSON' }
Object >> isSimdJSONFailure [
	"Whether I am the SimdJSONFailure that a primitive failed with"

	^ false
]

{ #category : '*SimdJSON' }
Object >> isSimdJSONFlatMap [
	"Whether I am a map of the tree that SimdJSONReader materializes"

	^ false
]

{ #category : '*SimdJSON' }
Object >> simdJSONKeyIn: aKeyTable [
	"A key of the tree, a String: myself"

	^ self
]

{ #category : '*SimdJSON' }
Object >> simdJSONMaterializeWith: aReader map: aMapClass list: aListClass [
	"A node of the tree, materialized by aReader with aMapClass and aListClass: a number, a
	string, nil, true or false is itself"

	^ self
]

{ #category : '*SimdJSON' }
Object >> simdJSONSinkOf: aStream [
	"The stream the JSON goes to when written on aStream, which is me or a proxy that stands
	for me: aStream itself"

	^ aStream
]

{ #category : '*SimdJSON' }
Object >> simdJSONWrite: anObject on: aWriter [
	"Write anObject, myself or a proxy that stands for me, on aWriter as NeoJSON's neoJsonOn:
	of my class does: with the mapping of the class of anObject"

	^ aWriter writeObject: anObject
]
