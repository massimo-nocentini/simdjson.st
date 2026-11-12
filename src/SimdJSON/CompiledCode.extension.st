Extension { #name : 'CompiledCode' }

{ #category : '*SimdJSON' }
CompiledCode >> simdJSONWrite: anObject on: aWriter [
	"With the mapping of the class of anObject, not as the list of my bytes that Collection's
	would write: I am a ByteArray that answers false to isCollection, which writeOther:
	asked before it asked the class"

	^ aWriter writeObject: anObject
]
