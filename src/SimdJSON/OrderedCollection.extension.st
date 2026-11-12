Extension { #name : 'OrderedCollection' }

{ #category : '*SimdJSON' }
OrderedCollection >> isSimdJSONPlain [
	"Exactly an OrderedCollection"

	^ self class == OrderedCollection
]
