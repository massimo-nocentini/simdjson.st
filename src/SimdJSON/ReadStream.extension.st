Extension { #name : 'ReadStream' }

{ #category : '*SimdJSON' }
ReadStream >> simdJSONContents [
	"My collection, exactly a ReadStream: the originalContents of InflateStream,
	GZipReadStream and the other subclasses are compressed"

	self class == ReadStream ifFalse: [ ^ super simdJSONContents ].
	^ self originalContents
]
