Extension { #name : 'String' }

{ #category : '*SimdJSON' }
String >> simdJSONSourceKind [
	"In characters"

	^ #string
]

{ #category : '*SimdJSON' }
String >> simdJSONWrite: anObject on: aWriter [
	"Any String, escaped"

	^ aWriter writeString: anObject
]
