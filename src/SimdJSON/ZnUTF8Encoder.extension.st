Extension { #name : 'ZnUTF8Encoder' }

{ #category : '*SimdJSON' }
ZnUTF8Encoder >> simdJSONSinkFor: aStream [
	"UTF-8 already: the binary stream of aStream, so that the JSON is not encoded twice;
	exactly a ZnUTF8Encoder"

	self class == ZnUTF8Encoder ifFalse: [ ^ super simdJSONSinkFor: aStream ].
	^ aStream wrappedStream
]
