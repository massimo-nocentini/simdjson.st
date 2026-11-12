Extension { #name : 'ZnCharacterWriteStream' }

{ #category : '*SimdJSON' }
ZnCharacterWriteStream >> simdJSONSinkOf: aStream [
	"What my encoder makes of aStream, which is me or a proxy that stands for me"

	^ self encoder simdJSONSinkFor: aStream
]
